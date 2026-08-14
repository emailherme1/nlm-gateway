const fs = require('fs');
const path = require('path');

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

// 1. Patch handlers.js
patchFile('/app/dist/tools/handlers.js', [
  ['Authentication failed or was cancelled', 'Auth Failed (JS Patched Exposures)'],
  ['Re-authentication failed or was cancelled', 'Re-Auth Failed (JS Patched Exposures)']
]);

// 2. Patch auth-manager.js
patchFile('/app/dist/auth/auth-manager.js', [
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
