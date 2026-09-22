import axios from 'axios';

const PROD_URL = 'https://acadex-backend-main.onrender.com/api/v1';

async function verifyAuthAndRoutes() {
  console.log('Testing live Render backend at:', PROD_URL);

  const collegeId = '6aa12468705970d83a966fa7';
  const departmentId = '6aa1262e705970d83a9670d7';
  const password = process.env.QA_USER_PASSWORD || 'Acadex@123456';

  // 1. Authenticate HOD
  console.log('\n--- 1. Authenticating HOD PRABHAKAR ---');
  let hodToken = '';
  try {
    const res = await axios.post(`${PROD_URL}/auth/login`, {
      identifier: 'prabhakar@gmail.com',
      password: password,
    });
    hodToken = res.data.data.accessToken;
    console.log('✅ HOD logged in successfully. Role:', res.data.data.user.role);
    console.log('   HOD Department:', res.data.data.user.departmentId);
  } catch (err: any) {
    console.error('❌ HOD Login failed:', err.response?.data || err.message);
  }

  // 2. Authenticate Faculty A (MOHAN)
  console.log('\n--- 2. Authenticating Faculty A MOHAN ---');
  let facultyAToken = '';
  try {
    const res = await axios.post(`${PROD_URL}/auth/login`, {
      identifier: 'mohan@gmail.com',
      password: password,
    });
    facultyAToken = res.data.data.accessToken;
    console.log('✅ Faculty A logged in successfully. Role:', res.data.data.user.role);
    console.log('   Faculty A Department:', res.data.data.user.departmentId);
  } catch (err: any) {
    console.error('❌ Faculty A Login failed:', err.response?.data || err.message);
  }

  // 3. Authenticate Faculty B (SURESH)
  console.log('\n--- 3. Authenticating Faculty B SURESH ---');
  let facultyBToken = '';
  try {
    const res = await axios.post(`${PROD_URL}/auth/login`, {
      identifier: 'suresh.faculty@gmail.com',
      password: password,
    });
    facultyBToken = res.data.data.accessToken;
    console.log('✅ Faculty B logged in successfully. Role:', res.data.data.user.role, 'Token prefix:', facultyBToken.slice(0, 10));
    console.log('   Faculty B Department:', res.data.data.user.departmentId);
  } catch (err: any) {
    console.error('❌ Faculty B Login failed:', err.response?.data || err.message);
  }

  // 4. Authenticate Student (RAMESH)
  console.log('\n--- 4. Authenticating Student RAMESH ---');
  let studentToken = '';
  try {
    const res = await axios.post(`${PROD_URL}/auth/login`, {
      identifier: 'ramesh.student@gmail.com',
      password: password,
    });
    studentToken = res.data.data.accessToken;
    console.log('✅ Student logged in successfully. Role:', res.data.data.user.role);
    console.log('   Student College:', res.data.data.user.collegeId);
    console.log('   Student Section:', res.data.data.user.sectionId);
  } catch (err: any) {
    console.error('❌ Student Login failed:', err.response?.data || err.message);
  }

  // 5. Test HOD Authorized Reads on deployed routes
  console.log('\n--- 5. Testing HOD Authorized Requests on Live Deployed Routes ---');
  if (hodToken) {
    try {
      const res = await axios.get(`${PROD_URL}/calendar-overrides?collegeId=${collegeId}&departmentId=${departmentId}`, {
        headers: { Authorization: `Bearer ${hodToken}` },
      });
      console.log('✅ GET /calendar-overrides response:', res.status, 'Items:', res.data.data?.length ?? res.data.length);
    } catch (err: any) {
      console.error('❌ GET /calendar-overrides failed:', err.response?.data || err.message);
    }

    try {
      const res = await axios.get(`${PROD_URL}/teacher-substitutions?collegeId=${collegeId}&departmentId=${departmentId}`, {
        headers: { Authorization: `Bearer ${hodToken}` },
      });
      console.log('✅ GET /teacher-substitutions response:', res.status, 'Items:', res.data.data?.length ?? res.data.length);
    } catch (err: any) {
      console.error('❌ GET /teacher-substitutions failed:', err.response?.data || err.message);
    }

    try {
      const res = await axios.get(`${PROD_URL}/timetables`, {
        headers: { Authorization: `Bearer ${hodToken}` },
      });
      console.log('✅ GET /timetables response:', res.status, 'Items:', res.data.data?.length ?? res.data.length);
    } catch (err: any) {
      console.error('❌ GET /timetables failed:', err.response?.data || err.message);
    }
  }

  // 6. Test Faculty Role Rejections (Mutations must return 403 Forbidden)
  console.log('\n--- 6. Testing Faculty Mutation Rejection (Must return 403) ---');
  if (facultyAToken) {
    try {
      await axios.post(
        `${PROD_URL}/calendar-overrides`,
        {
          collegeId,
          departmentId,
          date: '2026-10-02',
          type: 'HOLIDAY',
          scope: 'DEPARTMENT',
          reason: 'Test holiday',
        },
        { headers: { Authorization: `Bearer ${facultyAToken}` } }
      );
      console.error('❌ Faculty override creation was NOT rejected!');
    } catch (err: any) {
      console.log('✅ Faculty override creation correctly rejected with status:', err.response?.status, err.response?.data?.error?.message);
    }

    try {
      await axios.post(
        `${PROD_URL}/teacher-substitutions`,
        {
          collegeId,
          departmentId,
          timetableId: '6ab2c964df6b596004f73dcc',
          timetableEntryId: '6ab2c964df6b596004f73dcd',
          date: '2026-10-02',
          originalFacultyId: '6aa27fb10dc1cf629ec1e29e',
          substituteFacultyId: '6ab2c964df6b596004f73e09',
          reason: 'Medical Leave',
        },
        { headers: { Authorization: `Bearer ${facultyAToken}` } }
      );
      console.error('❌ Faculty substitution creation was NOT rejected!');
    } catch (err: any) {
      console.log('✅ Faculty substitution creation correctly rejected with status:', err.response?.status, err.response?.data?.error?.message);
    }
  }

  // 7. Test Student Role Rejections (Mutations must return 403 Forbidden)
  console.log('\n--- 7. Testing Student Mutation Rejection (Must return 403) ---');
  if (studentToken) {
    try {
      await axios.post(
        `${PROD_URL}/timetables`,
        {
          collegeId,
          departmentId,
          name: 'Unauthorized Student Timetable',
        },
        { headers: { Authorization: `Bearer ${studentToken}` } }
      );
      console.error('❌ Student timetable creation was NOT rejected!');
    } catch (err: any) {
      console.log('✅ Student timetable creation correctly rejected with status:', err.response?.status, err.response?.data?.error?.message);
    }

    try {
      await axios.post(
        `${PROD_URL}/calendar-overrides`,
        {
          collegeId,
          departmentId,
          date: '2026-10-02',
          type: 'HOLIDAY',
          scope: 'DEPARTMENT',
          reason: 'Student holiday',
        },
        { headers: { Authorization: `Bearer ${studentToken}` } }
      );
      console.error('❌ Student override creation was NOT rejected!');
    } catch (err: any) {
      console.log('✅ Student override creation correctly rejected with status:', err.response?.status, err.response?.data?.error?.message);
    }
  }

  console.log('\n--- VERIFICATION COMPLETE ---');
}

verifyAuthAndRoutes().catch(console.error);
