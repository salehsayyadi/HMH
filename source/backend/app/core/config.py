import os
from pathlib import Path
from typing import List, Union
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field, field_validator

class Settings(BaseSettings):
    PROJECT_NAME: str = "HMH"
    APP_ENV: str = "production"
    API_VERSION: str = "v1"
    TIMEZONE: str = "Asia/Tehran"
    LOG_LEVEL: str = "INFO"

    # Server & Domains
    SERVER_OS: str = "Ubuntu 24.04 LTS"
    DOMAIN: str = "salehvip-clud.ir"
    SUBDOMAIN: str = "reserve.salehvip-clud.ir"
    API_BASE_URL: str = "https://reserve.salehvip-clud.ir/api/v1"
    WEBSOCKET_URL: str = "wss://reserve.salehvip-clud.ir/ws"
    HTTP_PORT: int = 80
    HTTPS_PORT: int = 443

    # Database configuration (MySQL 9.7 LTS default, SQLite fallback for local test without docker)
    DATABASE_ENGINE: str = "mysql"
    MYSQL_HOST: str = "mysql"
    MYSQL_PORT: int = 3306
    MYSQL_DATABASE: str = "amphitheater_db"
    MYSQL_USER: str = "amphitheater_app"
    MYSQL_PASSWORD: str = "secure_random_production_secret"
    MYSQL_CHARSET: str = "utf8mb4"
    MYSQL_COLLATION: str = "utf8mb4_unicode_ci"
    DATABASE_URL: str = ""

    # JWT Authentication
    JWT_SECRET_KEY: str = "c7d9a1f4e8b23456789abcdef0123456789abcdef0123456789abcdef0123456"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 15
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    REFRESH_TOKEN_ROTATION: bool = True

    # Initial Super Admin Bootstrap
    INITIAL_ADMIN_USERNAME: str = "123IMHModirkol@1090"
    INITIAL_ADMIN_PASSWORD: str = "123IMHModirkol@1090"

    # CORS
    CORS_ORIGINS: List[str] = [
        "https://reserve.salehvip-clud.ir",
        "http://localhost:3000",
        "http://localhost:5173",
        "http://localhost:8000",
        "http://localhost",
        "http://127.0.0.1:3000",
        "http://127.0.0.1:5173",
        "http://127.0.0.1:8000"
    ]

    @field_validator("CORS_ORIGINS", mode="before")
    def parse_cors(cls, v: Union[str, List[str]]) -> List[str]:
        if isinstance(v, str):
            return [x.strip() for x in v.split(",") if x.strip()]
        return v

    def get_database_url(self, is_async: bool = True) -> str:
        if self.DATABASE_URL:
            return self.DATABASE_URL
        
        # When running locally or during tests if MySQL is not available, allow local sqlite fallback
        if self.DATABASE_ENGINE == "sqlite":
            prefix = "sqlite+aiosqlite:///" if is_async else "sqlite:///"
            db_path = Path("d:/IMH/source/backend/amphitheater_local.db")
            return f"{prefix}{db_path.as_posix()}"
        
        driver = "mysql+aiomysql" if is_async else "mysql+pymysql"
        return (
            f"{driver}://{self.MYSQL_USER}:{self.MYSQL_PASSWORD}"
            f"@{self.MYSQL_HOST}:{self.MYSQL_PORT}/{self.MYSQL_DATABASE}"
            f"?charset={self.MYSQL_CHARSET}"
        )

    model_config = SettingsConfigDict(
        env_file=("d:/IMH/.env", ".env"),
        env_file_encoding="utf-8",
        extra="ignore"
    )

settings = Settings()
