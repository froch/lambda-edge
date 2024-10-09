const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const projectRoot = path.resolve(__dirname, '..');
const timestamp = Date.now();
const pkgDir = path.join(projectRoot, 'pkg');
const zipDir = path.join(projectRoot, 'zip');
const zipFileName = `lambda-${timestamp}.zip`;
const zipFilePath = path.join(zipDir, zipFileName);

// -------- internals -------- //

const _getenv = (name) => {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Environment variable ${name} is required`);
  }
  return value;
};

const _mkdir = (dir) => {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir);
  }
};

const _mkZip = (sourceDir, zipFilePath) => {
  process.chdir(sourceDir);
  execSync(`zip -r ${zipFilePath} .`, { stdio: 'inherit' });
  process.chdir(projectRoot);
  console.log(`created ${zipFilePath}`);
};

const _zipExists = (zipFilePath, maxSizeMB) => {
  const stats = fs.statSync(zipFilePath);
  const fileSizeInMB = stats.size / (1024 * 1024);
  if (fileSizeInMB > maxSizeMB) {
    throw new Error(`Zip size is ${fileSizeInMB.toFixed(2)} MB. Lambda@Edge "viewerRequest" limit is ${maxSizeMB}MB.`);
  }
};

const _cp = (source, destination) => {
  fs.copyFileSync(source, destination);
  console.log(`created ${destination}`);
};

const _s3upload = (filePath, s3dirname) => {
  const fileName = path.basename(filePath);
  const fullUploadPath = `${s3dirname}/${fileName}`;
  console.log(`aws s3 cp ${filePath} ${fullUploadPath}`);
  execSync(`aws s3 cp ${filePath} ${fullUploadPath}`, { stdio: 'inherit' });
};

// -------- main -------- //

const main = () => {
  try {
    const s3bucket = _getenv('AWS_S3_BUCKET_NAME');
    const s3path = _getenv('AWS_S3_BUCKET_PATH');
    const s3dirname = `s3://${s3bucket}/${s3path}`;

    _mkdir(zipDir);
    _mkZip(pkgDir, zipFilePath);
    _zipExists(zipFilePath, 1);

    const latestZipFilePath = path.join(zipDir, 'lambda-latest.zip');
    _cp(zipFilePath, latestZipFilePath);

    _s3upload(zipFilePath, s3dirname);
    _s3upload(latestZipFilePath, s3dirname);
  } catch (error) {
    console.error('Zip job failed:', error);
    process.exit(1);
  }
}

// -------- entrypoint -------- //

main();
