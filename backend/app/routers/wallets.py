from datetime import date
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.core.database import get_db
from app.core.security import get_current_user
from app.models.models import Wallet, WalletTransfer, Income, Expense, User
from app.schemas.schemas import (
    WalletCreate, WalletUpdate, WalletTransferRequest, WalletAdjustRequest
)

router = APIRouter(prefix="/api/wallets", tags=["Wallets"])

def calculate_wallet_balance(db: Session, wallet: Wallet) -> float:
    # incomes
    inc_sum = db.query(func.coalesce(func.sum(Income.amount), 0.0))\
        .filter(Income.wallet_id == wallet.id, Income.status == "approved").scalar()
    
    # expenses
    exp_sum = db.query(func.coalesce(func.sum(Expense.amount), 0.0))\
        .filter(Expense.wallet_id == wallet.id, Expense.status == "approved").scalar()
    
    # transfers in
    tin_sum = db.query(func.coalesce(func.sum(WalletTransfer.amount), 0.0))\
        .filter(WalletTransfer.to_wallet_id == wallet.id).scalar()
    
    # transfers out
    tout_sum = db.query(func.coalesce(func.sum(WalletTransfer.amount), 0.0))\
        .filter(WalletTransfer.from_wallet_id == wallet.id).scalar()
    
    initial = float(wallet.initial_balance or 0.0)
    return float(initial + float(inc_sum) - float(exp_sum) + float(tin_sum) - float(tout_sum))

