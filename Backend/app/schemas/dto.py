from datetime import datetime, date
from typing import Optional, List
from pydantic import BaseModel, EmailStr, Field, ConfigDict
from app.models.domain import UserRole, AttendanceStatus, LeaveStatus, GradeLetter, PaymentStatus, GatePassStatus


# --- Auth & User Schemas ---
class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class TokenData(BaseModel):
    sub: Optional[str] = None
    roles: List[str] = []


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class ChangePasswordRequest(BaseModel):
    old_password: str
    new_password: str = Field(min_length=6)


class RegisterUserRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=6)
    full_name: str
    role: UserRole = UserRole.STUDENT
    phone: Optional[str] = None
    department_id: Optional[int] = None
    roll_number: Optional[str] = None
    employee_id: Optional[str] = None


class UserResponse(BaseModel):
    id: int
    email: str
    full_name: str
    role: UserRole
    is_active: bool
    phone: Optional[str] = None
    department_id: Optional[int] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class StudentProfileResponse(BaseModel):
    id: int
    user_id: int
    roll_number: str
    batch_year: int
    current_semester: int
    cgpa: float

    model_config = ConfigDict(from_attributes=True)


class FacultyProfileResponse(BaseModel):
    id: int
    user_id: int
    employee_id: str
    designation: str
    specialization: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


# --- Academic Schemas ---
class DepartmentCreate(BaseModel):
    code: str
    name: str
    description: Optional[str] = None


class DepartmentResponse(DepartmentCreate):
    id: int
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class ProgramCreate(BaseModel):
    code: str
    name: str
    degree_type: str = "UG"
    duration_years: int = 4
    department_id: int


class ProgramResponse(ProgramCreate):
    id: int

    model_config = ConfigDict(from_attributes=True)


class SemesterCreate(BaseModel):
    name: str
    start_date: date
    end_date: date
    is_active: bool = True


class SemesterResponse(SemesterCreate):
    id: int

    model_config = ConfigDict(from_attributes=True)


class CourseCreate(BaseModel):
    code: str
    title: str
    credits: int
    department_id: int


class CourseResponse(CourseCreate):
    id: int

    model_config = ConfigDict(from_attributes=True)


class SectionCreate(BaseModel):
    name: str
    course_id: int
    semester_id: int
    faculty_id: Optional[int] = None


class SectionResponse(SectionCreate):
    id: int

    model_config = ConfigDict(from_attributes=True)


class EnrollStudentRequest(BaseModel):
    student_id: int
    section_id: int


# --- Attendance & Leave Schemas ---
class AttendanceMarkRequest(BaseModel):
    course_id: int
    student_id: int
    status: AttendanceStatus


class BulkAttendanceItem(BaseModel):
    student_id: int
    status: AttendanceStatus


class BulkAttendanceRequest(BaseModel):
    course_id: int
    attendance_date: date
    records: List[BulkAttendanceItem]


class AttendanceResponse(BaseModel):
    id: int
    student_id: int
    course_id: int
    attendance_date: str
    status: AttendanceStatus

    model_config = ConfigDict(from_attributes=True)


class LeaveRequestCreate(BaseModel):
    start_date: date
    end_date: date
    reason: str


class LeaveRequestResponse(BaseModel):
    id: int
    student_id: int
    start_date: date
    end_date: date
    reason: str
    status: LeaveStatus
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class LeaveReviewRequest(BaseModel):
    status: LeaveStatus


# --- Timetable Schemas ---
class TimetableEntryCreate(BaseModel):
    section_id: int
    day_of_week: str
    start_time: str
    end_time: str
    room_number: str
    faculty_id: int


class TimetableEntryResponse(TimetableEntryCreate):
    id: int

    model_config = ConfigDict(from_attributes=True)


# --- Exam & Grade Schemas ---
class ExamCreate(BaseModel):
    title: str
    course_id: int
    exam_date: date
    total_marks: int = 100
    weightage_percent: float = 50.0


class ExamResponse(ExamCreate):
    id: int

    model_config = ConfigDict(from_attributes=True)


class GradeEntryItem(BaseModel):
    student_id: int
    marks_obtained: float
    grade: GradeLetter


class BulkGradeEntryRequest(BaseModel):
    exam_id: int
    grades: List[GradeEntryItem]


class TranscriptResponse(BaseModel):
    student_id: int
    student_name: str
    roll_number: str
    cgpa: float
    total_credits: int
    grades: List[dict]


# --- Finance Schemas ---
class FeeStructureCreate(BaseModel):
    program_id: int
    semester_number: int
    tuition_fee: float
    hostel_fee: float
    other_fees: float


class FeeStructureResponse(FeeStructureCreate):
    id: int
    total_fee: float

    model_config = ConfigDict(from_attributes=True)


class InvoiceResponse(BaseModel):
    id: int
    invoice_number: str
    student_id: int
    amount_due: float
    amount_paid: float
    status: PaymentStatus
    due_date: date

    model_config = ConfigDict(from_attributes=True)


class PaymentRecordRequest(BaseModel):
    invoice_id: int
    amount: float
    payment_method: str = "ONLINE"


# --- Hostel & Gate Pass Schemas ---
class GatePassCreate(BaseModel):
    reason: str
    out_time: datetime
    expected_in_time: datetime


class GatePassResponse(GatePassCreate):
    id: int
    student_id: int
    status: GatePassStatus

    model_config = ConfigDict(from_attributes=True)


# --- Campus Notice Schemas ---
class NoticeCreate(BaseModel):
    title: str
    content: str
    target_role: Optional[UserRole] = None


class NoticeResponse(NoticeCreate):
    id: int
    posted_by_id: int
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
