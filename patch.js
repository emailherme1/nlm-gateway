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

// Minimal error reporting patch
replaceInFile('/app/dist/tools/handlers.js', 'error: "Authentication failed or was cancelled"', 'error: "EXPOSED_AUTH_FAIL: " + (error ? (error.stack || error.message || String(error)) : "Unknown")');
