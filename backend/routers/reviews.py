from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session, joinedload # Nhớ import joinedload
from typing import List
from database import get_db
from models import Review, ReviewReply
from schemas import ReviewBase, ReviewReplyCreate, ReviewReplyBase

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