from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

from app.core.config import settings

# Engine — connection to PostgreSQL
engine = create_engine(
    settings.DATABASE_URL,
    echo=settings.DEBUG,       # SQL logs in development
    pool_pre_ping=True,        # verify connections before use
    future=True,
)

# SessionLocal — each request gets its own session
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine,
    future=True,
)

# Base — parent class for all SQLAlchemy models
Base = declarative_base()