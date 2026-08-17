from typing import Dict, Any


class CampusRAGService:
    def __init__(self):
        # Sample knowledge base for campus queries
        self.knowledge_base = {
            "attendance": "Minimum required attendance is 75%. Below 75% requires a medical certificate or dean permission.",
            "exams": "End-semester examinations start on the 15th of December. Hall tickets will be issued 1 week prior.",
            "library": "Library hours are 8:00 AM to 10:00 PM on weekdays. Students can borrow up to 5 books for 14 days.",
            "hostel": "Mess fee payments are due by the 5th of every month. Gate pass requests must be submitted before 7:00 PM.",
            "fees": "Tuition fee payment link opens 2 weeks before semester registration via the student portal."
        }

    async def answer_query(self, query: str) -> Dict[str, Any]:
        query_lower = query.lower()
        matched_category = None
        answer = "I am your Campus AI Assistant! I can help you with questions about attendance, exams, library rules, hostels, and fees. What would you like to know?"

        for key, text in self.knowledge_base.items():
            if key in query_lower:
                matched_category = key
                answer = f"📌 **{key.capitalize()} Information:** {text}"
                break

        return {
            "query": query,
            "category": matched_category,
            "answer": answer,
            "confidence": 0.95 if matched_category else 0.70
        }


rag_service = CampusRAGService()
