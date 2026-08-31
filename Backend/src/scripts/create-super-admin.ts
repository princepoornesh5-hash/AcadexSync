import 'dotenv/config';
import { User } from '../models/user.model';
import { PasswordService } from '../services/password.service';
import { AppRole } from '../constants/roles';
import { AccountStatus } from '../constants/status';
import { connectDB, disconnectDB } from '../db/connection';

async function main() {
  const email = (process.env.SUPER_ADMIN_EMAIL || 'princepoornesh5@gmail.com').trim().toLowerCase();
  const password = process.env.SUPER_ADMIN_PASSWORD || 'Poornesh@8686';
  const name = process.env.SUPER_ADMIN_NAME || 'Poornesh';
  const instituteId = process.env.SUPER_ADMIN_PIN || 'ADM-001';

  await connectDB();

  const existing = await User.findOne({ email });

  const passwordHash = await PasswordService.hashPassword(password);

  if (existing) {
    existing.name = name;
    existing.role = AppRole.SUPER_ADMIN;
    existing.passwordHash = passwordHash;
    existing.accountStatus = AccountStatus.ACTIVE;
    existing.activationStatus = 'activated';
    if (!existing.instituteId) existing.instituteId = instituteId;
    await existing.save();

    console.log('');
    console.log('========================================');
    console.log('SUPER ADMIN CREDENTIALS UPDATED');
    console.log('========================================');
    console.log(`Email: ${existing.email}`);
    console.log(`Role: ${existing.role}`);
    console.log(`User ID: ${existing.id}`);
    console.log(`Institute ID: ${existing.instituteId}`);
    console.log(`Account Status: ${existing.accountStatus}`);
    console.log('========================================');
    console.log('');
    await disconnectDB();
    return;
  }

  const user = await User.create({
    name,
    email,
    instituteId,
    role: AppRole.SUPER_ADMIN,
    passwordHash,
    accountStatus: AccountStatus.ACTIVE,
    activationStatus: 'activated',
    collegeId: null,
    departmentId: null,
    courseId: null,
    sectionId: null,
    semesterId: null,
  });

  console.log('');
  console.log('========================================');
  console.log('SUPER ADMIN CREATED SUCCESSFULLY');
  console.log('========================================');
  console.log(`Email: ${user.email}`);
  console.log(`Role: ${user.role}`);
  console.log(`User ID: ${user.id}`);
  console.log(`Institute ID: ${user.instituteId}`);
  console.log(`Account Status: ${user.accountStatus}`);
  console.log('========================================');
  console.log('');

  await disconnectDB();
}

main().catch(async (error) => {
  console.error('Failed to create Super Admin:', error);

  try {
    await disconnectDB();
  } catch { }

  process.exit(1);
});
