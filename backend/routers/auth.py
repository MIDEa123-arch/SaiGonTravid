import re
import os
import secrets
import smtplib
from email.mime.text import MIMEText
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from passlib.context import CryptContext

from database import get_db
from models import User
from schemas import (
    UserRegisterRequest,
    UserLoginRequest,
    ForgotPasswordRequest,
    UserGoogleLoginRequest,
    AuthResponse,
    MessageResponse,
)


router = APIRouter(prefix="/auth", tags=["Auth"])

# Passlib context – dùng bcrypt
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# Regex kiểm tra email đơn giản
_EMAIL_RE = re.compile(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$')

# Tiền tố nhận dạng bcrypt hash hợp lệ
_BCRYPT_PREFIXES = ("$2a$", "$2b$", "$2y$")


def _is_bcrypt(hash_value: str) -> bool:
    """Kiểm tra xem password_hash có phải bcrypt không."""
    return hash_value.startswith(_BCRYPT_PREFIXES)


def _hash_password(plain: str) -> str:
    return pwd_context.hash(plain)


def _verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)


# ─────────────────────────────────────────────────────────────────────────────
# POST /api/auth/register
# ─────────────────────────────────────────────────────────────────────────────
@router.post(
    "/register",
    response_model=AuthResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Đăng ký tài khoản mới",
)
def register(body: UserRegisterRequest, db: Session = Depends(get_db)):
    # 1. Validate email format
    if not _EMAIL_RE.match(body.email.strip()):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email không hợp lệ.",
        )

    # 2. Validate password length
    if len(body.password) < 6:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Mật khẩu phải có ít nhất 6 ký tự.",
        )

    # 3. Validate full_name
    if not body.full_name.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Vui lòng nhập họ và tên.",
        )

    # 4. Kiểm tra email đã tồn tại chưa
    existing = db.query(User).filter(User.email == body.email.strip().lower()).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email này đã được sử dụng. Vui lòng dùng email khác hoặc đăng nhập.",
        )

    # 5. Hash password bằng bcrypt
    hashed = _hash_password(body.password)

    # 6. Tạo user mới
    new_user = User(
        full_name=body.full_name.strip(),
        email=body.email.strip().lower(),
        password_hash=hashed,
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    return AuthResponse(
        user_id=new_user.user_id,
        full_name=new_user.full_name,
        email=new_user.email,
        avatar_url=new_user.avatar_url,
        message="Đăng ký thành công! Chào mừng bạn đến với SaiGonTravid.",
    )


# ─────────────────────────────────────────────────────────────────────────────
# POST /api/auth/login
# ─────────────────────────────────────────────────────────────────────────────
@router.post(
    "/login",
    response_model=AuthResponse,
    status_code=status.HTTP_200_OK,
    summary="Đăng nhập bằng email và mật khẩu",
)
def login(body: UserLoginRequest, db: Session = Depends(get_db)):
    # 1. Validate input cơ bản
    if not body.email.strip() or not body.password:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Vui lòng nhập email và mật khẩu.",
        )

    # 2. Tìm user theo email (so sánh lowercase)
    user = db.query(User).filter(User.email == body.email.strip().lower()).first()

    # 3. Không tìm thấy → 401 (thông báo chung, không tiết lộ email tồn tại)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email hoặc mật khẩu không đúng.",
        )

    # 4. Kiểm tra password_hash có phải bcrypt không
    if not _is_bcrypt(user.password_hash):
        # User cũ với hash không phải bcrypt (vd: imported_review_user$...)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=(
                "Tài khoản dữ liệu cũ chưa có mật khẩu đăng nhập. "
                "Vui lòng đăng ký tài khoản mới hoặc đặt lại mật khẩu."
            ),
        )

    # 5. Verify bcrypt
    try:
        is_valid = _verify_password(body.password, user.password_hash)
    except Exception:
        # Lỗi không mong muốn khi verify (hash bị corrupt...)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email hoặc mật khẩu không đúng.",
        )

    if not is_valid:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email hoặc mật khẩu không đúng.",
        )

    # 6. Login thành công
    return AuthResponse(
        user_id=user.user_id,
        full_name=user.full_name,
        email=user.email,
        avatar_url=user.avatar_url,
        message="Đăng nhập thành công!",
    )



