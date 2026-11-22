import os
import shutil
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.security import (
    verify_password, get_password_hash, create_access_token, get_current_user
)
from app.models.models import User, Wallet
from app.schemas.schemas import (
    LoginRequest, RegisterRequest, ProfileUpdateRequest, ApiResponse, UserOut
)

router = APIRouter(prefix="/api/auth", tags=["Auth"])

def serialize_user(user: User) -> dict:
    return {
        "id": user.id,
        "name": user.name,
        "email": user.email,
        "role": user.role,
        "is_active": user.is_active,
        "is_independent": user.is_independent,
        "parent_id": user.parent_id,
        "avatar_url": user.avatar_url,
        "telegram_chat_id": user.telegram_chat_id,
        "telegram_pair_code": user.telegram_pair_code,
        "created_at": user.created_at.isoformat() if user.created_at else None
    }

@router.post("/register", status_code=status.HTTP_201_CREATED)
def register(req: RegisterRequest, db: Session = Depends(get_db)):
    if req.password_confirmation and req.password != req.password_confirmation:
        raise HTTPException(status_code=422, detail="Konfirmasi password tidak cocok")
    
    existing_user = db.query(User).filter(User.email == req.email).first()
    if existing_user:
        raise HTTPException(status_code=422, detail="Email sudah terdaftar")
    
    role = "personal"
    if req.account_type == "parent":
        role = "parent"
    elif req.account_type == "child":
        role = "child"
    
    is_independent = req.account_type == "independent"

    user = User(
        name=req.name,
        email=req.email,
        password=get_password_hash(req.password),
        role=role,
        is_independent=is_independent,
        is_active=True
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    # Buat dompet cash default
    default_wallet = Wallet(
        user_id=user.id,
        name="Uang Tunai (Cash)",
        type="cash",
        initial_balance=0.0,
        color="#10B981",
        icon="payments",
        is_archived=False
    )
    db.add(default_wallet)
    db.commit()

    token = create_access_token({"sub": str(user.id), "email": user.email, "role": user.role})

    return {
        "success": True,
        "message": "Registrasi berhasil",
        "data": {
            "token": token,
            "user": serialize_user(user)
        }
    }

@router.post("/login")
def login(req: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == req.email).first()
    if not user or not verify_password(req.password, user.password):
        raise HTTPException(status_code=401, detail="Email atau password salah")
    
    token = create_access_token({"sub": str(user.id), "email": user.email, "role": user.role})

    return {
        "success": True,
        "message": "Login berhasil",
        "data": {
            "token": token,
            "user": serialize_user(user)
        }
    }

@router.get("/me")
def get_profile(current_user: User = Depends(get_current_user)):
    return {
        "success": True,
        "data": serialize_user(current_user)
    }

@router.put("/me")
def update_profile(
    req: ProfileUpdateRequest, 
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if req.name:
        current_user.name = req.name
    if req.email and req.email != current_user.email:
        existing = db.query(User).filter(User.email == req.email).first()
        if existing:
            raise HTTPException(status_code=422, detail="Email sudah digunakan user lain")
        current_user.email = req.email
    
    if req.new_password:
        if not req.current_password or not verify_password(req.current_password, current_user.password):
            raise HTTPException(status_code=422, detail="Password lama salah")
        if req.new_password_confirmation and req.new_password != req.new_password_confirmation:
            raise HTTPException(status_code=422, detail="Konfirmasi password baru tidak cocok")
        current_user.password = get_password_hash(req.new_password)
    
    db.commit()
    db.refresh(current_user)

    return {
        "success": True,
        "message": "Profil berhasil diperbarui",
        "data": serialize_user(current_user)
    }

@router.post("/me/avatar")
async def upload_avatar(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    upload_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), "uploads", "avatars")
    os.makedirs(upload_dir, exist_ok=True)

    filename = f"user_{current_user.id}_{file.filename}"
    file_path = os.path.join(upload_dir, filename)

    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    
    current_user.avatar_url = f"/uploads/avatars/{filename}"
    db.commit()

    return {
        "success": True,
        "message": "Avatar berhasil diperbarui",
        "data": {"avatar_url": current_user.avatar_url}
    }

@router.delete("/me/avatar")
def delete_avatar(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    current_user.avatar_url = None
    db.commit()
    return {
        "success": True,
        "message": "Avatar berhasil dihapus"
    }

@router.post("/logout")
def logout(current_user: User = Depends(get_current_user)):
    return {
        "success": True,
        "message": "Logout berhasil"
    }
