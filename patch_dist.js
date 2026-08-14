const fs = require('fs');

function patchFile(filePath, searchStr, replaceStr) {
  if (fs.existsSync(filePath)) {
    let content = fs.readFileSync(filePath, 'utf8');
    content = content.split(searchStr).join(replaceStr);
    fs.writeFileSync(filePath, content);
    console.log("Patched successfully:", filePath);
  }
}

// Patch compiled dist/session/shared-context-manager.js
patchFile('/app/dist/session/shared-context-manager.js', 'args: [', 'executablePath: "/usr/bin/chromium", args: [');
patchFile('/app/dist/auth/auth-manager.js', 'args: [', 'executablePath: "/usr/bin/chromium", args: [');

// Unify profile path to /data/chrome_profile
patchFile('/app/dist/config.js', 'paths.data, "chrome_profile"', '"/data/chrome_profile"');
