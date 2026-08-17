from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Optional

from app.services.rag_chatbot import rag_service
from app.services.timetable_solver import timetable_solver

app = FastAPI(
    title="Campus AI Service",
    version="1.0.0",
    description="Python Microservice for Campus RAG Chatbot, Timetable Constraint Solving, and Predictive Analytics"
)


class ChatQueryRequest(BaseModel):
    query: str
    user_id: Optional[int] = None


class TimetableRequest(BaseModel):
    courses: List[str]
    rooms: List[str]
    professors: List[str]


@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "Campus AI Microservice"}


@app.post("/api/v1/ai/chat")
async def chat_query(req: ChatQueryRequest):
    if not req.query.strip():
        raise HTTPException(status_code=400, detail="Query string cannot be empty")
    result = await rag_service.answer_query(req.query)
    return result


@app.post("/api/v1/ai/generate-timetable")
async def generate_timetable(req: TimetableRequest):
    result = await timetable_solver.generate_schedule(req.courses, req.rooms, req.professors)
    return result
