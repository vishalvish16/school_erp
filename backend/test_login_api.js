// Quick test for backend login
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
        const text = await r.text();
        console.log('Status:', r.status);
        console.log('Full Response:');
        console.log(text);
    })
    .catch(e => console.error('Error:', e));
