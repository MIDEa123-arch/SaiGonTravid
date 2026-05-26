from sqlalchemy import create_engine, event
from sqlalchemy.orm import sessionmaker, declarative_base

import os


SQLALCHEMY_DATABASE_URL = os.getenv(
    "DATABASE_URL", 
    "postgresql://postgres:Yeuuyen1234%40@localhost:5432/Travel_app"
)

engine = create_engine(SQLALCHEMY_DATABASE_URL)

# ⚠️ QUAN TRỌNG: Schema "TravelApp" là case-sensitive (chữ hoa T và A)
# Phải dùng quoted identifier, không được dùng connect_args options
# vì Postgres sẽ lowercase "TravelApp" → "travelapp" và không tìm thấy schema
@event.listens_for(engine, "connect")
def set_search_path(dbapi_connection, connection_record):
    cursor = dbapi_connection.cursor()
    cursor.execute('SET search_path TO "TravelApp", public')
    cursor.close()

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
