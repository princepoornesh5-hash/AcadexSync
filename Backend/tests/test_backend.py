# pyrefly: ignore [missing-import]
import pytest
# pyrefly: ignore [missing-import]
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from app.main import app
from app.core.database import init_db

@pytest_asyncio.fixture(autouse=True)
async def setup_db():
    await init_db()

@pytest.mark.asyncio
async def test_full_backend_suite():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        # 1. Health check
        res = await ac.get("/health")
        assert res.status_code == 200

        # 2. Seed Admin & Login
        await ac.post("/api/v1/auth/seed-admin")
        login_res = await ac.post("/api/v1/auth/login", data={"username": "admin@campus.edu", "password": "admin123"})
        assert login_res.status_code == 200
        token = login_res.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # 3. Create Department
        dept_res = await ac.post("/api/v1/academics/departments", json={"code": "CSE", "name": "Computer Science"}, headers=headers)
        assert dept_res.status_code in [201, 400]
        dept_id = dept_res.json().get("id", 1)

        # 4. Register Faculty & Student
        fac_res = await ac.post("/api/v1/auth/register", json={
            "email": "prof.test@campus.edu",
            "password": "password123",
            "full_name": "Prof. Alan Turing",
            "role": "FACULTY",
            "department_id": dept_id
        })
        assert fac_res.status_code in [201, 400]

        stu_res = await ac.post("/api/v1/auth/register", json={
            "email": "student.test@campus.edu",
            "password": "password123",
            "full_name": "Ada Lovelace",
            "role": "STUDENT",
            "department_id": dept_id
        })
        assert stu_res.status_code in [201, 400]
        student_id = stu_res.json().get("id", 2)

        # 5. Create Program & Course
        course_res = await ac.post("/api/v1/academics/courses", json={
            "code": "CS101",
            "title": "Introduction to Computer Science",
            "credits": 4,
            "department_id": dept_id
        }, headers=headers)
        assert course_res.status_code in [201, 400]
        course_id = course_res.json().get("id", 1)

        # 6. Post Campus Notice
        notice_res = await ac.post("/api/v1/notices", json={
            "title": "Welcome Semester Fall 2026",
            "content": "All students are requested to report to auditorium."
        }, headers=headers)
        assert notice_res.status_code == 201

        # 7. Get Notice Board Feed
        feed_res = await ac.get("/api/v1/notices", headers=headers)
        assert feed_res.status_code == 200
        assert len(feed_res.json()) > 0

        # 8. Create Fee Structure & Generate Invoice
        fee_res = await ac.post("/api/v1/finance/fee-structures", json={
            "program_id": 1,
            "semester_number": 1,
            "tuition_fee": 45000,
            "hostel_fee": 15000,
            "other_fees": 3000
        }, headers=headers)
        assert fee_res.status_code == 201
        fee_id = fee_res.json()["id"]

        inv_res = await ac.post(f"/api/v1/finance/invoices/generate?student_id={student_id}&fee_structure_id={fee_id}", headers=headers)
        assert inv_res.status_code == 201
        invoice_id = inv_res.json()["id"]

        # 9. Record Payment
        pay_res = await ac.post("/api/v1/finance/payments/record", json={
            "invoice_id": invoice_id,
            "amount": 63000,
            "payment_method": "ONLINE"
        }, headers=headers)
        assert pay_res.status_code == 201
        assert pay_res.json()["status"] == "PAID"

        # 10. Submit Gate Pass & Approve
        gp_res = await ac.post("/api/v1/hostel/gate-passes", json={
            "reason": "Weekend home visit",
            "out_time": "2026-08-10T10:00:00",
            "expected_in_time": "2026-08-12T18:00:00"
        }, headers=headers)
        assert gp_res.status_code == 201
        pass_id = gp_res.json()["id"]

        approve_res = await ac.put(f"/api/v1/hostel/gate-passes/{pass_id}/approve?approve=true", headers=headers)
        assert approve_res.status_code == 200
        assert approve_res.json()["status"] == "APPROVED"
