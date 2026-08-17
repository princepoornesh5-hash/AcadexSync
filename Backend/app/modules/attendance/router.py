from datetime import date
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select, func

from app.core.database import get_db
from app.models.domain import AttendanceRecord, LeaveRequest, UserRole, User, LeaveStatus
from app.schemas.dto import (
    AttendanceMarkRequest, BulkAttendanceRequest, AttendanceResponse,
    LeaveRequestCreate, LeaveRequestResponse, LeaveReviewRequest
)
from app.api.deps import require_roles, get_current_user

router = APIRouter(prefix="/attendance", tags=["Attendance Management"])


@router.post("/mark", response_model=AttendanceResponse, status_code=status.HTTP_201_CREATED)
async def mark_attendance(
    req: AttendanceMarkRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_roles([UserRole.FACULTY, UserRole.ADMIN, UserRole.SUPER_ADMIN]))
):
    today = date.today()
    stmt = select(AttendanceRecord).where(
        AttendanceRecord.student_id == req.student_id,
        AttendanceRecord.course_id == req.course_id,
        AttendanceRecord.attendance_date == today
    )
    existing = (await db.execute(stmt)).scalar_one_or_none()
    if existing:
        existing.status = req.status
        existing.marked_by_id = current_user.id
        db.add(existing)
        await db.commit()
        await db.refresh(existing)
        return AttendanceResponse(
            id=existing.id,
            student_id=existing.student_id,
            course_id=existing.course_id,
            attendance_date=str(existing.attendance_date),
            status=existing.status
        )

    record = AttendanceRecord(
        student_id=req.student_id,
        course_id=req.course_id,
        attendance_date=today,
        status=req.status,
        marked_by_id=current_user.id
    )
    db.add(record)
    await db.commit()
    await db.refresh(record)
    return AttendanceResponse(
        id=record.id,
        student_id=record.student_id,
        course_id=record.course_id,
        attendance_date=str(record.attendance_date),
        status=record.status
    )


@router.post("/bulk-mark", status_code=status.HTTP_201_CREATED)
async def bulk_mark_attendance(
    req: BulkAttendanceRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_roles([UserRole.FACULTY, UserRole.ADMIN, UserRole.SUPER_ADMIN]))
):
    """Faculty marks attendance for an entire class section on a given date"""
    marked_count = 0
    for item in req.records:
        stmt = select(AttendanceRecord).where(
            AttendanceRecord.student_id == item.student_id,
            AttendanceRecord.course_id == req.course_id,
            AttendanceRecord.attendance_date == req.attendance_date
        )
        existing = (await db.execute(stmt)).scalar_one_or_none()
        if existing:
            existing.status = item.status
            existing.marked_by_id = current_user.id
            db.add(existing)
        else:
            rec = AttendanceRecord(
                student_id=item.student_id,
                course_id=req.course_id,
                attendance_date=req.attendance_date,
                status=item.status,
                marked_by_id=current_user.id
            )
            db.add(rec)
        marked_count += 1

    await db.commit()
    return {"message": f"Successfully marked attendance for {marked_count} students", "date": str(req.attendance_date)}


@router.get("/my-summary")
async def get_my_attendance_summary(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    stmt = select(AttendanceRecord).where(AttendanceRecord.student_id == current_user.id)
    records = (await db.execute(stmt)).scalars().all()

    total = len(records)
    present = sum(1 for r in records if r.status in ["PRESENT", "EXCUSED"])
    percentage = (present / total * 100.0) if total > 0 else 100.0

    return {
        "student_id": current_user.id,
        "total_classes": total,
        "classes_attended": present,
        "attendance_percentage": round(percentage, 2),
        "is_shortage": percentage < 75.0
    }


# --- Leave Requests ---
@router.post("/leave-requests", response_model=LeaveRequestResponse, status_code=status.HTTP_201_CREATED)
async def submit_leave_request(
    req: LeaveRequestCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    leave = LeaveRequest(
        student_id=current_user.id,
        start_date=req.start_date,
        end_date=req.end_date,
        reason=req.reason,
        status=LeaveStatus.PENDING
    )
    db.add(leave)
    await db.commit()
    await db.refresh(leave)
    return leave


@router.get("/leave-requests", response_model=List[LeaveRequestResponse])
async def list_leave_requests(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    stmt = select(LeaveRequest)
    if current_user.role == UserRole.STUDENT:
        stmt = stmt.where(LeaveRequest.student_id == current_user.id)
    res = await db.execute(stmt)
    return res.scalars().all()


@router.put("/leave-requests/{leave_id}/review", response_model=LeaveRequestResponse)
async def review_leave_request(
    leave_id: int,
    req: LeaveReviewRequest,
    current_user: User = Depends(require_roles([UserRole.FACULTY, UserRole.ADMIN, UserRole.SUPER_ADMIN])),
    db: AsyncSession = Depends(get_db)
):
    stmt = select(LeaveRequest).where(LeaveRequest.id == leave_id)
    leave = (await db.execute(stmt)).scalar_one_or_none()
    if not leave:
        raise HTTPException(status_code=404, detail="Leave request not found")

    leave.status = req.status
    leave.reviewed_by_id = current_user.id
    db.add(leave)
    await db.commit()
    await db.refresh(leave)
    return leave
