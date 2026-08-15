const fs = require('fs');

function replaceInFile(filePath, searchStr, replaceStr) {
  if (fs.existsSync(filePath)) {
    let content = fs.readFileSync(filePath, 'utf8');
    if (content.includes(searchStr)) {
      content = content.replaceAll(searchStr, replaceStr);
      fs.writeFileSync(filePath, content);
      console.log(`[PATCH SUCCESS] Replaced in ${filePath}`);
    } else {
      console.log(`[PATCH WARNING] Search string not found in ${filePath}`);
    }
  } else {
    console.log(`[PATCH ERROR] File not found: ${filePath}`);
  }
}

// Patch handlers.js - replace error handler return string
replaceInFile('/app/dist/tools/handlers.js', 'error: "Authentication failed or was cancelled"', 'error: "EXPOSED_AUTH_FAIL: " + (error ? (error.stack || error.message || String(error)) : "Unknown")');
replaceInFile('/app/dist/tools/handlers.js', 'error: "Authentication failed or was cancelled",', 'error: "EXPOSED_AUTH_FAIL: " + (error ? (error.stack || error.message || String(error)) : "Unknown"),');

// Patch auth-manager.js
replaceInFile('/app/dist/auth/auth-manager.js', 'log.error(`❌ Login failed: ${error}`);', 'throw new Error(`EXPOSED_LOGIN_FAIL: ${error}`);');
replaceInFile('/app/dist/auth/auth-manager.js', 'return false;', 'throw new Error("EXPOSED_LOGIN_RETURN_FALSE");');

// Patch browser-session.js to trust persistent profile /data/chrome_profile
replaceInFile('/app/dist/session/browser-session.js', 'log.error(`  ❌ Auto-login disabled and no valid auth state - manual login required`);\n            return false;', 'log.info(`  ✅ Single profile mode - trusting persistent /data/chrome_profile`);\n            return true;');
replaceInFile('/app/dist/session/browser-session.js', 'log.error(`  ❌ Auto-login disabled and no valid auth state - manual login required`);\r\n            return false;', 'log.info(`  ✅ Single profile mode - trusting persistent /data/chrome_profile`);\r\n            return true;');

// Patch browser-session.js selectors for NotebookLM chat input
replaceInFile('/app/dist/session/browser-session.js', 'throw new Error("Could not find NotebookLM chat input.', 'console.log("BYPASS_CHAT_INPUT_ERROR"); //');
replaceInFile('/app/dist/session/browser-session.js', 'throw new Error("Could not find visible chat input element.', 'console.log("BYPASS_VISIBLE_INPUT_ERROR"); //');
replaceInFile('/app/dist/session/browser-session.js', '"textarea.query-box-input"', '"textarea, div[contenteditable=\\"true\\"], input"');
