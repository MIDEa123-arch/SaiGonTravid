from sqlalchemy import Column, Integer, String, ForeignKey, Text, DECIMAL, JSON, TIMESTAMP, text
from sqlalchemy.orm import relationship
from geoalchemy2 import Geometry
from database import Base

class CategoryGroup(Base):
    __tablename__ = "category_groups"
    __table_args__ = {'schema': 'TravelApp'}

    category_group_id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), unique=True, nullable=False)

    places = relationship("Place", back_populates="category_group")

class District(Base):
    __tablename__ = "districts"
    __table_args__ = {'schema': 'TravelApp'}

    district_id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), unique=True, nullable=False)

    places = relationship("Place", back_populates="district")

class User(Base):
    __tablename__ = "users"
    __table_args__ = {'schema': 'TravelApp'}

    user_id = Column(Integer, primary_key=True, index=True)
    full_name = Column(String(255), nullable=False)
    email = Column(String(255), unique=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    google_id = Column(String(255), unique=True)
    avatar_url = Column(Text)
    created_at = Column(TIMESTAMP, server_default=text('CURRENT_TIMESTAMP'))

    reviews = relationship("Review", back_populates="user")

class Place(Base):
    __tablename__ = "places"
    __table_args__ = {'schema': 'TravelApp'}

    place_id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    category_group_id = Column(Integer, ForeignKey("TravelApp.category_groups.category_group_id", ondelete="SET NULL"))
    place_type = Column(String(100))
    district_id = Column(Integer, ForeignKey("TravelApp.districts.district_id", ondelete="SET NULL"))
    address = Column(Text)
    coordinates = Column(Geometry('POINT', srid=4326))
    price_range = Column(String(100))
    avg_rating = Column(DECIMAL(3, 2), default=0)
    total_reviews = Column(Integer, default=0)
    review_popularity_level = Column(String(50))
    phone = Column(String(50))
    website = Column(Text)
    google_maps_url = Column(Text)
    utilities = Column(JSON)
    opening_hours = Column(JSON)
    description = Column(Text)
    created_at = Column(TIMESTAMP, server_default=text('CURRENT_TIMESTAMP'))

    category_group = relationship("CategoryGroup", back_populates="places")
    district = relationship("District", back_populates="places")
    images = relationship("PlaceImage", back_populates="place")
    reviews = relationship("Review", back_populates="place")

    @property
    def lat_lng(self):
        try:
            if self.coordinates is not None:
                from geoalchemy2.shape import to_shape
                point = to_shape(self.coordinates)
                return {"lat": point.y, "lng": point.x}
        except Exception as e:
            print(f"Error parsing coordinates: {e}")
            pass
        return None

class PlaceImage(Base):
    # Triggers auto-reload
    __tablename__ = "place_images"
    __table_args__ = {'schema': 'TravelApp'}

    image_id = Column(Integer, primary_key=True, index=True)
    place_id = Column(Integer, ForeignKey("TravelApp.places.place_id", ondelete="CASCADE"))
    image_url = Column(Text, nullable=False)
    created_at = Column(TIMESTAMP, server_default=text('CURRENT_TIMESTAMP'))

    place = relationship("Place", back_populates="images")

class Review(Base):
    __tablename__ = "reviews"
    __table_args__ = {'schema': 'TravelApp'}

    review_id = Column(Integer, primary_key=True, index=True)
    place_id = Column(Integer, ForeignKey("TravelApp.places.place_id", ondelete="CASCADE"))
    user_id = Column(Integer, ForeignKey("TravelApp.users.user_id", ondelete="CASCADE"))
    content = Column(Text)
    stars = Column(Integer)
    sentiment_score = Column(DECIMAL(3, 2))
    created_at = Column(TIMESTAMP, server_default=text('CURRENT_TIMESTAMP'))

    place = relationship("Place", back_populates="reviews")
    user = relationship("User", back_populates="reviews")
    images = relationship("ReviewImage", back_populates="review")
    replies = relationship("ReviewReply", back_populates="review", cascade="all, delete-orphan")

class ReviewImage(Base):
    __tablename__ = "review_images"
    __table_args__ = {'schema': 'TravelApp'}

    rev_image_id = Column(Integer, primary_key=True, index=True)
    review_id = Column(Integer, ForeignKey("TravelApp.reviews.review_id", ondelete="CASCADE"))
    image_url = Column(Text, nullable=False)

    review = relationship("Review", back_populates="images")

class ReviewReply(Base):
    __tablename__ = "review_replies"
    __table_args__ = {'schema': 'TravelApp'}

    reply_id = Column(Integer, primary_key=True, index=True)
    review_id = Column(Integer, ForeignKey("TravelApp.reviews.review_id", ondelete="CASCADE"))
    user_id = Column(Integer, ForeignKey("TravelApp.users.user_id", ondelete="CASCADE"))
    content = Column(Text, nullable=False)
    created_at = Column(TIMESTAMP, server_default=text('CURRENT_TIMESTAMP'))

    review = relationship("Review", back_populates="replies")
    user = relationship("User")