# ─────────────────────────────────────────────────────────────────────────────
# POST /api/auth/google
# ─────────────────────────────────────────────────────────────────────────────
@router.post(
    "/google",
    response_model=AuthResponse,
    status_code=status.HTTP_200_OK,
    summary="Đăng nhập hoặc đăng ký bằng tài khoản Google",
)
def google_login(body: UserGoogleLoginRequest, db: Session = Depends(get_db)):
    # LƯU Ý DEMO: Do đây là môi trường demo, chúng ta chấp nhận và tin cậy thông tin profile do client gửi lên.
    # Nếu client gửi kèm id_token, trong production chúng ta sẽ verify signature của id_token qua thư viện Google Auth.
    # id_token hiện tại: body.id_token (Demo Mode)
    email_clean = body.email.strip().lower()
    
    # 1. Tìm user theo google_id
    user = db.query(User).filter(User.google_id == body.google_id).first()
    
    if user:
        # Đăng nhập thẳng nếu đã liên kết Google trước đó
        if body.avatar_url and user.avatar_url != body.avatar_url:
            user.avatar_url = body.avatar_url
            db.commit()
            db.refresh(user)
        return AuthResponse(
            user_id=user.user_id,
            full_name=user.full_name,
            email=user.email,
            avatar_url=user.avatar_url,
            message="Đăng nhập bằng Google thành công!",
        )
        
    # 2. Tìm user theo email (liên kết tài khoản thường trước đó)
    user_by_email = db.query(User).filter(User.email == email_clean).first()
    if user_by_email:
        user_by_email.google_id = body.google_id
        if body.avatar_url and not user_by_email.avatar_url:
            user_by_email.avatar_url = body.avatar_url
        db.commit()
        db.refresh(user_by_email)
        return AuthResponse(
            user_id=user_by_email.user_id,
            full_name=user_by_email.full_name,
            email=user_by_email.email,
            avatar_url=user_by_email.avatar_url,
            message="Đã liên kết và đăng nhập bằng Google thành công!",
        )
        
    # 3. Đăng ký người dùng Google mới
    random_password = secrets.token_urlsafe(16)
    hashed_random = _hash_password(random_password)
    
    new_user = User(
        full_name=body.full_name.strip(),
        email=email_clean,
        google_id=body.google_id,
        password_hash=hashed_random,
        avatar_url=body.avatar_url,
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    return AuthResponse(
        user_id=new_user.user_id,
        full_name=new_user.full_name,
        email=new_user.email,
        avatar_url=new_user.avatar_url,
        message="Đăng ký tài khoản Google thành công!",
    )


# ─────────────────────────────────────────────────────────────────────────────
# POST /api/auth/forgot-password
# ─────────────────────────────────────────────────────────────────────────────
@router.post(
    "/forgot-password",
    response_model=MessageResponse,
    status_code=status.HTTP_200_OK,
    summary="Yêu cầu đặt lại mật khẩu",
)
def forgot_password(body: ForgotPasswordRequest, db: Session = Depends(get_db)):
    email_clean = body.email.strip().lower()
    
    # 1. Validate format email
    if not _EMAIL_RE.match(email_clean):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email không hợp lệ.",
        )

    # 2. Tìm kiếm user
    user = db.query(User).filter(User.email == email_clean).first()
    
    # Luôn trả về message an toàn để tránh email enumeration attack
    success_msg = "Nếu email tồn tại trên hệ thống, mật khẩu tạm thời đã được gửi về hộp thư của bạn."
    
    if not user:
        return MessageResponse(message=success_msg)
        
    # 3. Tạo mật khẩu tạm ngẫu nhiên: ST + 6 chữ số ngẫu nhiên
    temp_code = "".join(secrets.choice("0123456789") for _ in range(6))
    temp_password = f"ST{temp_code}"
    
    # 4. Cấu hình SMTP gửi email qua Gmail
    smtp_email = os.getenv("SMTP_EMAIL")
    smtp_password = os.getenv("SMTP_APP_PASSWORD")
    
    if not smtp_email or not smtp_password:
        # Nếu chưa cấu hình biến môi trường, trả lỗi rõ ràng không crash server
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Hệ thống Gmail SMTP chưa được cấu hình trên Server. Vui lòng liên hệ Admin.",
        )
        
    # 5. Gửi thư bằng smtplib
    try:
        subject = "Khôi phục mật khẩu - SaiGonTravid"
        mail_body = (
            f"Xin chào {user.full_name},\n\n"
            f"Chúng tôi đã nhận được yêu cầu khôi phục mật khẩu từ bạn.\n"
            f"Mật khẩu tạm thời mới của bạn là: {temp_password}\n\n"
            f"Vui lòng đăng nhập bằng mật khẩu tạm này và tiến hành đổi mật khẩu mới ngay trong mục tài khoản.\n\n"
            f"Trân trọng,\n"
            f"Đội ngũ SaiGonTravid"
        )
        
        msg = MIMEText(mail_body, 'plain', 'utf-8')
        msg['Subject'] = subject
        msg['From'] = smtp_email
        msg['To'] = user.email
        
        with smtplib.SMTP("smtp.gmail.com", 587, timeout=10) as server:
            server.starttls()
            server.login(smtp_email, smtp_password)
            server.sendmail(smtp_email, [user.email], msg.as_string())
            
    except Exception as e:
        # Ghi log exception phục vụ debug, KHÔNG log mật khẩu tạm
        print(f"[SMTP ERROR] Failed to send email to {user.email}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Gửi email khôi phục thất bại. Vui lòng liên hệ Admin hoặc thử lại sau.",
        )
        
    # 6. Chỉ cập nhật và lưu password_hash vào DB khi gửi email thành công
    try:
        hashed = _hash_password(temp_password)
        user.password_hash = hashed
        db.commit()
    except Exception as e:
        db.rollback()
        print(f"[DB ERROR] Failed to update password hash for {user.email}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Đã có lỗi xảy ra khi lưu thông tin. Vui lòng thử lại.",
        )
        
    return MessageResponse(message=success_msg)

