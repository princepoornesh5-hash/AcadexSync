import httpx
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from app.core.config import settings
from app.models.domain import User
from app.api.deps import get_current_user

router = APIRouter(prefix="/ai", tags=["AI Service Gateway"])


class ChatRequest(BaseModel):
    query: str


@router.post("/chat")
async def chat_with_campus_ai(
    req: ChatRequest,
    current_user: User = Depends(get_current_user)
):
    """Protected backend proxy forwarding student/faculty RAG queries to the AI Microservice"""
    payload = {
        "query": req.query,
        "user_id": current_user.id
    }
    try:
        async with httpx.AsyncClient() as client:
            resp = await client.post(f"{settings.AI_SERVICE_URL}/api/v1/ai/chat", json=payload, timeout=10.0)
            if resp.status_code == 200:
                return resp.json()
            else:
                raise HTTPException(status_code=resp.status_code, detail="Error from AI Service")
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"AI Service communication error: {str(e)}")
