from database import engine
from sqlalchemy import text

with engine.connect() as conn:
    res = conn.execute(text('SELECT popular_times FROM "TravelApp".places WHERE popular_times IS NOT NULL LIMIT 1')).fetchone()
    print("from places.popular_times:", res)
