from sqlalchemy import text
from database import engine
from models import Base

with engine.connect() as conn:
    try:
        places = conn.execute(text('SELECT place_id FROM "TravelApp".places LIMIT 10')).fetchall()
        for p in places:
            conn.execute(text('INSERT INTO "TravelApp".saved_places (user_id, place_id) VALUES (1, :pid)'), {'pid': p[0]})
        conn.commit()
        print("Inserted dummy saved places")
    except Exception as e:
        print(f"Error: {e}")
