from datetime import date
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func, extract
from app.core.database import get_db
from app.core.security import get_current_user
from app.models.models import Budget, Expense, Category, User
from app.schemas.schemas import BudgetCreate

router = APIRouter(prefix="/api/budgets", tags=["Budgets"])

@router.get("")
def get_budgets(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    user_id = current_user.id
    today = date.today()

    budgets = db.query(Budget).filter(Budget.user_id == user_id).all()

    total_limit = 0.0
    total_spent = 0.0
    mapped = []

    for b in budgets:
        limit = float(b.limit_amount or 0.0)

        # Hitung realisasi pengeluaran bulan ini untuk kategori ini
        spent = float(db.query(func.coalesce(func.sum(Expense.amount), 0.0))\
            .filter(
                Expense.user_id == user_id,
                Expense.category_id == b.category_id,
                Expense.status == "approved",
                extract('month', Expense.date) == today.month,
                extract('year', Expense.date) == today.year
            ).scalar())

        percentage = round((spent / limit) * 100, 1) if limit > 0 else 0.0
        remaining = max(0.0, limit - spent)

        total_limit += limit
        total_spent += spent

        c_name = b.category.name if b.category else "Kategori"

        mapped.append({
            "id": b.id,
            "category_id": b.category_id,
            "category_name": c_name,
            "limit_amount": limit,
            "spent_amount": spent,
            "remaining_amount": remaining,
            "percentage": percentage,
            "is_near_limit": percentage >= 80.0,
            "is_over_limit": spent > limit,
            "period": b.period or "monthly"
        })

    overall_percentage = round((total_spent / total_limit) * 100, 1) if total_limit > 0 else 0.0

    return {
        "success": True,
        "data": {
            "summary": {
                "total_limit": total_limit,
                "total_spent": total_spent,
                "total_remaining": max(0.0, total_limit - total_spent),
                "overall_percentage": overall_percentage,
                "is_over_limit": total_spent > total_limit
            },
            "budgets": mapped
        }
    }

@router.post("", status_code=status.HTTP_201_CREATED)
def create_or_update_budget(
    req: BudgetCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if req.limit_amount <= 0:
        raise HTTPException(status_code=422, detail="Limit budget harus lebih dari 0")

    category = db.query(Category).filter(Category.id == req.category_id).first()
    if not category:
        raise HTTPException(status_code=404, detail="Kategori tidak ditemukan")
    if category.is_neutral:
        raise HTTPException(status_code=422, detail="Tidak dapat membuat anggaran untuk kategori sistem/netral")
    if category.type != "expense":
        raise HTTPException(status_code=422, detail="Anggaran hanya dapat dibuat untuk kategori pengeluaran")

    budget = db.query(Budget).filter(
        Budget.user_id == current_user.id,
        Budget.category_id == req.category_id
    ).first()

    if budget:
        budget.limit_amount = req.limit_amount
        budget.period = req.period or "monthly"
        msg = "Budget berhasil diperbarui"
    else:
        budget = Budget(
            user_id=current_user.id,
            category_id=req.category_id,
            limit_amount=req.limit_amount,
            period=req.period or "monthly"
        )
        db.add(budget)
        msg = "Budget berhasil dibuat"

    db.commit()
    db.refresh(budget)

    return {
        "success": True,
        "message": msg,
        "data": {
            "id": budget.id,
            "category_id": budget.category_id,
            "limit_amount": float(budget.limit_amount),
            "period": budget.period
        }
    }

@router.delete("/{id}")
def delete_budget(
    id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    budget = db.query(Budget).filter(Budget.id == id, Budget.user_id == current_user.id).first()
    if not budget:
        raise HTTPException(status_code=404, detail="Budget tidak ditemukan")

    db.delete(budget)
    db.commit()

    return {
        "success": True,
        "message": "Budget berhasil dihapus"
    }
