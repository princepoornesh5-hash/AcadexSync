from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from app.core.database import get_db
from app.core.security import verify_password, get_password_hash, create_access_token, create_refresh_token, decode_token
from app.models.domain import User, UserRole, StudentProfile, FacultyProfile
from app.schemas.dto import Token, LoginRequest, RegisterUserRequest, UserResponse, ChangePasswordRequest
from app.api.deps import get_current_user

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/login", response_model=Token)
async def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: AsyncSession = Depends(get_db)
):
    statement = select(User).where(User.email == form_data.username)
    result = await db.execute(statement)
    user = result.scalar_one_or_none()

    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    access_token = create_access_token(subject=user.id, roles=[user.role.value])
    refresh_token = create_refresh_token(subject=user.id)

    return Token(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer"
    )


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def register(
    req: RegisterUserRequest,
    db: AsyncSession = Depends(get_db)
):
    stmt = select(User).where(User.email == req.email)
    existing = (await db.execute(stmt)).scalar_one_or_none()
    if existing:
        raise HTTPException(status_code=400, detail="User with this email already exists")

    new_user = User(
        email=req.email,
        hashed_password=get_password_hash(req.password),
        full_name=req.full_name,
        role=req.role,
        phone=req.phone,
        department_id=req.department_id
    )
    db.add(new_user)
    await db.flush()

    if req.role == UserRole.STUDENT:
        student_prof = StudentProfile(
            user_id=new_user.id,
            roll_number=req.roll_number or f"STU-{new_user.id:04d}"
        )
        db.add(student_prof)
    elif req.role in [UserRole.FACULTY, UserRole.ADMIN]:
        faculty_prof = FacultyProfile(
            user_id=new_user.id,
            employee_id=req.employee_id or f"EMP-{new_user.id:04d}"
        )
        db.add(faculty_prof)

    await db.commit()
    await db.refresh(new_user)
    return new_user


@router.get("/me", response_model=UserResponse)
async def get_me(current_user: User = Depends(get_current_user)):
    return current_user


@router.post("/change-password")
async def change_password(
    req: ChangePasswordRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    if not verify_password(req.old_password, current_user.hashed_password):
        raise HTTPException(status_code=400, detail="Incorrect current password")

    current_user.hashed_password = get_password_hash(req.new_password)
    db.add(current_user)
    await db.commit()
    return {"message": "Password updated successfully"}


@router.post("/seed-admin", response_model=UserResponse)
async def seed_admin(db: AsyncSession = Depends(get_db)):
    stmt = select(User)
    existing = (await db.execute(stmt)).first()
    if existing:
        raise HTTPException(status_code=400, detail="Database already initialized")

    admin = User(
        email="admin@campus.edu",
        hashed_password=get_password_hash("admin123"),
        full_name="System Super Admin",
        role=UserRole.SUPER_ADMIN,
        is_active=True
    )
    db.add(admin)
    await db.commit()
    await db.refresh(admin)
    return admin
