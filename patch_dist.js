const fs = require('fs');
const path = require('path');

function replaceInAllJsFiles(dir) {
  const files = fs.readdirSync(dir, { recursive: true });
  for (const file of files) {
    const fullPath = path.join(dir, file);
    if (fs.statSync(fullPath).isFile() && fullPath.endswith('.js')) {
      let content = fs.readFileSync(fullPath, 'utf8');
      let modified = false;
      
      // Patch executablePath into any launch options object
      if (content.includes('launchPersistentContext')) {
        content = content.replaceAll('launchPersistentContext(', 'launchPersistentContext(');
      }
      
      // Force channel: "chromium" or remove channel so patchright uses system executablePath
      if (content.includes('withChannel(')) {
        content = content.replaceAll('withChannel(baseLaunchOptions, preferred)', 'Object.assign({}, baseLaunchOptions, { channel: undefined, executablePath: "/usr/bin/chromium" })');
        content = content.replaceAll('withChannel(baseLaunchOptions, "chromium")', 'Object.assign({}, baseLaunchOptions, { channel: undefined, executablePath: "/usr/bin/chromium" })');
        modified = true;
      }

      if (content.includes('paths.data, "chrome_profile"') || content.includes('paths.data,"chrome_profile"')) {
        content = content.replaceAll('paths.data, "chrome_profile"', '"/data/chrome_profile"');
        content = content.replaceAll('paths.data,"chrome_profile"', '"/data/chrome_profile"');
        modified = true;
      }
      
      if (modified) {
        fs.writeFileSync(fullPath, content);
        console.log(`[PATCH SUCCESS] Patched ${fullPath}`);
      }
    }
  }
}

replaceInAllJsFiles('/app/dist');
