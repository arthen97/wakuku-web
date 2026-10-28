import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const dist = path.join(root, 'dist');
fs.rmSync(dist, { recursive: true, force: true });
fs.cpSync(path.join(root, 'public'), dist, { recursive: true });
const manifest = JSON.parse(fs.readFileSync(path.join(root, 'pack-parts/manifest.json'), 'utf8'));
const destination = path.join(dist, manifest.target);
const output = fs.openSync(destination, 'w');
const whole = crypto.createHash('sha256');
let bytes = 0;
try {
  for (const part of manifest.parts) {
    const data = fs.readFileSync(path.join(root, 'pack-parts', part.file));
    const digest = crypto.createHash('sha256').update(data).digest('hex');
    if (data.length !== part.bytes || digest !== part.sha256) throw new Error(`Corrupt resource part: ${part.file}`);
    fs.writeSync(output, data);
    whole.update(data);
    bytes += data.length;
  }
} finally {
  fs.closeSync(output);
}
if (bytes !== manifest.bytes || whole.digest('hex') !== manifest.sha256) throw new Error('Game resource pack checksum mismatch');
const release = JSON.parse(fs.readFileSync(path.join(dist, 'release-manifest.json'), 'utf8'));
if (release.pack_sha256 !== manifest.sha256) throw new Error('Release manifest does not match resource pack');
console.log(`WAKUKU v${release.version}: complete HTML game → dist (${bytes} pack bytes, SHA-256 verified)`);
