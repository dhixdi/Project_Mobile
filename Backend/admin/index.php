<?php
session_start();
if (isset($_SESSION['login_time']) && (time() - $_SESSION['login_time']) > 7200) {
    session_destroy();
    header('Location: login.php?reason=timeout');
    exit;
}
if (!isset($_SESSION['admin_id'])) {
    header('Location: login.php');
    exit;
}
$_SESSION['login_time'] = time();
$admin_username = htmlspecialchars($_SESSION['admin_username']);
?>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Panel - Gudang Pintar</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <style>
        body { font-family: 'Inter', system-ui, -apple-system, sans-serif; }
        .sidebar-link { transition: all 0.2s; }
        .sidebar-link:hover { background: rgba(255,255,255,0.1); }
        .sidebar-link.active { background: rgba(255,255,255,0.15); border-left: 3px solid #3b82f6; }
        .fade-in { animation: fadeIn 0.3s ease-in; }
        @keyframes fadeIn { from { opacity: 0; transform: translateY(8px); } to { opacity: 1; transform: translateY(0); } }
    </style>
</head>
<body class="bg-slate-100 min-h-screen">

    <!-- Navbar -->
    <nav class="fixed top-0 left-0 right-0 bg-slate-700 text-white shadow-lg z-50 h-14 flex items-center px-6">
        <div class="flex items-center gap-3">
            <span class="text-2xl">🏭</span>
            <span class="text-lg font-bold tracking-wide">Gudang Pintar</span>
            <span class="bg-blue-500 text-xs font-semibold px-2.5 py-0.5 rounded-full ml-1">Panel Admin</span>
        </div>
        <div class="ml-auto flex items-center gap-4 text-sm">
            <span>👤 <?= $admin_username ?></span>
            <span class="text-slate-400">|</span>
            <a href="logout.php" class="text-red-300 hover:text-red-100 font-medium transition">Logout</a>
        </div>
    </nav>

    <!-- Sidebar -->
    <aside class="fixed top-14 left-0 w-52 h-[calc(100vh-3.5rem)] bg-slate-800 text-white shadow-xl z-40">
        <div class="py-6 space-y-1 px-3">
            <button onclick="showTab('paket')" id="tab-paket"
                    class="sidebar-link active w-full text-left px-4 py-3 rounded-lg flex items-center gap-3 text-sm font-medium">
                <span class="text-lg">📦</span> Manajemen Paket
            </button>
            <button onclick="showTab('kurir')" id="tab-kurir"
                    class="sidebar-link w-full text-left px-4 py-3 rounded-lg flex items-center gap-3 text-sm font-medium">
                <span class="text-lg">👤</span> Data Kurir
            </button>
            <button onclick="showTab('user')" id="tab-user"
                    class="sidebar-link w-full text-left px-4 py-3 rounded-lg flex items-center gap-3 text-sm font-medium">
                <span class="text-lg">⚙️</span> Manajemen User
            </button>
        </div>
        <div class="absolute bottom-4 left-0 right-0 text-center text-xs text-slate-500">
            &copy; 2026 Gudang Pintar
        </div>
    </aside>

    <!-- Main Content -->
    <main class="ml-52 mt-14 p-6">

        <!-- ===================== TAB 1: MANAJEMEN PAKET ===================== -->
        <section id="section-paket" class="fade-in">
            <!-- Stats Row -->
            <div class="grid grid-cols-1 md:grid-cols-3 gap-5 mb-8">
                <div class="bg-white rounded-xl shadow p-5 border-l-4 border-blue-500">
                    <p class="text-sm text-slate-500 font-medium">Total Paket</p>
                    <p id="stat-total" class="text-3xl font-bold text-slate-800 mt-1">0</p>
                </div>
                <div class="bg-white rounded-xl shadow p-5 border-l-4 border-amber-500">
                    <p class="text-sm text-slate-500 font-medium">Sedang Diantar</p>
                    <p id="stat-diantar" class="text-3xl font-bold text-slate-800 mt-1">0</p>
                </div>
                <div class="bg-white rounded-xl shadow p-5 border-l-4 border-emerald-500">
                    <p class="text-sm text-slate-500 font-medium">Selesai</p>
                    <p id="stat-selesai" class="text-3xl font-bold text-slate-800 mt-1">0</p>
                </div>
            </div>

            <!-- Add Paket Form -->
            <div class="bg-white rounded-xl shadow-md p-6 mb-8">
                <h2 class="text-lg font-bold text-slate-800 mb-5 flex items-center gap-2">📦 Tambah Paket Baru</h2>
                <form onsubmit="event.preventDefault(); tambahPaket();" class="space-y-4">
                    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                        <!-- No Resi -->
                        <div>
                            <label class="block text-sm font-semibold text-slate-700 mb-1">No. Resi</label>
                            <div class="flex gap-2">
                                <input type="text" id="no_resi" required
                                       class="flex-1 px-3 py-2 border border-slate-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                                       placeholder="GP-XXXXXX">
                                <button type="button" onclick="generateResi()"
                                        class="px-3 py-2 bg-slate-100 hover:bg-slate-200 rounded-lg text-sm transition" title="Generate Resi">
                                    🔄
                                </button>
                            </div>
                        </div>
                        <!-- Deskripsi -->
                        <div>
                            <label class="block text-sm font-semibold text-slate-700 mb-1">Deskripsi Barang</label>
                            <input type="text" id="deskripsi_barang" required
                                   class="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                                   placeholder="Deskripsi barang">
                        </div>
                        <!-- Nama Pengirim -->
                        <div>
                            <label class="block text-sm font-semibold text-slate-700 mb-1">Nama Pengirim</label>
                            <input type="text" id="nama_pengirim" required
                                   class="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                                   placeholder="Nama pengirim">
                        </div>
                        <!-- Nama Penerima -->
                        <div>
                            <label class="block text-sm font-semibold text-slate-700 mb-1">Nama Penerima</label>
                            <input type="text" id="nama_penerima" required
                                   class="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                                   placeholder="Nama penerima">
                        </div>
                        <!-- Alamat Penerima -->
                        <div class="lg:col-span-2">
                            <label class="block text-sm font-semibold text-slate-700 mb-1">Alamat Penerima</label>
                            <div class="flex gap-2">
                                <input type="text" id="alamat_penerima" required
                                       class="flex-1 px-3 py-2 border border-slate-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                                       placeholder="Alamat lengkap penerima">
                                <button type="button" onclick="geocodeAlamat()"
                                        class="px-3 py-2 bg-emerald-50 hover:bg-emerald-100 text-emerald-700 rounded-lg text-sm font-medium transition whitespace-nowrap">
                                    📍 Cari Koordinat
                                </button>
                            </div>
                        </div>
                        <!-- Geocode Result (hidden by default) -->
                        <div id="geocode-result" class="lg:col-span-3 hidden">
                            <div class="bg-emerald-50 border border-emerald-200 rounded-lg px-4 py-2 text-sm text-emerald-700">
                                <span id="geocode-text"></span>
                            </div>
                        </div>
                        <!-- Latitude -->
                        <div>
                            <label class="block text-sm font-semibold text-slate-700 mb-1">Latitude</label>
                            <input type="text" id="lat_penerima"
                                   class="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm bg-slate-50 focus:outline-none focus:ring-2 focus:ring-blue-500"
                                   placeholder="Latitude" readonly>
                        </div>
                        <!-- Longitude -->
                        <div>
                            <label class="block text-sm font-semibold text-slate-700 mb-1">Longitude</label>
                            <input type="text" id="lng_penerima"
                                   class="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm bg-slate-50 focus:outline-none focus:ring-2 focus:ring-blue-500"
                                   placeholder="Longitude" readonly>
                        </div>
                        <!-- Warehouse -->
                        <div>
                            <label class="block text-sm font-semibold text-slate-700 mb-1">Gudang Asal</label>
                            <select id="id_warehouse"
                                    class="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500">
                                <option value="1">Gudang Pusat Yogyakarta</option>
                                <option value="2">Gudang Hub Banguntapan</option>
                                <option value="3">Gudang Sortir Sleman</option>
                            </select>
                        </div>
                        <!-- Tipe -->
                        <div>
                            <label class="block text-sm font-semibold text-slate-700 mb-1">Tipe Pengiriman</label>
                            <select id="tipe" onchange="toggleTipeFields()"
                                    class="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500">
                                <option value="lokal">Lokal</option>
                                <option value="antargudang">Antar Gudang</option>
                            </select>
                        </div>
                        <!-- Warehouse Tujuan (hidden unless antargudang) -->
                        <div id="warehouse-tujuan-wrap" class="hidden">
                            <label class="block text-sm font-semibold text-slate-700 mb-1">Gudang Tujuan</label>
                            <select id="id_warehouse_tujuan"
                                    class="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500">
                                <option value="1">Gudang Pusat Yogyakarta</option>
                                <option value="2">Gudang Hub Banguntapan</option>
                                <option value="3">Gudang Sortir Sleman</option>
                            </select>
                        </div>
                        <!-- Kurir -->
                        <div>
                            <label class="block text-sm font-semibold text-slate-700 mb-1">Kurir</label>
                            <select id="id_kurir"
                                    class="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500">
                                <option value="">-- Pilih Kurir --</option>
                            </select>
                        </div>
                    </div>
                    <div class="pt-2">
                        <button type="submit"
                                class="bg-blue-600 hover:bg-blue-700 text-white font-semibold px-6 py-2.5 rounded-lg transition shadow hover:shadow-lg text-sm">
                            ➕ Tambah Paket
                        </button>
                    </div>
                </form>
            </div>

            <!-- Paket Table -->
            <div class="bg-white rounded-xl shadow-md overflow-hidden">
                <div class="px-6 py-4 border-b border-slate-200 flex items-center justify-between">
                    <h2 class="text-lg font-bold text-slate-800">📋 Daftar Paket</h2>
                    <button onclick="loadPaket()" class="text-sm text-blue-600 hover:text-blue-800 font-medium transition">🔄 Refresh</button>
                </div>
                <div class="overflow-x-auto">
                    <table class="w-full text-sm">
                        <thead class="bg-slate-50 text-slate-600 uppercase text-xs tracking-wider">
                            <tr>
                                <th class="px-5 py-3 text-left">Resi</th>
                                <th class="px-5 py-3 text-left">Barang</th>
                                <th class="px-5 py-3 text-left">Penerima</th>
                                <th class="px-5 py-3 text-left">Tipe</th>
                                <th class="px-5 py-3 text-left">Kurir</th>
                                <th class="px-5 py-3 text-left">Status</th>
                                <th class="px-5 py-3 text-center">Aksi</th>
                            </tr>
                        </thead>
                        <tbody id="paket-tbody" class="divide-y divide-slate-100">
                            <tr><td colspan="7" class="px-5 py-8 text-center text-slate-400">Memuat data...</td></tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </section>

        <!-- ===================== TAB 2: DATA KURIR ===================== -->
        <section id="section-kurir" class="hidden fade-in">
            <div class="bg-white rounded-xl shadow-md overflow-hidden">
                <div class="px-6 py-4 border-b border-slate-200 flex items-center justify-between">
                    <h2 class="text-lg font-bold text-slate-800">👤 Data Kurir</h2>
                    <button onclick="loadKurirTable()" class="text-sm text-blue-600 hover:text-blue-800 font-medium transition">🔄 Refresh</button>
                </div>
                <div class="overflow-x-auto">
                    <table class="w-full text-sm">
                        <thead class="bg-slate-50 text-slate-600 uppercase text-xs tracking-wider">
                            <tr>
                                <th class="px-5 py-3 text-left">ID</th>
                                <th class="px-5 py-3 text-left">Username</th>
                                <th class="px-5 py-3 text-left">Role</th>
                            </tr>
                        </thead>
                        <tbody id="kurir-tbody" class="divide-y divide-slate-100">
                            <tr><td colspan="3" class="px-5 py-8 text-center text-slate-400">Memuat data...</td></tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </section>

        <!-- ===================== TAB 3: MANAJEMEN USER ===================== -->
        <section id="section-user" class="hidden fade-in">
            <!-- Add User Form -->
            <div class="bg-white rounded-xl shadow-md p-6 mb-8">
                <h2 class="text-lg font-bold text-slate-800 mb-5 flex items-center gap-2">➕ Tambah User Baru</h2>
                <form onsubmit="event.preventDefault(); tambahUser();">
                    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                        <div>
                            <label class="block text-sm font-semibold text-slate-700 mb-1">Username</label>
                            <input type="text" id="new_username" required
                                   class="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                                   placeholder="Username baru">
                        </div>
                        <div>
                            <label class="block text-sm font-semibold text-slate-700 mb-1">Password</label>
                            <input type="password" id="new_password" required
                                   class="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                                   placeholder="Password">
                        </div>
                        <div>
                            <label class="block text-sm font-semibold text-slate-700 mb-1">Role</label>
                            <select id="new_role"
                                    class="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500">
                                <option value="kurir">Kurir</option>
                                <option value="kurir_transit">Kurir Transit</option>
                                <option value="admin">Admin</option>
                            </select>
                        </div>
                    </div>
                    <div class="pt-4">
                        <button type="submit"
                                class="bg-blue-600 hover:bg-blue-700 text-white font-semibold px-6 py-2.5 rounded-lg transition shadow hover:shadow-lg text-sm">
                            ➕ Tambah User
                        </button>
                    </div>
                </form>
            </div>

            <!-- User Table -->
            <div class="bg-white rounded-xl shadow-md overflow-hidden">
                <div class="px-6 py-4 border-b border-slate-200 flex items-center justify-between">
                    <h2 class="text-lg font-bold text-slate-800">👥 Daftar User</h2>
                    <button onclick="loadUsers()" class="text-sm text-blue-600 hover:text-blue-800 font-medium transition">🔄 Refresh</button>
                </div>
                <div class="overflow-x-auto">
                    <table class="w-full text-sm">
                        <thead class="bg-slate-50 text-slate-600 uppercase text-xs tracking-wider">
                            <tr>
                                <th class="px-5 py-3 text-left">ID</th>
                                <th class="px-5 py-3 text-left">Username</th>
                                <th class="px-5 py-3 text-left">Role</th>
                                <th class="px-5 py-3 text-left">Dibuat</th>
                                <th class="px-5 py-3 text-center">Aksi</th>
                            </tr>
                        </thead>
                        <tbody id="user-tbody" class="divide-y divide-slate-100">
                            <tr><td colspan="5" class="px-5 py-8 text-center text-slate-400">Memuat data...</td></tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </section>

    </main>

    <script>
        const API_BASE = '../api';

        // ==================== TAB NAVIGATION ====================
        function showTab(tab) {
            const tabs = ['paket', 'kurir', 'user'];
            tabs.forEach(t => {
                document.getElementById('section-' + t).classList.toggle('hidden', t !== tab);
                document.getElementById('tab-' + t).classList.toggle('active', t === tab);
            });
            if (tab === 'paket') loadPaket();
            if (tab === 'kurir') loadKurirTable();
            if (tab === 'user') loadUsers();
        }

        // ==================== GENERATE RESI ====================
        async function generateResi() {
            try {
                const res = await fetch(API_BASE + '/generate_resi.php');
                const data = await res.json();
                if (data.status === 'success') {
                    document.getElementById('no_resi').value = data.no_resi;
                }
            } catch (e) {
                alert('Gagal generate resi: ' + e.message);
            }
        }

        // ==================== GEOCODE ====================
        async function geocodeAlamat() {
            const alamat = document.getElementById('alamat_penerima').value.trim();
            if (!alamat) { alert('Masukkan alamat terlebih dahulu'); return; }
            try {
                const res = await fetch(API_BASE + '/geocode.php?address=' + encodeURIComponent(alamat));
                const data = await res.json();
                if (data.status === 'success') {
                    document.getElementById('lat_penerima').value = data.lat;
                    document.getElementById('lng_penerima').value = data.lng;
                    document.getElementById('geocode-text').textContent = '✅ Ditemukan: ' + data.alamat_formatted;
                    document.getElementById('geocode-result').classList.remove('hidden');
                } else {
                    alert('Geocode gagal: ' + (data.message || 'Alamat tidak ditemukan'));
                }
            } catch (e) {
                alert('Gagal geocode: ' + e.message);
            }
        }

        // ==================== LOAD KURIR DROPDOWN ====================
        async function loadKurir() {
            try {
                const res = await fetch(API_BASE + '/get_kurir.php');
                const data = await res.json();
                const sel = document.getElementById('id_kurir');
                sel.innerHTML = '<option value="">-- Pilih Kurir --</option>';
                if (data.status === 'success' && data.data) {
                    data.data.forEach(k => {
                        sel.innerHTML += `<option value="${k.id}">${k.username} (${k.role})</option>`;
                    });
                }
            } catch (e) {
                console.error('Gagal load kurir:', e);
            }
        }

        // ==================== LOAD KURIR TRANSIT DROPDOWN (for assignTransit) ====================
        async function loadKurirTransit() {
            try {
                const res = await fetch(API_BASE + '/get_kurir.php');
                const data = await res.json();
                if (data.status === 'success' && data.data) {
                    return data.data.filter(k => k.role === 'kurir_transit');
                }
            } catch (e) {
                console.error('Gagal load kurir transit:', e);
            }
            return [];
        }

        // ==================== LOAD PAKET ====================
        async function loadPaket() {
            try {
                const res = await fetch(API_BASE + '/get_paket.php');
                const data = await res.json();
                const tbody = document.getElementById('paket-tbody');

                if (data.status === 'success' && data.data && data.data.length > 0) {
                    const pakets = data.data;

                    // Stats
                    document.getElementById('stat-total').textContent = pakets.length;
                    document.getElementById('stat-diantar').textContent = pakets.filter(p => p.status === 'Sedang Diantar').length;
                    document.getElementById('stat-selesai').textContent = pakets.filter(p => p.status === 'Selesai').length;

                    // Status badge color map
                    const statusMap = {
                        'Di Gudang': 'bg-blue-100 text-blue-700',
                        'Transit Antargudang': 'bg-purple-100 text-purple-700',
                        'Di Gudang Tujuan': 'bg-indigo-100 text-indigo-700',
                        'Sedang Diantar': 'bg-amber-100 text-amber-700',
                        'Selesai': 'bg-emerald-100 text-emerald-700',
                    };

                    tbody.innerHTML = pakets.map(p => {
                        const badgeClass = statusMap[p.status] || 'bg-gray-100 text-gray-700';
                        const kurirName = p.kurir_username || '-';
                        const tipeLabel = p.tipe === 'antargudang'
                            ? '<span class="bg-purple-50 text-purple-600 px-2 py-0.5 rounded text-xs font-medium">Antargudang</span>'
                            : '<span class="bg-sky-50 text-sky-600 px-2 py-0.5 rounded text-xs font-medium">Lokal</span>';

                        let aksiHtml = `<button onclick="assignKurir(${p.id}, '${p.no_resi}')" class="text-xs bg-blue-50 hover:bg-blue-100 text-blue-700 px-3 py-1.5 rounded-lg font-medium transition">Assign Kurir</button>`;
                        if (p.tipe === 'lokal') {
                            aksiHtml += ` <button onclick="assignTransit(${p.id}, '${p.no_resi}')" class="text-xs bg-purple-50 hover:bg-purple-100 text-purple-700 px-3 py-1.5 rounded-lg font-medium transition">Antargudang</button>`;
                        }

                        return `<tr class="hover:bg-slate-50 transition">
                            <td class="px-5 py-3 font-mono text-xs font-semibold text-slate-700">${p.no_resi}</td>
                            <td class="px-5 py-3 text-slate-600">${p.deskripsi_barang}</td>
                            <td class="px-5 py-3 text-slate-600">${p.nama_penerima}</td>
                            <td class="px-5 py-3">${tipeLabel}</td>
                            <td class="px-5 py-3 text-slate-600">${kurirName}</td>
                            <td class="px-5 py-3"><span class="px-2.5 py-1 rounded-full text-xs font-semibold ${badgeClass}">${p.status}</span></td>
                            <td class="px-5 py-3 text-center space-x-1">${aksiHtml}</td>
                        </tr>`;
                    }).join('');
                } else {
                    document.getElementById('stat-total').textContent = '0';
                    document.getElementById('stat-diantar').textContent = '0';
                    document.getElementById('stat-selesai').textContent = '0';
                    tbody.innerHTML = '<tr><td colspan="7" class="px-5 py-8 text-center text-slate-400">Belum ada data paket</td></tr>';
                }
            } catch (e) {
                console.error('Gagal load paket:', e);
            }
        }

        // ==================== TAMBAH PAKET ====================
        async function tambahPaket() {
            const body = {
                no_resi: document.getElementById('no_resi').value.trim(),
                deskripsi_barang: document.getElementById('deskripsi_barang').value.trim(),
                nama_pengirim: document.getElementById('nama_pengirim').value.trim(),
                nama_penerima: document.getElementById('nama_penerima').value.trim(),
                alamat_penerima: document.getElementById('alamat_penerima').value.trim(),
                lat_penerima: document.getElementById('lat_penerima').value.trim(),
                lng_penerima: document.getElementById('lng_penerima').value.trim(),
                id_warehouse: document.getElementById('id_warehouse').value,
                tipe: document.getElementById('tipe').value,
                id_kurir: document.getElementById('id_kurir').value || null,
            };
            if (body.tipe === 'antargudang') {
                body.id_warehouse_tujuan = document.getElementById('id_warehouse_tujuan').value;
            }
            try {
                const res = await fetch(API_BASE + '/add_paket.php', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(body)
                });
                const data = await res.json();
                if (data.status === 'success') {
                    alert('✅ Paket berhasil ditambahkan!');
                    // Reset form
                    ['no_resi','deskripsi_barang','nama_pengirim','nama_penerima','alamat_penerima','lat_penerima','lng_penerima'].forEach(id => document.getElementById(id).value = '');
                    document.getElementById('geocode-result').classList.add('hidden');
                    loadPaket();
                } else {
                    alert('❌ Gagal: ' + (data.message || 'Terjadi kesalahan'));
                }
            } catch (e) {
                alert('❌ Error: ' + e.message);
            }
        }

        // ==================== ASSIGN KURIR ====================
        async function assignKurir(id, resi) {
            const kurirId = prompt(`Masukkan ID Kurir untuk paket ${resi}:`);
            if (!kurirId) return;
            try {
                const res = await fetch(API_BASE + '/assign_kurir.php', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ id_paket: id, id_kurir: parseInt(kurirId) })
                });
                const data = await res.json();
                if (data.status === 'success') {
                    alert('✅ Kurir berhasil di-assign!');
                    loadPaket();
                } else {
                    alert('❌ Gagal: ' + (data.message || 'Terjadi kesalahan'));
                }
            } catch (e) {
                alert('❌ Error: ' + e.message);
            }
        }

        // ==================== ASSIGN TRANSIT ====================
        async function assignTransit(id, resi) {
            const kurirTransitId = prompt(`Masukkan ID Kurir Transit untuk paket ${resi}:`);
            if (!kurirTransitId) return;
            const gudangTujuan = prompt('Masukkan ID Gudang Tujuan (1=Pusat Yogyakarta, 2=Hub Banguntapan, 3=Sortir Sleman):');
            if (!gudangTujuan) return;
            try {
                const res = await fetch(API_BASE + '/assign_kurir_transit.php', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        id_paket: id,
                        id_kurir_transit: parseInt(kurirTransitId),
                        id_warehouse_tujuan: parseInt(gudangTujuan)
                    })
                });
                const data = await res.json();
                if (data.status === 'success') {
                    alert('✅ Kurir Transit & Gudang Tujuan berhasil di-assign!');
                    loadPaket();
                } else {
                    alert('❌ Gagal: ' + (data.message || 'Terjadi kesalahan'));
                }
            } catch (e) {
                alert('❌ Error: ' + e.message);
            }
        }

        // ==================== TOGGLE TIPE FIELDS ====================
        function toggleTipeFields() {
            const tipe = document.getElementById('tipe').value;
            document.getElementById('warehouse-tujuan-wrap').classList.toggle('hidden', tipe !== 'antargudang');
        }

        // ==================== LOAD KURIR TABLE (Tab 2) ====================
        async function loadKurirTable() {
            try {
                const res = await fetch(API_BASE + '/get_kurir.php');
                const data = await res.json();
                const tbody = document.getElementById('kurir-tbody');
                if (data.status === 'success' && data.data && data.data.length > 0) {
                    tbody.innerHTML = data.data.map(k => {
                        const roleClass = k.role === 'kurir'
                            ? 'bg-blue-100 text-blue-700'
                            : 'bg-purple-100 text-purple-700';
                        return `<tr class="hover:bg-slate-50 transition">
                            <td class="px-5 py-3 font-semibold text-slate-700">${k.id}</td>
                            <td class="px-5 py-3 text-slate-600">${k.username}</td>
                            <td class="px-5 py-3"><span class="px-2.5 py-1 rounded-full text-xs font-semibold ${roleClass}">${k.role}</span></td>
                        </tr>`;
                    }).join('');
                } else {
                    tbody.innerHTML = '<tr><td colspan="3" class="px-5 py-8 text-center text-slate-400">Belum ada data kurir</td></tr>';
                }
            } catch (e) {
                console.error('Gagal load kurir table:', e);
            }
        }

        // ==================== LOAD USERS (Tab 3) ====================
        async function loadUsers() {
            try {
                const res = await fetch(API_BASE + '/get_users.php');
                const data = await res.json();
                const tbody = document.getElementById('user-tbody');
                if (data.status === 'success' && data.data && data.data.length > 0) {
                    tbody.innerHTML = data.data.map(u => {
                        const roleColors = {
                            admin: 'bg-red-100 text-red-700',
                            kurir: 'bg-blue-100 text-blue-700',
                            kurir_transit: 'bg-purple-100 text-purple-700',
                        };
                        const roleClass = roleColors[u.role] || 'bg-gray-100 text-gray-700';
                        const deleteBtn = u.role !== 'admin'
                            ? `<button onclick="hapusUser(${u.id}, '${u.username}')" class="text-xs bg-red-50 hover:bg-red-100 text-red-700 px-3 py-1.5 rounded-lg font-medium transition">Hapus</button>`
                            : '<span class="text-xs text-slate-400">—</span>';
                        return `<tr class="hover:bg-slate-50 transition">
                            <td class="px-5 py-3 font-semibold text-slate-700">${u.id}</td>
                            <td class="px-5 py-3 text-slate-600">${u.username}</td>
                            <td class="px-5 py-3"><span class="px-2.5 py-1 rounded-full text-xs font-semibold ${roleClass}">${u.role}</span></td>
                            <td class="px-5 py-3 text-slate-500 text-xs">${u.created_at || '-'}</td>
                            <td class="px-5 py-3 text-center">${deleteBtn}</td>
                        </tr>`;
                    }).join('');
                } else {
                    tbody.innerHTML = '<tr><td colspan="5" class="px-5 py-8 text-center text-slate-400">Belum ada data user</td></tr>';
                }
            } catch (e) {
                console.error('Gagal load users:', e);
            }
        }

        // ==================== TAMBAH USER ====================
        async function tambahUser() {
            const body = {
                username: document.getElementById('new_username').value.trim(),
                password: document.getElementById('new_password').value,
                role: document.getElementById('new_role').value,
            };
            if (!body.username || !body.password) {
                alert('Username dan password wajib diisi');
                return;
            }
            try {
                const res = await fetch(API_BASE + '/add_user.php', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(body)
                });
                const data = await res.json();
                if (data.status === 'success') {
                    alert('✅ User berhasil ditambahkan!');
                    document.getElementById('new_username').value = '';
                    document.getElementById('new_password').value = '';
                    loadUsers();
                    loadKurir(); // refresh kurir dropdown too
                } else {
                    alert('❌ Gagal: ' + (data.message || 'Terjadi kesalahan'));
                }
            } catch (e) {
                alert('❌ Error: ' + e.message);
            }
        }

        // ==================== HAPUS USER ====================
        async function hapusUser(id, username) {
            if (!confirm(`Yakin ingin menghapus user "${username}"?`)) return;
            try {
                const res = await fetch(API_BASE + '/delete_user.php', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ id: id })
                });
                const data = await res.json();
                if (data.status === 'success') {
                    alert('✅ User berhasil dihapus!');
                    loadUsers();
                    loadKurir();
                } else {
                    alert('❌ Gagal: ' + (data.message || 'Terjadi kesalahan'));
                }
            } catch (e) {
                alert('❌ Error: ' + e.message);
            }
        }

        // ==================== INIT ====================
        document.addEventListener('DOMContentLoaded', () => {
            loadPaket();
            loadKurir();
        });
    </script>
</body>
</html>
