const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const projectRoot = path.resolve(__dirname, '..');
const timestamp = Date.now();
const pkgDir = path.join(projectRoot, 'pkg');
const zipDir = path.join(projectRoot, 'zip');
const zipFileName = `lambda-${timestamp}.zip`;
const zipFilePath = path.join(zipDir, zipFileName);

try {
  if (!fs.existsSync(zipDir)) {
    fs.mkdirSync(zipDir);
  }
  process.chdir(pkgDir);
  execSync(`zip -r ${zipFilePath} .`, { stdio: 'inherit' });
  process.chdir(projectRoot);
  console.log(`created ${zipFilePath}`);

  const stats = fs.statSync(zipFilePath);
  const fileSizeInBytes = stats.size;
  const fileSizeInMB = fileSizeInBytes / (1024 * 1024);

  if (fileSizeInMB > 1) {
    throw new Error(
      `Zip size is ${fileSizeInMB.toFixed(2)} MB. Lambda@Edge "viewerRequest" limit is 1MB.`
    );
  }
} catch (error) {
  console.error('Zip creation failed:', error);
  process.exit(1);
}
