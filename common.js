// common.js - ใช้ร่วมกันทุกหน้า (ต้องโหลดหลัง supabase-js)
const SUPABASE_URL = 'https://luuclnuknivvekxyiojz.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx1dWNsbnVrbml2dmVreHlpb2p6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI4NzY0MTIsImV4cCI6MjA4ODQ1MjQxMn0.0qmDRylJ-yN6QJtf50bGrn2mcqedwoakxVASKTxmLVg'; // anon key เปิดเผยได้ แต่ต้องเปิด RLS ใน Supabase
const _supabase = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// กัน XSS: ใช้ทุกครั้งที่นำข้อมูลจากฐานข้อมูลไปใส่ใน innerHTML
function esc(s) {
    return String(s ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
}

async function getUser() {
    const { data } = await _supabase.auth.getUser();
    return data?.user || null;
}
function displayName(user) {
    return user?.user_metadata?.full_name || user?.email?.split('@')[0] || 'User';
}
async function requireLogin() {
    const user = await getUser();
    if (!user) { alert('กรุณาเข้าสู่ระบบก่อนครับ'); location.href = 'login.html'; }
    return user;
}
async function logout() {
    await _supabase.auth.signOut();
    localStorage.removeItem('cart');
    location.href = 'index.html';
}

// ตะกร้า (เก็บในเครื่อง)
const Cart = {
    get() { try { return JSON.parse(localStorage.getItem('cart')) || []; } catch { return []; } },
    set(c) { localStorage.setItem('cart', JSON.stringify(c)); },
    add(item) {
        const c = this.get(), e = c.find(i => i.id === item.id);
        e ? e.quantity++ : c.push({ ...item, quantity: 1 });
        this.set(c);
    },
    count() { return this.get().reduce((s, i) => s + (i.quantity || 1), 0); }
};
