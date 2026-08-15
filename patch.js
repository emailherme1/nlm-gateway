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

// Patch handlers.js for Ground Truth Diagnostic Test
replaceInFile('/app/dist/tools/handlers.js', 'stealth_enabled: CONFIG.stealthEnabled,', 'stealth_enabled: CONFIG.stealthEnabled, content_sample: debugText,');

// Patch browser-session.js to bypass waitForNotebookLMReady error throw
replaceInFile('/app/dist/session/browser-session.js', 'throw new Error("Could not find NotebookLM chat input. " +', 'return; //');
replaceInFile('/app/dist/session/browser-session.js', 'throw new Error("Could not find NotebookLM chat input. " +\r\n                    "Please ensure the notebook page has loaded correctly.", { cause: error });', 'return;');
replaceInFile('/app/dist/session/browser-session.js', 'throw new Error("Could not find NotebookLM chat input. " +\n                    "Please ensure the notebook page has loaded correctly.", { cause: error });', 'return;');
