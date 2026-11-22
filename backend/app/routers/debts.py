from datetime import date
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from sqlalchemy import func as sqlfunc
from app.core.database import get_db
from app.core.security import get_current_user
from app.models.models import Debt, Expense, Income, Wallet, Category, User
from app.schemas.schemas import DebtCreate, DebtUpdate, DebtPayRequest

router = APIRouter(prefix="/api/debts", tags=["Debts & Receivables"])

def format_debt(db: Session, debt: Debt) -> dict:
    is_debt = (debt.type == "debt")
    if is_debt:
        records = db.query(Expense).filter(Expense.debt_id == debt.id).all()
    else:
        records = db.query(Income).filter(Income.debt_id == debt.id).all()

    paid_amount = 0.0
    payments = []

    for r in records:
        if r.status == "approved":
            paid_amount += float(r.amount)
        w_name = r.wallet.name if r.wallet else "Dompet"
        payments.append({
            "id": r.id,
            "amount": float(r.amount),
            "wallet_id": r.wallet_id,
            "wallet_name": w_name,
            "source": r.source,
            "source_label": w_name,
            "date": r.date.isoformat() if r.date else None,
            "description": r.description or "",
            "status": r.status,
            "created_at": r.created_at.isoformat() if r.created_at else None
        })

    payments.sort(key=lambda x: (x["date"] or "", x["created_at"] or ""), reverse=True)

    total_amount = float(debt.amount or 0.0)
    remaining_amount = max(0.0, total_amount - paid_amount)
    percent_paid = min(100.0, round((paid_amount / total_amount) * 100, 1)) if total_amount > 0 else 0.0

    return {
        "id": debt.id,
        "user_id": debt.user_id,
        "type": debt.type,
        "person_name": debt.person_name,
        "amount": total_amount,
        "paid_amount": paid_amount,
        "remaining_amount": remaining_amount,
        "percent_paid": percent_paid,
        "due_date": debt.due_date.isoformat() if debt.due_date else None,
        "date": debt.date.isoformat() if debt.date else None,
        "description": debt.description,
        "status": debt.status,
        "installments_count": len(payments),
        "payments": payments,
        "created_at": debt.created_at.isoformat() if debt.created_at else None
    }

