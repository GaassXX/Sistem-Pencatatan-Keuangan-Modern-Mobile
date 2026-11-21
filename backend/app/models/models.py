from datetime import datetime
from sqlalchemy import (
    Column, Integer, String, Boolean, Numeric, DateTime, Date, 
    Text, ForeignKey, func
)
from sqlalchemy.orm import relationship
from app.core.database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    name = Column(String(255), nullable=False)
    email = Column(String(255), unique=True, index=True, nullable=False)
    password = Column(String(255), nullable=False)
    role = Column(String(50), default="personal") # personal, parent, child, admin, super_admin
    parent_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    is_active = Column(Boolean, default=True)
    is_independent = Column(Boolean, default=True)
    avatar_url = Column(String(255), nullable=True)
    telegram_chat_id = Column(String(100), nullable=True)
    telegram_pair_code = Column(String(50), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    wallets = relationship("Wallet", back_populates="user", cascade="all, delete-orphan")
    incomes = relationship("Income", back_populates="user", foreign_keys="Income.user_id")
    expenses = relationship("Expense", back_populates="user", foreign_keys="Expense.user_id")
    debts = relationship("Debt", back_populates="user")
    savings = relationship("Saving", back_populates="user")
    budgets = relationship("Budget", back_populates="user")


class Wallet(Base):
    __tablename__ = "wallets"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    name = Column(String(100), nullable=False)
    type = Column(String(50), default="cash") # cash, bank, emoney, other
    initial_balance = Column(Numeric(15, 2), default=0.0)
    color = Column(String(30), default="#10B981")
    icon = Column(String(50), default="cash")
    is_archived = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    user = relationship("User", back_populates="wallets")
    incomes = relationship("Income", back_populates="wallet")
    expenses = relationship("Expense", back_populates="wallet")


class WalletTransfer(Base):
    __tablename__ = "wallet_transfers"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    from_wallet_id = Column(Integer, ForeignKey("wallets.id"), nullable=False)
    to_wallet_id = Column(Integer, ForeignKey("wallets.id"), nullable=False)
    amount = Column(Numeric(15, 2), nullable=False)
    notes = Column(Text, nullable=True)
    date = Column(Date, default=func.current_date())
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class Category(Base):
    __tablename__ = "categories"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    name = Column(String(100), nullable=False)
    type = Column(String(50), default="expense") # income, expense
    icon = Column(String(50), nullable=True)
    color = Column(String(30), nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class Income(Base):
    __tablename__ = "incomes"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    category_id = Column(Integer, ForeignKey("categories.id"), nullable=True)
    wallet_id = Column(Integer, ForeignKey("wallets.id"), nullable=True)
    debt_id = Column(Integer, ForeignKey("debts.id"), nullable=True)
    amount = Column(Numeric(15, 2), nullable=False)
    source = Column(String(50), default="cash")
    description = Column(Text, nullable=True)
    date = Column(Date, default=func.current_date())
    status = Column(String(50), default="approved") # approved, pending, rejected
    approved_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    user = relationship("User", foreign_keys=[user_id], back_populates="incomes")
    category = relationship("Category")
    wallet = relationship("Wallet", back_populates="incomes")
    debt = relationship("Debt", back_populates="incomes")


class Expense(Base):
    __tablename__ = "expenses"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    category_id = Column(Integer, ForeignKey("categories.id"), nullable=True)
    wallet_id = Column(Integer, ForeignKey("wallets.id"), nullable=True)
    debt_id = Column(Integer, ForeignKey("debts.id"), nullable=True)
    amount = Column(Numeric(15, 2), nullable=False)
    source = Column(String(50), default="cash")
    description = Column(Text, nullable=True)
    date = Column(Date, default=func.current_date())
    status = Column(String(50), default="approved") # approved, pending, rejected
    approved_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    user = relationship("User", foreign_keys=[user_id], back_populates="expenses")
    category = relationship("Category")
    wallet = relationship("Wallet", back_populates="expenses")
    debt = relationship("Debt", back_populates="expenses")


class Debt(Base):
    __tablename__ = "debts"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    type = Column(String(50), default="debt") # debt (utang), receivable (piutang)
    person_name = Column(String(255), nullable=False)
    amount = Column(Numeric(15, 2), nullable=False)
    due_date = Column(Date, nullable=True)
    date = Column(Date, default=func.current_date())
    description = Column(Text, nullable=True)
    status = Column(String(50), default="unpaid") # unpaid, paid
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    user = relationship("User", back_populates="debts")
    incomes = relationship("Income", back_populates="debt")
    expenses = relationship("Expense", back_populates="debt")


class Saving(Base):
    __tablename__ = "savings"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    name = Column(String(255), nullable=False)
    category = Column(String(255), nullable=True)
    target_amount = Column(Numeric(15, 2), nullable=False)
    current_amount = Column(Numeric(15, 2), default=0.0)
    target_date = Column(Date, nullable=True)
    description = Column(Text, nullable=True)
    status = Column(String(50), default="active") # active, completed, cancelled
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    user = relationship("User", back_populates="savings")
    deposits = relationship("SavingDeposit", back_populates="saving", cascade="all, delete-orphan")


class SavingDeposit(Base):
    __tablename__ = "saving_deposits"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    saving_id = Column(Integer, ForeignKey("savings.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    wallet_id = Column(Integer, ForeignKey("wallets.id"), nullable=True)
    amount = Column(Numeric(15, 2), nullable=False)
    date = Column(Date, default=func.current_date())
    note = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    saving = relationship("Saving", back_populates="deposits")


class Budget(Base):
    __tablename__ = "budgets"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    category_id = Column(Integer, ForeignKey("categories.id"), nullable=False)
    limit_amount = Column(Numeric(15, 2), nullable=False)
    period = Column(String(50), default="monthly") # monthly, weekly
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    user = relationship("User", back_populates="budgets")
    category = relationship("Category")
