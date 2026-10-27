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
import { AccountStatus, MembershipStatus, RoleAssignmentStatus, MembershipType } from '../../constants/status';
import { logger } from '../../utils/logger';

export interface MigrationAnomaly {
  userId?: string;
  membershipId?: string;
  roleAssignmentId?: string;
  profileId?: string;
  instituteId?: string;
  email?: string;
  role?: string;
  collegeId?: string;
  departmentId?: string;
  category:
    | 'MISSING_COLLEGE'
    | 'MISSING_PIN'
    | 'CONFLICTING_PIN'
    | 'ORPHAN_REFERENCE'
    | 'CROSS_TENANT_MISMATCH'
    | 'STATUS_CONFLICT'
    | 'INVALID_DATE'
    | 'PROFILE_UNMAPPABLE'
    | 'MANUAL_RESOLUTION_REQUIRED';
  reason: string;
  requiresManualResolution: boolean;
  details?: Record<string, unknown>;
}

export interface IndexConflict {
  collection: 'Faculty' | 'Student' | 'WorkspaceMembership' | 'WorkspaceRoleAssignment' | 'User';
  indexKey?: Record<string, number>;
  collegeId?: string;
  userId?: string;
  instituteId?: string;
  count: number;
  conflictingIds: string[];
  reason: string;
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
        indexKey: { collegeId: 1, userId: 1 },
        collegeId: dup._id.collegeId.toString(),
        userId: dup._id.userId.toString(),
        count: dup.count,
        conflictingIds: dup.ids.map((id: any) => id.toString()),
        reason: 'Multiple Faculty profile records found for the same user in the same college.',
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
        indexKey: { collegeId: 1, userId: 1 },
        collegeId: dup._id.collegeId.toString(),
        userId: dup._id.userId.toString(),
        count: dup.count,
        conflictingIds: dup.ids.map((id: any) => id.toString()),
        reason: 'Multiple Student profile records found for the same user in the same college.',
      });
    }

    return conflicts;
  }

  /**
   * Detects duplicate institutional PIN numbers within the same college across
   * WorkspaceMembership and legacy User models to prevent compound index collision.
   */
  public static async detectPinDuplicates(): Promise<{
    conflicts: IndexConflict[];
    anomalies: MigrationAnomaly[];
  }> {
    const conflicts: IndexConflict[] = [];
    const anomalies: MigrationAnomaly[] = [];

    // 1. Check duplicate PINs in WorkspaceMembership on { collegeId, instituteId }
    const membershipPinDups = await WorkspaceMembership.aggregate([
      {
        $match: {
          collegeId: { $ne: null },
          instituteId: { $ne: null, $nin: ['', null] },
        },
      },
      {
        $group: {
          _id: { collegeId: '$collegeId', instituteId: '$instituteId' },
          count: { $sum: 1 },
          membershipIds: { $push: '$_id' },
          userIds: { $push: '$userId' },
        },
      },
      { $match: { count: { $gt: 1 } } },
    ]);

    for (const dup of membershipPinDups) {
      const collegeIdStr = dup._id.collegeId.toString();
      const pinStr = dup._id.instituteId.toString();
      conflicts.push({
        collection: 'WorkspaceMembership',
        indexKey: { collegeId: 1, instituteId: 1 },
        collegeId: collegeIdStr,
        instituteId: pinStr,
        count: dup.count,
        conflictingIds: dup.membershipIds.map((id: any) => id.toString()),
        reason: `Duplicate PIN Number "${pinStr}" in WorkspaceMembership for college ${collegeIdStr}`,
      });

      anomalies.push({
        collegeId: collegeIdStr,
        instituteId: pinStr,
        category: 'CONFLICTING_PIN',
        reason: `Duplicate institutional PIN Number "${pinStr}" found across ${dup.count} memberships in college ${collegeIdStr}`,
        requiresManualResolution: true,
        details: {
          conflictingMembershipIds: dup.membershipIds.map((id: any) => id.toString()),
          conflictingUserIds: dup.userIds.map((id: any) => id.toString()),
        },
      });
    }

    // 2. Check duplicate PINs in User collection for the same collegeId
    const userPinDups = await User.aggregate([
      {
        $match: {
          collegeId: { $ne: null },
          instituteId: { $ne: null, $nin: ['', null] },
          role: { $ne: AppRole.SUPER_ADMIN },
        },
      },
      {
        $group: {
          _id: { collegeId: '$collegeId', instituteId: '$instituteId' },
          count: { $sum: 1 },
          userIds: { $push: '$_id' },
        },
      },
      { $match: { count: { $gt: 1 } } },
    ]);

    for (const dup of userPinDups) {
      const collegeIdStr = dup._id.collegeId.toString();
      const pinStr = dup._id.instituteId.toString();
      conflicts.push({
        collection: 'User',
        indexKey: { collegeId: 1, instituteId: 1 },
        collegeId: collegeIdStr,
        instituteId: pinStr,
        count: dup.count,
        conflictingIds: dup.userIds.map((id: any) => id.toString()),
        reason: `Duplicate PIN Number "${pinStr}" in legacy User records for college ${collegeIdStr}`,
      });

      anomalies.push({
        collegeId: collegeIdStr,
        instituteId: pinStr,
        category: 'CONFLICTING_PIN',
        reason: `Duplicate institutional PIN Number "${pinStr}" found across ${dup.count} users in college ${collegeIdStr}`,
        requiresManualResolution: true,
        details: {
          conflictingUserIds: dup.userIds.map((id: any) => id.toString()),
        },
      });
    }

    return { conflicts, anomalies };
  }

  /**
   * Scans for orphaned references and cross-tenant mismatches in memberships, roles, and profiles.
   */
  public static async detectOrphanedReferences(): Promise<MigrationAnomaly[]> {
    const anomalies: MigrationAnomaly[] = [];

    // A. Check orphaned WorkspaceMembership records
    const memberships = await WorkspaceMembership.find({}).lean();
    for (const m of memberships) {
      const userExists = await User.exists({ _id: m.userId });
      if (!userExists) {
        anomalies.push({
          membershipId: m._id.toString(),
          userId: m.userId.toString(),
          collegeId: m.collegeId?.toString(),
          category: 'ORPHAN_REFERENCE',
          reason: `WorkspaceMembership references non-existent User ${m.userId}`,
          requiresManualResolution: true,
        });
      }

      const collegeExists = await College.exists({ _id: m.collegeId });
      if (!collegeExists) {
        anomalies.push({
          membershipId: m._id.toString(),
          userId: m.userId?.toString(),
          collegeId: m.collegeId.toString(),
          category: 'ORPHAN_REFERENCE',
          reason: `WorkspaceMembership references non-existent College ${m.collegeId}`,
          requiresManualResolution: true,
        });
      }
    }

    // B. Check orphaned WorkspaceRoleAssignment records
    const roleAssignments = await WorkspaceRoleAssignment.find({}).lean();
    for (const r of roleAssignments) {
      const membershipExists = await WorkspaceMembership.exists({ _id: r.membershipId });
      if (!membershipExists) {
        anomalies.push({
          roleAssignmentId: r._id.toString(),
          membershipId: r.membershipId.toString(),
          userId: r.userId?.toString(),
          collegeId: r.collegeId?.toString(),
          category: 'ORPHAN_REFERENCE',
          reason: `WorkspaceRoleAssignment references non-existent WorkspaceMembership ${r.membershipId}`,
          requiresManualResolution: true,
        });
      }

      const userExists = await User.exists({ _id: r.userId });
      if (!userExists) {
        anomalies.push({
          roleAssignmentId: r._id.toString(),
          userId: r.userId.toString(),
          collegeId: r.collegeId?.toString(),
          category: 'ORPHAN_REFERENCE',
          reason: `WorkspaceRoleAssignment references non-existent User ${r.userId}`,
          requiresManualResolution: true,
        });
      }

      const collegeExists = await College.exists({ _id: r.collegeId });
      if (!collegeExists) {
        anomalies.push({
          roleAssignmentId: r._id.toString(),
          collegeId: r.collegeId.toString(),
          category: 'ORPHAN_REFERENCE',
          reason: `WorkspaceRoleAssignment references non-existent College ${r.collegeId}`,
          requiresManualResolution: true,
        });
      }
    }

    // C. Check Faculty profile tenant integrity
    const facultyProfiles = await Faculty.find({}).lean();
    for (const f of facultyProfiles) {
      const user = await User.findById(f.userId).lean();
      if (!user) {
        anomalies.push({
          profileId: f._id.toString(),
          userId: f.userId?.toString(),
          collegeId: f.collegeId?.toString(),
          category: 'PROFILE_UNMAPPABLE',
          reason: `Faculty profile references non-existent User ${f.userId}`,
          requiresManualResolution: true,
        });
        continue;
      }

      const collegeExists = await College.exists({ _id: f.collegeId });
      if (!collegeExists) {
        anomalies.push({
          profileId: f._id.toString(),
          userId: f.userId.toString(),
          collegeId: f.collegeId?.toString(),
          category: 'PROFILE_UNMAPPABLE',
          reason: `Faculty profile references non-existent College ${f.collegeId}`,
          requiresManualResolution: true,
        });
        continue;
      }

      // If user has scalar collegeId that differs from faculty profile collegeId, verify membership exists
      if (user.collegeId && user.collegeId.toString() !== f.collegeId.toString()) {
        const membership = await WorkspaceMembership.findOne({
          userId: f.userId,
          collegeId: f.collegeId,
        }).lean();
        if (!membership) {
          anomalies.push({
            profileId: f._id.toString(),
            userId: f.userId.toString(),
            collegeId: f.collegeId.toString(),
            category: 'CROSS_TENANT_MISMATCH',
            reason: `Faculty profile belongs to College ${f.collegeId}, but User primary collegeId is ${user.collegeId} with no corresponding membership`,
            requiresManualResolution: true,
          });
        }
      }
    }

    // D. Check Student profile tenant integrity
    const studentProfiles = await Student.find({}).lean();
    for (const s of studentProfiles) {
      const user = await User.findById(s.userId).lean();
      if (!user) {
        anomalies.push({
          profileId: s._id.toString(),
          userId: s.userId?.toString(),
          collegeId: s.collegeId?.toString(),
          category: 'PROFILE_UNMAPPABLE',
          reason: `Student profile references non-existent User ${s.userId}`,
          requiresManualResolution: true,
        });
        continue;
      }

      const collegeExists = await College.exists({ _id: s.collegeId });
      if (!collegeExists) {
        anomalies.push({
          profileId: s._id.toString(),
          userId: s.userId.toString(),
          collegeId: s.collegeId?.toString(),
          category: 'PROFILE_UNMAPPABLE',
          reason: `Student profile references non-existent College ${s.collegeId}`,
          requiresManualResolution: true,
        });
        continue;
      }

      // Check cross-tenant profile mapping
      if (user.collegeId && user.collegeId.toString() !== s.collegeId.toString()) {
        const membership = await WorkspaceMembership.findOne({
          userId: s.userId,
          collegeId: s.collegeId,
        }).lean();
        if (!membership) {
          anomalies.push({
            profileId: s._id.toString(),
            userId: s.userId.toString(),
            collegeId: s.collegeId.toString(),
            category: 'CROSS_TENANT_MISMATCH',
            reason: `Student profile belongs to College ${s.collegeId}, but User primary collegeId is ${user.collegeId} with no corresponding membership`,
            requiresManualResolution: true,
          });
        }
      }
    }

    return anomalies;
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
          category: 'MISSING_COLLEGE',
          reason: 'Non-SuperAdmin user is missing collegeId reference',
          requiresManualResolution: true,
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
          category: 'ORPHAN_REFERENCE',
          reason: 'Referenced college document does not exist',
          requiresManualResolution: true,
        });
        continue;
      }

      // 3. Validate institutional PIN Number presence
      if (!u.instituteId || u.instituteId.trim() === '') {
        anomalies.push({
          userId: u._id.toString(),
          email: u.email,
          role: u.role,
          collegeId: u.collegeId.toString(),
          category: 'MISSING_PIN',
          reason: 'User record is missing institutional PIN Number (instituteId)',
          requiresManualResolution: true,
        });
      }

      // 4. Validate department reference for HOD
      if (u.role === AppRole.HOD) {
        if (!u.departmentId) {
          anomalies.push({
            userId: u._id.toString(),
            instituteId: u.instituteId,
            email: u.email,
            role: u.role,
            collegeId: u.collegeId.toString(),
            category: 'ORPHAN_REFERENCE',
            reason: 'HOD user is missing departmentId reference',
            requiresManualResolution: true,
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
            category: 'ORPHAN_REFERENCE',
            reason: 'HOD department document does not exist',
            requiresManualResolution: true,
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
            category: 'CROSS_TENANT_MISMATCH',
            reason: 'Cross-tenant violation: HOD department belongs to a different college',
            requiresManualResolution: true,
          });
          continue;
        }
      }

      // 5. Validate AccountStatus mapping
      const mappedStatus = this.mapAccountStatusToMembershipStatus(u.accountStatus);
      if (!mappedStatus) {
        anomalies.push({
          userId: u._id.toString(),
          instituteId: u.instituteId,
          email: u.email,
          role: u.role,
          category: 'MANUAL_RESOLUTION_REQUIRED',
          reason: `Unrecognized or ambiguous accountStatus "${u.accountStatus}"`,
          requiresManualResolution: true,
        });
        continue;
      }

      // 6. Check existing membership and scalar identity consistency
      const existingMembership = await WorkspaceMembership.findOne({
        userId: u._id,
        collegeId: u.collegeId,
      }).lean();

      if (existingMembership) {
        alreadyMigrated++;

        // Verify PIN Number consistency if both are set
        if (
          existingMembership.instituteId &&
          u.instituteId &&
          existingMembership.instituteId.trim().toUpperCase() !== u.instituteId.trim().toUpperCase()
        ) {
          anomalies.push({
            userId: u._id.toString(),
            membershipId: existingMembership._id.toString(),
            instituteId: u.instituteId,
            collegeId: u.collegeId.toString(),
            category: 'CONFLICTING_PIN',
            reason: `PIN Number mismatch: User.instituteId "${u.instituteId}" conflicts with WorkspaceMembership.instituteId "${existingMembership.instituteId}"`,
            requiresManualResolution: true,
            details: {
              userInstituteId: u.instituteId,
              membershipInstituteId: existingMembership.instituteId,
            },
          });
        }

        // Verify status consistency
        if (
          (u.accountStatus === AccountStatus.DEACTIVATED && existingMembership.status === MembershipStatus.ACTIVE) ||
          (u.accountStatus === AccountStatus.ACTIVE && existingMembership.status === MembershipStatus.DEACTIVATED)
        ) {
          anomalies.push({
            userId: u._id.toString(),
            membershipId: existingMembership._id.toString(),
            collegeId: u.collegeId.toString(),
            category: 'STATUS_CONFLICT',
            reason: `Account status conflict: User is "${u.accountStatus}" but WorkspaceMembership is "${existingMembership.status}"`,
            requiresManualResolution: true,
          });
        }

        // Verify date integrity
        if (
          existingMembership.effectiveEndDate &&
          existingMembership.effectiveStartDate &&
          new Date(existingMembership.effectiveStartDate).getTime() > new Date(existingMembership.effectiveEndDate).getTime()
        ) {
          anomalies.push({
            userId: u._id.toString(),
            membershipId: existingMembership._id.toString(),
            collegeId: u.collegeId.toString(),
            category: 'INVALID_DATE',
            reason: 'Membership effectiveStartDate is later than effectiveEndDate',
            requiresManualResolution: true,
          });
        }
      } else {
        eligibleForMigration++;
      }
    }

    // 7. Detect PIN duplicate conflicts
    const { conflicts: pinConflicts, anomalies: pinAnomalies } = await this.detectPinDuplicates();
    anomalies.push(...pinAnomalies);

    // 8. Detect profile duplicates and orphaned references
    const profileConflicts = await this.detectProfileDuplicates();
    const orphanAnomalies = await this.detectOrphanedReferences();
    anomalies.push(...orphanAnomalies);

    const allIndexConflicts = [...pinConflicts, ...profileConflicts];
    const unresolvedAnomaliesCount = anomalies.filter((a) => a.requiresManualResolution).length;

    return {
      runId,
      mode: 'DRY_RUN',
      timestamp: new Date().toISOString(),
      totalUsersScanned: users.length,
      classifications: {
        eligibleForMigration,
        alreadyMigrated,
        superAdminPlatformUsers,
        unresolvedAnomalies: unresolvedAnomaliesCount,
      },
      statusBreakdown,
      roleBreakdown,
      anomalies,
      indexConflicts: allIndexConflicts,
      safeToMigrate: unresolvedAnomaliesCount === 0 && allIndexConflicts.length === 0,
    };
  }

  /**
   * Helper to derive canonical MembershipType from legacy AppRole.
   */
  public static mapRoleToMemberType(role: AppRole | string): MembershipType {
    if (role === AppRole.STUDENT) {
      return MembershipType.STUDENT;
    }
    if (role === AppRole.COLLEGE_ADMIN) {
      return MembershipType.ADMINISTRATOR;
    }
    return MembershipType.FACULTY;
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

          const memberType = this.mapRoleToMemberType(user.role);
          const effectiveStartDate = (user as any).createdAt || new Date();

          // A. Idempotent WorkspaceMembership creation / backfill
          let membership = await WorkspaceMembership.findOne({
            userId: user._id,
            collegeId: user.collegeId,
          });

          if (!membership) {
            membership = await WorkspaceMembership.create({
              userId: user._id,
              collegeId: user.collegeId,
              instituteId: user.instituteId ? user.instituteId.trim().toUpperCase() : null,
              memberType,
              status: mappedMembershipStatus,
              isDefault: true,
              joinedAt: (user as any).createdAt || new Date(),
              effectiveStartDate,
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
                instituteId: membership.instituteId,
                memberType: membership.memberType,
                status: membership.status,
                migrationRunId: runId,
              },
            }).catch((err) => logger.warn(`Migration audit log failed: ${err.message}`));
          } else {
            // Already exists - safely backfill instituteId or memberType if missing
            let updated = false;
            if (!membership.instituteId && user.instituteId) {
              membership.instituteId = user.instituteId.trim().toUpperCase();
              updated = true;
            }
            if (!membership.memberType) {
              membership.memberType = memberType;
              updated = true;
            }
            if (!membership.effectiveStartDate) {
              membership.effectiveStartDate = effectiveStartDate;
              updated = true;
            }
            if (updated) {
              await membership.save();
            }
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
              effectiveStartDate,
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
        hasCompoundCollegeUserUniqueness: boolean;
        hasCompoundCollegePinUniqueness: boolean;
        userDuplicateCount: number;
        pinDuplicateCount: number;
        pinDuplicateSample: Array<{ collegeId: string; instituteId: string; count: number }>;
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

    const membershipUserCompound = membershipIndexes.some(
      (idx) =>
        (idx.key.userId === 1 && idx.key.collegeId === 1) ||
        (idx.key.collegeId === 1 && idx.key.userId === 1)
    );

    const membershipPinCompound = membershipIndexes.some(
      (idx) =>
        (idx.key.collegeId === 1 && idx.key.instituteId === 1) ||
        (idx.key.instituteId === 1 && idx.key.collegeId === 1)
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

    const membershipUserDups = await WorkspaceMembership.aggregate([
      { $match: { collegeId: { $ne: null }, userId: { $ne: null } } },
      {
        $group: {
          _id: { collegeId: '$collegeId', userId: '$userId' },
          count: { $sum: 1 },
        },
      },
      { $match: { count: { $gt: 1 } } },
    ]);

    const membershipPinDups = await WorkspaceMembership.aggregate([
      {
        $match: {
          collegeId: { $ne: null },
          instituteId: { $ne: null, $nin: ['', null] },
        },
      },
      {
        $group: {
          _id: { collegeId: '$collegeId', instituteId: '$instituteId' },
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
    if (!membershipPinCompound) {
      recommendations.push(
        'Compound index on WorkspaceMembership {collegeId: 1, instituteId: 1} is pending initialization.'
      );
    }

    if (facultyDups.length > 0) {
      blockers.push(`Found ${facultyDups.length} duplicate (collegeId, userId) records in Faculty collection.`);
    }
    if (studentDups.length > 0) {
      blockers.push(`Found ${studentDups.length} duplicate (collegeId, userId) records in Student collection.`);
    }
    if (membershipUserDups.length > 0) {
      blockers.push(`Found ${membershipUserDups.length} duplicate (collegeId, userId) records in WorkspaceMembership collection.`);
    }
    if (membershipPinDups.length > 0) {
      blockers.push(`Found ${membershipPinDups.length} duplicate (collegeId, instituteId) PIN records in WorkspaceMembership collection.`);
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
          hasCompoundCollegeUserUniqueness: membershipUserCompound,
          hasCompoundCollegePinUniqueness: membershipPinCompound,
          userDuplicateCount: membershipUserDups.length,
          pinDuplicateCount: membershipPinDups.length,
          pinDuplicateSample: membershipPinDups.slice(0, 5).map((d) => ({
            collegeId: d._id.collegeId.toString(),
            instituteId: d._id.instituteId.toString(),
            count: d.count,
          })),
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
