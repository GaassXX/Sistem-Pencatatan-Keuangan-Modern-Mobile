import os
from pathlib import Path
from pydantic_settings import BaseSettings

# Selalu cari .env relatif terhadap folder backend/ (bukan cwd)
_BACKEND_DIR = Path(__file__).resolve().parent.parent.parent
_ENV_FILE = _BACKEND_DIR / ".env"

class Settings(BaseSettings):
    APP_NAME: str = "FinChat API - Laporan Keuangan"
    APP_VERSION: str = "1.0.0"

    # DATABASE — wajib diisi via .env; default SQLite aman untuk development lokal
    DATABASE_URL: str = "sqlite:///./dompetkuu.db"

    ENVIRONMENT: str = "development"

    # SECRET_KEY — TIDAK ada default. Aplikasi akan gagal start jika tidak diset.
    # Generate: python -c "import secrets; print(secrets.token_urlsafe(64))"
    SECRET_KEY: str = ""

    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 43200
    USE_SQLITE_FALLBACK: bool = True

    def validate_security(self):
        # Key dianggap aman jika panjangnya >= 32 karakter dan bukan placeholder
        placeholder_keywords = [
            "finchat-secret-key",
            "change-me",
            "GANTI_DENGAN",
            "ganti-dengan",
            "dev-local-only",
        ]
        is_placeholder = not self.SECRET_KEY or any(
            kw in self.SECRET_KEY for kw in placeholder_keywords
        )
        is_too_short = len(self.SECRET_KEY) < 32

        if is_placeholder or is_too_short:
            if self.ENVIRONMENT == "production":
                raise RuntimeError(
                    "KRITIS: SECRET_KEY wajib diisi dengan kunci acak di file .env "
                    "(production mode). Jalankan: python -c \"import secrets; print(secrets.token_urlsafe(64))\""
                )
            else:
                print(
                    "[Security Warning] SECRET_KEY belum diset atau masih memakai nilai placeholder. "
                    "Buat kunci acak di file backend/.env sebelum deploy!\n"
                    "  → python -c \"import secrets; print(secrets.token_urlsafe(64))\""
                )

    class Config:
        env_file = str(_ENV_FILE)
        extra = "allow"

settings = Settings()
settings.validate_security()
