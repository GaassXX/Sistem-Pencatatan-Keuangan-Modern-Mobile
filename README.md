# 📱 FinChat (Laporan Keuangan)

**FinChat** adalah aplikasi pencatatan dan pengelolaan keuangan cerdas berbasis **Flutter** (Mobile) dan **FastAPI** (Backend REST API) yang dilengkapi dengan fitur **AI ChatBot** untuk mencatat transaksi secara otomatis menggunakan pesan percakapan natural.

---

## 🏗️ Arsitektur Sistem

- **Frontend (Mobile App):** Flutter (Android, iOS, Web)
- **Backend (REST API):** FastAPI (Python 3.12+) dengan validasi Pydantic & JWT Bearer Token
- **Database:** SQLite lokal (tanpa perlu Docker) atau MySQL/MariaDB
- **Dokumentasi API Interaktif:** Swagger UI (`/docs`)

---

## 📁 Struktur Direktori Repositori

```text
test_app_rizqi/
├── lib/                      # Source code Flutter (UI, State, Services, Models)
├── assets/                   # Aset gambar & icon
├── android/                  # Native Android wrapper
├── backend/                  # Source code Backend FastAPI (Python)
│   ├── app/
│   │   ├── core/             # Konfigurasi JWT, CORS, & Database
│   │   ├── models/           # SQLAlchemy Models
│   │   ├── schemas/          # Pydantic Schemas
│   │   ├── routers/          # Endpoint API (Auth, Transaksi, Dompet, ChatBot, dll)
│   │   └── main.py           # Entrypoint FastAPI
│   ├── requirements.txt      # Daftar library Python
│   ├── run.py                # Script runner server
│   └── .env.example          # Template konfigurasi environment
├── .gitignore                # Filter file rahasia & build artifacts
├── PANDUAN_MENJALANKAN.md     # Panduan detail eksekusi
└── README.md                 # Dokumentasi utama proyek
```

---

## 🚀 Panduan Menjalankan Sistem

Jalankan sistem menggunakan **2 Tab Terminal**:

### 🔹 Tab 1: Menjalankan Backend FastAPI

```bash
# 1. Masuk ke direktori backend
cd backend

# 2. Buat & aktifkan virtual environment (jika belum)
python3 -m venv venv
source venv/bin/activate

# 3. Install dependensi
pip install -r requirements.txt

# 4. Jalankan backend server
python run.py
```
> Server akan aktif di `http://0.0.0.0:8000`. Dokumentasi Swagger UI dapat diakses di browser: **`http://localhost:8000/docs`**.

---

### 🔹 Tab 2: Menjalankan Aplikasi Flutter (Mobile)

Pilih salah satu metode pengujian perangkat di bawah ini:

#### **Pilihan A: Menggunakan HP Fisik Android (Rekomendasi)**
1. Aktifkan **Opsi Pengembang (Developer Options)** dan **Debugging Nirkabel (Wireless Debugging)** di HP Anda.
2. Hubungkan HP ke Wi-Fi yang sama dengan laptop.
3. Jalankan perintah berikut di terminal:
   ```bash
   # Sambungkan ADB ke HP Anda (ganti <IP_HP> dan <PORT_HP> sesuai yang tertera di menu Debugging HP)
   # Contoh: adb connect 192.168.1.50:38921
   adb connect <IP_HP>:<PORT_HP>

   # Buka terowongan port HP ke laptop (Wajib)
   adb reverse tcp:8000 tcp:8000

   # Jalankan aplikasi ke HP
   flutter run -d <IP_HP>:<PORT_HP>
   ```

#### **Pilihan B: Menggunakan Kabel USB (Paling Praktis)**
1. Colokkan HP ke laptop via kabel USB dengan mode **USB Debugging** aktif.
2. Jalankan:
   ```bash
   adb reverse tcp:8000 tcp:8000
   flutter run
   ```

#### **Pilihan C: Menggunakan Android Emulator**
1. Buka Android Emulator Anda.
2. Ubah `baseUrl` di `lib/services/api_service.dart` menjadi `http://10.0.2.2:8000/api`.
3. Jalankan:
   ```bash
   flutter run
   ```

#### **Pilihan D: Menggunakan Google Chrome / Web**
1. Ubah `baseUrl` di `lib/services/api_service.dart` menjadi `http://localhost:8000/api`.
2. Jalankan:
   ```bash
   flutter run -d chrome
   ```

---

## ⚙️ Konfigurasi Alamat API (`api_service.dart`)

Alamat backend diatur di file `lib/services/api_service.dart`:

```dart
class ApiService {
  // Gunakan 127.0.0.1 jika menggunakan 'adb reverse tcp:8000 tcp:8000'
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  
  // Gunakan IP LAN jika menghubungkan langsung tanpa adb reverse:
  // static const String baseUrl = 'http://192.168.x.x:8000/api';
  
  // Gunakan 10.0.2.2 untuk Android Emulator bawaan Android Studio:
  // static const String baseUrl = 'http://10.0.2.2:8000/api';
}
```

---

## 🛡️ Fitur Utama Aplikasi

1. **Autentikasi & Akun:** Pendaftaran, login, profil pengguna, dan token keamanan JWT.
2. **Dasbor Finansial:** Ringkasan total saldo, kalkulasi arus kas bulanan, dan grafik visual interaktif.
3. **Multi-Dompet (Wallets):** Pengelolaan kas, rekening bank, e-wallet, mutasi/transfer, serta penyesuaian saldo.
4. **Pencatatan Transaksi:** Pengelompokan kategori pemasukan dan pengeluaran secara lengkap.
5. **Hutang & Piutang:** Pemantauan tanggal jatuh tempo dan pencatatan cicilan pelunasan.
6. **Target Tabungan (Savings):** Manajemen target dana impian beserta setoran deposit bertahap.
7. **Batas Anggaran (Budgets):** Penetapan batas pengeluaran per kategori untuk mencegah pemborosan.
8. **AI ChatBot Asisten:** Pengenalan bahasa natural untuk mencatat transaksi secara otomatis (contoh: *"Makan siang 25000"*).
9. **Ekspor Laporan:** Unduh laporan keuangan berkala dalam format dokumen.

---

## 👨‍💻 Lisensi & Pembuat

Dibuat untuk keperluan akademik mata kuliah **Pemrograman Mobile**.
