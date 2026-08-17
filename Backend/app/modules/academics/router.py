from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from app.core.database import get_db
from app.core.redis import redis_client
from app.models.domain import Department, Program, AcademicSemester, Course, Section, CourseEnrollment, UserRole, User
from app.schemas.dto import (
    DepartmentCreate, DepartmentResponse,
    ProgramCreate, ProgramResponse,
    SemesterCreate, SemesterResponse,
    CourseCreate, CourseResponse,
    SectionCreate, SectionResponse,
    EnrollStudentRequest
)
from app.api.deps import require_roles, get_current_user

router = APIRouter(prefix="/academics", tags=["Academic Management"])


# --- Departments ---
@router.get("/departments", response_model=List[DepartmentResponse])
async def list_departments(db: AsyncSession = Depends(get_db)):
    cached = await redis_client.get_json("cache:departments")
    if cached:
        return cached

    stmt = select(Department)
    res = await db.execute(stmt)
    depts = [DepartmentResponse.model_validate(d).model_dump(mode="json") for d in res.scalars().all()]
    await redis_client.set_json("cache:departments", depts, expire_seconds=600)
    return depts


@router.post("/departments", response_model=DepartmentResponse, status_code=status.HTTP_201_CREATED)
async def create_department(
    dept_in: DepartmentCreate,
    db: AsyncSession = Depends(get_db),
    _user=Depends(require_roles([UserRole.ADMIN, UserRole.SUPER_ADMIN]))
):
    stmt = select(Department).where(Department.code == dept_in.code)
    existing = (await db.execute(stmt)).scalar_one_or_none()
    if existing:
        raise HTTPException(status_code=400, detail="Department code already exists")

    dept = Department(**dept_in.model_dump())
    db.add(dept)
    await db.commit()
    await db.refresh(dept)
    await redis_client.delete("cache:departments")
    return dept


# --- Programs & Semesters ---
@router.get("/programs", response_model=List[ProgramResponse])
async def list_programs(db: AsyncSession = Depends(get_db)):
    stmt = select(Program)
    res = await db.execute(stmt)
    return res.scalars().all()


@router.post("/programs", response_model=ProgramResponse, status_code=status.HTTP_201_CREATED)
async def create_program(
    prog_in: ProgramCreate,
    db: AsyncSession = Depends(get_db),
    _user=Depends(require_roles([UserRole.ADMIN, UserRole.SUPER_ADMIN]))
):
    prog = Program(**prog_in.model_dump())
    db.add(prog)
    await db.commit()
    await db.refresh(prog)
    return prog


@router.get("/semesters", response_model=List[SemesterResponse])
async def list_semesters(db: AsyncSession = Depends(get_db)):
    stmt = select(AcademicSemester)
    res = await db.execute(stmt)
    return res.scalars().all()


@router.post("/semesters", response_model=SemesterResponse, status_code=status.HTTP_201_CREATED)
async def create_semester(
    sem_in: SemesterCreate,
    db: AsyncSession = Depends(get_db),
    _user=Depends(require_roles([UserRole.ADMIN, UserRole.SUPER_ADMIN]))
):
    sem = AcademicSemester(**sem_in.model_dump())
    db.add(sem)
    await db.commit()
    await db.refresh(sem)
    return sem


# --- Courses ---
@router.get("/courses", response_model=List[CourseResponse])
async def list_courses(db: AsyncSession = Depends(get_db)):
    stmt = select(Course)
    res = await db.execute(stmt)
    return res.scalars().all()


@router.post("/courses", response_model=CourseResponse, status_code=status.HTTP_201_CREATED)
async def create_course(
    course_in: CourseCreate,
    db: AsyncSession = Depends(get_db),
    _user=Depends(require_roles([UserRole.ADMIN, UserRole.SUPER_ADMIN, UserRole.FACULTY]))
):
    stmt = select(Course).where(Course.code == course_in.code)
    existing = (await db.execute(stmt)).scalar_one_or_none()
    if existing:
        raise HTTPException(status_code=400, detail="Course code already exists")

    course = Course(**course_in.model_dump())
    db.add(course)
    await db.commit()
    await db.refresh(course)
    return course


# --- Sections & Enrollments ---
@router.get("/sections", response_model=List[SectionResponse])
async def list_sections(course_id: Optional[int] = None, db: AsyncSession = Depends(get_db)):
    stmt = select(Section)
    if course_id:
        stmt = stmt.where(Section.course_id == course_id)
    res = await db.execute(stmt)
    return res.scalars().all()


@router.post("/sections", response_model=SectionResponse, status_code=status.HTTP_201_CREATED)
async def create_section(
    sec_in: SectionCreate,
    db: AsyncSession = Depends(get_db),
    _user=Depends(require_roles([UserRole.ADMIN, UserRole.SUPER_ADMIN]))
):
    sec = Section(**sec_in.model_dump())
    db.add(sec)
    await db.commit()
    await db.refresh(sec)
    return sec


@router.post("/enroll", status_code=status.HTTP_201_CREATED)
async def enroll_student(
    req: EnrollStudentRequest,
    db: AsyncSession = Depends(get_db),
    _user=Depends(require_roles([UserRole.ADMIN, UserRole.SUPER_ADMIN, UserRole.FACULTY]))
):
    stmt = select(CourseEnrollment).where(
        CourseEnrollment.student_id == req.student_id,
        CourseEnrollment.section_id == req.section_id
    )
    existing = (await db.execute(stmt)).scalar_one_or_none()
    if existing:
        raise HTTPException(status_code=400, detail="Student is already enrolled in this section")

    enrollment = CourseEnrollment(student_id=req.student_id, section_id=req.section_id)
    db.add(enrollment)
    await db.commit()
    return {"message": "Student enrolled successfully", "student_id": req.student_id, "section_id": req.section_id}
