from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List, Optional
from database import get_db
from models import Category, CategoryGroup, District
from schemas import CategoryBase, CategoryGroupBase, DistrictBase

router = APIRouter()

@router.get("/categories", response_model=List[CategoryBase], tags=["Categories"])
def get_categories(db: Session = Depends(get_db)):
    return db.query(Category).all()

@router.get("/category_groups", response_model=List[CategoryGroupBase], tags=["Categories"])
def get_category_groups(db: Session = Depends(get_db), category_id: Optional[int] = None):
    query = db.query(CategoryGroup)
    if category_id:
        query = query.filter(CategoryGroup.category_id == category_id)
    return query.all()

@router.get("/districts", response_model=List[DistrictBase], tags=["Districts"])
def get_districts(db: Session = Depends(get_db)):
    return db.query(District).all()
