from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session, joinedload # Nhớ import joinedload
from typing import List
from database import get_db
from models import Review, ReviewReply, ReviewLike
from schemas import ReviewBase, ReviewReplyCreate, ReviewReplyBase, ReviewLikeCreate

# Giữ prefix là /places để link thành /api/places/{id}/reviews
router = APIRouter(prefix="/places", tags=["Reviews"])

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