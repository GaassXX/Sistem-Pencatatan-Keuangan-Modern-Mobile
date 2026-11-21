import re
from datetime import date
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.security import get_current_user
from app.models.models import Income, Expense, Category, Wallet, User
from app.schemas.schemas import ChatBotRequest

router = APIRouter(prefix="/api/chat-bot", tags=["AI ChatBot"])

def extract_amount(text: str) -> float:
    # 50k, 50rb, 20.000, 20000
    cleaned = text.lower()
    
    # 50k / 50 k / 50rb / 50 rb
    k_match = re.search(r'(\d+(?:[.,]\d+)?)\s*(?:k|rb|ribu)', cleaned)
    if k_match:
        val = float(k_match.group(1).replace(',', '.'))
        return val * 1000

    # 1.5jt / 2jt / 2 juta
    jt_match = re.search(r'(\d+(?:[.,]\d+)?)\s*(?:jt|juta)', cleaned)
    if jt_match:
        val = float(jt_match.group(1).replace(',', '.'))
        return val * 1000000

    # Nominal biasa: Rp 50.000 atau 50000
    num_match = re.search(r'(?:rp\.?\s*)?(\d{1,3}(?:\.\d{3})+|\d+)', cleaned)
    if num_match:
        raw_num = num_match.group(1).replace('.', '')
        return float(raw_num)

    return 0.0

def detect_transaction_type(text: str) -> str:
    cleaned = text.lower()
    income_keywords = ["gaji", "pemasukan", "dapat", "terima", "bonus", "transfer masuk", "untung", "hasil"]
    for kw in income_keywords:
        if kw in cleaned:
            return "income"
    return "expense"

def guess_category(text: str, t_type: str, db: Session) -> Category:
    cleaned = text.lower()
    keywords_map = {
        "Makanan & Minuman": ["makan", "minum", "kopi", "cafe", "resto", "sarapan", "siang", "malam", "bakso", "nasi", "ayam", "snack"],
        "Transportasi": ["bensin", "pertalite", "pertamax", "ojol", "gojek", "grab", "maxim", "parkir", "tol", "angkot", "kereta"],
        "Belanja Bulanan": ["belanja", "supermarket", "indomaret", "alfamart", "sabun", "shampoo", "minyak", "beras"],
        "Tagihan & Utilitas": ["listrik", "pln", "air", "pdam", "wifi", "indihome", "pulsa", "kuota", "token"],
        "Pendidikan & Kuliah": ["kuliah", "spp", "buku", "fotocopy", "tugas", "kursus", "seminar"],
        "Hiburan & Rekreasi": ["nonton", "bioskop", "game", "steam", "wisata", "liburan", "spotify", "netflix"],
        "Kesehatan": ["obat", "apotek", "dokter", "klinik", "rumah sakit", "vitamin"],
        "Gaji & Pendapatan": ["gaji", "payroll", "upah", "honor"],
        "Investasi & Bunga": ["dividen", "reksadana", "saham", "crypto", "bunga"],
        "Bonus & Hadiah": ["hadiah", "angpao", "giveaway", "reward"]
    }

    matched_cat_name = None
    for cat_name, kws in keywords_map.items():
        if any(kw in cleaned for kw in kws):
            matched_cat_name = cat_name
            break

    if matched_cat_name:
        cat = db.query(Category).filter(Category.name.ilike(f"%{matched_cat_name}%")).first()
        if cat:
            return cat

    # Default category fallback
    default_name = "Makanan & Minuman" if t_type == "expense" else "Gaji & Pendapatan"
    cat = db.query(Category).filter(Category.name.ilike(f"%{default_name}%")).first()
    if not cat:
        cat = db.query(Category).first()
    return cat

@router.post("/parse-and-save")
def parse_and_save_chatbot_message(
    req: ChatBotRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    msg = req.message.strip()
    amount = extract_amount(msg)

    if amount <= 0:
        raise HTTPException(
            status_code=422, 
            detail="Tidak dapat mengenali nominal uang pada pesan Anda. Contoh: 'Beli nasi goreng 25000' atau 'Bensin 30rb'"
        )

    t_type = detect_transaction_type(msg)
    category = guess_category(msg, t_type, db)

    # Dapatkan dompet default
    wallet = db.query(Wallet).filter(Wallet.user_id == current_user.id, Wallet.is_archived == False).first()
    if not wallet:
        wallet = Wallet(user_id=current_user.id, name="Uang Tunai", type="cash", initial_balance=0.0)
        db.add(wallet)
        db.commit()
        db.refresh(wallet)

    description = msg
    tx_date = date.today()
    tx_status = "pending" if current_user.parent_id else "approved"

    if t_type == "income":
        item = Income(
            user_id=current_user.id,
            category_id=category.id if category else None,
            wallet_id=wallet.id,
            amount=amount,
            source=wallet.type,
            description=description,
            date=tx_date,
            status=tx_status
        )
        db.add(item)
        db.commit()
        db.refresh(item)
        tx_id = f"inc-{item.id}"
    else:
        item = Expense(
            user_id=current_user.id,
            category_id=category.id if category else None,
            wallet_id=wallet.id,
            amount=amount,
            source=wallet.type,
            description=description,
            date=tx_date,
            status=tx_status
        )
        db.add(item)
        db.commit()
        db.refresh(item)
        tx_id = f"exp-{item.id}"

    type_label = "Pemasukan" if t_type == "income" else "Pengeluaran"
    cat_label = category.name if category else "-"

    return {
        "success": True,
        "message": f"Berhasil mencatat {type_label} sebesar Rp {amount:,.0f} ({cat_label}) via AI ChatBot",
        "data": {
            "id": tx_id,
            "type": t_type,
            "amount": amount,
            "category": cat_label,
            "wallet": wallet.name,
            "description": description,
            "date": tx_date.isoformat()
        }
    }
