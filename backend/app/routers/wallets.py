from datetime import date
from decimal import Decimal
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.core.database import get_db
from app.core.security import get_current_user
from app.models.models import Wallet, WalletTransfer, Income, Expense, Category, User
from app.schemas.schemas import (
    WalletCreate, WalletUpdate, WalletTransferRequest, WalletAdjustRequest, WalletArchiveRequest
)

router = APIRouter(prefix="/api/wallets", tags=["Wallets"])

def to_utc_iso(dt):
    if not dt:
        return None
    s = dt.isoformat()
    if not s.endswith("Z") and "+" not in s:
        return s + "Z"
    return s

def calculate_wallet_balance(db: Session, wallet: Wallet) -> Decimal:
    inc_sum = db.query(func.coalesce(func.sum(Income.amount), 0))\
        .filter(Income.wallet_id == wallet.id, Income.user_id == wallet.user_id, Income.status == "approved").scalar()
    
    exp_sum = db.query(func.coalesce(func.sum(Expense.amount), 0))\
        .filter(Expense.wallet_id == wallet.id, Expense.user_id == wallet.user_id, Expense.status == "approved").scalar()
    
    tin_sum = db.query(func.coalesce(func.sum(WalletTransfer.amount), 0))\
        .filter(WalletTransfer.to_wallet_id == wallet.id, WalletTransfer.user_id == wallet.user_id).scalar()
    
    tout_sum = db.query(func.coalesce(func.sum(WalletTransfer.amount), 0))\
        .filter(WalletTransfer.from_wallet_id == wallet.id, WalletTransfer.user_id == wallet.user_id).scalar()
    
    initial = Decimal(str(wallet.initial_balance or 0))
    return initial + Decimal(str(inc_sum)) - Decimal(str(exp_sum)) + Decimal(str(tin_sum)) - Decimal(str(tout_sum))

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
    total_balance = Decimal("0.0")

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
            "current_balance": float(bal),
            "color": w.color or "#10B981",
            "icon": w.icon or "cash",
            "is_archived": bool(w.is_archived),
            "created_at": w.created_at.isoformat() if w.created_at else None
        })

    return {
        "success": True,
        "data": {
            "total_balance": float(total_balance),
            "wallets": wallet_list
        }
    }

@router.post("", status_code=status.HTTP_201_CREATED)
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
            "current_balance": float(bal),
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
            "current_balance": float(calculate_wallet_balance(db, wallet))
        }
    }

