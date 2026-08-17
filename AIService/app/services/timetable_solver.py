from typing import List, Dict, Any


class TimetableSolverService:
    async def generate_schedule(self, courses: List[str], rooms: List[str], professors: List[str]) -> Dict[str, Any]:
        """Simple greedy / constraint satisfaction solver for conflict-free timetable generation"""
        slots = ["09:00 AM - 10:00 AM", "10:00 AM - 11:00 AM", "11:15 AM - 12:15 PM", "01:30 PM - 02:30 PM", "02:30 PM - 03:30 PM"]
        days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]

        schedule = []
        course_idx = 0

        for day in days:
            for slot in slots:
                if course_idx < len(courses):
                    course = courses[course_idx]
                    room = rooms[course_idx % len(rooms)] if rooms else "Room 101"
                    prof = professors[course_idx % len(professors)] if professors else "Prof. Smith"

                    schedule.append({
                        "day": day,
                        "time_slot": slot,
                        "course": course,
                        "room": room,
                        "professor": prof
                    })
                    course_idx += 1

        return {
            "status": "success",
            "total_classes_scheduled": len(schedule),
            "schedule": schedule
        }


timetable_solver = TimetableSolverService()
