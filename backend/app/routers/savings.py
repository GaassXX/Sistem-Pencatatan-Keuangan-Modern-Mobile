from datetime import date
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.core.database import get_db
from app.core.security import get_current_user
from app.models.models import Saving, SavingDeposit, Wallet, User
from app.schemas.schemas import SavingCreate, SavingUpdate, SavingDepositCreate

router = APIRouter(prefix="/api/savings", tags=["Savings"])

def format_saving(s: Saving) -> dict:
    target = float(s.target_amount or 0.0)
    current = float(s.current_amount or 0.0)
    pct = min(100.0, round((current / target) * 100, 1)) if target > 0 else 0.0
    remaining = max(0.0, target - current)

    return {
        "id": s.id,
        "name": s.name,
        "category": s.category,
        "target_amount": target,
        "current_amount": current,
        "target_date": s.target_date.isoformat() if s.target_date else None,
        "description": s.description,
        "status": s.status,
        "progress_percentage": pct,
        "remaining_amount": remaining,
        "is_completed": current >= target,
        "created_at": s.created_at.isoformat() if s.created_at else None
    }

@router.get("")
def get_savings(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    savings = db.query(Saving).filter(Saving.user_id == current_user.id).order_by(Saving.id.desc()).all()
    return {
        "success": True,
        "data": [format_saving(s) for s in savings]
    }

@router.post("", status_code=status.HTTP_201_CREATED)
def create_saving(
    req: SavingCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if req.target_amount <= 0:
        raise HTTPException(status_code=422, detail="Target tabungan harus lebih dari 0")

    saving = Saving(
        user_id=current_user.id,
        name=req.name,
        category=req.category,
        target_amount=req.target_amount,
        current_amount=0.0,
        target_date=req.target_date,
        description=req.description,
        status="active"
    )
    db.add(saving)
    db.commit()
    db.refresh(saving)

    return {
        "success": True,
        "message": "Tabungan berhasil dibuat",
        "data": format_saving(saving)
    }

@router.get("/{id}")
def get_saving_detail(
    id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    saving = db.query(Saving).filter(Saving.id == id, Saving.user_id == current_user.id).first()
    if not saving:
        raise HTTPException(status_code=404, detail="Tabungan tidak ditemukan")

    deposits = db.query(SavingDeposit).filter(SavingDeposit.saving_id == id).order_by(SavingDeposit.id.desc()).all()
    dep_list = [
        {
            "id": d.id,
            "amount": float(d.amount),
            "date": d.date.isoformat() if d.date else None,
            "note": d.note,
            "created_at": d.created_at.isoformat() if d.created_at else None
        }
        for d in deposits
    ]

    res = format_saving(saving)
    res["deposits"] = dep_list

    return {
        "success": True,
        "data": res
    }

@router.put("/{id}")
def update_saving(
    id: int,
    req: SavingUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    saving = db.query(Saving).filter(Saving.id == id, Saving.user_id == current_user.id).first()
    if not saving:
        raise HTTPException(status_code=404, detail="Tabungan tidak ditemukan")

    if req.name is not None:
        saving.name = req.name
    if req.category is not None:
        saving.category = req.category
    if req.target_amount is not None:
        saving.target_amount = req.target_amount
    if req.target_date is not None:
        saving.target_date = req.target_date
    if req.description is not None:
        saving.description = req.description
    if req.status is not None:
        saving.status = req.status

    db.commit()
    db.refresh(saving)

    return {
        "success": True,
        "message": "Tabungan berhasil diperbarui",
        "data": format_saving(saving)
    }

@router.delete("/{id}")
def delete_saving(
    id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    saving = db.query(Saving).filter(Saving.id == id, Saving.user_id == current_user.id).first()
    if not saving:
        raise HTTPException(status_code=404, detail="Tabungan tidak ditemukan")

    db.delete(saving)
    db.commit()

    return {
        "success": True,
        "message": "Tabungan berhasil dihapus"
    }

@router.get("/{id}/deposits")
def get_saving_deposits(
    id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    saving = db.query(Saving).filter(Saving.id == id, Saving.user_id == current_user.id).first()
    if not saving:
        raise HTTPException(status_code=404, detail="Tabungan tidak ditemukan")

    try:
        deposits = db.query(SavingDeposit).filter(SavingDeposit.saving_id == id).order_by(SavingDeposit.id.desc()).all()
        return {
            "success": True,
            "data": [
                {
                    "id": d.id,
                    "amount": float(d.amount or 0.0),
                    "date": d.date.isoformat() if d.date else None,
                    "note": d.note,
                    "created_at": d.created_at.isoformat() if d.created_at else None
                }
                for d in deposits
            ]
        }
    except Exception as e:
        print(f"[Warning] Failed to fetch saving deposits: {e}")
        return {
            "success": True,
            "data": []
        }

@router.post("/{id}/deposits", status_code=status.HTTP_201_CREATED)
def add_saving_deposit(
    id: int,
    req: SavingDepositCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    saving = db.query(Saving).filter(
        Saving.id == id, Saving.user_id == current_user.id
    ).with_for_update().first()
    if not saving:
        raise HTTPException(status_code=404, detail="Tabungan tidak ditemukan")
    if saving.status == "completed":
        raise HTTPException(status_code=422, detail="Target tabungan ini sudah tercapai (completed)")
    if req.amount <= 0:
        raise HTTPException(status_code=422, detail="Jumlah setoran harus lebih dari 0")

    target_amount = float(saving.target_amount or 0.0)
    current_amount = float(saving.current_amount or 0.0)
    remaining_target = max(0.0, target_amount - current_amount)

    if remaining_target <= 0:
        saving.status = "completed"
        db.commit()
        raise HTTPException(status_code=422, detail="Target tabungan ini sudah tercapai (completed)")

    if req.amount > remaining_target:
        raise HTTPException(
            status_code=422,
            detail=f"Nominal setoran (Rp {req.amount:,.0f}) melebihi sisa target tabungan (Rp {remaining_target:,.0f})"
        )

    # Validasi wallet_id jika diberikan (tanpa membuat Expense — setoran tidak
    # mengurangi saldo kas, hanya mencatat progres tabungan per BRD FR-105)
    if req.wallet_id:
        wallet = db.query(Wallet).filter(
            Wallet.id == req.wallet_id, Wallet.user_id == current_user.id
        ).with_for_update().first()
        if not wallet:
            raise HTTPException(status_code=404, detail="Dompet tidak ditemukan atau bukan milik Anda")
        if wallet.is_archived:
            raise HTTPException(status_code=422, detail=f"Dompet '{wallet.name}' telah diarsipkan")

    dep_date = req.date or date.today()
    deposit = SavingDeposit(
        saving_id=saving.id,
        user_id=current_user.id,
        wallet_id=req.wallet_id,
        amount=req.amount,
        date=dep_date,
        note=req.note
    )
    db.add(deposit)

    # Update current_amount
    new_curr = current_amount + req.amount
    saving.current_amount = new_curr
    if new_curr >= target_amount:
        saving.status = "completed"

    db.commit()
    db.refresh(saving)

    return {
        "success": True,
        "message": "Setoran tabungan berhasil disimpan",
        "data": {
            "deposit_id": deposit.id,
            "saving": format_saving(saving)
        }
    }
