#!/bin/bash
set -euo pipefail

echo "============================================================"
echo "  HMH — Imam Hossein Schools Central Reservation System"
echo "  Production Server Deployment Script (Ubuntu 24.04 LTS)"
echo "============================================================"

# Check Docker and Docker Compose
command -v docker >/dev/null 2>&1 || { echo "Error: docker is not installed. Aborting." >&2; exit 1; }
command -v docker compose >/dev/null 2>&1 || { echo "Error: docker compose is not installed. Aborting." >&2; exit 1; }

# Check .env file
if [ ! -f .env ]; then
    echo "Creating .env from .env.example..."
    cp .env.example .env
    echo "IMPORTANT: Please configure production passwords in .env before starting!"
fi

cd docker

echo "Pulling base container images..."
docker compose pull mysql nginx

echo "Building backend and admin web services..."
docker compose build

echo "Starting HMH application stack..."
docker compose up -d

echo "Waiting for MySQL database readiness..."
docker compose exec -T mysql mysqladmin ping -h localhost -u root --silent --wait=60

echo "Running database initialization and Alembic migrations..."
docker compose exec -T backend python -c "
import asyncio
from app.core.database import engine, Base, AsyncSessionLocal
from app.core.init_db import init_database_data

async def init():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    async with AsyncSessionLocal() as session:
        await init_database_data(session)
    print('Production database initialization complete.')

asyncio.run(init())
"

echo "Checking system health..."
docker compose exec -T backend curl -f http://localhost:8000/api/v1/system/health

echo "============================================================"
echo "  Deployment completed successfully!"
echo "  Web Admin: https://reserve.salehvip-clud.ir"
echo "  API Docs:  https://reserve.salehvip-clud.ir/docs"
echo "============================================================"
