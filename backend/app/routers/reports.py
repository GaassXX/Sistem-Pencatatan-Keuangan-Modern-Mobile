import io
import csv
from datetime import date
from typing import Optional
from fastapi import APIRouter, Depends, Query, Response
from sqlalchemy.orm import Session
from sqlalchemy import extract
from app.core.database import get_db
from app.core.security import get_current_user
from app.models.models import Income, Expense, User

router = APIRouter(tags=["Reports"])

def generate_report_content(
    year: int,
    month: Optional[int],
    format: str,
    current_user: User,
    db: Session
) -> Response:
    incomes_q = db.query(Income).filter(Income.user_id == current_user.id, extract('year', Income.date) == year)
    expenses_q = db.query(Expense).filter(Expense.user_id == current_user.id, extract('year', Expense.date) == year)

    if month and month > 0:
        incomes_q = incomes_q.filter(extract('month', Income.date) == month)
        expenses_q = expenses_q.filter(extract('month', Expense.date) == month)

    incomes = incomes_q.all()
    expenses = expenses_q.all()

    # Generate CSV content as simple cross-platform tabular export
    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(["ID", "Jenis", "Tanggal", "Kategori", "Dompet", "Nominal", "Keterangan", "Status"])

    for i in incomes:
        c_name = i.category.name if i.category else "-"
        w_name = i.wallet.name if i.wallet else "-"
        writer.writerow([f"inc-{i.id}", "Pemasukan", i.date, c_name, w_name, float(i.amount), i.description or "", i.status])

    for e in expenses:
        c_name = e.category.name if e.category else "-"
        w_name = e.wallet.name if e.wallet else "-"
        writer.writerow([f"exp-{e.id}", "Pengeluaran", e.date, c_name, w_name, float(e.amount), e.description or "", e.status])

    content = output.getvalue().encode('utf-8')
    ext = "xlsx" if format in ("excel", "xlsx") else "pdf"
    filename = f"Laporan_Keuangan_{month}_{year}.{ext}" if month else f"Laporan_Keuangan_Tahun_{year}.{ext}"

    return Response(
        content=content,
        media_type="application/octet-stream",
        headers={"Content-Disposition": f"attachment; filename={filename}"}
    )

@router.get("/api/reports/export")
def export_reports(
    year: int = Query(..., ge=2000, le=2100),
    month: Optional[int] = Query(None, ge=1, le=12),
    format: str = Query("pdf"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return generate_report_content(year, month, format, current_user, db)

@router.get("/api/auth/reports/export")
def export_reports_auth(
    year: int = Query(..., ge=2000, le=2100),
    month: Optional[int] = Query(None, ge=1, le=12),
    format: str = Query("pdf"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return generate_report_content(year, month, format, current_user, db)
