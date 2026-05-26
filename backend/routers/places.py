from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import desc, asc, func, cast, literal, Float
from geoalchemy2 import Geography
from typing import List, Optional
from database import get_db
from models import Place, PlaceImage, District, CategoryGroup
from schemas import PlaceBase, PlaceDetail, PlaceImageBase, DistrictBase, CategoryGroupBase

router = APIRouter(prefix="/places", tags=["Places"])

# --- 1. LẤY DANH SÁCH TỔNG HỢP (Nearby, DrinkShop, Experiences, Search...) ---
@router.get("", response_model=List[PlaceBase])
def get_places(
    db: Session = Depends(get_db),
    district_id: Optional[int] = None,
    category_group_id: Optional[int] = None,
    search: Optional[str] = None,
    lat: Optional[float] = None,
    lng: Optional[float] = None,
    sort_by: Optional[str] = None,
    order: Optional[str] = "desc",
    skip: int = 0,
    limit: int = 50
):
    # Khởi tạo Query: Luôn nạp sẵn ảnh để Flutter hiện được hình ngay
    if lat is not None and lng is not None:
        # Chuẩn PostGIS: POINT(lng lat)
        user_point = func.ST_GeomFromText(f'POINT({lng} {lat})', 4326)
        
        # Tính khoảng cách và cast sang Geography để lấy đơn vị MÉT
        dist_col = func.ST_Distance(
            cast(Place.coordinates, Geography),
            cast(user_point, Geography)
        ).label("distance")
        
        query = db.query(Place, dist_col).options(joinedload(Place.images))
    else:
        # Sửa lỗi: dùng cast để đảm bảo kiểu dữ liệu đồng nhất
        query = db.query(Place, cast(literal(None), Float).label("distance")).options(joinedload(Place.images))

    # --- CÁC BỘ LỌC THEO BẢNG KHÁC ---
    if district_id:
        query = query.filter(Place.district_id == district_id)
    if category_group_id:
        query = query.filter(Place.category_group_id == category_group_id)
    if search:
        query = query.filter(Place.name.ilike(f"%{search}%"))

    # --- LOGIC SẮP XẾP ---
    if lat is not None and lng is not None and not sort_by:
        # Nếu có GPS và không chọn sort khác -> Ưu tiên quán GẦN NHẤT
        query = query.order_by(asc("distance"))
    elif sort_by and hasattr(Place, sort_by):
        col = getattr(Place, sort_by)
        query = query.order_by(desc(col) if order == "desc" else asc(col))
    else:
        # Mặc định xếp theo nhiều Review nhất
        query = query.order_by(desc(Place.total_reviews))

    # Thực thi Query
    results = query.offset(skip).limit(limit).all()
    
    # Map dữ liệu về Schema: results là list các tuple (Place, distance)
    return [PlaceBase.from_orm_place(p, distance=d) for p, d in results]

# --- 2. LẤY DANH SÁCH QUẬN (Bảng Districts) ---
@router.get("/districts/all", response_model=List[DistrictBase])
def get_districts(db: Session = Depends(get_db)):
    return db.query(District).order_by(asc(District.name)).all()

# --- 3. LẤY DANH SÁCH NHÓM (Bảng CategoryGroups) ---
@router.get("/categories/all", response_model=List[CategoryGroupBase])
def get_categories(db: Session = Depends(get_db)):
    return db.query(CategoryGroup).all()

# --- 4. LẤY CHI TIẾT 1 ĐỊA ĐIỂM (Full thông tin để làm trang Detail) ---
@router.get("/{place_id}", response_model=PlaceDetail)
def get_place_detail(place_id: int, db: Session = Depends(get_db)):
    place = db.query(Place).options(
        joinedload(Place.images),
        joinedload(Place.reviews).joinedload(Place.reviews.prop.mapper.class_.user) # Lấy cả user của review
    ).filter(Place.place_id == place_id).first()
    
    if not place:
        raise HTTPException(status_code=404, detail="Không tìm thấy địa điểm này")
    return place

# --- 5. LẤY RIÊNG ẢNH ĐỊA ĐIỂM ---
@router.get("/{place_id}/images", response_model=List[PlaceImageBase])
def get_place_images(place_id: int, db: Session = Depends(get_db)):
    return db.query(PlaceImage).filter(PlaceImage.place_id == place_id).all()