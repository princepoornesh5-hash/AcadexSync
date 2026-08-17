import json
from typing import Optional, Any
import redis.asyncio as aioredis
from app.core.config import settings

class RedisManager:
    def __init__(self):
        self.redis: Optional[aioredis.Redis] = None

    async def connect(self):
        try:
            self.redis = aioredis.from_url(settings.REDIS_URL, encoding="utf-8", decode_responses=True)
            await self.redis.ping()
            print("✅ Redis Connected Successfully")
        except Exception as e:
            print(f"⚠️ Redis Connection Failed (Using in-memory/fallback): {e}")
            self.redis = None

    async def close(self):
        if self.redis:
            await self.redis.close()

    async def get_json(self, key: str) -> Optional[Any]:
        if not self.redis:
            return None
        try:
            data = await self.redis.get(key)
            return json.loads(data) if data else None
        except Exception:
            return None

    async def set_json(self, key: str, value: Any, expire_seconds: int = 300) -> bool:
        if not self.redis:
            return False
        try:
            await self.redis.set(key, json.dumps(value), ex=expire_seconds)
            return True
        except Exception:
            return False

    async def delete(self, key: str) -> bool:
        if not self.redis:
            return False
        try:
            await self.redis.delete(key)
            return True
        except Exception:
            return False

redis_client = RedisManager()
