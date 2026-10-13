import mongoose from 'mongoose';
import { User, IUser } from '../../models/user.model';
import { College } from '../../models/college.model';
import { Department } from '../../models/department.model';
import { Faculty } from '../../models/faculty.model';
import { Student } from '../../models/student.model';
import { WorkspaceMembership } from '../../models/workspaceMembership.model';
import { WorkspaceRoleAssignment } from '../../models/workspaceRoleAssignment.model';
import { AuditLog } from '../../models/auditLog.model';
import { AppRole } from '../../constants/roles';
import { AccountStatus, MembershipStatus, RoleAssignmentStatus } from '../../constants/status';
import { logger } from '../../utils/logger';

export interface MigrationAnomaly {
  userId: string;
  instituteId?: string;
  email?: string;
  role?: string;
  collegeId?: string;
  departmentId?: string;
  reason: string;
  details?: Record<string, unknown>;
}

export interface IndexConflict {
  collection: 'Faculty' | 'Student';
  collegeId: string;
  userId: string;
  count: number;
  conflictingIds: string[];
}

export interface DryRunReport {
  runId: string;
  mode: 'DRY_RUN' | 'EXECUTE';
  timestamp: string;
  totalUsersScanned: number;
  classifications: {
    eligibleForMigration: number;
    alreadyMigrated: number;
    superAdminPlatformUsers: number;
    unresolvedAnomalies: number;
  };
  statusBreakdown: Record<string, number>;
  roleBreakdown: Record<string, number>;
  anomalies: MigrationAnomaly[];
  indexConflicts: IndexConflict[];
  safeToMigrate: boolean;
}

export interface ExecutionReport extends DryRunReport {
  createdMembershipsCount: number;
  createdRoleAssignmentsCount: number;
  skippedExistingCount: number;
  failedRecordsCount: number;
  errors: Array<{ userId: string; error: string }>;
}

export class WorkspaceMigrationService {
  /**
   * Maps legacy AccountStatus to canonical MembershipStatus without loss of semantics.
   */
  public static mapAccountStatusToMembershipStatus(status: AccountStatus | string): MembershipStatus | null {
    switch (status) {
      case AccountStatus.ACTIVE:
        return MembershipStatus.ACTIVE;
      case AccountStatus.PENDING_ACTIVATION:
        return MembershipStatus.PENDING;
      case AccountStatus.SUSPENDED:
        return MembershipStatus.SUSPENDED;
      case AccountStatus.DEACTIVATED:
        return MembershipStatus.DEACTIVATED;
      case AccountStatus.INACTIVE:
        return MembershipStatus.INACTIVE;
      default:
        return null;
    }
  }

  /**
   * Maps membership status to initial role assignment status.
   */
  public static mapMembershipStatusToRoleStatus(membershipStatus: MembershipStatus): RoleAssignmentStatus {
    switch (membershipStatus) {
      case MembershipStatus.ACTIVE:
        return RoleAssignmentStatus.ACTIVE;
      case MembershipStatus.PENDING:
        return RoleAssignmentStatus.PENDING;
      case MembershipStatus.SUSPENDED:
        return RoleAssignmentStatus.SUSPENDED;
      case MembershipStatus.REVOKED:
        return RoleAssignmentStatus.REVOKED;
      case MembershipStatus.DEACTIVATED:
      case MembershipStatus.INACTIVE:
      default:
        return RoleAssignmentStatus.INACTIVE;
    }
  }

