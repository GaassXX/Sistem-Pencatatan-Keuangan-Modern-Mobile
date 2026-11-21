import uvicorn
import os

if __name__ == "__main__":
    port = int(os.getenv("PORT", 8000))
    host = os.getenv("HOST", "0.0.0.0")
    print(f"==================================================")
    print(f"🚀 Menjalankan FinChat FastAPI Backend di http://{host}:{port}")
    print(f"📖 Dokumentasi Interaktif (Swagger UI): http://localhost:{port}/docs")
    print(f"==================================================")
    uvicorn.run("app.main:app", host=host, port=port, reload=True)
