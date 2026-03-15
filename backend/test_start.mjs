import { execSync } from 'child_process';
import { writeFileSync } from 'fs';
try {
    const out = execSync('node src/server.js', { cwd: '.', timeout: 5000, encoding: 'utf8', stdio: ['pipe', 'pipe', 'pipe'] });
    writeFileSync('startup_output.txt', 'STDOUT:\n' + out, 'utf8');
} catch (e) {
    writeFileSync('startup_output.txt', 'ERROR:\n' + (e.stderr || '') + '\nSTDOUT:\n' + (e.stdout || '') + '\nMessage: ' + e.message, 'utf8');
}
console.log('Check startup_output.txt');
