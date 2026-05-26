from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List
from database import get_db
from models import CategoryGroup, District
from schemas import CategoryGroupBase, DistrictBase

router = APIRouter()

@router.get("/categories", response_model=List[CategoryGroupBase], tags=["Categories"])
def get_categories(db: Session = Depends(get_db)):
    return db.query(CategoryGroup).all()

@router.get("/districts", response_model=List[DistrictBase], tags=["Districts"])
def get_districts(db: Session = Depends(get_db)):
    return db.query(District).all()
