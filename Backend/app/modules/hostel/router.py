from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from app.core.database import get_db
from app.models.domain import GatePass, GatePassStatus, UserRole, User
from app.schemas.dto import GatePassCreate, GatePassResponse
from app.api.deps import require_roles, get_current_user

router = APIRouter(prefix="/hostel", tags=["Hostel & Gate Pass Management"])


@router.post("/gate-passes", response_model=GatePassResponse, status_code=status.HTTP_201_CREATED)
async def submit_gate_pass(
    req: GatePassCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    gp = GatePass(
        student_id=current_user.id,
        reason=req.reason,
        out_time=req.out_time,
        expected_in_time=req.expected_in_time,
        status=GatePassStatus.PENDING
    )
    db.add(gp)
    await db.commit()
    await db.refresh(gp)
    return gp


@router.get("/gate-passes", response_model=List[GatePassResponse])
async def list_gate_passes(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    stmt = select(GatePass)
    if current_user.role == UserRole.STUDENT:
        stmt = stmt.where(GatePass.student_id == current_user.id)
    res = await db.execute(stmt)
    return res.scalars().all()


@router.put("/gate-passes/{pass_id}/approve", response_model=GatePassResponse)
async def approve_gate_pass(
    pass_id: int,
    approve: bool = True,
    current_user: User = Depends(require_roles([UserRole.ADMIN, UserRole.SUPER_ADMIN, UserRole.STAFF])),
    db: AsyncSession = Depends(get_db)
):
    stmt = select(GatePass).where(GatePass.id == pass_id)
    gp = (await db.execute(stmt)).scalar_one_or_none()
    if not gp:
        raise HTTPException(status_code=404, detail="Gate pass not found")

    gp.status = GatePassStatus.APPROVED if approve else GatePassStatus.REJECTED
    gp.approved_by_id = current_user.id
    db.add(gp)
    await db.commit()
    await db.refresh(gp)
    return gp
