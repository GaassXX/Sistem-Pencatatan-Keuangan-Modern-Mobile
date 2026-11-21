import os
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker
from app.core.config import settings

DATABASE_URL = settings.DATABASE_URL
engine = None

try:
    # Coba koneksi ke MySQL/MariaDB
    test_engine = create_engine(
        DATABASE_URL, 
        pool_pre_ping=True, 
        pool_recycle=3600,
        connect_args={"connect_timeout": 3}
    )
    with test_engine.connect() as conn:
        pass
    engine = test_engine
    print("[Database] Terhubung ke MySQL/MariaDB!")
except Exception as e:
    if settings.USE_SQLITE_FALLBACK:
        print(f"[Database] Gagal terhubung ke MySQL ({e}). Menggunakan SQLite lokal sebagai fallback.")
        sqlite_path = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), "dompetkuu.db")
        DATABASE_URL = f"sqlite:///{sqlite_path}"
        engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
    else:
        raise e

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