  /**
   * Pre-flight checks for profile index conflicts prior to migration or index rollout.
   */
  public static async detectProfileDuplicates(): Promise<IndexConflict[]> {
    const conflicts: IndexConflict[] = [];

    // Check Faculty duplicates on { collegeId, userId }
    const facultyDups = await Faculty.aggregate([
      { $match: { collegeId: { $ne: null }, userId: { $ne: null } } },
      {
        $group: {
          _id: { collegeId: '$collegeId', userId: '$userId' },
          count: { $sum: 1 },
          ids: { $push: '$_id' },
        },
      },
      { $match: { count: { $gt: 1 } } },
    ]);

    for (const dup of facultyDups) {
      conflicts.push({
        collection: 'Faculty',
        collegeId: dup._id.collegeId.toString(),
        userId: dup._id.userId.toString(),
        count: dup.count,
        conflictingIds: dup.ids.map((id: any) => id.toString()),
      });
    }

    // Check Student duplicates on { collegeId, userId }
    const studentDups = await Student.aggregate([
      { $match: { collegeId: { $ne: null }, userId: { $ne: null } } },
      {
        $group: {
          _id: { collegeId: '$collegeId', userId: '$userId' },
          count: { $sum: 1 },
          ids: { $push: '$_id' },
        },
      },
      { $match: { count: { $gt: 1 } } },
    ]);

    for (const dup of studentDups) {
      conflicts.push({
        collection: 'Student',
        collegeId: dup._id.collegeId.toString(),
        userId: dup._id.userId.toString(),
        count: dup.count,
        conflictingIds: dup.ids.map((id: any) => id.toString()),
      });
    }

    return conflicts;
  }

  /**
   * Dry Run Analysis: Scans database and identifies all migration classifications and anomalies.
   * STRICTLY READ-ONLY: No modifications to any collection.
   */
  public static async runDryRun(runId: string = `dryrun_${Date.now()}`): Promise<DryRunReport> {
    const users = await User.find({}).lean();
    const anomalies: MigrationAnomaly[] = [];
    const statusBreakdown: Record<string, number> = {};
    const roleBreakdown: Record<string, number> = {};

    let eligibleForMigration = 0;
    let alreadyMigrated = 0;
    let superAdminPlatformUsers = 0;

    for (const user of users) {
      const u = user as unknown as IUser;
      const statusKey = u.accountStatus || 'unknown';
      statusBreakdown[statusKey] = (statusBreakdown[statusKey] || 0) + 1;
      const roleKey = u.role || 'unknown';
      roleBreakdown[roleKey] = (roleBreakdown[roleKey] || 0) + 1;

      // 1. Super Admin is platform authority: never assign standard college membership
      if (u.role === AppRole.SUPER_ADMIN) {
        superAdminPlatformUsers++;
        continue;
      }

      // 2. Validate college reference
      if (!u.collegeId) {
        anomalies.push({
          userId: u._id.toString(),
          instituteId: u.instituteId,
          email: u.email,
          role: u.role,
          reason: 'Non-SuperAdmin user is missing collegeId reference',
        });
        continue;
      }

      const college = await College.findById(u.collegeId).lean();
      if (!college) {
        anomalies.push({
          userId: u._id.toString(),
          instituteId: u.instituteId,
          email: u.email,
          role: u.role,
          collegeId: u.collegeId.toString(),
          reason: 'Referenced college document does not exist',
        });
        continue;
      }

      // 3. Validate department reference for HOD
      if (u.role === AppRole.HOD) {
        if (!u.departmentId) {
          anomalies.push({
            userId: u._id.toString(),
            instituteId: u.instituteId,
            email: u.email,
            role: u.role,
            collegeId: u.collegeId.toString(),
            reason: 'HOD user is missing departmentId reference',
          });
          continue;
        }

        const dept = await Department.findById(u.departmentId).lean();
        if (!dept) {
          anomalies.push({
            userId: u._id.toString(),
            instituteId: u.instituteId,
            email: u.email,
            role: u.role,
            collegeId: u.collegeId.toString(),
            departmentId: u.departmentId.toString(),
            reason: 'HOD department document does not exist',
          });
          continue;
        }

        if (dept.collegeId.toString() !== u.collegeId.toString()) {
          anomalies.push({
            userId: u._id.toString(),
            instituteId: u.instituteId,
            email: u.email,
            role: u.role,
            collegeId: u.collegeId.toString(),
            departmentId: u.departmentId.toString(),
            reason: 'Cross-tenant violation: HOD department belongs to a different college',
          });
          continue;
        }
      }

      // 4. Validate AccountStatus mapping
      const mappedStatus = this.mapAccountStatusToMembershipStatus(u.accountStatus);
      if (!mappedStatus) {
        anomalies.push({
          userId: u._id.toString(),
          instituteId: u.instituteId,
          email: u.email,
          role: u.role,
          reason: `Unrecognized or ambiguous accountStatus "${u.accountStatus}"`,
        });
        continue;
      }

      // 5. Check if already migrated
      const existingMembership = await WorkspaceMembership.findOne({
        userId: u._id,
        collegeId: u.collegeId,
      }).lean();

      if (existingMembership) {
        alreadyMigrated++;
      } else {
        eligibleForMigration++;
      }
    }

    // Check profile duplicates
    const indexConflicts = await this.detectProfileDuplicates();

    return {
      runId,
      mode: 'DRY_RUN',
      timestamp: new Date().toISOString(),
      totalUsersScanned: users.length,
      classifications: {
        eligibleForMigration,
        alreadyMigrated,
        superAdminPlatformUsers,
        unresolvedAnomalies: anomalies.length,
      },
      statusBreakdown,
      roleBreakdown,
      anomalies,
      indexConflicts,
      safeToMigrate: anomalies.length === 0 && indexConflicts.length === 0,
    };
  }

