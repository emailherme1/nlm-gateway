const fs = require('fs');
const path = require('path');

function replaceInAllJsFiles(dir) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      replaceInAllJsFiles(fullPath);
    } else if (entry.isFile() && entry.name.endsWith('.js')) {
      let content = fs.readFileSync(fullPath, 'utf8');
      let modified = false;

      // Add executablePath directly inside baseLaunchOptions
      if (content.includes('headless: shouldBeHeadless')) {
        content = content.replaceAll('headless: shouldBeHeadless', 'executablePath: "/usr/bin/chromium", headless: shouldBeHeadless');
        modified = true;
      }

      if (content.includes('paths.data, "chrome_profile"') || content.includes('paths.data,"chrome_profile"')) {
        content = content.replaceAll('paths.data, "chrome_profile"', '"/data/chrome_profile"');
        content = content.replaceAll('paths.data,"chrome_profile"', '"/data/chrome_profile"');
        modified = true;
      }

      if (modified) {
        fs.writeFileSync(fullPath, content);
        console.log("[PATCH SUCCESS] Patched JS:", fullPath);
      }
    }
  }
}

replaceInAllJsFiles('/app/dist');
