from typing import AsyncGenerator
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlmodel import SQLModel
from app.core.config import settings

# Engine configuration
engine_kwargs = {}
if "sqlite" in settings.DATABASE_URL:
    engine_kwargs["connect_args"] = {"check_same_thread": False}

engine = create_async_engine(
    settings.DATABASE_URL,
    echo=settings.DEBUG,
    future=True,
    **engine_kwargs
)

AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autoflush=False
)


async def init_db():
    """Create tables automatically for dev/sqlite setups and seed demo accounts"""
    async with engine.begin() as conn:
        await conn.run_sync(SQLModel.metadata.create_all)

    # Seed demo users if not existing
    from sqlmodel import select
    from app.models.domain import User, UserRole, Department, StudentProfile, FacultyProfile
    from app.core.security import get_password_hash

    async with AsyncSessionLocal() as session:
        result = await session.execute(select(User).where(User.email == "admin@campus.edu"))
        admin_existing = result.scalar_one_or_none()
        if not admin_existing:
            print("🌱 Seeding Demo Credentials into database...")
            # Create Default Department
            dept = Department(code="CS", name="Computer Science & Engineering", description="Core CS Dept")
            session.add(dept)
            await session.flush()

            # Admin
            admin = User(
                email="admin@campus.edu",
                hashed_password=get_password_hash("admin123"),
                full_name="Super Administrator",
                role=UserRole.SUPER_ADMIN,
                is_active=True,
                department_id=dept.id
            )
            # Faculty
            faculty = User(
                email="prof.smith@campus.edu",
                hashed_password=get_password_hash("prof123"),
                full_name="Dr. Alan Smith",
                role=UserRole.FACULTY,
                is_active=True,
                department_id=dept.id
            )
            # Student
            student = User(
                email="student.john@campus.edu",
                hashed_password=get_password_hash("student123"),
                full_name="John Doe",
                role=UserRole.STUDENT,
                is_active=True,
                department_id=dept.id
            )
            session.add_all([admin, faculty, student])
            await session.flush()

            f_profile = FacultyProfile(user_id=faculty.id, employee_id="F1001", designation="Associate Professor", specialization="Artificial Intelligence")
            s_profile = StudentProfile(user_id=student.id, roll_number="CS24001", batch_year=2024, current_semester=2, cgpa=8.8)
            session.add_all([f_profile, s_profile])
            await session.commit()
            print("✅ Demo accounts seeded successfully!")


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """Dependency for obtaining async DB session"""
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()
