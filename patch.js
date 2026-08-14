const fs = require('fs');

// Patch handlers.js
let hPath = '/app/dist/tools/handlers.js';
if (fs.existsSync(hPath)) {
  let content = fs.readFileSync(hPath, 'utf8');
  content = content.replace(/Authentication failed or was cancelled/g, "Auth Failed (Patched JS Exposed)");
  fs.writeFileSync(hPath, content);
  console.log("Patched handlers.js successfully!");
}

// Patch auth-manager.js performSetup headless
let aPath = '/app/dist/auth/auth-manager.js';
if (fs.existsSync(aPath)) {
  let content = fs.readFileSync(aPath, 'utf8');
  content = content.replace(/headless:\s*!shouldShowBrowser/g, "headless: false");
  content = content.replace(/notebooklm\.google\.com/g, "notebook.google.com");
  content = content.replace(/notebooklm%2Egoogle%2Ecom/g, "notebook%2Egoogle%2Ecom");
  fs.writeFileSync(aPath, content);
  console.log("Patched auth-manager.js successfully!");
}
