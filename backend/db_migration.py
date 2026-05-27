from database import engine, Base
from models import User, ReviewReply, ReviewLike # Ensures models are loaded
from sqlalchemy import text

def run_migration():
    # 1. Add @gmail.com to emails that don't have @
    print("Migrating emails...")
    with engine.begin() as conn:
        conn.execute(text("""
            UPDATE "TravelApp".users 
            SET email = email || '@gmail.com' 
            WHERE email NOT LIKE '%@%';
        """))
    
    # 2. Add title and likes to reviews
    print("Migrating reviews...")
    with engine.begin() as conn:
        try:
            conn.execute(text('ALTER TABLE reviews ADD COLUMN title VARCHAR(255);'))
        except Exception as e:
            pass
        try:
            conn.execute(text('ALTER TABLE reviews ADD COLUMN likes INTEGER DEFAULT 0;'))
        except Exception as e:
            pass
            
    # 3. Create tables
    Base.metadata.create_all(engine)
    print("Migration successful.")

if __name__ == "__main__":
    run_migration()