@router.post("/{id}/archive")
def archive_wallet(
    id: int,
    req: Optional[WalletArchiveRequest] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    wallet = db.query(Wallet).filter(Wallet.id == id, Wallet.user_id == current_user.id).with_for_update().first()
    if not wallet:
        raise HTTPException(status_code=404, detail="Dompet tidak ditemukan")
    
    will_be_archived = not wallet.is_archived
    if will_be_archived and req and req.transfer_to_wallet_id:
        if req.transfer_to_wallet_id == wallet.id:
            raise HTTPException(status_code=422, detail="Dompet tujuan transfer tidak boleh sama dengan dompet yang diarsip")
        
        dest_wallet = db.query(Wallet).filter(
            Wallet.id == req.transfer_to_wallet_id,
            Wallet.user_id == current_user.id,
            Wallet.is_archived == False
        ).with_for_update().first()
        if not dest_wallet:
            raise HTTPException(status_code=404, detail="Dompet tujuan transfer tidak ditemukan atau sudah diarsipkan")
        
        bal = calculate_wallet_balance(db, wallet)
        if bal > 0:
            transfer = WalletTransfer(
                user_id=current_user.id,
                from_wallet_id=wallet.id,
                to_wallet_id=dest_wallet.id,
                amount=float(bal),
                notes=f"Transfer otomatis penutupan dompet {wallet.name}",
                date=date.today()
            )
            db.add(transfer)

    wallet.is_archived = will_be_archived
    db.commit()

    msg = "Dompet berhasil diarsipkan" if wallet.is_archived else "Dompet berhasil dipulihkan"
    return {
        "success": True,
        "message": msg,
        "data": {"is_archived": wallet.is_archived}
    }

@router.post("/transfer", status_code=status.HTTP_201_CREATED)
def transfer_wallet(
    req: WalletTransferRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if req.from_wallet_id == req.to_wallet_id:
        raise HTTPException(status_code=422, detail="Dompet asal dan tujuan tidak boleh sama")
    if req.amount <= 0:
        raise HTTPException(status_code=422, detail="Jumlah transfer harus lebih dari 0")

    # Kunci kedua dompet dengan urutan id terurut untuk mencegah deadlock (with_for_update)
    ordered_ids = sorted([req.from_wallet_id, req.to_wallet_id])
    locked_wallets = db.query(Wallet).filter(
        Wallet.id.in_(ordered_ids),
        Wallet.user_id == current_user.id
    ).with_for_update().all()

    wallet_map = {w.id: w for w in locked_wallets}
    from_w = wallet_map.get(req.from_wallet_id)
    to_w = wallet_map.get(req.to_wallet_id)

    if not from_w or not to_w:
        raise HTTPException(status_code=404, detail="Salah satu dompet tidak ditemukan atau bukan milik Anda")
    
    from_balance = calculate_wallet_balance(db, from_w)
    transfer_amount = Decimal(str(req.amount))
    admin_fee = Decimal(str(req.admin_fee or 0.0))
    total_deduct = transfer_amount + admin_fee

    warning_msg = None
    if from_balance < total_deduct:
        if not req.allow_negative:
            raise HTTPException(
                status_code=422, 
                detail=f"Saldo tidak cukup untuk transfer (Dibutuhkan Rp {float(total_deduct):,.0f}, Saldo saat ini: Rp {float(from_balance):,.0f})"
            )
        else:
            warning_msg = f"Perhatian: Saldo dompet '{from_w.name}' menjadi negatif setelah transfer ini."
    
    transfer = WalletTransfer(
        user_id=current_user.id,
        from_wallet_id=from_w.id,
        to_wallet_id=to_w.id,
        amount=req.amount,
        notes=req.notes,
        date=req.date or date.today()
    )
    db.add(transfer)

    # Catat biaya admin jika ada (kategori pengeluaran sistem)
    if admin_fee > 0:
        admin_cat = db.query(Category).filter(Category.name == "Biaya Admin").first()
        if not admin_cat:
            admin_cat = Category(name="Biaya Admin", type="expense", icon="cash", color="#EF4444")
            db.add(admin_cat)
            db.flush()
        
        fee_expense = Expense(
            user_id=current_user.id,
            category_id=admin_cat.id,
            wallet_id=from_w.id,
            amount=float(admin_fee),
            source=from_w.type,
            description=f"Biaya admin transfer ke {to_w.name}",
            date=req.date or date.today(),
            status="approved"
        )
        db.add(fee_expense)

    db.commit()

    res_data = {
        "from_wallet": from_w.name,
        "to_wallet": to_w.name,
        "amount": req.amount,
        "admin_fee": float(admin_fee),
        "date": transfer.date.isoformat() if transfer.date else None
    }
    if warning_msg:
        res_data["warning"] = warning_msg

    return {
        "success": True,
        "message": "Transfer antar dompet berhasil" if not warning_msg else f"Transfer berhasil. {warning_msg}",
        "data": res_data
    }

@router.post("/{id}/adjust")
def adjust_wallet(
    id: int,
    req: WalletAdjustRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    wallet = db.query(Wallet).filter(
        Wallet.id == id, 
        Wallet.user_id == current_user.id
    ).with_for_update().first()

    if not wallet:
        raise HTTPException(status_code=404, detail="Dompet tidak ditemukan atau bukan milik Anda")
    
    current_bal = calculate_wallet_balance(db, wallet)
    target_bal = Decimal(str(req.new_balance))
    diff = target_bal - current_bal

    # Cari atau buat kategori netral "Penyesuaian Saldo" agar tidak mengotori analitik belanja
    adj_category = db.query(Category).filter(Category.name == "Penyesuaian Saldo").first()
    if not adj_category:
        adj_category = Category(name="Penyesuaian Saldo", type="expense", icon="sync_alt", is_active=True)
        db.add(adj_category)
        db.flush()

    if diff > 0:
        inc = Income(
            user_id=current_user.id,
            category_id=adj_category.id,
            wallet_id=wallet.id,
            amount=float(diff),
            source=wallet.type,
            description=req.notes or "Penyesuaian saldo (Koreksi Tambah)",
            date=date.today(),
            status="approved"
        )
        db.add(inc)
    elif diff < 0:
        exp = Expense(
            user_id=current_user.id,
            category_id=adj_category.id,
            wallet_id=wallet.id,
            amount=float(abs(diff)),
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

    incomes = db.query(Income).filter(Income.wallet_id == id, Income.user_id == current_user.id).all()
    expenses = db.query(Expense).filter(Expense.wallet_id == id, Expense.user_id == current_user.id).all()
    
    # Masukkan riwayat transfer agar mutasi cocok dengan saldo!
    transfers_out = db.query(WalletTransfer).filter(WalletTransfer.from_wallet_id == id, WalletTransfer.user_id == current_user.id).all()
    transfers_in = db.query(WalletTransfer).filter(WalletTransfer.to_wallet_id == id, WalletTransfer.user_id == current_user.id).all()

    txs = []
    for i in incomes:
        txs.append({
            "id": f"inc-{i.id}",
            "type": "income",
            "amount": float(i.amount),
            "description": i.description or "Pemasukan",
            "category": i.category.name if i.category else "-",
            "wallet_name": wallet.name,
            "date": i.date.isoformat() if i.date else None,
            "created_at": to_utc_iso(i.created_at),
            "status": i.status
        })
    for e in expenses:
        txs.append({
            "id": f"exp-{e.id}",
            "type": "expense",
            "amount": float(e.amount),
            "description": e.description or "Pengeluaran",
            "category": e.category.name if e.category else "-",
            "wallet_name": wallet.name,
            "date": e.date.isoformat() if e.date else None,
            "created_at": to_utc_iso(e.created_at),
            "status": e.status
        })
    for to in transfers_out:
        to_wallet = db.query(Wallet).filter(Wallet.id == to.to_wallet_id).first()
        to_name = to_wallet.name if to_wallet else "Dompet Lain"
        txs.append({
            "id": f"trf-out-{to.id}",
            "type": "transfer_out",
            "amount": float(to.amount),
            "description": f"Transfer ke {to_name}" + (f": {to.notes}" if to.notes else ""),
            "category": "Transfer",
            "wallet_name": wallet.name,
            "date": to.date.isoformat() if to.date else None,
            "created_at": to_utc_iso(to.created_at),
            "status": "approved"
        })
    for ti in transfers_in:
        from_wallet = db.query(Wallet).filter(Wallet.id == ti.from_wallet_id).first()
        from_name = from_wallet.name if from_wallet else "Dompet Lain"
        txs.append({
            "id": f"trf-in-{ti.id}",
            "type": "transfer_in",
            "amount": float(ti.amount),
            "description": f"Transfer masuk dari {from_name}" + (f": {ti.notes}" if ti.notes else ""),
            "category": "Transfer",
            "wallet_name": wallet.name,
            "date": ti.date.isoformat() if ti.date else None,
            "created_at": to_utc_iso(ti.created_at),
            "status": "approved"
        })

    txs.sort(key=lambda x: (x.get("date") or "", x.get("created_at") or ""), reverse=True)

    return {
        "success": True,
        "data": {
            "transactions": txs
        }
    }
