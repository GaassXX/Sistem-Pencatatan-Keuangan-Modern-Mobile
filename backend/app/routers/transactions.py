from datetime import date
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.security import get_current_user
from app.models.models import Income, Expense, Category, Wallet, Debt, User
from app.schemas.schemas import TransactionCreate, TransactionUpdate

router = APIRouter(prefix="/api/transactions", tags=["Transactions"])

def parse_tx_id(raw_id: str):
    if raw_id.startswith("inc-"):
        return "income", int(raw_id.replace("inc-", ""))
    elif raw_id.startswith("exp-"):
        return "expense", int(raw_id.replace("exp-", ""))
    return None, int(raw_id)

@router.get("")
def get_transactions(
    wallet_id: Optional[int] = Query(None),
    type: Optional[str] = Query(None), # income, expense
    status: Optional[str] = Query(None),
    source: Optional[str] = Query(None),
    date_from: Optional[date] = Query(None),
    date_to: Optional[date] = Query(None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    incomes_q = db.query(Income).filter(Income.user_id == current_user.id)
    expenses_q = db.query(Expense).filter(Expense.user_id == current_user.id)

    if wallet_id:
        incomes_q = incomes_q.filter(Income.wallet_id == wallet_id)
        expenses_q = expenses_q.filter(Expense.wallet_id == wallet_id)
    
    if status:
        incomes_q = incomes_q.filter(Income.status == status)
        expenses_q = expenses_q.filter(Expense.status == status)

    if source:
        incomes_q = incomes_q.filter(Income.source == source)
        expenses_q = expenses_q.filter(Expense.source == source)

    if date_from:
        incomes_q = incomes_q.filter(Income.date >= date_from)
        expenses_q = expenses_q.filter(Expense.date >= date_from)

    if date_to:
        incomes_q = incomes_q.filter(Income.date <= date_to)
        expenses_q = expenses_q.filter(Expense.date <= date_to)

    items = []

    if type != "expense":
        incomes = incomes_q.all()
        for i in incomes:
            w_name = i.wallet.name if i.wallet else "Dompet"
            c_name = i.category.name if i.category else "-"
            items.append({
                "id": f"inc-{i.id}",
                "type": "income",
                "amount": float(i.amount),
                "description": i.description or "",
                "category": c_name,
                "category_id": i.category_id,
                "wallet_id": i.wallet_id,
                "wallet_name": w_name,
                "source": i.source,
                "source_label": w_name,
                "date": i.date.isoformat() if i.date else None,
                "status": i.status,
                "debt_id": i.debt_id,
                "created_at": i.created_at.isoformat() if i.created_at else None
            })

    if type != "income":
        expenses = expenses_q.all()
        for e in expenses:
            w_name = e.wallet.name if e.wallet else "Dompet"
            c_name = e.category.name if e.category else "-"
            items.append({
                "id": f"exp-{e.id}",
                "type": "expense",
                "amount": float(e.amount),
                "description": e.description or "",
                "category": c_name,
                "category_id": e.category_id,
                "wallet_id": e.wallet_id,
                "wallet_name": w_name,
                "source": e.source,
                "source_label": w_name,
                "date": e.date.isoformat() if e.date else None,
                "status": e.status,
                "debt_id": e.debt_id,
                "created_at": e.created_at.isoformat() if e.created_at else None
            })

    # Urutkan tanggal terbaru
    items.sort(key=lambda x: (x["date"] or "", x["created_at"] or ""), reverse=True)

    return {
        "success": True,
        "data": items
    }

@router.post("")
def create_transaction(
    req: TransactionCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if req.amount <= 0:
        raise HTTPException(status_code=422, detail="Jumlah transaksi harus lebih dari 0")
    
    # Validasi kepemilikan wallet (Cegah IDOR)
    wallet = None
    if req.wallet_id:
        wallet = db.query(Wallet).filter(Wallet.id == req.wallet_id, Wallet.user_id == current_user.id).first()
        if not wallet:
            raise HTTPException(status_code=404, detail="Dompet tidak ditemukan atau bukan milik Anda")
    else:
        wallet = db.query(Wallet).filter(Wallet.user_id == current_user.id, Wallet.is_archived == False).first()
        if not wallet:
            wallet = Wallet(user_id=current_user.id, name="Uang Tunai (Cash)", type="cash", initial_balance=0.0)
            db.add(wallet)
            db.commit()
            db.refresh(wallet)

    # Validasi kategori
    if req.category_id:
        category = db.query(Category).filter(Category.id == req.category_id).first()
        if not category:
            raise HTTPException(status_code=404, detail="Kategori tidak ditemukan")

    # Validasi kepemilikan debt
    if req.debt_id:
        debt = db.query(Debt).filter(Debt.id == req.debt_id, Debt.user_id == current_user.id).first()
        if not debt:
            raise HTTPException(status_code=404, detail="Data hutang/piutang tidak ditemukan atau bukan milik Anda")

    tx_status = "pending" if current_user.parent_id else "approved"
    tx_date = req.date or date.today()

    if req.type == "income":
        item = Income(
            user_id=current_user.id,
            category_id=req.category_id,
            wallet_id=wallet.id,
            debt_id=req.debt_id,
            amount=req.amount,
            source=req.source or wallet.type,
            description=req.description,
            date=tx_date,
            status=tx_status
        )
        db.add(item)
        db.commit()
        db.refresh(item)
        raw_id = f"inc-{item.id}"
    elif req.type == "expense":
        item = Expense(
            user_id=current_user.id,
            category_id=req.category_id,
            wallet_id=wallet.id,
            debt_id=req.debt_id,
            amount=req.amount,
            source=req.source or wallet.type,
            description=req.description,
            date=tx_date,
            status=tx_status
        )
        db.add(item)
        db.commit()
        db.refresh(item)
        raw_id = f"exp-{item.id}"
    else:
        raise HTTPException(status_code=422, detail="Tipe transaksi harus 'income' atau 'expense'")

    return {
        "success": True,
        "message": "Transaksi berhasil disimpan",
        "data": {
            "id": raw_id,
            "type": req.type,
            "amount": float(item.amount),
            "description": item.description,
            "wallet_id": wallet.id,
            "wallet_name": wallet.name,
            "date": item.date.isoformat() if item.date else None,
            "status": item.status
        }
    }

@router.get("/{id}")
def get_transaction_detail(
    id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    t_type, real_id = parse_tx_id(id)

    if t_type == "income" or (t_type is None and db.query(Income).filter(Income.id == real_id, Income.user_id == current_user.id).first()):
        item = db.query(Income).filter(Income.id == real_id, Income.user_id == current_user.id).first()
        if not item:
            raise HTTPException(status_code=404, detail="Transaksi tidak ditemukan")
        return {
            "success": True,
            "data": {
                "id": f"inc-{item.id}",
                "type": "income",
                "amount": float(item.amount),
                "description": item.description,
                "category": item.category.name if item.category else "-",
                "category_id": item.category_id,
                "wallet_id": item.wallet_id,
                "wallet_name": item.wallet.name if item.wallet else "Dompet",
                "date": item.date.isoformat() if item.date else None,
                "status": item.status,
                "created_at": item.created_at.isoformat() if item.created_at else None
            }
        }
    else:
        item = db.query(Expense).filter(Expense.id == real_id, Expense.user_id == current_user.id).first()
        if not item:
            raise HTTPException(status_code=404, detail="Transaksi tidak ditemukan")
        return {
            "success": True,
            "data": {
                "id": f"exp-{item.id}",
                "type": "expense",
                "amount": float(item.amount),
                "description": item.description,
                "category": item.category.name if item.category else "-",
                "category_id": item.category_id,
                "wallet_id": item.wallet_id,
                "wallet_name": item.wallet.name if item.wallet else "Dompet",
                "date": item.date.isoformat() if item.date else None,
                "status": item.status,
                "created_at": item.created_at.isoformat() if item.created_at else None
            }
        }

@router.put("/{id}")
def update_transaction(
    id: str,
    req: TransactionUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    t_type, real_id = parse_tx_id(id)

    if t_type == "income":
        item = db.query(Income).filter(Income.id == real_id, Income.user_id == current_user.id).first()
    else:
        item = db.query(Expense).filter(Expense.id == real_id, Expense.user_id == current_user.id).first()
    
    if not item:
        raise HTTPException(status_code=404, detail="Transaksi tidak ditemukan")
    
    if req.wallet_id is not None:
        wallet = db.query(Wallet).filter(Wallet.id == req.wallet_id, Wallet.user_id == current_user.id).first()
        if not wallet:
            raise HTTPException(status_code=404, detail="Dompet tidak ditemukan atau bukan milik Anda")
        item.wallet_id = req.wallet_id

    if req.category_id is not None:
        category = db.query(Category).filter(Category.id == req.category_id).first()
        if not category:
            raise HTTPException(status_code=404, detail="Kategori tidak ditemukan")
        item.category_id = req.category_id

    if req.amount is not None:
        if req.amount <= 0:
            raise HTTPException(status_code=422, detail="Jumlah transaksi harus lebih dari 0")
        item.amount = req.amount
    if req.description is not None:
        item.description = req.description
    if req.date is not None:
        item.date = req.date
    if req.source is not None:
        item.source = req.source

    db.commit()
    db.refresh(item)

    return {
        "success": True,
        "message": "Transaksi berhasil diperbarui",
        "data": {
            "id": id,
            "amount": float(item.amount),
            "description": item.description,
            "date": item.date.isoformat() if item.date else None
        }
    }

@router.delete("/{id}")
def delete_transaction(
    id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    t_type, real_id = parse_tx_id(id)

    item = None
    if t_type == "income":
        item = db.query(Income).filter(Income.id == real_id, Income.user_id == current_user.id).first()
    elif t_type == "expense":
        item = db.query(Expense).filter(Expense.id == real_id, Expense.user_id == current_user.id).first()
    else:
        item = db.query(Income).filter(Income.id == real_id, Income.user_id == current_user.id).first()
        if not item:
            item = db.query(Expense).filter(Expense.id == real_id, Expense.user_id == current_user.id).first()

    if not item:
        raise HTTPException(status_code=404, detail="Transaksi tidak ditemukan")
    
    db.delete(item)
    db.commit()

    return {
        "success": True,
        "message": "Transaksi berhasil dihapus"
    }
