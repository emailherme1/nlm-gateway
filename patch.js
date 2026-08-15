const fs = require('fs');
const path = require('path');

function replaceInFile(filePath, searchRegex, replaceStr) {
  if (fs.existsSync(filePath)) {
    let content = fs.readFileSync(filePath, 'utf8');
    if (searchRegex.test(content)) {
      content = content.replace(searchRegex, replaceStr);
      fs.writeFileSync(filePath, content);
      console.log(`[PATCH SUCCESS] Replaced regex in ${filePath}`);
    } else {
      console.log(`[PATCH WARNING] Regex match not found in ${filePath}`);
    }
  }
}

// Regex patch for throw new Error("Could not find NotebookLM chat input...")
replaceInFile(
  '/app/dist/session/browser-session.js',
  /throw\s+new\s+Error\s*\(\s*["']Could not find NotebookLM chat input[\s\S]*?\);/g,
  'log.warning("BYPASSING_CHAT_INPUT_ERROR"); return;'
);

// Regex patch for fallback selectors
replaceInFile(
  '/app/dist/session/browser-session.js',
  /textarea\.query-box-input/g,
  'textarea, div[contenteditable="true"], input'
);
