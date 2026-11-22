from datetime import date, datetime
from typing import Any, Dict, List, Literal, Optional
from pydantic import BaseModel, Field

# ----------------- Base Response -----------------
class ApiResponse(BaseModel):
    success: bool = True
    message: Optional[str] = None
    data: Optional[Any] = None


# ----------------- Auth -----------------
class LoginRequest(BaseModel):
    email: str
    password: str

class RegisterRequest(BaseModel):
    name: str
    email: str
    password: str
    password_confirmation: Optional[str] = None
    account_type: str = "independent" # parent, child, independent

class ProfileUpdateRequest(BaseModel):
    name: Optional[str] = None
    email: Optional[str] = None
    current_password: Optional[str] = None
    new_password: Optional[str] = None
    new_password_confirmation: Optional[str] = None

class UserOut(BaseModel):
    id: int
    name: str
    email: str
    role: str
    is_active: bool
    is_independent: bool
    parent_id: Optional[int] = None
    avatar_url: Optional[str] = None
    telegram_chat_id: Optional[str] = None
    telegram_pair_code: Optional[str] = None
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# ----------------- Wallets -----------------
class WalletCreate(BaseModel):
    name: str
    type: Literal["cash", "bank", "emoney", "other"] = "cash"
    initial_balance: Optional[float] = 0.0
    color: Optional[str] = "#10B981"
    icon: Optional[str] = "cash"

class WalletUpdate(BaseModel):
    name: Optional[str] = None
    type: Optional[Literal["cash", "bank", "emoney", "other"]] = None
    initial_balance: Optional[float] = None
    color: Optional[str] = None
    icon: Optional[str] = None

class WalletTransferRequest(BaseModel):
    from_wallet_id: int
    to_wallet_id: int
    amount: float
    admin_fee: Optional[float] = 0.0
    allow_negative: Optional[bool] = False
    notes: Optional[str] = None
    date: Optional[date] = None

class WalletAdjustRequest(BaseModel):
    new_balance: float
    notes: Optional[str] = None

class WalletArchiveRequest(BaseModel):
    transfer_to_wallet_id: Optional[int] = None


# ----------------- Transactions -----------------
class TransactionCreate(BaseModel):
    type: str # income, expense
    amount: float
    category_id: Optional[int] = None
    wallet_id: Optional[int] = None
    source: Optional[str] = "cash"
    date: Optional[date] = None
    description: Optional[str] = None
    debt_id: Optional[int] = None

class TransactionUpdate(BaseModel):
    type: Optional[str] = None
    amount: Optional[float] = None
    category_id: Optional[int] = None
    wallet_id: Optional[int] = None
    source: Optional[str] = None
    date: Optional[date] = None
    description: Optional[str] = None


# ----------------- Debts -----------------
class DebtCreate(BaseModel):
    type: str # debt (utang), receivable (piutang)
    person_name: str
    amount: float
    due_date: Optional[date] = None
    description: Optional[str] = None
    wallet_id: Optional[int] = None

class DebtUpdate(BaseModel):
    type: Optional[str] = None
    person_name: Optional[str] = None
    amount: Optional[float] = None
    due_date: Optional[date] = None
    description: Optional[str] = None
    status: Optional[str] = None

class DebtPayRequest(BaseModel):
    amount: float
    wallet_id: Optional[int] = None
    date: Optional[date] = None
    note: Optional[str] = None


# ----------------- Savings -----------------
class SavingCreate(BaseModel):
    name: str
    category: Optional[str] = None
    target_amount: float
    target_date: Optional[date] = None
    description: Optional[str] = None

class SavingUpdate(BaseModel):
    name: Optional[str] = None
    category: Optional[str] = None
    target_amount: Optional[float] = None
    target_date: Optional[date] = None
    description: Optional[str] = None
    status: Optional[str] = None

class SavingDepositCreate(BaseModel):
    amount: float
    wallet_id: Optional[int] = None
    date: Optional[date] = None
    note: Optional[str] = None


# ----------------- Budgets -----------------
class BudgetCreate(BaseModel):
    category_id: int
    limit_amount: float
    period: Optional[str] = "monthly"


# ----------------- ChatBot -----------------
class ChatBotRequest(BaseModel):
    message: str
