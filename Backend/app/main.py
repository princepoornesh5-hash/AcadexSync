from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.core.database import init_db
from app.core.redis import redis_client

from app.modules.auth.router import router as auth_router
from app.modules.users.router import router as users_router
from app.modules.academics.router import router as academics_router
from app.modules.attendance.router import router as attendance_router
from app.modules.timetable.router import router as timetable_router
from app.modules.exams.router import router as exams_router
from app.modules.finance.router import router as finance_router
from app.modules.hostel.router import router as hostel_router
from app.modules.notices.router import router as notices_router
from app.modules.ai_gateway.router import router as ai_gateway_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: Database schema & Redis connection
    print(f"🚀 Starting {settings.PROJECT_NAME} Backend v{settings.VERSION}")
    await init_db()
    await redis_client.connect()
    yield
    # Shutdown
    print("👋 Shutting down Backend")
    await redis_client.close()


app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    docs_url=f"{settings.API_V1_STR}/docs",
    lifespan=lifespan
)

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.BACKEND_CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include All 9 API v1 Routers
app.include_router(auth_router, prefix=settings.API_V1_STR)
app.include_router(users_router, prefix=settings.API_V1_STR)
app.include_router(academics_router, prefix=settings.API_V1_STR)
app.include_router(attendance_router, prefix=settings.API_V1_STR)
app.include_router(timetable_router, prefix=settings.API_V1_STR)
app.include_router(exams_router, prefix=settings.API_V1_STR)
app.include_router(finance_router, prefix=settings.API_V1_STR)
app.include_router(hostel_router, prefix=settings.API_V1_STR)
app.include_router(notices_router, prefix=settings.API_V1_STR)
app.include_router(ai_gateway_router, prefix=settings.API_V1_STR)


@app.get("/health", tags=["Health Check"])
async def health_check():
    return {
        "status": "healthy",
        "app": settings.PROJECT_NAME,
        "version": settings.VERSION,
        "environment": settings.ENVIRONMENT
    }
