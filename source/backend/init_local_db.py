import asyncio
import sys
from pathlib import Path

# Add backend directory to path
backend_dir = Path(__file__).resolve().parent
if str(backend_dir) not in sys.path:
    sys.path.insert(0, str(backend_dir))

from app.core.database import engine, Base, AsyncSessionLocal
from app.core.init_db import init_database_data

async def main():
    print("Creating tables...")
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    print("Tables created.")
    
    print("Seeding initial data (including test / test user)...")
    async with AsyncSessionLocal() as session:
        await init_database_data(session)
    print("Database initialization completed successfully!")

if __name__ == "__main__":
    asyncio.run(main())
