from typing import Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.security import get_current_user
from app.models.models import Category, User

router = APIRouter(prefix="/api", tags=["Categories & Payment Methods"])

DEFAULT_CATEGORIES = [
    {"name": "Gaji & Pendapatan", "type": "income", "icon": "payments", "color": "#10B981"},
    {"name": "Investasi & Bunga", "type": "income", "icon": "trending_up", "color": "#3B82F6"},
    {"name": "Bonus & Hadiah", "type": "income", "icon": "card_giftcard", "color": "#F59E0B"},
    {"name": "Makanan & Minuman", "type": "expense", "icon": "restaurant", "color": "#EF4444"},
    {"name": "Transportasi", "type": "expense", "icon": "directions_car", "color": "#F97316"},
    {"name": "Belanja Bulanan", "type": "expense", "icon": "shopping_cart", "color": "#8B5CF6"},
    {"name": "Tagihan & Utilitas", "type": "expense", "icon": "receipt", "color": "#EC4899"},
    {"name": "Pendidikan & Kuliah", "type": "expense", "icon": "school", "color": "#6366F1"},
    {"name": "Hiburan & Rekreasi", "type": "expense", "icon": "movie", "color": "#14B8A6"},
    {"name": "Kesehatan", "type": "expense", "icon": "medical_services", "color": "#06B6D4"},
    {"name": "Lain-lain", "type": "expense", "icon": "more_horiz", "color": "#6B7280"},
]

def seed_categories_if_empty(db: Session):
    count = db.query(Category).count()
    if count == 0:
        for c in DEFAULT_CATEGORIES:
            db.add(Category(**c, is_active=True))
        db.commit()

@router.get("/categories")
def get_categories(
    type: Optional[str] = Query(None),
    db: Session = Depends(get_db)
):
    seed_categories_if_empty(db)
    query = db.query(Category).filter(Category.is_active == True)
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
