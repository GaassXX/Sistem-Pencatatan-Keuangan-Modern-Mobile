import pytest
import time
from datetime import date
from fastapi.testclient import TestClient
from app.main import app
from app.core.database import Base, engine, SessionLocal
from app.models.models import User, Wallet, Category, Debt, Saving

client = TestClient(app)
TEST_EMAIL = f"test_{time.time_ns()}@example.com"
TEST_PASSWORD = "Password123!"

@pytest.fixture(scope="module", autouse=True)
def setup_test_db():
    Base.metadata.create_all(bind=engine)
    if engine.dialect.name == "sqlite":
        from sqlalchemy import text
        with engine.connect() as conn:
            try:
                conn.execute(text("ALTER TABLE categories ADD COLUMN is_neutral BOOLEAN DEFAULT 0"))
                conn.commit()
            except Exception:
                pass
    yield

def test_01_register_returns_201():
    payload = {
        "name": "User Pengujian",
        "email": TEST_EMAIL,
        "password": TEST_PASSWORD,
        "password_confirmation": TEST_PASSWORD,
        "account_type": "independent"
    }
    res = client.post("/api/auth/register", json=payload)
    # Harus 201 Created sesuai kontrak Flutter
    assert res.status_code == 201
    data = res.json()
    assert data["success"] is True
    assert "token" in data["data"]
    assert data["data"]["user"]["email"] == TEST_EMAIL

