from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from app.core.database import get_db
from app.models.domain import Exam, GradeRecord, UserRole, User, StudentProfile, Course, GradeLetter
from app.schemas.dto import ExamCreate, ExamResponse, BulkGradeEntryRequest, TranscriptResponse
from app.api.deps import require_roles, get_current_user

router = APIRouter(prefix="/exams", tags=["Exams & Grading Engine"])

GRADE_POINT_MAP = {
    GradeLetter.O: 10.0,
    GradeLetter.A_PLUS: 9.0,
    GradeLetter.A: 8.0,
    GradeLetter.B_PLUS: 7.0,
    GradeLetter.B: 6.0,
    GradeLetter.C: 5.0,
    GradeLetter.F: 0.0,
}


@router.get("", response_model=List[ExamResponse])
async def list_exams(course_id: Optional[int] = None, db: AsyncSession = Depends(get_db)):
    stmt = select(Exam)
    if course_id:
        stmt = stmt.where(Exam.course_id == course_id)
    res = await db.execute(stmt)
    return res.scalars().all()


@router.post("", response_model=ExamResponse, status_code=status.HTTP_201_CREATED)
async def create_exam(
    exam_in: ExamCreate,
    db: AsyncSession = Depends(get_db),
    _user=Depends(require_roles([UserRole.ADMIN, UserRole.SUPER_ADMIN, UserRole.FACULTY]))
):
    exam = Exam(**exam_in.model_dump())
    db.add(exam)
    await db.commit()
    await db.refresh(exam)
    return exam


@router.post("/gradebook/bulk-enter", status_code=status.HTTP_201_CREATED)
async def bulk_enter_grades(
    req: BulkGradeEntryRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_roles([UserRole.FACULTY, UserRole.ADMIN, UserRole.SUPER_ADMIN]))
):
    """Faculty submits exam marks and grades for a class. Auto-recalculates student CGPA."""
    stmt = select(Exam).where(Exam.id == req.exam_id)
    exam = (await db.execute(stmt)).scalar_one_or_none()
    if not exam:
        raise HTTPException(status_code=404, detail="Exam not found")

    entered_count = 0
    for g in req.grades:
        pts = GRADE_POINT_MAP.get(g.grade, 8.0)

        # Check existing grade record
        stmt = select(GradeRecord).where(
            GradeRecord.exam_id == req.exam_id,
            GradeRecord.student_id == g.student_id
        )
        existing = (await db.execute(stmt)).scalar_one_or_none()
        if existing:
            existing.marks_obtained = g.marks_obtained
            existing.grade = g.grade
            existing.grade_points = pts
            existing.recorded_by_id = current_user.id
            db.add(existing)
        else:
            rec = GradeRecord(
                exam_id=req.exam_id,
                student_id=g.student_id,
                marks_obtained=g.marks_obtained,
                grade=g.grade,
                grade_points=pts,
                recorded_by_id=current_user.id
            )
            db.add(rec)
        entered_count += 1

        # Auto-update student CGPA
        await _recalculate_student_cgpa(g.student_id, db)

    await db.commit()
    return {"message": f"Recorded grades for {entered_count} students successfully"}


@router.get("/transcript/{student_id}", response_model=TranscriptResponse)
async def get_student_transcript(
    student_id: int,
    db: AsyncSession = Depends(get_db)
):
    """Generates official transcript with GPA and CGPA calculations"""
    stmt = select(User).where(User.id == student_id)
    user = (await db.execute(stmt)).scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="Student not found")

    stmt = select(StudentProfile).where(StudentProfile.user_id == student_id)
    prof = (await db.execute(stmt)).scalar_one_or_none()
    roll = prof.roll_number if prof else "STU-0000"

    # Fetch all grade records
    stmt = select(GradeRecord).where(GradeRecord.student_id == student_id)
    records = (await db.execute(stmt)).scalars().all()

    total_pts = sum(r.grade_points * 3.0 for r in records) # Assuming 3 credits default
    total_credits = len(records) * 3
    computed_cgpa = (total_pts / total_credits) if total_credits > 0 else 0.0

    grade_details = []
    for r in records:
        grade_details.append({
            "exam_id": r.exam_id,
            "marks_obtained": r.marks_obtained,
            "grade": r.grade.value,
            "grade_points": r.grade_points
        })

    return TranscriptResponse(
        student_id=student_id,
        student_name=user.full_name,
        roll_number=roll,
        cgpa=round(computed_cgpa, 2),
        total_credits=total_credits,
        grades=grade_details
    )


async def _recalculate_student_cgpa(student_id: int, db: AsyncSession):
    stmt = select(GradeRecord).where(GradeRecord.student_id == student_id)
    records = (await db.execute(stmt)).scalars().all()
    if not records:
        return

    total_pts = sum(r.grade_points for r in records)
    cgpa = round(total_pts / len(records), 2)

    stmt = select(StudentProfile).where(StudentProfile.user_id == student_id)
    prof = (await db.execute(stmt)).scalar_one_or_none()
    if prof:
        prof.cgpa = cgpa
        db.add(prof)
