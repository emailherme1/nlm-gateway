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

// Patch handlers.js for nlm diagnostic test
replaceInFile('/app/dist/tools/handlers.js', 'stealth_enabled: CONFIG.stealthEnabled,', 'stealth_enabled: CONFIG.stealthEnabled, query_result: queryResult, add_source_result: addSourceResult,');
