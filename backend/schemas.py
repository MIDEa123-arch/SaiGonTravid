from pydantic import BaseModel, ConfigDict
from typing import List, Optional, Any
from datetime import datetime
from decimal import Decimal

# 1. Coordinate (Dùng cho lat_lng)
class Coordinate(BaseModel):
    lat: float
    lng: float
    model_config = ConfigDict(from_attributes=True)

# 2. Bảng phụ
class CategoryBase(BaseModel):
    category_id: int
    name: str
    model_config = ConfigDict(from_attributes=True)

class CategoryGroupBase(BaseModel):
    category_group_id: int
    name: str
    category_id: Optional[int] = None
    model_config = ConfigDict(from_attributes=True)

class DistrictBase(BaseModel):
    district_id: int
    name: str
    model_config = ConfigDict(from_attributes=True)

class PlaceImageBase(BaseModel):
    image_id: int
    image_url: str
    created_at: Optional[datetime] = None
    model_config = ConfigDict(from_attributes=True)

# 3. User & Review (Phải định nghĩa trước UserDetail)
class UserMinimal(BaseModel):
    user_id: int
    full_name: str
    avatar_url: Optional[str] = None
    google_id: Optional[str] = None
    model_config = ConfigDict(from_attributes=True)

class UserDetail(UserMinimal):
    email: str
    created_at: Optional[datetime] = None
    model_config = ConfigDict(from_attributes=True)

class ReviewImageBase(BaseModel):
    rev_image_id: int
    image_url: str
    model_config = ConfigDict(from_attributes=True)

class ReviewReplyBase(BaseModel):
    reply_id: int
    content: str
    created_at: Optional[datetime] = None
    user: Optional[UserMinimal] = None
    model_config = ConfigDict(from_attributes=True)

class ReviewReplyCreate(BaseModel):
    content: str
    user_id: int

class ReviewLikeCreate(BaseModel):
    user_id: int

class ReviewBase(BaseModel):
    review_id: int
    title: Optional[str] = None
    content: Optional[str] = None
    stars: Optional[int] = None
    sentiment_score: Optional[float] = None
    likes: Optional[int] = 0
    created_at: Optional[datetime] = None
    user: Optional[UserMinimal] = None
    images: List[ReviewImageBase] = []
    replies: List[ReviewReplyBase] = []
    model_config = ConfigDict(from_attributes=True)

# 4. Model chính Place
class PlaceBase(BaseModel):
    place_id: int
    name: str
    place_type: Optional[str] = None
    address: Optional[str] = None
    price_range: Optional[str] = None
    avg_rating: Optional[float] = None
    total_reviews: Optional[int] = 0
    image_url: Optional[str] = None
    lat_lng: Optional[Coordinate] = None 
    distance: Optional[float] = None 
    category_group_id: Optional[int] = None # Đã khai báo đúng ở đây
    model_config = ConfigDict(from_attributes=True)

    @classmethod
    def from_orm_place(cls, place: Any, distance: Optional[float] = None):
        # Xử lý ảnh mặc định
        img = "1.jpg"
        if hasattr(place, 'images') and place.images:
            img = place.images[0].image_url
        elif hasattr(place, 'image_url') and place.image_url:
            img = place.image_url

        return cls(
            place_id=place.place_id,
            name=place.name,
            place_type=place.place_type,
            address=place.address,
            price_range=place.price_range,
            avg_rating=float(place.avg_rating) if place.avg_rating else 0.0,
            total_reviews=place.total_reviews or 0,
            image_url=img,
            lat_lng=place.lat_lng,
            distance=distance,            
            category_group_id=place.category_group_id 
        )

# 5. Model chi tiết
class PlaceDetail(PlaceBase):
    category_group: Optional[CategoryGroupBase] = None
    district: Optional[DistrictBase] = None
    images: List[PlaceImageBase] = []
    reviews: List[ReviewBase] = []
    description: Optional[str] = None
    utilities: Optional[Any] = None
    opening_hours: Optional[Any] = None
    popular_times: Optional[Any] = None
    phone: Optional[str] = None
    website: Optional[str] = None
    google_maps_url: Optional[str] = None
    review_popularity_level: Optional[str] = None
    model_config = ConfigDict(from_attributes=True)


# ─────────────────────────────────────────────────────────────────────────────
# Auth Schemas
# ─────────────────────────────────────────────────────────────────────────────

class UserRegisterRequest(BaseModel):
    """Body cho POST /api/auth/register"""
    full_name: str
    email: str
    password: str

class UserLoginRequest(BaseModel):
    """Body cho POST /api/auth/login"""
    email: str
    password: str

class ForgotPasswordRequest(BaseModel):
    """Body cho POST /api/auth/forgot-password"""
    email: str

class UserGoogleLoginRequest(BaseModel):
    """Body cho POST /api/auth/google"""
    google_id: str
    email: str
    full_name: str
    avatar_url: Optional[str] = None
    id_token: Optional[str] = None


class AuthResponse(BaseModel):
    """Response trả về sau register/login thành công"""
    user_id: int
    full_name: str
    email: str
    avatar_url: Optional[str] = None
    message: str
    model_config = ConfigDict(from_attributes=True)

class MessageResponse(BaseModel):
    """Response chỉ có message (dùng cho forgot-password)"""
    message: str


class ReviewCreateRequest(BaseModel):
    user_id: int
    rating: int
    title: Optional[str] = None
    comment: Optional[str] = None
    image_url: Optional[str] = None


class UserReviewResponse(BaseModel):
    review_id: int
    place_id: int
    place_name: str
    place_address: Optional[str] = None
    place_image_url: Optional[str] = None
    rating: int
    title: Optional[str] = None
    comment: Optional[str] = None
    created_at: Optional[datetime] = None
    model_config = ConfigDict(from_attributes=True)

# ─────────────────────────────────────────────────────────────────────────────
# Saved Place Schemas
# ─────────────────────────────────────────────────────────────────────────────

class SavedPlaceCreate(BaseModel):
    place_id: int

class SavedPlaceResponse(BaseModel):
    saved_id: int
    user_id: int
    place: PlaceBase
    created_at: datetime
    model_config = ConfigDict(from_attributes=True)

# ─────────────────────────────────────────────────────────────────────────────
# Trip Schemas
# ─────────────────────────────────────────────────────────────────────────────

class TripPlaceCreate(BaseModel):
    day_index: int
    place_id: int
    order_index: int
    start_time: Optional[str] = None

class TripCreateRequest(BaseModel):
    name: str
    start_date: datetime
    num_days: int
    note: Optional[str] = None
    places: List[TripPlaceCreate] = []

class TripItineraryResponse(BaseModel):
    itinerary_id: int
    day_index: int
    order_index: int
    start_time: Optional[str] = None
    place: PlaceBase
    model_config = ConfigDict(from_attributes=True)

class TripResponse(BaseModel):
    trip_id: int
    user_id: int
    name: str
    start_date: datetime
    num_days: int
    note: Optional[str] = None
    cover_image_url: Optional[str] = None
    created_at: datetime
    is_completed: bool = False
    itinerary: List[TripItineraryResponse] = []
    model_config = ConfigDict(from_attributes=True)
