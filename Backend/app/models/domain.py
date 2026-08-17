from datetime import datetime, date, time
from enum import Enum
from typing import Optional, List
from sqlmodel import SQLModel, Field, Relationship


# --- Enums ---
class UserRole(str, Enum):
    SUPER_ADMIN = "SUPER_ADMIN"
    ADMIN = "ADMIN"
    FACULTY = "FACULTY"
    STUDENT = "STUDENT"
    STAFF = "STAFF"


class AttendanceStatus(str, Enum):
    PRESENT = "PRESENT"
    ABSENT = "ABSENT"
    LATE = "LATE"
    EXCUSED = "EXCUSED"


class LeaveStatus(str, Enum):
    PENDING = "PENDING"
    APPROVED = "APPROVED"
    REJECTED = "REJECTED"


class GradeLetter(str, Enum):
    O = "O"   # 10 points (Outstanding)
    A_PLUS = "A+" # 9 points
    A = "A"   # 8 points
    B_PLUS = "B+" # 7 points
    B = "B"   # 6 points
    C = "C"   # 5 points
    F = "F"   # 0 points (Fail)


class PaymentStatus(str, Enum):
    UNPAID = "UNPAID"
    PARTIAL = "PARTIAL"
    PAID = "PAID"
    OVERDUE = "OVERDUE"


class GatePassStatus(str, Enum):
    PENDING = "PENDING"
    APPROVED = "APPROVED"
    REJECTED = "REJECTED"
    EXPIRED = "EXPIRED"


# --- Core Domain Entities ---

class Department(SQLModel, table=True):
    __tablename__ = "departments"

    id: Optional[int] = Field(default=None, primary_key=True)
    code: str = Field(unique=True, index=True, min_length=2, max_length=10)
    name: str = Field(min_length=2, max_length=100)
    description: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)

    # Relationships
    users: List["User"] = Relationship(back_populates="department")
    programs: List["Program"] = Relationship(back_populates="department")
    courses: List["Course"] = Relationship(back_populates="department")


class Program(SQLModel, table=True):
    __tablename__ = "programs"

    id: Optional[int] = Field(default=None, primary_key=True)
    code: str = Field(unique=True, index=True, min_length=2, max_length=15)
    name: str = Field(min_length=2, max_length=100) # e.g. Bachelor of Technology
    degree_type: str = Field(default="UG") # UG / PG / Ph.D
    duration_years: int = Field(default=4)
    department_id: int = Field(foreign_key="departments.id")

    department: Optional[Department] = Relationship(back_populates="programs")


class AcademicSemester(SQLModel, table=True):
    __tablename__ = "academic_semesters"

    id: Optional[int] = Field(default=None, primary_key=True)
    name: str = Field(min_length=3, max_length=50) # Fall 2026, Spring 2027
    start_date: date
    end_date: date
    is_active: bool = Field(default=True)


class User(SQLModel, table=True):
    __tablename__ = "users"

    id: Optional[int] = Field(default=None, primary_key=True)
    email: str = Field(unique=True, index=True, min_length=5, max_length=255)
    hashed_password: str
    full_name: str = Field(min_length=2, max_length=150)
    role: UserRole = Field(default=UserRole.STUDENT, index=True)
    is_active: bool = Field(default=True)
    phone: Optional[str] = None
    department_id: Optional[int] = Field(default=None, foreign_key="departments.id")
    created_at: datetime = Field(default_factory=datetime.utcnow)

    department: Optional[Department] = Relationship(back_populates="users")
    student_profile: Optional["StudentProfile"] = Relationship(back_populates="user")
    faculty_profile: Optional["FacultyProfile"] = Relationship(back_populates="user")


class StudentProfile(SQLModel, table=True):
    __tablename__ = "student_profiles"

    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="users.id", unique=True, index=True)
    roll_number: str = Field(unique=True, index=True, min_length=3, max_length=30)
    batch_year: int = Field(default=2024)
    current_semester: int = Field(default=1)
    cgpa: float = Field(default=0.0)

    user: Optional[User] = Relationship(back_populates="student_profile")


class FacultyProfile(SQLModel, table=True):
    __tablename__ = "faculty_profiles"

    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="users.id", unique=True, index=True)
    employee_id: str = Field(unique=True, index=True, min_length=3, max_length=30)
    designation: str = Field(default="Assistant Professor")
    specialization: Optional[str] = None

    user: Optional[User] = Relationship(back_populates="faculty_profile")


class Course(SQLModel, table=True):
    __tablename__ = "courses"

    id: Optional[int] = Field(default=None, primary_key=True)
    code: str = Field(unique=True, index=True, min_length=2, max_length=20)
    title: str = Field(min_length=2, max_length=150)
    credits: int = Field(default=3, ge=1, le=10)
    department_id: int = Field(foreign_key="departments.id")

    department: Optional[Department] = Relationship(back_populates="courses")
    sections: List["Section"] = Relationship(back_populates="course")


class Section(SQLModel, table=True):
    __tablename__ = "sections"

    id: Optional[int] = Field(default=None, primary_key=True)
    name: str = Field(min_length=1, max_length=10) # A, B, C
    course_id: int = Field(foreign_key="courses.id", index=True)
    semester_id: int = Field(foreign_key="academic_semesters.id", index=True)
    faculty_id: Optional[int] = Field(default=None, foreign_key="users.id")

    course: Optional[Course] = Relationship(back_populates="sections")


class CourseEnrollment(SQLModel, table=True):
    __tablename__ = "course_enrollments"

    id: Optional[int] = Field(default=None, primary_key=True)
    student_id: int = Field(foreign_key="users.id", index=True)
    section_id: int = Field(foreign_key="sections.id", index=True)
    enrolled_at: datetime = Field(default_factory=datetime.utcnow)


