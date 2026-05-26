from database import engine, Base
from models import User, ReviewReply # Ensures models are loaded
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
    
    # 2. Create review_replies table
    print("Creating tables...")
    Base.metadata.create_all(engine)
    print("Migration successful.")

if __name__ == "__main__":
    run_migration()
