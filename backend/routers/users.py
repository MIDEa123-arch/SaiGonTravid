from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session, joinedload
from typing import List
from database import get_db
from models import User, Review, Place, SavedPlace
from schemas import UserDetail, UserReviewResponse, SavedPlaceResponse, SavedPlaceCreate
from sqlalchemy.exc import IntegrityError

router = APIRouter(prefix="/users", tags=["Users"])

@router.get("/{user_id}", response_model=UserDetail)
def get_user_detail(user_id: int, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.user_id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@router.get("/{user_id}/reviews", response_model=List[UserReviewResponse])
def get_user_reviews(user_id: int, db: Session = Depends(get_db)):
    # Check if user exists
    user = db.query(User).filter(User.user_id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    reviews = db.query(Review).options(
        joinedload(Review.place).joinedload(Place.images)
    ).filter(Review.user_id == user_id).order_by(Review.created_at.desc()).all()
    
    res = []
    for r in reviews:
        img_url = "1.jpg"
        if r.place.images:
            img_url = r.place.images[0].image_url
            
        res.append(UserReviewResponse(
            review_id=r.review_id,
            place_id=r.place_id,
            place_name=r.place.name,
            place_address=r.place.address,
            place_image_url=img_url,
            rating=r.stars or 0,
            title=r.title,
            comment=r.content,
            created_at=r.created_at
        ))
    return res

@router.get("/{user_id}/saved_places", response_model=List[SavedPlaceResponse])
def get_user_saved_places(user_id: int, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.user_id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    saved = db.query(SavedPlace).options(
        joinedload(SavedPlace.place)
    ).filter(SavedPlace.user_id == user_id).order_by(SavedPlace.created_at.desc()).all()
    
    return saved

@router.post("/{user_id}/saved_places", response_model=SavedPlaceResponse)
def add_saved_place(user_id: int, place_data: SavedPlaceCreate, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.user_id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    place = db.query(Place).filter(Place.place_id == place_data.place_id).first()
    if not place:
        raise HTTPException(status_code=404, detail="Place not found")
        
    existing = db.query(SavedPlace).filter(SavedPlace.user_id == user_id, SavedPlace.place_id == place_data.place_id).first()
    if existing:
        return existing
        
    new_saved = SavedPlace(user_id=user_id, place_id=place_data.place_id)
    db.add(new_saved)
    try:
        db.commit()
        db.refresh(new_saved)
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=400, detail="Could not save place")
        
    # load place relationship
    db.refresh(new_saved)
    return new_saved

@router.delete("/{user_id}/saved_places/{place_id}")
def remove_saved_place(user_id: int, place_id: int, db: Session = Depends(get_db)):
    saved = db.query(SavedPlace).filter(SavedPlace.user_id == user_id, SavedPlace.place_id == place_id).first()
    if not saved:
        raise HTTPException(status_code=404, detail="Saved place not found")
        
    db.delete(saved)
    db.commit()
    return {"message": "Removed successfully"}




import re
import os
import uuid
from pydantic import BaseModel
from fastapi import UploadFile, File

class UserUpdate(BaseModel):
    full_name: str
    email: str

@router.put("/{user_id}", response_model=UserDetail)
def update_user_profile(user_id: int, update_data: UserUpdate, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.user_id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    # Validate email
    email_regex = r'^[\w.-]+@([\w-]+\.)+[\w-]{2,}$'
    if not re.match(email_regex, update_data.email):
        raise HTTPException(status_code=400, detail="Email không hợp lệ")
        
    # Check email duplicate
    if update_data.email != user.email:
        existing = db.query(User).filter(User.email == update_data.email).first()
        if existing:
            raise HTTPException(status_code=400, detail="Email này đã được sử dụng bởi tài khoản khác")
            
    user.full_name = update_data.full_name
    user.email = update_data.email
    db.commit()
    db.refresh(user)
    return user

@router.post("/{user_id}/avatar")
def upload_avatar(
    user_id: int,
    file: UploadFile = File(...),
    db: Session = Depends(get_db)
):
    user = db.query(User).filter(User.user_id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    # Create static/avatars folder if not exists
    os.makedirs("static/avatars", exist_ok=True)
    
    # Generate unique filename
    ext = os.path.splitext(file.filename)[1]
    filename = f"{uuid.uuid4()}{ext}"
    filepath = os.path.join("static/avatars", filename)
    
    # Save file contents
    with open(filepath, "wb") as buffer:
        buffer.write(file.file.read())
        
    avatar_url = f"/static/avatars/{filename}"
    user.avatar_url = avatar_url
    db.commit()
    db.refresh(user)
    
    return {"avatar_url": avatar_url}



