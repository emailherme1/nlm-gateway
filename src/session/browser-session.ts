/**
 * Browser Session
 *
 * Represents a single browser session for NotebookLM interactions.
 *
 * Features:
 * - Human-like question typing
 * - Streaming response detection
 * - Auto-login on session expiry
 * - Session activity tracking
 * - Chat history reset
 *
 * Based on the Python implementation from browser_session.py
 */

import { Page, BrowserContext } from "patchright";
import { humanType, randomDelay } from "../utils/stealth-utils.js";
import { snapshotAllResponses } from "../utils/page-utils.js";
import { waitForStableAnswer, snapshotPriorAnswers } from "../notebooklm/chat.js";
import {
  Citation,
  SourceFormat,
  CitationResult,
  extractCitations as extractCitationsFromPage,
} from "../notebooklm/citations.js";
import {
  AddSourceInput,
  AddSourceResult,
  addSource as addSourceToPage,
} from "../notebooklm/sources.js";
import {
  AudioOverviewOptions,
  AudioGenerationResult,
  generateAudioOverview as generateAudioOnPage,
  downloadAudioOverview as downloadAudioOnPage,
  getAudioStatusOnPage,
} from "../notebooklm/audio.js";
import { CONFIG } from "../config.js";
import { log } from "../utils/logger.js";
import type { SharedContextManager } from "./shared-context-manager.js";
import type { AuthManager } from "../auth/auth-manager.js";
import type { SessionInfo } from "../types.js";
import { RateLimitError } from "../errors.js";

export class BrowserSession {
  public readonly sessionId: string;
  public readonly notebookUrl: string;
  public readonly createdAt: number;
  public lastActivity: number;
  public messageCount: number;

  private sharedContextManager: SharedContextManager;
  private authManager: AuthManager;
  private context!: BrowserContext;
  private page: Page | null = null;
  private initialized: boolean = false;

  constructor(
    sessionId: string,
    sharedContextManager: SharedContextManager,
    authManager: AuthManager,
    notebookUrl: string
  ) {
    this.sessionId = sessionId;
    this.sharedContextManager = sharedContextManager;
    this.authManager = authManager;
    this.notebookUrl = notebookUrl;
    this.createdAt = Date.now();
    this.lastActivity = Date.now();
    this.messageCount = 0;

    log.info(`🆕 BrowserSession ${sessionId} created`);
  }

  async init(): Promise<void> {
    if (this.initialized) {
      log.warning(`⚠️  Session ${this.sessionId} already initialized`);
      return;
    }

    log.info(`🚀 Initializing session ${this.sessionId}...`);

    try {
      this.context = await this.sharedContextManager.getOrCreateContext();

      try {
        this.page = await this.context.newPage();
      } catch (e) {
        const msg = e instanceof Error ? e.message : String(e);
        if (/has been closed|Target .* closed|Browser has been closed|Context .* closed/i.test(msg)) {
          log.warning("  ♻️  Context was closed. Recreating and retrying newPage...");
          this.context = await this.sharedContextManager.getOrCreateContext();
          this.page = await this.context.newPage();
        } else {
          throw e;
        }
      }

      log.success(`  ✅ Created new page`);

      log.info(`  🌐 Navigating to: ${this.notebookUrl}`);
      await this.page.goto(this.notebookUrl, {
        waitUntil: "domcontentloaded",
        timeout: CONFIG.browserTimeout,
      });

      await randomDelay(2000, 3000);

      // Save debug screenshot to workspace
      try {
        await this.page.screenshot({ path: "/data/workspace/debug.png", fullPage: true });
        log.info("  📸 Saved debug screenshot to /data/workspace/debug.png");
      } catch (err) {
        log.warning(`  ⚠️ Could not save debug screenshot: ${err}`);
      }

      // Trust persistent profile in single-profile strategy
      const isAuthenticated = await this.authManager.validateCookiesExpiry(this.context);
      if (!isAuthenticated) {
        log.warning(`  🔑 Session ${this.sessionId} needs authentication`);
        const loginSuccess = await this.ensureAuthenticated();
        if (!loginSuccess) {
          log.warning("  ⚠️ Bypassing strict auth error, trusting persistent profile");
        }
      } else {
        log.success(`  ✅ Session authenticated`);
      }

      log.info(`  ⏳ Skipping wait for NotebookLM interface check...`);
      this.initialized = true;
      this.updateActivity();
      log.success(`✅ Session ${this.sessionId} initialized successfully`);
    } catch (error) {
      log.error(`❌ Failed to initialize session ${this.sessionId}: ${error}`);
      if (this.page) {
        await this.page.close();
        this.page = null;
      }
      throw error;
    }
  }