class AttendanceRecord(SQLModel, table=True):
    __tablename__ = "attendance_records"

    id: Optional[int] = Field(default=None, primary_key=True)
    student_id: int = Field(foreign_key="users.id", index=True)
    course_id: int = Field(foreign_key="courses.id", index=True)
    attendance_date: date = Field(index=True)
    status: AttendanceStatus = Field(default=AttendanceStatus.PRESENT)
    marked_by_id: int = Field(foreign_key="users.id")
    created_at: datetime = Field(default_factory=datetime.utcnow)


class LeaveRequest(SQLModel, table=True):
    __tablename__ = "leave_requests"

    id: Optional[int] = Field(default=None, primary_key=True)
    student_id: int = Field(foreign_key="users.id", index=True)
    start_date: date
    end_date: date
    reason: str
    status: LeaveStatus = Field(default=LeaveStatus.PENDING)
    reviewed_by_id: Optional[int] = Field(default=None, foreign_key="users.id")
    created_at: datetime = Field(default_factory=datetime.utcnow)


class TimetableEntry(SQLModel, table=True):
    __tablename__ = "timetable_entries"

    id: Optional[int] = Field(default=None, primary_key=True)
    section_id: int = Field(foreign_key="sections.id", index=True)
    day_of_week: str = Field(min_length=3, max_length=10) # Monday, Tuesday...
    start_time: str # "09:00"
    end_time: str   # "10:00"
    room_number: str = Field(default="Room 101")
    faculty_id: int = Field(foreign_key="users.id")


class Exam(SQLModel, table=True):
    __tablename__ = "exams"

    id: Optional[int] = Field(default=None, primary_key=True)
    title: str = Field(min_length=2, max_length=100)
    course_id: int = Field(foreign_key="courses.id", index=True)
    exam_date: date
    total_marks: int = Field(default=100)
    weightage_percent: float = Field(default=50.0)


class GradeRecord(SQLModel, table=True):
    __tablename__ = "grade_records"

    id: Optional[int] = Field(default=None, primary_key=True)
    exam_id: int = Field(foreign_key="exams.id", index=True)
    student_id: int = Field(foreign_key="users.id", index=True)
    marks_obtained: float = Field(default=0.0)
    grade: GradeLetter = Field(default=GradeLetter.A)
    grade_points: float = Field(default=8.0)
    recorded_by_id: int = Field(foreign_key="users.id")


class FeeStructure(SQLModel, table=True):
    __tablename__ = "fee_structures"

    id: Optional[int] = Field(default=None, primary_key=True)
    program_id: int = Field(foreign_key="programs.id", index=True)
    semester_number: int = Field(default=1)
    tuition_fee: float = Field(default=50000.0)
    hostel_fee: float = Field(default=20000.0)
    other_fees: float = Field(default=5000.0)

    @property
    def total_fee(self) -> float:
        return self.tuition_fee + self.hostel_fee + self.other_fees


class StudentInvoice(SQLModel, table=True):
    __tablename__ = "student_invoices"

    id: Optional[int] = Field(default=None, primary_key=True)
    invoice_number: str = Field(unique=True, index=True)
    student_id: int = Field(foreign_key="users.id", index=True)
    fee_structure_id: int = Field(foreign_key="fee_structures.id")
    amount_due: float
    amount_paid: float = Field(default=0.0)
    status: PaymentStatus = Field(default=PaymentStatus.UNPAID)
    due_date: date
    created_at: datetime = Field(default_factory=datetime.utcnow)


class PaymentTransaction(SQLModel, table=True):
    __tablename__ = "payment_transactions"

    id: Optional[int] = Field(default=None, primary_key=True)
    invoice_id: int = Field(foreign_key="student_invoices.id", index=True)
    transaction_id: str = Field(unique=True, index=True)
    amount: float
    payment_method: str = Field(default="ONLINE") # STRIPE, RAZORPAY, CASH
    paid_at: datetime = Field(default_factory=datetime.utcnow)


class HostelBlock(SQLModel, table=True):
    __tablename__ = "hostel_blocks"

    id: Optional[int] = Field(default=None, primary_key=True)
    name: str = Field(unique=True, min_length=2, max_length=50) # Block A (Boys), Block B (Girls)
    total_rooms: int = Field(default=50)


class HostelRoom(SQLModel, table=True):
    __tablename__ = "hostel_rooms"

    id: Optional[int] = Field(default=None, primary_key=True)
    block_id: int = Field(foreign_key="hostel_blocks.id", index=True)
    room_number: str = Field(min_length=1, max_length=10)
    capacity: int = Field(default=2)
    current_occupancy: int = Field(default=0)


class GatePass(SQLModel, table=True):
    __tablename__ = "gate_passes"

    id: Optional[int] = Field(default=None, primary_key=True)
    student_id: int = Field(foreign_key="users.id", index=True)
    reason: str
    out_time: datetime
    expected_in_time: datetime
    status: GatePassStatus = Field(default=GatePassStatus.PENDING)
    approved_by_id: Optional[int] = Field(default=None, foreign_key="users.id")


class CampusNotice(SQLModel, table=True):
    __tablename__ = "campus_notices"

    id: Optional[int] = Field(default=None, primary_key=True)
    title: str = Field(min_length=2, max_length=200)
    content: str
    target_role: Optional[UserRole] = None # None = All
    posted_by_id: int = Field(foreign_key="users.id")
    created_at: datetime = Field(default_factory=datetime.utcnow)
