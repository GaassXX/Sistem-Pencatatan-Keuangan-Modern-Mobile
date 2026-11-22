from datetime import date
from typing import Optional
from dateutil.relativedelta import relativedelta
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import func, extract
from app.core.database import get_db
from app.core.security import get_current_user
from app.models.models import Income, Expense, Debt, Saving, Category, User

router = APIRouter(prefix="/api/dashboard", tags=["Dashboard"])

MONTH_NAMES = [
    "Jan", "Feb", "Mar", "Apr", "Mei", "Jun", 
    "Jul", "Agu", "Sep", "Okt", "Nov", "Des"
]

@router.get("/stats")
def get_dashboard_stats(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    user_id = current_user.id
    today = date.today()

    # Total keseluruhan operasional (mengecualikan kategori netral seperti bayar utang / penyesuaian saldo)
    total_income = float(db.query(func.coalesce(func.sum(Income.amount), 0.0))\
        .outerjoin(Category, Income.category_id == Category.id)\
        .filter(
            Income.user_id == user_id, 
            Income.status == "approved",
            (Category.is_neutral == False) | (Category.is_neutral == None)
        ).scalar())
    
    total_expense = float(db.query(func.coalesce(func.sum(Expense.amount), 0.0))\
        .outerjoin(Category, Expense.category_id == Category.id)\
        .filter(
            Expense.user_id == user_id, 
            Expense.status == "approved",
            (Category.is_neutral == False) | (Category.is_neutral == None)
        ).scalar())
    
    net_balance = total_income - total_expense

    # Bulan ini (hanya operasional riil)
    month_income = float(db.query(func.coalesce(func.sum(Income.amount), 0.0))\
        .outerjoin(Category, Income.category_id == Category.id)\
        .filter(
            Income.user_id == user_id, 
            Income.status == "approved",
            (Category.is_neutral == False) | (Category.is_neutral == None),
            extract('month', Income.date) == today.month,
            extract('year', Income.date) == today.year
        ).scalar())

    month_expense = float(db.query(func.coalesce(func.sum(Expense.amount), 0.0))\
        .outerjoin(Category, Expense.category_id == Category.id)\
        .filter(
            Expense.user_id == user_id, 
            Expense.status == "approved",
            (Category.is_neutral == False) | (Category.is_neutral == None),
            extract('month', Expense.date) == today.month,
            extract('year', Expense.date) == today.year
        ).scalar())

    # Utang dan piutang belum lunas
    total_debt_unpaid = float(db.query(func.coalesce(func.sum(Debt.amount), 0.0))\
        .filter(Debt.user_id == user_id, Debt.type == "debt", Debt.status == "unpaid").scalar())

    total_receivable_unpaid = float(db.query(func.coalesce(func.sum(Debt.amount), 0.0))\
        .filter(Debt.user_id == user_id, Debt.type == "receivable", Debt.status == "unpaid").scalar())

    # Tabungan yang sedang berjalan (mengunci saldo kas menjadi tidak tersedia untuk belanja bebas)
    total_savings_allocated = float(db.query(func.coalesce(func.sum(Saving.current_amount), 0.0))\
        .filter(Saving.user_id == user_id, Saving.status == "active").scalar())

    # Saldo tersedia (Kas bersih dikurangi kewajiban utang & alokasi tabungan per BRD FR-29 & FR-105)
    available_balance = max(0.0, net_balance - total_debt_unpaid - total_savings_allocated)

    # Breakdown kategori bulan ini (eksklusif kategori netral)
    breakdown_query = db.query(
        Category.name.label("category_name"),
        func.sum(Expense.amount).label("total_amount")
    ).join(Category, Expense.category_id == Category.id)\
     .filter(
         Expense.user_id == user_id,
         Expense.status == "approved",
         Category.is_neutral == False,
         extract('month', Expense.date) == today.month,
         extract('year', Expense.date) == today.year
     ).group_by(Category.id, Category.name)\
      .order_by(func.sum(Expense.amount).desc()).all()

    category_breakdown = []
    for row in breakdown_query:
        amt = float(row.total_amount)
        pct = round((amt / month_expense) * 100, 1) if month_expense > 0 else 0.0
        category_breakdown.append({
            "category": row.category_name,
            "amount": amt,
            "percentage": pct
        })

    pending_transactions = 0
    if current_user.parent_id:
        pending_transactions = db.query(Expense).filter(Expense.user_id == user_id, Expense.status == "pending").count()

    return {
        "success": True,
        "data": {
            "total_income": total_income,
            "total_expense": total_expense,
            "net_balance": net_balance,
            "available_balance": available_balance,
            "month_income": month_income,
            "month_expense": month_expense,
            "month_net": float(month_income - month_expense),
            "pending_transactions": pending_transactions,
            "total_debt_unpaid": total_debt_unpaid,
            "total_receivable_unpaid": total_receivable_unpaid,
            "category_breakdown": category_breakdown
        }
    }

@router.get("/chart")
def get_dashboard_chart(
    months: int = Query(6, ge=1, le=12),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    user_id = current_user.id
    today = date.today()
    chart_data = []

    for i in range(months - 1, -1, -1):
        target_month_date = today - relativedelta(months=i)
        m = target_month_date.month
        y = target_month_date.year
        month_label = f"{MONTH_NAMES[m-1]} {str(y)[-2:]}"

        inc = float(db.query(func.coalesce(func.sum(Income.amount), 0.0))\
            .outerjoin(Category, Income.category_id == Category.id)\
            .filter(
                Income.user_id == user_id,
                Income.status == "approved",
                (Category.is_neutral == False) | (Category.is_neutral == None),
                extract('month', Income.date) == m,
                extract('year', Income.date) == y
            ).scalar())

        exp = float(db.query(func.coalesce(func.sum(Expense.amount), 0.0))\
            .outerjoin(Category, Expense.category_id == Category.id)\
            .filter(
                Expense.user_id == user_id,
                Expense.status == "approved",
                (Category.is_neutral == False) | (Category.is_neutral == None),
                extract('month', Expense.date) == m,
                extract('year', Expense.date) == y
            ).scalar())

        chart_data.append({
            "month": month_label,
            "income": inc,
            "expense": exp,
            "net": float(inc - exp)
        })

    return {
        "success": True,
        "data": chart_data
    }
