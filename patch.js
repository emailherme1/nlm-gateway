const fs = require('fs');

function replaceInFile(filePath, searchStr, replaceStr) {
  if (fs.existsSync(filePath)) {
    let content = fs.readFileSync(filePath, 'utf8');
    if (content.includes(searchStr)) {
      content = content.replaceAll(searchStr, replaceStr);
      fs.writeFileSync(filePath, content);
      console.log(`[PATCH SUCCESS] Replaced in ${filePath}`);
    }
  }
}

// Patch handlers.js for active account check
replaceInFile('/app/dist/tools/handlers.js', 'stealth_enabled: CONFIG.stealthEnabled,', 'stealth_enabled: CONFIG.stealthEnabled, active_google_email: activeEmail, target_url: "https://notebooklm.google.com/notebook/8ea457f6-2a15-4b96-b689-60839083c577", screenshot_saved: screenshotExists,');
