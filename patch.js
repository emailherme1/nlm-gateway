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
replaceInFile('/app/dist/tools/handlers.js', 'troubleshooting_tip: "For fresh start', 'troubleshooting_tip: "PERSIAN_CONTENT: " + debugText, tip: "For fresh start');
replaceInFile('/app/dist/tools/handlers.js', 'authenticated,', 'authenticated, ground_truth: true,');
