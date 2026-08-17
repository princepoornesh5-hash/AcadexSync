from datetime import date, timedelta
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from app.core.database import get_db
from app.models.domain import FeeStructure, StudentInvoice, PaymentTransaction, UserRole, User, PaymentStatus
from app.schemas.dto import (
    FeeStructureCreate, FeeStructureResponse,
    InvoiceResponse, PaymentRecordRequest
)
from app.api.deps import require_roles, get_current_user

router = APIRouter(prefix="/finance", tags=["Finance & Fee Management"])


@router.get("/fee-structures", response_model=List[FeeStructureResponse])
async def list_fee_structures(db: AsyncSession = Depends(get_db)):
    stmt = select(FeeStructure)
    res = await db.execute(stmt)
    return res.scalars().all()


@router.post("/fee-structures", response_model=FeeStructureResponse, status_code=status.HTTP_201_CREATED)
async def create_fee_structure(
    fee_in: FeeStructureCreate,
    db: AsyncSession = Depends(get_db),
    _user=Depends(require_roles([UserRole.ADMIN, UserRole.SUPER_ADMIN]))
):
    fee = FeeStructure(**fee_in.model_dump())
    db.add(fee)
    await db.commit()
    await db.refresh(fee)
    return fee


@router.post("/invoices/generate", response_model=InvoiceResponse, status_code=status.HTTP_201_CREATED)
async def generate_invoice_for_student(
    student_id: int,
    fee_structure_id: int,
    db: AsyncSession = Depends(get_db),
    _user=Depends(require_roles([UserRole.ADMIN, UserRole.SUPER_ADMIN]))
):
    stmt = select(FeeStructure).where(FeeStructure.id == fee_structure_id)
    fee_struct = (await db.execute(stmt)).scalar_one_or_none()
    if not fee_struct:
        raise HTTPException(status_code=404, detail="Fee structure not found")

    inv_num = f"INV-2026-{student_id:04d}-{fee_structure_id}"
    due = fee_struct.total_fee

    invoice = StudentInvoice(
        invoice_number=inv_num,
        student_id=student_id,
        fee_structure_id=fee_structure_id,
        amount_due=due,
        amount_paid=0.0,
        status=PaymentStatus.UNPAID,
        due_date=date.today() + timedelta(days=30)
    )
    db.add(invoice)
    await db.commit()
    await db.refresh(invoice)
    return invoice


@router.get("/my-invoices", response_model=List[InvoiceResponse])
async def list_my_invoices(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    stmt = select(StudentInvoice).where(StudentInvoice.student_id == current_user.id)
    res = await db.execute(stmt)
    return res.scalars().all()


@router.post("/payments/record", status_code=status.HTTP_201_CREATED)
async def record_payment(
    req: PaymentRecordRequest,
    db: AsyncSession = Depends(get_db)
):
    stmt = select(StudentInvoice).where(StudentInvoice.id == req.invoice_id)
    invoice = (await db.execute(stmt)).scalar_one_or_none()
    if not invoice:
        raise HTTPException(status_code=404, detail="Invoice not found")

    tx_id = f"TXN-{date.today().strftime('%Y%m%d')}-{invoice.id:04d}"
    tx = PaymentTransaction(
        invoice_id=invoice.id,
        transaction_id=tx_id,
        amount=req.amount,
        payment_method=req.payment_method
    )
    db.add(tx)

    invoice.amount_paid += req.amount
    if invoice.amount_paid >= invoice.amount_due:
        invoice.status = PaymentStatus.PAID
    elif invoice.amount_paid > 0:
        invoice.status = PaymentStatus.PARTIAL

    db.add(invoice)
    await db.commit()
    return {"message": "Payment recorded successfully", "transaction_id": tx_id, "status": invoice.status.value}
