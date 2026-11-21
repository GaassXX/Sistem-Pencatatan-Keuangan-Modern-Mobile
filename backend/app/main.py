import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.core.config import settings
from app.core.database import Base, engine, SessionLocal
from app.routers.categories import seed_categories_if_empty
from app.routers import (
    auth, dashboard, categories, wallets, 
    transactions, debts, savings, budgets, chatbot, reports
)

# Inisialisasi tabel database
try:
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    seed_categories_if_empty(db)
    db.close()
except Exception as e:
    print(f"[Startup Warning] Error creating tables / seeding: {e}")

app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="Backend REST API untuk Aplikasi Mobile FinChat (Laporan Keuangan Berbasis AI)",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Setup CORS agar Flutter (Web, Android Emulator, Device Fisik) bisa akses bebas tanpa blokir
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Folder upload avatar
upload_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "uploads")
os.makedirs(upload_dir, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=upload_dir), name="uploads")

# Include semua router modul
app.include_router(auth.router)
app.include_router(dashboard.router)
app.include_router(categories.router)
app.include_router(wallets.router)
app.include_router(transactions.router)
app.include_router(debts.router)
app.include_router(savings.router)
app.include_router(budgets.router)
app.include_router(chatbot.router)
app.include_router(reports.router)

@app.get("/")
def root():
    return {
        "status": "online",
        "app": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "docs": "/docs",
        "message": "FastAPI Backend untuk DompetKuu siap digunakan oleh Flutter Mobile App!"
    }

@app.get("/api/health")
def health_check():
    return {"status": "ok", "app": settings.APP_NAME}