  /**
   * Executes migration with explicit write confirmation and bounded batching.
   * IDEMPOTENT: Safe to run repeatedly or resume after interruption.
   */
  public static async executeMigration(options: {
    runId?: string;
    batchSize?: number;
    allowAnomalies?: boolean;
    actorUserId?: string;
  } = {}): Promise<ExecutionReport> {
    const runId = options.runId || `mig_${Date.now()}`;
    const batchSize = options.batchSize || 100;
    const actorUserId = options.actorUserId || 'system_migration_runner';

    // 1. Run dry-run validation first
    const dryRun = await this.runDryRun(runId);
    if (!dryRun.safeToMigrate && !options.allowAnomalies) {
      throw new Error(
        `Migration aborted: Dry run detected ${dryRun.anomalies.length} anomalies and ${dryRun.indexConflicts.length} index conflicts. Resolve them or pass allowAnomalies: true.`
      );
    }

    let createdMembershipsCount = 0;
    let createdRoleAssignmentsCount = 0;
    let skippedExistingCount = 0;
    let failedRecordsCount = 0;
    const errors: Array<{ userId: string; error: string }> = [];

    // 2. Fetch users in cursor batches
    let skip = 0;
    let hasMore = true;

    while (hasMore) {
      const users = await User.find({})
        .skip(skip)
        .limit(batchSize)
        .sort({ _id: 1 });

      if (users.length === 0) {
        hasMore = false;
        break;
      }

      for (const user of users) {
        // Skip platform SUPER_ADMIN
        if (user.role === AppRole.SUPER_ADMIN) {
          continue;
        }

        // Validate basic college reference
        if (!user.collegeId) {
          continue;
        }

        try {
          const mappedMembershipStatus = this.mapAccountStatusToMembershipStatus(user.accountStatus);
          if (!mappedMembershipStatus) {
            continue; // Skip unrecognized statuses to avoid guessing
          }

          // A. Idempotent WorkspaceMembership creation / lookup
          let membership = await WorkspaceMembership.findOne({
            userId: user._id,
            collegeId: user.collegeId,
          });

          if (!membership) {
            membership = await WorkspaceMembership.create({
              userId: user._id,
              collegeId: user.collegeId,
              status: mappedMembershipStatus,
              isDefault: true,
              joinedAt: (user as any).createdAt || new Date(),
              statusReason: 'Backfilled via WorkspaceMigrationService',
              metadata: {
                migrationRunId: runId,
                source: 'legacy_backfill',
                legacyAccountStatus: user.accountStatus,
              },
              createdBy: actorUserId,
            });
            createdMembershipsCount++;

            // Audit Log
            await AuditLog.create({
              collegeId: user.collegeId.toString(),
              workspaceMembershipId: membership.id,
              actorUserId,
              action: 'MIGRATION_MEMBERSHIP_BACKFILLED',
              entityType: 'WorkspaceMembership',
              entityId: membership.id,
              newValue: {
                userId: user.id,
                collegeId: user.collegeId.toString(),
                status: membership.status,
                migrationRunId: runId,
              },
            }).catch((err) => logger.warn(`Migration audit log failed: ${err.message}`));
          } else {
            // Already exists - DO NOT overwrite status or reactivate suspended/revoked
            skippedExistingCount++;
          }

          // B. Idempotent WorkspaceRoleAssignment creation
          const initialRoleStatus = this.mapMembershipStatusToRoleStatus(membership.status);
          const deptObjectId = user.departmentId ? new mongoose.Types.ObjectId(user.departmentId) : null;

          const existingRole = await WorkspaceRoleAssignment.findOne({
            membershipId: membership._id,
            role: user.role,
            departmentId: deptObjectId,
          });

          if (!existingRole) {
            const roleAssignment = await WorkspaceRoleAssignment.create({
              membershipId: membership._id,
              userId: user._id,
              collegeId: user.collegeId,
              role: user.role,
              departmentId: deptObjectId,
              status: initialRoleStatus,
              assignedAt: (user as any).createdAt || new Date(),
              assignedBy: actorUserId,
              statusReason: 'Backfilled via WorkspaceMigrationService',
              scope: {
                migrationRunId: runId,
                source: 'legacy_backfill',
              },
            });
            createdRoleAssignmentsCount++;

            // Audit Log
            await AuditLog.create({
              collegeId: user.collegeId.toString(),
              workspaceMembershipId: membership.id,
              departmentId: deptObjectId ? deptObjectId.toString() : undefined,
              actorUserId,
              action: 'MIGRATION_ROLE_ASSIGNED',
              entityType: 'WorkspaceRoleAssignment',
              entityId: roleAssignment.id,
              newValue: {
                membershipId: membership.id,
                userId: user.id,
                role: user.role,
                status: roleAssignment.status,
                migrationRunId: runId,
              },
            }).catch((err) => logger.warn(`Migration audit log failed: ${err.message}`));
          }
        } catch (recordError: any) {
          failedRecordsCount++;
          errors.push({
            userId: user.id,
            error: recordError.message,
          });
          logger.error(`Migration error for user ${user.id}: ${recordError.message}`);
        }
      }

      skip += batchSize;
      if (users.length < batchSize) {
        hasMore = false;
      }
    }

    return {
      ...dryRun,
      mode: 'EXECUTE',
      timestamp: new Date().toISOString(),
      createdMembershipsCount,
      createdRoleAssignmentsCount,
      skippedExistingCount,
      failedRecordsCount,
      errors,
    };
  }