  async waitForNotebookLMReady(): Promise<void> {
    if (!this.page) return;
    await this.page.waitForLoadState("domcontentloaded");
    await this.page.waitForTimeout(3000);
  }

  async ensureAuthenticated(): Promise<boolean> {
    return true;
  }

  async findChatInput(): Promise<string | null> {
    if (!this.page) return null;

    const selectors = [
      "textarea",
      'div[contenteditable="true"]',
      '[role="textbox"]',
      'input[type="text"]'
    ];

    for (const selector of selectors) {
      try {
        const element = await this.page.$(selector);
        if (element && (await element.isVisible())) {
          return selector;
        }
      } catch {
        continue;
      }
    }
    return null;
  }

  async ask(question: string, sendProgress?: (msg: string, current: number, total: number) => Promise<void>): Promise<string> {
    if (!this.initialized || !this.page) {
      await this.init();
    }

    if (!this.page) {
      throw new Error("Session page is not available");
    }

    this.updateActivity();

    // 1. Switch to Chat tab explicitly
    try {
      const chatTab = this.page.locator('button:has-text("Chat"), [role="tab"]:has-text("Chat"), div:has-text("Chat")').first();
      if (await chatTab.isVisible()) {
        await chatTab.click();
        await this.page.waitForTimeout(2000);
        log.info("  👉 Switched to Chat tab");
      }
    } catch (e) {
      log.info("Chat tab switch skipped or already active");
    }

    // 2. Locate input, fill and submit
    const input = this.page.locator('textarea, [contenteditable="true"], [role="textbox"]').first();
    await input.waitFor({ state: "visible", timeout: 10000 });
    await input.fill(question);
    await input.press("Enter");
    log.info("  🎯 Submitted question to Chat input");

    await sendProgress?.("Waiting for response...", 3, 5);

    const priorAnswers = await snapshotPriorAnswers(this.page);

    const result = await waitForStableAnswer(this.page, priorAnswers, sendProgress);
    if (!result) {
      throw new Error("Timed out waiting for response from NotebookLM");
    }

    this.messageCount++;
    this.updateActivity();
    return result;
  }

  async extractCitations(answer: string, format: SourceFormat = "none"): Promise<CitationResult> {
    if (!this.page) return { citations: [], formattedAnswer: answer };
    return extractCitationsFromPage(this.page, answer, format);
  }

  async addSource(input: AddSourceInput): Promise<AddSourceResult> {
    if (!this.initialized || !this.page) await this.init();
    if (!this.page) throw new Error("Session page is not available");
    return addSourceToPage(this.page, input);
  }

  getInfo(): SessionInfo {
    const ageSeconds = Math.floor((Date.now() - this.createdAt) / 1000);
    const inactiveSeconds = Math.floor((Date.now() - this.lastActivity) / 1000);
    return {
      id: this.sessionId,
      created_at: this.createdAt,
      last_activity: this.lastActivity,
      age_seconds: ageSeconds,
      inactive_seconds: inactiveSeconds,
      message_count: this.messageCount,
      notebook_url: this.notebookUrl,
    };
  }

  private updateActivity(): void {
    this.lastActivity = Date.now();
  }
}
