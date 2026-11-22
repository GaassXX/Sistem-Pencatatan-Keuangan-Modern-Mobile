import uvicorn
import os
import socket
import subprocess
import time

def check_and_start_docker():
    """Mengecek apakah MariaDB Docker aktif; jika belum, coba auto-start container."""
    mariadb_port = 13306
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(0.5)
    is_open = False
    try:
        s.connect(('127.0.0.1', mariadb_port))
        s.close()
        is_open = True
    except Exception:
        is_open = False

    if not is_open:
        print(f"🔍 Port {mariadb_port} (MariaDB Docker) belum merespons.")
        print("🚀 Mencoba menjalankan container MariaDB 'dompetkuu_c' secara otomatis...")
        started = False
        for target in ["dompetkuu_c", "16ba0dee79fe"]:
            try:
                res = subprocess.run(["docker", "start", target], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, timeout=5)
                if res.returncode == 0:
                    print(f"✅ Container Docker '{target}' berhasil dijalankan!")
                    started = True
                    break
            except Exception:
                pass
        
        if started:
            # Beri jeda 2 detik agar daemon MariaDB siap menerima koneksi
            print("⏳ Menunggu MariaDB siap...")
            time.sleep(2)
        else:
            print("ℹ️ Tidak dapat menjalankan container secara otomatis. Pastikan Docker Desktop menyala.")

if __name__ == "__main__":
    check_and_start_docker()
    port = int(os.getenv("PORT", 8000))
    host = os.getenv("HOST", "0.0.0.0")
    print(f"==================================================")
    print(f"🚀 Menjalankan FinChat FastAPI Backend di http://{host}:{port}")
    print(f"📖 Dokumentasi Interaktif (Swagger UI): http://localhost:{port}/docs")
    print(f"==================================================")
    uvicorn.run("app.main:app", host=host, port=port, reload=True)
