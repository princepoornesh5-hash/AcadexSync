import mongoose from 'mongoose';
import { env } from '../src/config/env';
import { User } from '../src/models/user.model';
import { College } from '../src/models/college.model';
import { signJwtToken } from '../src/utils/token';
import { TokenType } from '../src/constants/status';
import { AppRole } from '../src/constants/roles';

async function runRuntimeVerification() {
  console.log('--- ACADEX PROMPT 2 RUNTIME VERIFICATION ---');
  await mongoose.connect(env.MONGODB_URI!);
  console.log('Connected to MongoDB for test user lookup.');

  // Find or create test college
  let college = await College.findOne();
  if (!college) {
    college = await College.create({
      name: 'Runtime Test College',
      code: 'RTC01',
      domain: 'rtc.edu',
    });
  }

  // Find or create a student user
  let student = await User.findOne({ role: AppRole.STUDENT, collegeId: college._id });
  if (!student) {
    student = await User.create({
      name: 'Runtime Test Student',
      email: 'student_runtime@test.com',
      role: AppRole.STUDENT,
      collegeId: college._id,
      accountStatus: 'ACTIVE',
    });
  }

  // Find or create HOD user for status update
  let hod = await User.findOne({ role: AppRole.HOD, collegeId: college._id });
  if (!hod) {
    hod = await User.create({
      name: 'Runtime Test HOD',
      email: 'hod_runtime@test.com',
      role: AppRole.HOD,
      collegeId: college._id,
      accountStatus: 'ACTIVE',
    });
  }

  const studentToken = signJwtToken({
    userId: student._id.toString(),
    email: student.email,
    role: student.role,
    collegeId: college._id.toString(),
    tokenType: TokenType.ACCESS,
  });

  const hodToken = signJwtToken({
    userId: hod._id.toString(),
    email: hod.email,
    role: hod.role,
    collegeId: college._id.toString(),
    tokenType: TokenType.ACCESS,
  });

  const BASE_URL = `http://localhost:${env.PORT}/api/v1/requests`;

  const results: any[] = [];

  // Helper for requests
  async function callApi(name: string, url: string, method: string, token: string, body?: any) {
    const res = await fetch(url, {
      method,
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: body ? JSON.stringify(body) : undefined,
    });
    const status = res.status;
    let data: any;
    try {
      data = await res.json();
    } catch {
      data = await res.text();
    }
    const summary = { name, status, response: data };
    results.push(summary);
    console.log(`\n[${status}] ${name}`);
    console.log(JSON.stringify(data, null, 2));
    return { status, data };
  }

  // 1. Valid request with dates
  const test1 = await callApi('1. Valid request with dates (LEAVE_REQUEST)', BASE_URL, 'POST', studentToken, {
    requestType: 'LEAVE',
    description: 'Medical leave for viral fever symptoms',
    startDate: '2026-10-10T00:00:00.000Z',
    endDate: '2026-10-12T00:00:00.000Z',
  });
  const createdRequestId = test1.data?.data?.request?.id || test1.data?.data?.request?._id || test1.data?.data?._id;

  // 2. Valid request without optional dates (GENERAL_REQUEST)
  await callApi('2. Valid request without optional dates (GENERAL_REQUEST)', BASE_URL, 'POST', studentToken, {
    requestType: 'GENERAL_REQUEST',
    title: 'Lab access after hours',
    description: 'Requesting permission to access IoT lab after regular college hours.',
  });

  // 3. Invalid date (Feb 30)
  await callApi('3. Invalid date rejection (Feb 30)', BASE_URL, 'POST', studentToken, {
    requestType: 'LEAVE',
    description: 'Leave request with impossible date',
    startDate: '2026-02-30T00:00:00.000Z',
  });

  // 4. Missing required field (empty description)
  await callApi('4. Missing required field (empty description)', BASE_URL, 'POST', studentToken, {
    requestType: 'LEAVE',
    description: 'ab', // < 3 characters
    startDate: '2026-10-10T00:00:00.000Z',
  });

  // 5. Unauthorized request attempt (Student attempting FACULTY_REQUIREMENT)
  await callApi('5. Unauthorized request attempt (Student -> FACULTY_REQUIREMENT)', BASE_URL, 'POST', studentToken, {
    requestType: 'FACULTY_REQUIREMENT',
    description: 'Student attempting faculty requirement',
  });

  // 6. Successful request with notification
  // The leave request in 1 triggered notification listener. Let's verify notification creation or status:
  await callApi('6. Check student own requests list', `${BASE_URL}/my`, 'GET', studentToken);

  // 7. Request status update (HOD approves request)
  if (createdRequestId) {
    await callApi('7. Request status update (HOD approves)', `${BASE_URL}/${createdRequestId}/status`, 'PATCH', hodToken, {
      status: 'APPROVED',
      remarks: 'Leave approved by HOD.',
    });
  }

  await mongoose.disconnect();
  console.log('\n--- RUNTIME VERIFICATION COMPLETE ---');
}

runRuntimeVerification().catch((err) => {
  console.error('Runtime verification failed:', err);
  process.exit(1);
});
