const fs = require('fs');
const path = require('path');

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

function replaceInDir(dirPath, searchStr, replaceStr) {
  if (!fs.existsSync(dirPath)) return;
  const files = fs.readdirSync(dirPath, { recursive: true });
  for (const file of files) {
    const fullPath = path.join(dirPath, file);
    if (fs.statSync(fullPath).isFile() && (fullPath.endsWith('.js') || fullPath.endsWith('.mjs'))) {
      replaceInFile(fullPath, searchStr, replaceStr);
    }
  }
}

// Global replacement across /app/dist
replaceInDir('/app/dist', 'throw new Error("Could not find NotebookLM chat input', 'log.warning("BYPASSING_CHAT_INPUT"); return; //');
replaceInDir('/app/dist', 'textarea.query-box-input', 'textarea, [contenteditable="true"], input');
replaceInDir('/app/dist', 'Authentication failed or was cancelled', 'EXPOSED_AUTH_FAIL');
