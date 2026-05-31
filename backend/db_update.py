from sqlalchemy import text
from database import engine
from models import Base

Base.metadata.create_all(bind=engine)

with engine.connect() as conn:
    try:
        conn.execute(text('ALTER TABLE "TravelApp".trip_itinerary ADD COLUMN IF NOT EXISTS start_time VARCHAR(10)'))
        conn.commit()
        print("Added start_time successfully")
    except Exception as e:
        print(f"Error adding start_time: {e}")
