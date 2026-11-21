import os
from fastapi import FastAPI, Request, status
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

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
    else:
        # Untuk MySQL / MariaDB yang berbagi dengan Laravel:
        # Hanya buat tabel jika skema belum ada agar tidak merusak tabel migration Laravel
        from sqlalchemy import inspect
        inspector = inspect(engine)
        if not inspector.has_table("users"):
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
