from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select, or_

from app.core.database import get_db
from app.models.domain import CampusNotice, UserRole, User
from app.schemas.dto import NoticeCreate, NoticeResponse
from app.api.deps import require_roles, get_current_user

router = APIRouter(prefix="/notices", tags=["Campus Notice Board"])


@router.get("", response_model=List[NoticeResponse])
async def get_notice_board(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    stmt = select(CampusNotice).where(
        or_(
            CampusNotice.target_role == None,
            CampusNotice.target_role == current_user.role
        )
    ).order_by(CampusNotice.created_at.desc())

    res = await db.execute(stmt)
    return res.scalars().all()


@router.post("", response_model=NoticeResponse, status_code=status.HTTP_201_CREATED)
async def post_notice(
    req: NoticeCreate,
    current_user: User = Depends(require_roles([UserRole.ADMIN, UserRole.SUPER_ADMIN, UserRole.FACULTY])),
    db: AsyncSession = Depends(get_db)
):
    notice = CampusNotice(
        title=req.title,
        content=req.content,
        target_role=req.target_role,
        posted_by_id=current_user.id
    )
    db.add(notice)
    await db.commit()
    await db.refresh(notice)
    return notice
