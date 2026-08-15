/**
 * Browser-channel selection with safe fallback (issues #13 + #19).
 *
 * Patchright launches `channel: "chrome"` by default, which talks to the
 * system Chrome install. Two failure modes hit users:
 *   - macOS 26 (Tahoe) ships a Chrome binary that crashes on launch in
 *     headless mode (issue #13).
 *   - Windows 11 reports `Chrome exited immediately with exit code 21`
 *     when the persistent profile is locked or the channel binary is
 *     missing (issue #19).
 *
 * Patchright bundles its own Chromium build, which avoids both. We let users
 * pick explicitly via `BROWSER_CHANNEL` / `NOTEBOOKLM_BROWSER_CHANNEL` and
 * fall back to bundled Chromium if Chrome refuses to launch.
 */

export type BrowserChannel = "chrome" | "chromium";

/**
 * Errors from a failed `chromium.launchPersistentContext` that hint at a
 * channel/binary problem we can recover from by switching to bundled
 * Chromium.
 */
const CHANNEL_FAILURE_PATTERNS: readonly RegExp[] = [
  /Failed to launch.*chrome/i,
  /chrome.*not found/i,
  /chrome.*exited immediately/i,
  /executable doesn't exist/i,
  /executable.*missing/i,
  /code 21/i,
  /code -?6/i,
];

export function getPreferredChannel(): BrowserChannel {
  const raw = (process.env.NOTEBOOKLM_BROWSER_CHANNEL || process.env.BROWSER_CHANNEL || "")
    .trim()
    .toLowerCase();
  if (raw === "chromium") return "chromium";
  return "chrome";
}

export function isChannelFailure(error: unknown): boolean {
  const msg = error instanceof Error ? error.message : String(error);
  return CHANNEL_FAILURE_PATTERNS.some((re) => re.test(msg));
}

/**
 * Wrap an existing launch options object with the chosen channel. `chromium`
 * means "no channel" — the bundled binary is selected by omitting the field.
 */
const LOW_MEMORY_FLAGS = [
  "--no-sandbox",
  "--disable-dev-shm-usage",
  "--disable-gpu",
  "--no-zygote",
  "--renderer-process-limit=1",
  "--disable-smooth-scrolling",
  "--disable-component-update",
  "--disable-features=Translate,OptimizationHints,MediaRouter",
  "--js-flags=--max-old-space-size=256 --optimize-for-size",
];

export function withChannel<T extends Record<string, unknown>>(
  options: T,
  _channel: BrowserChannel
): T {
  const { channel: _drop, ...rest } = options as { channel?: unknown } & T;
  const merged: Record<string, unknown> = { ...rest, executablePath: "/usr/bin/chromium" };
  const existingArgs = Array.isArray(merged.args) ? (merged.args as string[]) : [];
  merged.args = [...existingArgs, ...LOW_MEMORY_FLAGS.filter((f) => !existingArgs.includes(f))];
  return merged as unknown as T;
}
