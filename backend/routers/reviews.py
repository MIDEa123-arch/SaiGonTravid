from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session, joinedload
from typing import List
from database import get_db
from models import Review, ReviewReply, ReviewLike, Place, ReviewImage
from schemas import ReviewBase, ReviewReplyCreate, ReviewReplyBase, ReviewLikeCreate, ReviewCreateRequest

# Giữ prefix là /places để link thành /api/places/{id}/reviews
router = APIRouter(prefix="/places", tags=["Reviews"])

@router.post("/{place_id}/reviews", response_model=ReviewBase)
def create_place_review(
    place_id: int,
    review_data: ReviewCreateRequest,
    db: Session = Depends(get_db)
):
    # Check if place exists
    place = db.query(Place).filter(Place.place_id == place_id).first()
    if not place:
        raise HTTPException(status_code=404, detail="Place not found")
        
    # Check if user already reviewed this place
    existing_review = db.query(Review).filter(
        Review.place_id == place_id,
        Review.user_id == review_data.user_id
    ).first()
    if existing_review:
        raise HTTPException(status_code=400, detail="Bạn đã đánh giá địa điểm này rồi.")
        
    new_review = Review(
        place_id=place_id,
        user_id=review_data.user_id,
        title=review_data.title,
        content=review_data.comment,
        stars=review_data.rating,
        sentiment_score=0.0,
        likes=0
    )
    db.add(new_review)
    db.commit()
    db.refresh(new_review)
    
    # Add review image if provided
    if review_data.image_url:
        new_img = ReviewImage(review_id=new_review.review_id, image_url=review_data.image_url)
        db.add(new_img)
        db.commit()
        db.refresh(new_review)
        
    # Update place avg_rating and total_reviews
    place.total_reviews = (place.total_reviews or 0) + 1
    all_reviews = db.query(Review.stars).filter(Review.place_id == place_id).all()
    if all_reviews:
        stars_list = [r[0] for r in all_reviews if r[0] is not None]
        place.avg_rating = sum(stars_list) / len(stars_list)
    db.commit()
    
    # Reload with joined options to return full response
    created_review = db.query(Review).options(
        joinedload(Review.user),
        joinedload(Review.images),
        joinedload(Review.replies)
    ).filter(Review.review_id == new_review.review_id).first()
    
    return created_review


@router.get("/{place_id}/reviews", response_model=List[ReviewBase])
def get_place_reviews(
    place_id: int, 
    db: Session = Depends(get_db), 
    skip: int = 0, 
    limit: int = 20
):
    reviews = db.query(Review).options(
        joinedload(Review.user),
        joinedload(Review.images),
        joinedload(Review.replies).joinedload(ReviewReply.user)
    ).filter(Review.place_id == place_id)\
     .order_by(Review.created_at.desc())\
     .offset(skip).limit(limit).all()
    
    return reviews

@router.post("/{place_id}/reviews/{review_id}/reply", response_model=ReviewReplyBase)
def post_review_reply(
    place_id: int,
    review_id: int,
    reply: ReviewReplyCreate,
    db: Session = Depends(get_db)
):
    new_reply = ReviewReply(
        review_id=review_id,
        user_id=reply.user_id,
        content=reply.content
    )
    db.add(new_reply)
    db.commit()
    db.refresh(new_reply)
    
    # Reload with user to return in response
    created_reply = db.query(ReviewReply).options(joinedload(ReviewReply.user)).filter(ReviewReply.reply_id == new_reply.reply_id).first()
    return created_reply

@router.post("/{place_id}/reviews/{review_id}/like")
def like_review(
    place_id: int,
    review_id: int,
    like_data: ReviewLikeCreate,
    db: Session = Depends(get_db)
):
    review = db.query(Review).filter(Review.review_id == review_id, Review.place_id == place_id).first()
    if not review:
        return {"error": "Review not found"}
    
    # Check if already liked
    existing_like = db.query(ReviewLike).filter(
        ReviewLike.review_id == review_id, 
        ReviewLike.user_id == like_data.user_id
    ).first()
    
    if review.likes is None:
        review.likes = 0
        
    action = "liked"
    if existing_like:
        # Toggle: Remove like
        db.delete(existing_like)
        review.likes = max(0, review.likes - 1)
        action = "unliked"
    else:
        # Add like
        new_like = ReviewLike(review_id=review_id, user_id=like_data.user_id)
        db.add(new_like)
        review.likes += 1
        
    db.commit()
    db.refresh(review)
    return {"message": "Success", "action": action, "likes": review.likes}


@router.delete("/{place_id}/reviews/{review_id}")
def delete_place_review(
    place_id: int,
    review_id: int,
    user_id: int,
    db: Session = Depends(get_db)
):
    review = db.query(Review).filter(Review.review_id == review_id, Review.place_id == place_id).first()
    if not review:
        raise HTTPException(status_code=404, detail="Review not found")
        
    if review.user_id != user_id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this review")
        
    db.delete(review)
    db.commit()
    
    # Recalculate place avg_rating and total_reviews
    place = db.query(Place).filter(Place.place_id == place_id).first()
    if place:
        all_reviews = db.query(Review.stars).filter(Review.place_id == place_id).all()
        if all_reviews:
            stars_list = [r[0] for r in all_reviews if r[0] is not None]
            place.total_reviews = len(stars_list)
            place.avg_rating = sum(stars_list) / len(stars_list)
        else:
            place.total_reviews = 0
            place.avg_rating = 0.0
        db.commit()
        
    return {"message": "Review deleted successfully"}


import os
import uuid
from fastapi import UploadFile, File

@router.post("/reviews/upload-image")
def upload_review_image(
    file: UploadFile = File(...)
):
    # Create static/reviews folder if not exists
    os.makedirs("static/reviews", exist_ok=True)
    
    # Generate unique filename
    ext = os.path.splitext(file.filename)[1]
    filename = f"{uuid.uuid4()}{ext}"
    filepath = os.path.join("static/reviews", filename)
    
    # Save file contents
    with open(filepath, "wb") as buffer:
        buffer.write(file.file.read())
        
    image_url = f"/static/reviews/{filename}"
    return {"image_url": image_url}
