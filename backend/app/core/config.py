import os
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    APP_NAME: str = "FinChat API - Laporan Keuangan"
    APP_VERSION: str = "1.0.0"
    DATABASE_URL: str = os.getenv(
        "DATABASE_URL", 
        "mysql+pymysql://root:p455w0rd@127.0.0.1:13306/dompetkuu"
    )
    SECRET_KEY: str = os.getenv(
        "SECRET_KEY", 
        "finchat-secret-key-change-me-in-production-2026"
    )
    ALGORITHM: str = os.getenv("ALGORITHM", "HS256")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "43200"))
    USE_SQLITE_FALLBACK: bool = os.getenv("USE_SQLITE_FALLBACK", "true").lower() in ("true", "1")

    class Config:
        env_file = ".env"
        extra = "allow"

settings = Settings()
