from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from app.core.database import get_db
from app.models.domain import User, UserRole, StudentProfile, FacultyProfile
from app.schemas.dto import UserResponse, StudentProfileResponse, FacultyProfileResponse
from app.api.deps import require_roles, get_current_user

router = APIRouter(prefix="/users", tags=["User Directory & Profiles"])


@router.get("/students", response_model=List[UserResponse])
async def list_students(
    department_id: Optional[int] = Query(None),
    db: AsyncSession = Depends(get_db),
    _user=Depends(require_roles([UserRole.ADMIN, UserRole.SUPER_ADMIN, UserRole.FACULTY]))
):
    stmt = select(User).where(User.role == UserRole.STUDENT)
    if department_id:
        stmt = stmt.where(User.department_id == department_id)
    res = await db.execute(stmt)
    return res.scalars().all()


@router.get("/faculty", response_model=List[UserResponse])
async def list_faculty(
    department_id: Optional[int] = Query(None),
    db: AsyncSession = Depends(get_db)
):
    stmt = select(User).where(User.role == UserRole.FACULTY)
    if department_id:
        stmt = stmt.where(User.department_id == department_id)
    res = await db.execute(stmt)
    return res.scalars().all()


@router.get("/student-profile/{user_id}", response_model=StudentProfileResponse)
async def get_student_profile(
    user_id: int,
    db: AsyncSession = Depends(get_db)
):
    stmt = select(StudentProfile).where(StudentProfile.user_id == user_id)
    prof = (await db.execute(stmt)).scalar_one_or_none()
    if not prof:
        raise HTTPException(status_code=404, detail="Student profile not found")
    return prof


@router.get("/faculty-profile/{user_id}", response_model=FacultyProfileResponse)
async def get_faculty_profile(
    user_id: int,
    db: AsyncSession = Depends(get_db)
):
    stmt = select(FacultyProfile).where(FacultyProfile.user_id == user_id)
    prof = (await db.execute(stmt)).scalar_one_or_none()
    if not prof:
        raise HTTPException(status_code=404, detail="Faculty profile not found")
    return prof
