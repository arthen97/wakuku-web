import fs from 'node:fs';
fs.rmSync('dist',{recursive:true,force:true});
fs.cpSync('public','dist',{recursive:true});
console.log('WAKUKU V9: static WebGL release copied to dist');
