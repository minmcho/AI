"""
Pytest configuration and fixtures

Provides test fixtures for database, authentication, and test clients.
"""

import pytest
import asyncio
from typing import AsyncGenerator, Generator
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.pool import NullPool

from app.main import app
from app.db.database import Base, get_db
from app.config.settings import get_settings
from app.services.auth_service import auth_service
from app.models.user import User

settings = get_settings()

# Test database URL (use separate test database)
TEST_DATABASE_URL = "postgresql+asyncpg://postgres:postgres@localhost:5432/nutrivision_test"


@pytest.fixture(scope="session")
def event_loop() -> Generator:
    """Create an instance of the default event loop for each test case."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()


@pytest.fixture(scope="function")
async def test_db_engine():
    """Create test database engine"""
    engine = create_async_engine(
        TEST_DATABASE_URL,
        echo=False,
        poolclass=NullPool,
    )

    # Create all tables
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    yield engine

    # Drop all tables
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)

    await engine.dispose()


@pytest.fixture(scope="function")
async def db_session(test_db_engine) -> AsyncGenerator[AsyncSession, None]:
    """Create test database session"""
    async_session = async_sessionmaker(
        test_db_engine,
        class_=AsyncSession,
        expire_on_commit=False,
        autocommit=False,
        autoflush=False,
    )

    async with async_session() as session:
        yield session


@pytest.fixture(scope="function")
async def client(db_session: AsyncSession) -> AsyncGenerator[AsyncClient, None]:
    """Create test HTTP client with database override"""

    async def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db

    async with AsyncClient(app=app, base_url="http://test") as ac:
        yield ac

    app.dependency_overrides.clear()


@pytest.fixture
async def test_user(db_session: AsyncSession) -> User:
    """Create a test user"""
    user = await auth_service.register_user(
        db=db_session,
        email="test@example.com",
        username="testuser",
        password="SecurePassword123!",
        full_name="Test User",
        age=30,
        weight_kg=70.0,
        height_cm=170,
        sex="male",
    )
    return user


@pytest.fixture
async def auth_headers(test_user: User) -> dict:
    """Get authentication headers for test user"""
    access_token = auth_service.create_access_token(
        data={"sub": test_user.id, "email": test_user.email}
    )
    return {"Authorization": f"Bearer {access_token}"}


@pytest.fixture
async def admin_user(db_session: AsyncSession) -> User:
    """Create an admin test user"""
    user = await auth_service.register_user(
        db=db_session,
        email="admin@example.com",
        username="adminuser",
        password="AdminPassword123!",
        full_name="Admin User",
    )
    # In production, set admin role here
    return user


@pytest.fixture
async def admin_headers(admin_user: User) -> dict:
    """Get authentication headers for admin user"""
    access_token = auth_service.create_access_token(
        data={"sub": admin_user.id, "email": admin_user.email, "role": "admin"}
    )
    return {"Authorization": f"Bearer {access_token}"}
