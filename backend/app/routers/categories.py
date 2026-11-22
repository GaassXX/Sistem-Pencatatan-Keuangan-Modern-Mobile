from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.security import get_current_user
from app.models.models import Category, User

router = APIRouter(prefix="/api", tags=["Categories & Payment Methods"])

class CategoryCreate(BaseModel):
    name: str
    type: str  # income / expense
    icon: Optional[str] = None
    color: Optional[str] = None

class CategoryUpdate(BaseModel):
    name: Optional[str] = None
    type: Optional[str] = None
    icon: Optional[str] = None
    color: Optional[str] = None

DEFAULT_CATEGORIES = [
    {"name": "Gaji & Pendapatan", "type": "income", "icon": "payments", "color": "#10B981", "is_neutral": False},
    {"name": "Investasi & Bunga", "type": "income", "icon": "trending_up", "color": "#3B82F6", "is_neutral": False},
    {"name": "Bonus & Hadiah", "type": "income", "icon": "card_giftcard", "color": "#F59E0B", "is_neutral": False},
    {"name": "Makanan & Minuman", "type": "expense", "icon": "restaurant", "color": "#EF4444", "is_neutral": False},
    {"name": "Transportasi", "type": "expense", "icon": "directions_car", "color": "#F97316", "is_neutral": False},
    {"name": "Belanja Bulanan", "type": "expense", "icon": "shopping_cart", "color": "#8B5CF6", "is_neutral": False},
    {"name": "Tagihan & Utilitas", "type": "expense", "icon": "receipt", "color": "#EC4899", "is_neutral": False},
    {"name": "Pendidikan & Kuliah", "type": "expense", "icon": "school", "color": "#6366F1", "is_neutral": False},
    {"name": "Hiburan & Rekreasi", "type": "expense", "icon": "movie", "color": "#14B8A6", "is_neutral": False},
    {"name": "Kesehatan", "type": "expense", "icon": "medical_services", "color": "#06B6D4", "is_neutral": False},
    {"name": "Lain-lain", "type": "expense", "icon": "more_horiz", "color": "#6B7280", "is_neutral": False},
    # Kategori Sistem Netral (Tidak masuk ke perhitungan laba/rugi operasional & budget)
    {"name": "Penyesuaian Saldo", "type": "expense", "icon": "tune", "color": "#64748B", "is_neutral": True},
    {"name": "Pembayaran Hutang", "type": "expense", "icon": "assignment_turned_in", "color": "#6366F1", "is_neutral": True},
    {"name": "Penerimaan Piutang", "type": "income", "icon": "call_received", "color": "#10B981", "is_neutral": True},
    {"name": "Biaya Admin", "type": "expense", "icon": "receipt_long", "color": "#EF4444", "is_neutral": False},
]

def seed_categories_if_empty(db: Session):
    for c in DEFAULT_CATEGORIES:
        existing = db.query(Category).filter(Category.name == c["name"]).first()
        if not existing:
            db.add(Category(**c, is_active=True, created_by=1))
        else:
            if hasattr(existing, "is_neutral") and existing.is_neutral != c.get("is_neutral", False):
                existing.is_neutral = c.get("is_neutral", False)
    db.commit()

@router.get("/categories")
def get_categories(
    type: Optional[str] = Query(None),
    include_neutral: bool = Query(False),
    db: Session = Depends(get_db)
):
    seed_categories_if_empty(db)
    query = db.query(Category).filter(Category.is_active == True)
    if not include_neutral:
        query = query.filter(Category.is_neutral == False)
    if type:
        query = query.filter(Category.type == type)
    
    categories = query.all()
    data = [
        {
            "id": c.id,
            "name": c.name,
            "type": c.type,
            "icon": c.icon,
            "color": c.color,
            "is_active": c.is_active
        }
        for c in categories
    ]
    return {
        "success": True,
        "data": data
    }

@router.get("/payment-methods")
def get_payment_methods():
    return {
        "success": True,
        "data": [
            {"value": "cash", "label": "Uang Tunai (Cash)"},
            {"value": "bank", "label": "Transfer Bank"},
            {"value": "emoney", "label": "E-Wallet / QRIS"},
            {"value": "other", "label": "Lainnya"}
        ]
    }

# ── CRUD Kategori (Tambah, Edit, Hapus) ──────────────────────────────────────

@router.post("/categories", status_code=201)
def create_category(
    req: CategoryCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    existing = db.query(Category).filter(Category.name == req.name).first()
    if existing:
        raise HTTPException(status_code=422, detail=f"Kategori '{req.name}' sudah ada")

    cat = Category(
        name=req.name,
        type=req.type,
        icon=req.icon,
        color=req.color or "#6B7280",
        is_active=True,
        is_neutral=False,
        created_by=current_user.id,
    )
    db.add(cat)
    db.commit()
    db.refresh(cat)
    return {
        "success": True,
        "message": "Kategori berhasil ditambahkan",
        "data": {
            "id": cat.id,
            "name": cat.name,
            "type": cat.type,
            "icon": cat.icon,
            "color": cat.color,
            "is_active": cat.is_active,
        }
    }

@router.put("/categories/{id}")
def update_category(
    id: int,
    req: CategoryUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    cat = db.query(Category).filter(Category.id == id).first()
    if not cat:
        raise HTTPException(status_code=404, detail="Kategori tidak ditemukan")
    if cat.is_neutral:
        raise HTTPException(status_code=422, detail="Kategori sistem tidak dapat diubah")

    if req.name is not None:
        dup = db.query(Category).filter(Category.name == req.name, Category.id != id).first()
        if dup:
            raise HTTPException(status_code=422, detail=f"Nama kategori '{req.name}' sudah digunakan")
        cat.name = req.name
    if req.type is not None:
        cat.type = req.type
    if req.icon is not None:
        cat.icon = req.icon
    if req.color is not None:
        cat.color = req.color

    db.commit()
    db.refresh(cat)
    return {
        "success": True,
        "message": "Kategori berhasil diperbarui",
        "data": {
            "id": cat.id,
            "name": cat.name,
            "type": cat.type,
            "icon": cat.icon,
            "color": cat.color,
            "is_active": cat.is_active,
        }
    }

@router.delete("/categories/{id}")
def delete_category(
    id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    cat = db.query(Category).filter(Category.id == id).first()
    if not cat:
        raise HTTPException(status_code=404, detail="Kategori tidak ditemukan")
    if cat.is_neutral:
        raise HTTPException(status_code=422, detail="Kategori sistem tidak dapat dihapus")

    # Soft delete: nonaktifkan agar data transaksi lama tidak rusak
    cat.is_active = False
    db.commit()
    return {
        "success": True,
        "message": f"Kategori '{cat.name}' berhasil dihapus"
    }
