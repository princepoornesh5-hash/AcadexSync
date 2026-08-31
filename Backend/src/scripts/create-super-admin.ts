import 'dotenv/config';
import { User } from '../models/user.model';
import { PasswordService } from '../services/password.service';
import { AppRole } from '../constants/roles';
import { AccountStatus } from '../constants/status';
import { connectDB, disconnectDB } from '../db/connection';

async function main() {
  const email = 'princepoornesh5@gmail.com';
  const password = 'Poornesh@8686';

  await connectDB();

  const existing = await User.findOne({ email });

  if (existing) {
    console.log(`User already exists: ${email}`);
    console.log(`Role: ${existing.role}`);
    await disconnectDB();
    return;
  }

  const passwordHash = await PasswordService.hashPassword(password);

  const user = await User.create({
    name: 'Poornesh',
    email,
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
  console.log('College: None');
  console.log('Institute ID: None');
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
