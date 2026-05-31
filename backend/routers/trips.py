from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import desc
from datetime import datetime, timedelta
import models, schemas
from database import get_db

router = APIRouter(
    prefix="/api/trips",
    tags=["Trips"]
)

@router.post("/", response_model=schemas.TripResponse)
def create_trip(trip: schemas.TripCreateRequest, user_id: int, db: Session = Depends(get_db)):
    # Validate user
    user = db.query(models.User).filter(models.User.user_id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    cover_image_url = "https://images.unsplash.com/photo-1583417319070-4a69db38a482?q=80&w=400&auto=format&fit=crop" # Default fallback
    if trip.places:
        first_place_id = trip.places[0].place_id
        first_place = db.query(models.Place).filter(models.Place.place_id == first_place_id).first()
        if first_place and first_place.images:
            cover_image_url = first_place.images[0].image_url

    new_trip = models.Trip(
        user_id=user_id,
        name=trip.name,
        start_date=trip.start_date.replace(tzinfo=None), # Ensure naive datetime for DB if needed
        num_days=trip.num_days,
        note=trip.note,
        cover_image_url=cover_image_url
    )
    db.add(new_trip)
    db.flush() # get new_trip.trip_id

    for place_data in trip.places:
        itinerary_item = models.TripItinerary(
            trip_id=new_trip.trip_id,
            day_index=place_data.day_index,
            place_id=place_data.place_id,
            order_index=place_data.order_index,
            start_time=place_data.start_time
        )
        db.add(itinerary_item)
        
    db.commit()
    db.refresh(new_trip)
    
    # Format response
    response_data = schemas.TripResponse.model_validate(new_trip)
    end_date = new_trip.start_date + timedelta(days=new_trip.num_days)
    response_data.is_completed = end_date < datetime.now()
        
    return response_data

@router.get("/user/{user_id}", response_model=list[schemas.TripResponse])
def get_user_trips(user_id: int, db: Session = Depends(get_db)):
    trips = db.query(models.Trip).filter(models.Trip.user_id == user_id).order_by(desc(models.Trip.created_at)).all()
    
    response_trips = []
    now = datetime.now()
    
    for trip in trips:
        trip_resp = schemas.TripResponse.model_validate(trip)
        try:
            end_date = trip.start_date + timedelta(days=trip.num_days)
            trip_resp.is_completed = end_date < now
        except Exception as e:
            trip_resp.is_completed = False
            
        response_trips.append(trip_resp)
        
    return response_trips