@router.get("")
def get_debts(
    type: Optional[str] = Query(None), # debt, receivable
    status: Optional[str] = Query(None), # unpaid, paid
    date_from: Optional[date] = Query(None),
    date_to: Optional[date] = Query(None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    query = db.query(Debt).filter(Debt.user_id == current_user.id)
    if type:
        query = query.filter(Debt.type == type)
    if status:
        query = query.filter(Debt.status == status)
    if date_from:
        query = query.filter(Debt.date >= date_from)
    if date_to:
        query = query.filter(Debt.date <= date_to)

    debts = query.order_by(Debt.id.desc()).all()
    data = [format_debt(db, d) for d in debts]

    return {
        "success": True,
        "data": data
    }

@router.post("", status_code=status.HTTP_201_CREATED)
def create_debt(
    req: DebtCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if req.amount <= 0:
        raise HTTPException(status_code=422, detail="Jumlah hutang harus lebih dari 0")
    
    debt = Debt(
        user_id=current_user.id,
        type=req.type,
        person_name=req.person_name,
        amount=req.amount,
        due_date=req.due_date,
        date=date.today(),
        description=req.description,
        status="unpaid"
    )
    db.add(debt)
    db.commit()
    db.refresh(debt)

    return {
        "success": True,
        "message": f"{'Hutang' if req.type == 'debt' else 'Piutang'} berhasil dicatat",
        "data": format_debt(db, debt)
    }

@router.get("/{id}")
def get_debt_detail(
    id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    debt = db.query(Debt).filter(Debt.id == id, Debt.user_id == current_user.id).first()
    if not debt:
        raise HTTPException(status_code=404, detail="Data hutang/piutang tidak ditemukan")
    
    return {
        "success": True,
        "data": format_debt(db, debt)
    }

@router.put("/{id}")
def update_debt(
    id: int,
    req: DebtUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    debt = db.query(Debt).filter(Debt.id == id, Debt.user_id == current_user.id).first()
    if not debt:
        raise HTTPException(status_code=404, detail="Data tidak ditemukan")

    if req.person_name is not None:
        debt.person_name = req.person_name
    if req.amount is not None:
        debt.amount = req.amount
    if req.due_date is not None:
        debt.due_date = req.due_date
    if req.description is not None:
        debt.description = req.description
    if req.status is not None:
        debt.status = req.status
    if req.type is not None:
        debt.type = req.type

    db.commit()
    db.refresh(debt)

    return {
        "success": True,
        "message": "Data berhasil diperbarui",
        "data": format_debt(db, debt)
    }

@router.delete("/{id}")
def delete_debt(
    id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    debt = db.query(Debt).filter(Debt.id == id, Debt.user_id == current_user.id).first()
    if not debt:
        raise HTTPException(status_code=404, detail="Data tidak ditemukan")
    
    db.delete(debt)
    db.commit()

    return {
        "success": True,
        "message": "Data berhasil dihapus"
    }

@router.post("/{id}/pay", status_code=status.HTTP_201_CREATED)
def pay_debt_installment(
    id: int,
    req: DebtPayRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    debt = db.query(Debt).filter(
        Debt.id == id, Debt.user_id == current_user.id
    ).with_for_update().first()
    if not debt:
        raise HTTPException(status_code=404, detail="Data hutang/piutang tidak ditemukan")
    if debt.status == "paid":
        raise HTTPException(status_code=422, detail=f"{'Hutang' if debt.type == 'debt' else 'Piutang'} ini sudah lunas")
    if req.amount <= 0:
        raise HTTPException(status_code=422, detail="Nominal pembayaran harus lebih dari 0")

    # Hitung pembayaran yang telah disetujui sebelumnya
    if debt.type == "debt":
        paid_so_far = db.query(sqlfunc.coalesce(sqlfunc.sum(Expense.amount), 0.0)).filter(
            Expense.debt_id == debt.id, Expense.status == "approved"
        ).scalar()
    else:
        paid_so_far = db.query(sqlfunc.coalesce(sqlfunc.sum(Income.amount), 0.0)).filter(
            Income.debt_id == debt.id, Income.status == "approved"
        ).scalar()

    total_amount = float(debt.amount or 0.0)
    remaining = max(0.0, total_amount - float(paid_so_far or 0.0))

    if remaining <= 0:
        debt.status = "paid"
        db.commit()
        raise HTTPException(status_code=422, detail=f"{'Hutang' if debt.type == 'debt' else 'Piutang'} ini sudah lunas")

    if req.amount > remaining:
        raise HTTPException(
            status_code=422,
            detail=f"Nominal pembayaran (Rp {req.amount:,.0f}) melebihi sisa yang harus dibayar (Rp {remaining:,.0f})"
        )

    wallet = None
    if req.wallet_id:
        wallet = db.query(Wallet).filter(
            Wallet.id == req.wallet_id, Wallet.user_id == current_user.id
        ).with_for_update().first()
        if not wallet:
            raise HTTPException(status_code=404, detail="Dompet tidak ditemukan atau bukan milik Anda")
    else:
        wallet = db.query(Wallet).filter(
            Wallet.user_id == current_user.id, Wallet.is_archived == False
        ).with_for_update().first()

    if wallet and wallet.is_archived:
        raise HTTPException(status_code=422, detail=f"Dompet '{wallet.name}' telah diarsipkan")

    pay_date = req.date or date.today()
    desc = req.note or f"Cicilan {debt.type} ke {debt.person_name}"

    # Gunakan kategori netral sistem agar tidak merusak statistik pengeluaran operasional
    cat_name = "Pembayaran Hutang" if debt.type == "debt" else "Penerimaan Piutang"
    cat_type = "expense" if debt.type == "debt" else "income"
    sys_cat = db.query(Category).filter(Category.name == cat_name).first()
    if not sys_cat:
        sys_cat = Category(name=cat_name, type=cat_type, icon="account_balance", color="#6366F1", is_neutral=True)
        db.add(sys_cat)
        db.flush()

    if debt.type == "debt":
        rec = Expense(
            user_id=current_user.id,
            debt_id=debt.id,
            category_id=sys_cat.id,
            wallet_id=wallet.id if wallet else None,
            amount=req.amount,
            source=wallet.type if wallet else "cash",
            description=desc,
            date=pay_date,
            status="approved"
        )
        db.add(rec)
    else:
        rec = Income(
            user_id=current_user.id,
            debt_id=debt.id,
            category_id=sys_cat.id,
            wallet_id=wallet.id if wallet else None,
            amount=req.amount,
            source=wallet.type if wallet else "cash",
            description=desc,
            date=pay_date,
            status="approved"
        )
        db.add(rec)

    new_paid = float(paid_so_far or 0.0) + req.amount
    if new_paid >= total_amount:
        debt.status = "paid"

    # Satu transaksi atomik
    db.commit()
    db.refresh(debt)

    return {
        "success": True,
        "message": "Pembayaran berhasil dicatat",
        "data": format_debt(db, debt)
    }