@router.get("")
def get_wallets(
    include_archived: bool = Query(False),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    query = db.query(Wallet).filter(Wallet.user_id == current_user.id)
    if not include_archived:
        query = query.filter(Wallet.is_archived == False)
    
    wallets = query.order_by(Wallet.is_archived.asc(), Wallet.id.asc()).all()

    wallet_list = []
    total_balance = 0.0

    type_labels = {
        "cash": "Uang Tunai (Cash)",
        "bank": "Transfer Bank",
        "emoney": "E-Wallet / QRIS",
        "other": "Lainnya"
    }

    for w in wallets:
        bal = calculate_wallet_balance(db, w)
        if not w.is_archived:
            total_balance += bal
        
        wallet_list.append({
            "id": w.id,
            "name": w.name,
            "type": w.type,
            "type_label": type_labels.get(w.type, w.type.capitalize()),
            "initial_balance": float(w.initial_balance or 0.0),
            "current_balance": bal,
            "color": w.color or "#10B981",
            "icon": w.icon or "cash",
            "is_archived": bool(w.is_archived),
            "created_at": w.created_at.isoformat() if w.created_at else None
        })

    return {
        "success": True,
        "data": {
            "total_balance": total_balance,
            "wallets": wallet_list
        }
    }

@router.post("")
def create_wallet(
    req: WalletCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    wallet = Wallet(
        user_id=current_user.id,
        name=req.name,
        type=req.type,
        initial_balance=req.initial_balance or 0.0,
        color=req.color or "#10B981",
        icon=req.icon or "cash",
        is_archived=False
    )
    db.add(wallet)
    db.commit()
    db.refresh(wallet)

    return {
        "success": True,
        "message": "Dompet berhasil ditambahkan",
        "data": {
            "id": wallet.id,
            "name": wallet.name,
            "type": wallet.type,
            "initial_balance": float(wallet.initial_balance),
            "current_balance": float(wallet.initial_balance),
            "color": wallet.color,
            "icon": wallet.icon,
            "is_archived": wallet.is_archived
        }
    }

@router.get("/{id}")
def get_wallet_detail(
    id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    wallet = db.query(Wallet).filter(Wallet.id == id, Wallet.user_id == current_user.id).first()
    if not wallet:
        raise HTTPException(status_code=404, detail="Dompet tidak ditemukan")
    
    bal = calculate_wallet_balance(db, wallet)
    return {
        "success": True,
        "data": {
            "id": wallet.id,
            "name": wallet.name,
            "type": wallet.type,
            "initial_balance": float(wallet.initial_balance or 0.0),
            "current_balance": bal,
            "color": wallet.color,
            "icon": wallet.icon,
            "is_archived": wallet.is_archived,
            "created_at": wallet.created_at.isoformat() if wallet.created_at else None
        }
    }

@router.put("/{id}")
def update_wallet(
    id: int,
    req: WalletUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    wallet = db.query(Wallet).filter(Wallet.id == id, Wallet.user_id == current_user.id).first()
    if not wallet:
        raise HTTPException(status_code=404, detail="Dompet tidak ditemukan")
    
    if req.name is not None:
        wallet.name = req.name
    if req.type is not None:
        wallet.type = req.type
    if req.initial_balance is not None:
        wallet.initial_balance = req.initial_balance
    if req.color is not None:
        wallet.color = req.color
    if req.icon is not None:
        wallet.icon = req.icon
    
    db.commit()
    db.refresh(wallet)

    return {
        "success": True,
        "message": "Dompet berhasil diperbarui",
        "data": {
            "id": wallet.id,
            "name": wallet.name,
            "type": wallet.type,
            "current_balance": calculate_wallet_balance(db, wallet)
        }
    }

@router.post("/{id}/archive")
def archive_wallet(
    id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    wallet = db.query(Wallet).filter(Wallet.id == id, Wallet.user_id == current_user.id).first()
    if not wallet:
        raise HTTPException(status_code=404, detail="Dompet tidak ditemukan")
    
    wallet.is_archived = not wallet.is_archived
    db.commit()

    msg = "Dompet berhasil diarsipkan" if wallet.is_archived else "Dompet berhasil dipulihkan"
    return {
        "success": True,
        "message": msg,
        "data": {"is_archived": wallet.is_archived}
    }

@router.post("/transfer")
def transfer_wallet(
    req: WalletTransferRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    from_w = db.query(Wallet).filter(Wallet.id == req.from_wallet_id, Wallet.user_id == current_user.id).first()
    to_w = db.query(Wallet).filter(Wallet.id == req.to_wallet_id, Wallet.user_id == current_user.id).first()

    if not from_w or not to_w:
        raise HTTPException(status_code=404, detail="Salah satu dompet tidak ditemukan")
    if from_w.id == to_w.id:
        raise HTTPException(status_code=422, detail="Dompet asal dan tujuan tidak boleh sama")
    if req.amount <= 0:
        raise HTTPException(status_code=422, detail="Jumlah transfer harus lebih dari 0")
    
    from_balance = calculate_wallet_balance(db, from_w)
    if from_balance < req.amount:
        raise HTTPException(status_code=422, detail=f"Saldo tidak cukup. Saldo saat ini: {from_balance}")
    
    transfer = WalletTransfer(
        user_id=current_user.id,
        from_wallet_id=from_w.id,
        to_wallet_id=to_w.id,
        amount=req.amount,
        notes=req.notes,
        date=req.date or date.today()
    )
    db.add(transfer)
    db.commit()

    return {
        "success": True,
        "message": "Transfer antar dompet berhasil",
        "data": {
            "from_wallet": from_w.name,
            "to_wallet": to_w.name,
            "amount": req.amount,
            "date": transfer.date.isoformat() if transfer.date else None
        }
    }

@router.post("/{id}/adjust")
def adjust_wallet(
    id: int,
    req: WalletAdjustRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    wallet = db.query(Wallet).filter(Wallet.id == id, Wallet.user_id == current_user.id).first()
    if not wallet:
        raise HTTPException(status_code=404, detail="Dompet tidak ditemukan")
    
    current_bal = calculate_wallet_balance(db, wallet)
    diff = req.new_balance - current_bal

    if diff > 0:
        # Penyesuaian masuk
        inc = Income(
            user_id=current_user.id,
            wallet_id=wallet.id,
            amount=diff,
            source=wallet.type,
            description=req.notes or "Penyesuaian saldo (Koreksi Tambah)",
            date=date.today(),
            status="approved"
        )
        db.add(inc)
    elif diff < 0:
        # Penyesuaian keluar
        exp = Expense(
            user_id=current_user.id,
            wallet_id=wallet.id,
            amount=abs(diff),
            source=wallet.type,
            description=req.notes or "Penyesuaian saldo (Koreksi Kurang)",
            date=date.today(),
            status="approved"
        )
        db.add(exp)
    
    db.commit()

    return {
        "success": True,
        "message": "Saldo berhasil disesuaikan",
        "data": {
            "new_balance": req.new_balance
        }
    }

@router.get("/{id}/transactions")
def get_wallet_transactions(
    id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    wallet = db.query(Wallet).filter(Wallet.id == id, Wallet.user_id == current_user.id).first()
    if not wallet:
        raise HTTPException(status_code=404, detail="Dompet tidak ditemukan")

    incomes = db.query(Income).filter(Income.wallet_id == id).all()
    expenses = db.query(Expense).filter(Expense.wallet_id == id).all()

    txs = []
    for i in incomes:
        txs.append({
            "id": f"inc-{i.id}",
            "type": "income",
            "amount": float(i.amount),
            "description": i.description,
            "category": i.category.name if i.category else "-",
            "wallet_name": wallet.name,
            "date": i.date.isoformat() if i.date else None,
            "status": i.status
        })
    for e in expenses:
        txs.append({
            "id": f"exp-{e.id}",
            "type": "expense",
            "amount": float(e.amount),
            "description": e.description,
            "category": e.category.name if e.category else "-",
            "wallet_name": wallet.name,
            "date": e.date.isoformat() if e.date else None,
            "status": e.status
        })

    txs.sort(key=lambda x: x["date"] or "", reverse=True)

    return {
        "success": True,
        "data": txs
    }
