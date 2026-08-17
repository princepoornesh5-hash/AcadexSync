from typing import List, Optional
import httpx
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from app.core.config import settings
from app.core.database import get_db
from app.models.domain import TimetableEntry, UserRole, User, Section, Course
from app.schemas.dto import TimetableEntryCreate, TimetableEntryResponse
from app.api.deps import require_roles, get_current_user

router = APIRouter(prefix="/timetable", tags=["Timetable & Scheduling"])


@router.get("/entries", response_model=List[TimetableEntryResponse])
async def list_timetable(
    section_id: Optional[int] = None,
    faculty_id: Optional[int] = None,
    db: AsyncSession = Depends(get_db)
):
    stmt = select(TimetableEntry)
    if section_id:
        stmt = stmt.where(TimetableEntry.section_id == section_id)
    if faculty_id:
        stmt = stmt.where(TimetableEntry.faculty_id == faculty_id)
    res = await db.execute(stmt)
    return res.scalars().all()


@router.post("/entries", response_model=TimetableEntryResponse, status_code=status.HTTP_201_CREATED)
async def create_timetable_entry(
    entry_in: TimetableEntryCreate,
    db: AsyncSession = Depends(get_db),
    _user=Depends(require_roles([UserRole.ADMIN, UserRole.SUPER_ADMIN]))
):
    entry = TimetableEntry(**entry_in.model_dump())
    db.add(entry)
    await db.commit()
    await db.refresh(entry)
    return entry


@router.post("/generate-ai")
async def trigger_ai_timetable_generation(
    section_id: int,
    db: AsyncSession = Depends(get_db),
    _user=Depends(require_roles([UserRole.ADMIN, UserRole.SUPER_ADMIN]))
):
    """Bridge endpoint calling Python AI Service constraint solver to build timetable"""
    # Fetch active courses
    courses_stmt = select(Course)
    courses = (await db.execute(courses_stmt)).scalars().all()
    course_names = [c.title for c in courses] or ["Data Structures", "Database Systems", "Operating Systems"]

    payload = {
        "courses": course_names,
        "rooms": ["Lab 101", "Room 202", "Auditorium B"],
        "professors": ["Prof. Smith", "Prof. Johnson", "Prof. Davis"]
    }

    try:
        async with httpx.AsyncClient() as client:
            resp = await client.post(f"{settings.AI_SERVICE_URL}/api/v1/ai/generate-timetable", json=payload, timeout=10.0)
            if resp.status_code == 200:
                ai_schedule = resp.json()
                return {
                    "section_id": section_id,
                    "status": "Generated via AI Microservice",
                    "schedule": ai_schedule.get("schedule", [])
                }
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Failed to communicate with AI Service: {str(e)}")
