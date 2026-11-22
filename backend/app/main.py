import os
from fastapi import FastAPI, Request, status
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy import text

from app.core.config import settings
from app.core.database import Base, engine, SessionLocal
from app.routers.categories import seed_categories_if_empty
from app.routers import (
    auth, dashboard, categories, wallets, 
    transactions, debts, savings, budgets, chatbot, reports
)

# Inisialisasi tabel database dengan aman (Koeksistensi dengan Laravel)
try:
    if engine.dialect.name == "sqlite":
        Base.metadata.create_all(bind=engine)
        # Auto-migration jika tabel sqlite sudah ada sebelumnya
        with engine.connect() as conn:
            try:
                conn.execute(text("ALTER TABLE categories ADD COLUMN is_neutral BOOLEAN DEFAULT 0"))
                conn.commit()
            except Exception:
                pass
    else:
        # Untuk MySQL / MariaDB (Docker / Laravel):
        # Jalankan DDL migration terlebih dahulu agar kolom baru ada sebelum tabel diakses
        with engine.connect() as conn:
            ddls = [
                "ALTER TABLE categories ADD COLUMN icon VARCHAR(50) NULL",
                "ALTER TABLE categories ADD COLUMN color VARCHAR(30) NULL",
                "ALTER TABLE categories ADD COLUMN is_neutral BOOLEAN DEFAULT 0",
                "ALTER TABLE categories MODIFY COLUMN created_by INT NULL",
                "ALTER TABLE users ADD COLUMN avatar_url VARCHAR(255) NULL",
                "ALTER TABLE users ADD COLUMN is_active BOOLEAN DEFAULT 1",
                "ALTER TABLE users ADD COLUMN is_independent BOOLEAN DEFAULT 1",
                """CREATE TABLE IF NOT EXISTS saving_deposits (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    saving_id INT NOT NULL,
                    user_id INT NOT NULL,
                    wallet_id INT NULL,
                    amount DECIMAL(15, 2) NOT NULL,
                    date DATE NULL,
                    note TEXT NULL,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                    INDEX idx_saving_id (saving_id),
                    INDEX idx_user_id (user_id)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4""",
                """CREATE TABLE IF NOT EXISTS wallet_transfers (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    user_id INT NOT NULL,
                    from_wallet_id INT NOT NULL,
                    to_wallet_id INT NOT NULL,
                    amount DECIMAL(15, 2) NOT NULL,
                    notes TEXT NULL,
                    date DATE NULL,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                    INDEX idx_wt_user (user_id),
                    INDEX idx_wt_from (from_wallet_id),
                    INDEX idx_wt_to (to_wallet_id)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4"""
            ]
            for ddl in ddls:
                try:
                    conn.execute(text(ddl))
                    conn.commit()
                except Exception:
                    pass

        # Buat tabel yang belum ada secara aman (tidak akan menimpa tabel lama)
        Base.metadata.create_all(bind=engine)

    db = SessionLocal()
    seed_categories_if_empty(db)
    db.close()
except Exception as e:
    print(f"[Startup Warning] Error creating tables / seeding: {e}")

app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="Backend REST API untuk Aplikasi Mobile FinChat (Sistem Pencatatan Keuangan Modern)",
    docs_url="/docs",
    redoc_url="/redoc"
)

# ----------------- GLOBAL EXCEPTION HANDLERS (Untuk Flutter) -----------------
@app.exception_handler(StarletteHTTPException)
async def http_exception_handler(request: Request, exc: StarletteHTTPException):
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "success": False,
            "message": str(exc.detail),
            "data": None
        }
    )

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    errors = exc.errors()
    first_msg = "Validasi data gagal"
    if errors:
        loc_parts = [str(l) for l in errors[0].get("loc", []) if l != "body"]
        loc = " -> ".join(loc_parts)
        msg = errors[0].get("msg", "")
        first_msg = f"{loc}: {msg}" if loc else msg
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={
            "success": False,
            "message": first_msg,
            "errors": errors,
            "data": None
        }
    )

@app.exception_handler(Exception)
async def generic_exception_handler(request: Request, exc: Exception):
    import traceback
    traceback.print_exc()
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "success": False,
            "message": "Terjadi kesalahan internal pada server",
            "data": None
        }
    )

# Setup CORS aman untuk mobile & web
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
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
