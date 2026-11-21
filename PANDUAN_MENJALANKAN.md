# 🚀 PANDUAN MENJALANKAN SISTEM FINCHAT (LAPORAN KEUANGAN)
### FastAPI Backend & Aplikasi Mobile Flutter

Panduan ini berisi langkah-langkah praktis dan terstruktur untuk menjalankan sistem **FinChat** baik di HP fisik (Wireless / Kabel USB), Android Emulator, maupun Browser Web.

---

## ⚡ Langkah Cepat (Hanya 2 Terminal)

Buka **2 Tab Terminal** di VS Code:

### 🔹 Tab 1: Menyalakan Backend FinChat (FastAPI)
```bash
# 1. Masuk ke folder backend
cd backend

# 2. Aktifkan virtual environment
source venv/bin/activate

# 3. Jalankan server backend
python run.py
```
*Server aktif di `http://0.0.0.0:8000`*.

---

### 🔹 Tab 2: Menghubungkan HP & Menjalankan Aplikasi Mobile

#### **Jika Menggunakan HP Fisik (Wireless ADB):**
```bash
# 1. Pastikan berada di root folder proyek
cd ~/perkuliahan/pemrograman_mobile/test_app_rizqi

# 2. Sambungkan ADB Wireless ke HP Anda (lihat IP & Port di Opsi Pengembang HP)
# Contoh: adb connect 192.168.1.50:41235
adb connect <IP_HP_ANDA>:<PORT_HP>

# 3. KUNCI UTAMA: Buka jembatan port HP ke Laptop
adb reverse tcp:8000 tcp:8000

# 4. Jalankan aplikasi ke HP
flutter run -d <IP_HP_ANDA>:<PORT_HP>
```

#### **Jika Menggunakan Kabel USB:**
```bash
adb reverse tcp:8000 tcp:8000
flutter run
```

#### **Jika Menggunakan Android Emulator:**
Ganti `baseUrl` di `lib/services/api_service.dart` menjadi `http://10.0.2.2:8000/api`, lalu jalankan:
```bash
flutter run
```

---

## 🌐 Konfigurasi Alamat API di Flutter (`api_service.dart`)

Di file `lib/services/api_service.dart`:
```dart
static const String baseUrl = 'http://127.0.0.1:8000/api';
```
> **Mengapa menggunakan `127.0.0.1`?**  
> Perintah `adb reverse tcp:8000 tcp:8000` membuat HP menganggap server laptop berada langsung di dalam perangkat HP itu sendiri.  
> **Manfaat:** Bebas hambatan firewall Wi-Fi, anti *Connection Timed Out*, dan tidak terpengaruh jika IP Wi-Fi laptop berubah.

---

## 🗄️ Database Sistem

- **Default (SQLite Lokal):** Sistem secara mandiri menggunakan database lokal. **Tidak wajib menyalakan Docker**, sehingga laptop tetap ringan dan responsif saat demo ke dosen.
- **Opsional (MariaDB / MySQL Docker):** Jika ingin menyambung ke basis data MariaDB, cukup jalankan Docker compose. Backend otomatis mendeteksi dan beralih ke port `13306`.

---

## 📖 Dokumentasi Interaktif untuk Demo ke Dosen (Swagger UI)

Buka Google Chrome di laptop:  
👉 **`http://localhost:8000/docs`**

Tampilan visual interaktif ini mencakup seluruh modul:
1. **Autentikasi & Akun:** Pendaftaran pengguna, login, profil, dan token JWT Bearer.
2. **Dasbor FinChat:** Ringkasan total saldo, arus kas bulanan, dan diagram grafik.
3. **Dompet / Sumber Dana:** Pengelolaan multi-dompet (Kas, Rekening Bank, E-Wallet) beserta transfer saldo.
4. **Transaksi Keuangan:** Pencatatan pemasukan dan pengeluaran secara terperinci.
5. **Hutang & Piutang:** Pencatatan kewajiban serta cicilan pelunasan.
6. **Target Tabungan:** Pengelolaan tujuan tabungan dan riwayat setoran deposit.
7. **Batas Anggaran:** Pemantauan alokasi batas pengeluaran per kategori.
8. **ChatBot FinChat:** Pencatatan transaksi otomatis melalui pesan teks percakapan biasa (contoh: *"Beli bensin 30rb"* atau *"Makan siang 25000"*).
