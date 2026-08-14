const fs = require('fs');

function patchFile(filePath, replacements) {
  if (fs.existsSync(filePath)) {
    let content = fs.readFileSync(filePath, 'utf8');
    for (const [oldVal, newVal] of replacements) {
      content = content.split(oldVal).join(newVal);
    }
    fs.writeFileSync(filePath, content);
    console.log("Patched successfully:", filePath);
  }
}

// 1. Patch handlers.js to return exact error message from catch
patchFile('/app/dist/tools/handlers.js', [
  ['error: "Authentication failed or was cancelled"', 'error: "Auth Fail: " + (error ? (error.stack || error.message || String(error)) : "Unknown")'],
  ['error: "Re-authentication failed or was cancelled"', 'error: "Re-Auth Fail: " + (error ? (error.stack || error.message || String(error)) : "Unknown")']
]);

// 2. Patch auth-manager.js to throw error on failure instead of returning false
patchFile('/app/dist/auth/auth-manager.js', [
  ['log.error(`❌ Login failed: ${error}`);', 'throw new Error(`Login failed details: ${error}`);'],
  ['log.error("❌ Login verification failed - timeout reached");', 'throw new Error(`Login verification timeout reached on URL: ${currentUrl}`);'],
  ['headless: !shouldShowBrowser', 'headless: false'],
  ['getPreferredChannel()', '"chromium"'],
  ['currentUrl.startsWith("https://notebooklm.google.com/")', 'currentUrl.includes("notebook.google.com") || currentUrl.includes("notebooklm.google.com")'],
  ['notebooklm.google.com', 'notebook.google.com'],
  ['notebooklm%2Egoogle%2Ecom', 'notebook%2Egoogle%2Ecom']
]);

// 3. Patch config.js
patchFile('/app/dist/config.js', [
  ['notebooklm.google.com', 'notebook.google.com'],
  ['notebooklm%2Egoogle%2Ecom', 'notebook%2Egoogle%2Ecom']
]);
