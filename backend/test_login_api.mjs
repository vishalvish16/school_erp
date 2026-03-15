import 'dotenv/config';
import { writeFileSync } from 'fs';

const url = 'http://localhost:3000/api/platform/auth/login';
const body = {
    email: "vishal.vish16@gmail.com",
    identifier: "vishal.vish16@gmail.com",
    password: "Vishal@123",
    device_fingerprint: "test-fingerprint-123",
    device_meta: { device_type: "web" },
    portal_type: "super_admin"
};

fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body)
})
    .then(async r => {
        const data = await r.json();
        writeFileSync('login_full_response.txt', JSON.stringify(data, null, 2), 'utf8');
        console.log('Status:', r.status);
        console.log('Check login_full_response.txt');
    })
    .catch(e => console.error('Error:', e));
