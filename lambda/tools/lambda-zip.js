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
    execSync('pnpm lambda:pkg', { stdio: 'inherit', cwd: projectRoot });
    if (!fs.existsSync(zipDir)) {
        fs.mkdirSync(zipDir);
    }
    process.chdir(pkgDir);
    execSync(`zip -r ${zipFilePath} .`, { stdio: 'inherit' });
    process.chdir(projectRoot);
    console.log(`created ${zipFilePath}`);
} catch (error) {
    console.error('failed to create lambda zip:', error);
    process.exit(1);
}