  /**
   * Safe Rollback for a specific migration run:
   * Only deletes records tagged with metadata.migrationRunId matching runId
   * and source === 'legacy_backfill', avoiding post-migration real user actions.
   */
  public static async rollbackMigrationRun(runId: string): Promise<{
    deletedRoleAssignments: number;
    deletedMemberships: number;
  }> {
    if (!runId || runId.trim() === '') {
      throw new Error('runId is required for safe rollback');
    }

    const deletedRoleAssignments = await WorkspaceRoleAssignment.deleteMany({
      'scope.migrationRunId': runId,
      'scope.source': 'legacy_backfill',
    });

    const deletedMemberships = await WorkspaceMembership.deleteMany({
      'metadata.migrationRunId': runId,
      'metadata.source': 'legacy_backfill',
    });

    logger.info(
      `Rollback completed for runId ${runId}: ${deletedMemberships.deletedCount} memberships, ${deletedRoleAssignments.deletedCount} roles deleted.`
    );

    return {
      deletedRoleAssignments: deletedRoleAssignments.deletedCount || 0,
      deletedMemberships: deletedMemberships.deletedCount || 0,
    };
  }

  /**
   * Read-only Index Preflight Inspection:
   * Inspects existing indexes, compound uniqueness requirements, and duplicate conflicts
   * without dropping or creating production indexes.
   */
  public static async runIndexPreflight(): Promise<{
    timestamp: string;
    databaseName?: string;
    collections: {
      faculty: {
        existingIndexes: Array<{ name: string; key: Record<string, any>; unique?: boolean }>;
        hasGlobalUniqueUserIdIndex: boolean;
        hasCompoundCollegeUserIdIndex: boolean;
        duplicateCount: number;
        duplicateSample: Array<{ collegeId: string; userId: string; count: number }>;
      };
      student: {
        existingIndexes: Array<{ name: string; key: Record<string, any>; unique?: boolean }>;
        hasGlobalUniqueUserIdIndex: boolean;
        hasCompoundCollegeUserIdIndex: boolean;
        duplicateCount: number;
        duplicateSample: Array<{ collegeId: string; userId: string; count: number }>;
      };
      workspaceMembership: {
        existingIndexes: Array<{ name: string; key: Record<string, any>; unique?: boolean }>;
        hasCompoundUniqueness: boolean;
        conflictCount: number;
      };
      workspaceRoleAssignment: {
        existingIndexes: Array<{ name: string; key: Record<string, any>; unique?: boolean }>;
        hasCompoundUniqueness: boolean;
        conflictCount: number;
      };
    };
    canSafelyApplyIndexes: boolean;
    blockers: string[];
    recommendations: string[];
  }> {
    const blockers: string[] = [];
    const recommendations: string[] = [];

    const getIndexes = async (model: mongoose.Model<any>) => {
      try {
        return await model.collection.indexes();
      } catch {
        return [];
      }
    };

    const facultyIndexes = await getIndexes(Faculty);
    const studentIndexes = await getIndexes(Student);
    const membershipIndexes = await getIndexes(WorkspaceMembership);
    const roleAssignmentIndexes = await getIndexes(WorkspaceRoleAssignment);

    const facultyGlobalUnique = facultyIndexes.some(
      (idx) => idx.key.userId === 1 && Object.keys(idx.key).length === 1 && idx.unique === true
    );
    const facultyCompound = facultyIndexes.some(
      (idx) => idx.key.collegeId === 1 && idx.key.userId === 1 && idx.unique === true
    );

    const studentGlobalUnique = studentIndexes.some(
      (idx) => idx.key.userId === 1 && Object.keys(idx.key).length === 1 && idx.unique === true
    );
    const studentCompound = studentIndexes.some(
      (idx) => idx.key.collegeId === 1 && idx.key.userId === 1 && idx.unique === true
    );

    const membershipCompound = membershipIndexes.some(
      (idx) =>
        (idx.key.userId === 1 && idx.key.collegeId === 1) ||
        (idx.key.collegeId === 1 && idx.key.userId === 1)
    );

    const roleCompound = roleAssignmentIndexes.some(
      (idx) => idx.key.membershipId === 1 && idx.key.role === 1
    );

    const facultyDups = await Faculty.aggregate([
      { $match: { collegeId: { $ne: null }, userId: { $ne: null } } },
      {
        $group: {
          _id: { collegeId: '$collegeId', userId: '$userId' },
          count: { $sum: 1 },
        },
      },
      { $match: { count: { $gt: 1 } } },
    ]);

    const studentDups = await Student.aggregate([
      { $match: { collegeId: { $ne: null }, userId: { $ne: null } } },
      {
        $group: {
          _id: { collegeId: '$collegeId', userId: '$userId' },
          count: { $sum: 1 },
        },
      },
      { $match: { count: { $gt: 1 } } },
    ]);

    const membershipDups = await WorkspaceMembership.aggregate([
      { $match: { collegeId: { $ne: null }, userId: { $ne: null } } },
      {
        $group: {
          _id: { collegeId: '$collegeId', userId: '$userId' },
          count: { $sum: 1 },
        },
      },
      { $match: { count: { $gt: 1 } } },
    ]);

    const roleDups = await WorkspaceRoleAssignment.aggregate([
      { $match: { membershipId: { $ne: null }, role: { $ne: null } } },
      {
        $group: {
          _id: { membershipId: '$membershipId', role: '$role', departmentId: '$departmentId' },
          count: { $sum: 1 },
        },
      },
      { $match: { count: { $gt: 1 } } },
    ]);

    if (facultyGlobalUnique) {
      recommendations.push(
        'Legacy unique index on Faculty.userId exists. In production, drop after compound {collegeId: 1, userId: 1} is validated.'
      );
    }
    if (studentGlobalUnique) {
      recommendations.push(
        'Legacy unique index on Student.userId exists. In production, drop after compound {collegeId: 1, userId: 1} is validated.'
      );
    }

    if (facultyDups.length > 0) {
      blockers.push(`Found ${facultyDups.length} duplicate (collegeId, userId) records in Faculty collection.`);
    }
    if (studentDups.length > 0) {
      blockers.push(`Found ${studentDups.length} duplicate (collegeId, userId) records in Student collection.`);
    }
    if (membershipDups.length > 0) {
      blockers.push(`Found ${membershipDups.length} duplicate (collegeId, userId) records in WorkspaceMembership collection.`);
    }
    if (roleDups.length > 0) {
      blockers.push(`Found ${roleDups.length} duplicate role assignments in WorkspaceRoleAssignment collection.`);
    }

    return {
      timestamp: new Date().toISOString(),
      databaseName: mongoose.connection.db?.databaseName,
      collections: {
        faculty: {
          existingIndexes: facultyIndexes.map((i) => ({ name: i.name || 'unnamed', key: i.key, unique: i.unique })),
          hasGlobalUniqueUserIdIndex: facultyGlobalUnique,
          hasCompoundCollegeUserIdIndex: facultyCompound,
          duplicateCount: facultyDups.length,
          duplicateSample: facultyDups.slice(0, 5).map((d) => ({
            collegeId: d._id.collegeId.toString(),
            userId: d._id.userId.toString(),
            count: d.count,
          })),
        },
        student: {
          existingIndexes: studentIndexes.map((i) => ({ name: i.name || 'unnamed', key: i.key, unique: i.unique })),
          hasGlobalUniqueUserIdIndex: studentGlobalUnique,
          hasCompoundCollegeUserIdIndex: studentCompound,
          duplicateCount: studentDups.length,
          duplicateSample: studentDups.slice(0, 5).map((d) => ({
            collegeId: d._id.collegeId.toString(),
            userId: d._id.userId.toString(),
            count: d.count,
          })),
        },
        workspaceMembership: {
          existingIndexes: membershipIndexes.map((i) => ({ name: i.name || 'unnamed', key: i.key, unique: i.unique })),
          hasCompoundUniqueness: membershipCompound,
          conflictCount: membershipDups.length,
        },
        workspaceRoleAssignment: {
          existingIndexes: roleAssignmentIndexes.map((i) => ({ name: i.name || 'unnamed', key: i.key, unique: i.unique })),
          hasCompoundUniqueness: roleCompound,
          conflictCount: roleDups.length,
        },
      },
      canSafelyApplyIndexes: blockers.length === 0,
      blockers,
      recommendations,
    };
  }
}