def test_02_login_and_auth():
    # Login dengan user pengujian
    res = client.post("/api/auth/login", json={
        "email": TEST_EMAIL,
        "password": TEST_PASSWORD
    })
    assert res.status_code == 200
    token = res.json()["data"]["token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Cek profile me
    me_res = client.get("/api/auth/me", headers=headers)
    assert me_res.status_code == 200
    assert me_res.json()["data"]["email"] == TEST_EMAIL

def test_03_create_wallet_returns_201():
    # Login
    login_res = client.post("/api/auth/login", json={
        "email": TEST_EMAIL,
        "password": TEST_PASSWORD
    })
    token = login_res.json()["data"]["token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Buat dompet bank baru
    res = client.post("/api/wallets", headers=headers, json={
        "name": "BCA Utama",
        "type": "bank",
        "initial_balance": 500000.0,
        "color": "#3B82F6",
        "icon": "account_balance"
    })
    # Kontrak Flutter: harus 201 Created
    assert res.status_code == 201
    assert res.json()["success"] is True
    assert res.json()["data"]["name"] == "BCA Utama"

def test_04_create_transaction_returns_201_and_checks_category():
    login_res = client.post("/api/auth/login", json={
        "email": TEST_EMAIL,
        "password": TEST_PASSWORD
    })
    token = login_res.json()["data"]["token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Ambil dompet & kategori
    wallets = client.get("/api/wallets", headers=headers).json()["data"]["wallets"]
    w_id = wallets[0]["id"]

    categories = client.get("/api/categories", headers=headers).json()["data"]
    exp_cat = next(c for c in categories if c["type"] == "expense" and not c.get("is_neutral"))
    inc_cat = next(c for c in categories if c["type"] == "income" and not c.get("is_neutral"))

    # Transaksi Pengeluaran Valid -> Harus 201 Created
    res = client.post("/api/transactions", headers=headers, json={
        "type": "expense",
        "amount": 25000.0,
        "category_id": exp_cat["id"],
        "wallet_id": w_id,
        "description": "Makan siang"
    })
    assert res.status_code == 201
    assert res.json()["success"] is True

    # Transaksi Salah Kategori (Expense tapi pakai kategori Income) -> Harus 422
    invalid_res = client.post("/api/transactions", headers=headers, json={
        "type": "expense",
        "amount": 25000.0,
        "category_id": inc_cat["id"],
        "wallet_id": w_id,
        "description": "Makan siang salah kategori"
    })
    assert invalid_res.status_code == 422
    assert "tidak cocok" in invalid_res.json()["message"]

def test_05_transfer_wallet_and_negative_balance_support():
    login_res = client.post("/api/auth/login", json={
        "email": TEST_EMAIL,
        "password": TEST_PASSWORD
    })
    token = login_res.json()["data"]["token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Buat dompet tujuan
    w2 = client.post("/api/wallets", headers=headers, json={
        "name": "Dompet E-Wallet",
        "type": "emoney",
        "initial_balance": 10000.0
    }).json()["data"]

    wallets = client.get("/api/wallets", headers=headers).json()["data"]["wallets"]
    # Pilih dompet asal yang memiliki saldo cukup (BCA Utama dari test_03)
    w1 = next(w for w in wallets if w["current_balance"] >= 100000.0)

    # Transfer sukses saldo cukup -> Harus 201
    tx_res = client.post("/api/wallets/transfer", headers=headers, json={
        "from_wallet_id": w1["id"],
        "to_wallet_id": w2["id"],
        "amount": 50000.0,
        "admin_fee": 2500.0,
        "notes": "Topup e-wallet"
    })
    assert tx_res.status_code == 201
    assert tx_res.json()["success"] is True

    # Transfer melebihi saldo tanpa allow_negative -> Harus 422
    fail_res = client.post("/api/wallets/transfer", headers=headers, json={
        "from_wallet_id": w1["id"],
        "to_wallet_id": w2["id"],
        "amount": 99999999.0,
        "allow_negative": False
    })
    assert fail_res.status_code == 422
    assert "Saldo tidak cukup" in fail_res.json()["message"]

    # Transfer melebihi saldo dengan allow_negative=True -> Harus 201 dengan peringatan
    neg_res = client.post("/api/wallets/transfer", headers=headers, json={
        "from_wallet_id": w1["id"],
        "to_wallet_id": w2["id"],
        "amount": 99999999.0,
        "allow_negative": True
    })
    assert neg_res.status_code == 201
    assert "warning" in neg_res.json()["data"]

def test_06_debt_locking_and_overpayment_prevention():
    login_res = client.post("/api/auth/login", json={
        "email": TEST_EMAIL,
        "password": TEST_PASSWORD
    })
    token = login_res.json()["data"]["token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Buat utang baru -> Harus 201
    debt_res = client.post("/api/debts", headers=headers, json={
        "type": "debt",
        "person_name": "Budi Santoso",
        "amount": 100000.0,
        "description": "Pinjaman buku"
    })
    assert debt_res.status_code == 201
    debt_id = debt_res.json()["data"]["id"]

    # Bayar melebihi sisa (bayar 150.000 dari utang 100.000) -> Harus 422
    over_res = client.post(f"/api/debts/{debt_id}/pay", headers=headers, json={
        "amount": 150000.0
    })
    assert over_res.status_code == 422
    assert "melebihi sisa" in over_res.json()["message"]

    # Bayar pas 100.000 -> Harus 201 dan status otomatis 'paid'
    pay_res = client.post(f"/api/debts/{debt_id}/pay", headers=headers, json={
        "amount": 100000.0
    })
    assert pay_res.status_code == 201
    assert pay_res.json()["data"]["status"] == "paid"

    # Bayar lagi setelah lunas -> Harus ditolak 422
    again_res = client.post(f"/api/debts/{debt_id}/pay", headers=headers, json={
        "amount": 10000.0
    })
    assert again_res.status_code == 422
    assert "sudah lunas" in again_res.json()["message"]

def test_07_savings_locking_and_limit():
    login_res = client.post("/api/auth/login", json={
        "email": TEST_EMAIL,
        "password": TEST_PASSWORD
    })
    token = login_res.json()["data"]["token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Buat target tabungan -> Harus 201
    sav_res = client.post("/api/savings", headers=headers, json={
        "name": "Beli Laptop",
        "target_amount": 200000.0,
        "category": "Elektronik"
    })
    assert sav_res.status_code == 201
    sav_id = sav_res.json()["data"]["id"]

    # Setor melebihi target -> Harus ditolak 422
    over_dep = client.post(f"/api/savings/{sav_id}/deposits", headers=headers, json={
        "amount": 300000.0
    })
    assert over_dep.status_code == 422
    assert "melebihi sisa target" in over_dep.json()["message"]

    # Setor pas 200.000 -> Harus 201 dan status otomatis 'completed'
    dep_res = client.post(f"/api/savings/{sav_id}/deposits", headers=headers, json={
        "amount": 200000.0
    })
    assert dep_res.status_code == 201
    assert dep_res.json()["data"]["saving"]["status"] == "completed"

    # Setor lagi setelah selesai -> Harus ditolak 422
    again_dep = client.post(f"/api/savings/{sav_id}/deposits", headers=headers, json={
        "amount": 50000.0
    })
    assert again_dep.status_code == 422
    assert "sudah tercapai" in again_dep.json()["message"]

def test_08_wallet_archive_with_balance_transfer():
    login_res = client.post("/api/auth/login", json={
        "email": TEST_EMAIL,
        "password": TEST_PASSWORD
    })
    token = login_res.json()["data"]["token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Buat dompet yang mau diarsip dengan saldo
    old_w = client.post("/api/wallets", headers=headers, json={
        "name": "Dompet Lama Mau Tutup",
        "type": "cash",
        "initial_balance": 75000.0
    }).json()["data"]

    # Buat dompet penampung
    target_w = client.post("/api/wallets", headers=headers, json={
        "name": "Dompet Penampung",
        "type": "bank",
        "initial_balance": 0.0
    }).json()["data"]

    # Arsip dompet lama dengan transfer_to_wallet_id
    arch_res = client.post(f"/api/wallets/{old_w['id']}/archive", headers=headers, json={
        "transfer_to_wallet_id": target_w["id"]
    })
    assert arch_res.status_code == 200
    assert arch_res.json()["data"]["is_archived"] is True

    # Cek saldo dompet lama harusnya sudah 0, dompet baru bertambah 75.000
    old_detail = client.get(f"/api/wallets/{old_w['id']}", headers=headers).json()["data"]
    target_detail = client.get(f"/api/wallets/{target_w['id']}", headers=headers).json()["data"]
    assert old_detail["current_balance"] == 0.0
    assert target_detail["current_balance"] == 75000.0

