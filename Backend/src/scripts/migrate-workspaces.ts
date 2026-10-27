import 'dotenv/config';
import { connectDB, disconnectDB } from '../db/connection';
import { WorkspaceMigrationService } from '../services/migration/workspaceMigration.service';
import { logger } from '../utils/logger';

async function main() {
  const args = process.argv.slice(2);
  const isExecute = args.includes('--execute');
  const allowAnomalies = args.includes('--allow-anomalies');
  const isIndexPreflightOnly = args.includes('--index-preflight');
  const isStrict = args.includes('--strict');
  const rollbackIdx = args.indexOf('--rollback');
  const rollbackRunId = rollbackIdx !== -1 && args[rollbackIdx + 1] ? args[rollbackIdx + 1] : null;

  console.log('=================================================================');
  console.log('ACADEX WORKSPACE MEMBERSHIP MIGRATION RUNNER');
  console.log('=================================================================');

  await connectDB();

  try {
    if (rollbackRunId) {
      console.log(`[ACTION] Executing safe rollback for migration runId: ${rollbackRunId}...`);
      const result = await WorkspaceMigrationService.rollbackMigrationRun(rollbackRunId);
      console.log('Rollback Summary:');
      console.log(`- Deleted Memberships: ${result.deletedMemberships}`);
      console.log(`- Deleted Role Assignments: ${result.deletedRoleAssignments}`);
      return;
    }

    if (isIndexPreflightOnly) {
      console.log('[MODE] READ-ONLY INDEX PREFLIGHT INSPECTION');
      const preflight = await WorkspaceMigrationService.runIndexPreflight();
      console.log('-----------------------------------------------------------------');
      console.log(`Database: ${preflight.databaseName || 'Current connection'}`);
      console.log(`Faculty compound index exists: ${preflight.collections.faculty.hasCompoundCollegeUserIdIndex}`);
      console.log(`Student compound index exists: ${preflight.collections.student.hasCompoundCollegeUserIdIndex}`);
      console.log(`Faculty duplicate records: ${preflight.collections.faculty.duplicateCount}`);
      console.log(`Student duplicate records: ${preflight.collections.student.duplicateCount}`);
      console.log(`Membership user conflicts: ${preflight.collections.workspaceMembership.userDuplicateCount}`);
      console.log(`Membership PIN conflicts: ${preflight.collections.workspaceMembership.pinDuplicateCount}`);
      console.log(`Role conflicts: ${preflight.collections.workspaceRoleAssignment.conflictCount}`);
      console.log(`Can safely apply indexes: ${preflight.canSafelyApplyIndexes ? 'YES' : 'NO'}`);
      console.log('-----------------------------------------------------------------');
      if (preflight.blockers.length > 0) {
        console.log('\n[BLOCKERS]');
        preflight.blockers.forEach((b) => console.log(` - ${b}`));
      }
      if (preflight.recommendations.length > 0) {
        console.log('\n[RECOMMENDATIONS]');
        preflight.recommendations.forEach((r) => console.log(` - ${r}`));
      }
      return;
    }

    if (!isExecute) {
      console.log('[MODE] DRY RUN (No writes will be performed)');
      console.log('Scanning users, colleges, departments, and indexes...\n');

      const report = await WorkspaceMigrationService.runDryRun();
      const preflight = await WorkspaceMigrationService.runIndexPreflight();

      console.log('-----------------------------------------------------------------');
      console.log(`Dry Run Identifier: ${report.runId}`);
      console.log(`Total Users Scanned: ${report.totalUsersScanned}`);
      console.log(`Eligible For Migration: ${report.classifications.eligibleForMigration}`);
      console.log(`Already Migrated: ${report.classifications.alreadyMigrated}`);
      console.log(`Super Admin Platform Users: ${report.classifications.superAdminPlatformUsers}`);
      console.log(`Unresolved Anomalies: ${report.classifications.unresolvedAnomalies}`);
      console.log(`Profile Index Conflicts: ${report.indexConflicts.length}`);
      console.log(`Safe to Migrate: ${report.safeToMigrate ? 'YES' : 'NO'}`);
      console.log('-----------------------------------------------------------------');

      console.log('\nStatus Breakdown:', report.statusBreakdown);
      console.log('Role Breakdown:', report.roleBreakdown);

      if (report.anomalies.length > 0) {
        console.log('\n[WARNING] Detected Anomalies:');
        for (const a of report.anomalies.slice(0, 20)) {
          console.log(` - [${a.category}] User: ${a.userId || 'N/A'}, PIN: ${a.instituteId || 'N/A'}, College: ${a.collegeId || 'N/A'}`);
          console.log(`   Reason: ${a.reason}`);
        }
        if (report.anomalies.length > 20) {
          console.log(`   ...and ${report.anomalies.length - 20} more anomalies.`);
        }
      }

      if (report.indexConflicts.length > 0) {
        console.log('\n[WARNING] Detected Index Conflicts:');
        for (const c of report.indexConflicts) {
          console.log(
            ` - Collection: ${c.collection}, Key: ${JSON.stringify(c.indexKey || {})}, College: ${c.collegeId || 'N/A'}, User: ${c.userId || 'N/A'}, PIN: ${c.instituteId || 'N/A'}, Count: ${c.count}`
          );
          console.log(`   Reason: ${c.reason}`);
        }
      }

      console.log('\nIndex Preflight Status:');
      console.log(`- Faculty compound index: ${preflight.collections.faculty.hasCompoundCollegeUserIdIndex ? 'Present' : 'Pending migration rollout'}`);
      console.log(`- Student compound index: ${preflight.collections.student.hasCompoundCollegeUserIdIndex ? 'Present' : 'Pending migration rollout'}`);
      console.log(`- Membership PIN compound index: ${preflight.collections.workspaceMembership.hasCompoundCollegePinUniqueness ? 'Present' : 'Pending migration rollout'}`);
      console.log(`- Preflight Index Blockers: ${preflight.blockers.length}`);
      if (preflight.recommendations.length > 0) {
        preflight.recommendations.forEach((r) => console.log(`  * ${r}`));
      }

      if (!report.safeToMigrate && isStrict) {
        console.error('\n[STRICT CHECK FAILED] Migration cannot proceed safely due to unresolved anomalies or index conflicts.');
        process.exitCode = 1;
        return;
      }

      console.log('\nTo execute migration, re-run with:');
      console.log('  npx ts-node src/scripts/migrate-workspaces.ts --execute\n');
      return;
    }

    // Explicit execution mode
    console.log('[MODE] EXPLICIT WRITE EXECUTION');
    console.log('Applying migration in batches...\n');

    const result = await WorkspaceMigrationService.executeMigration({
      allowAnomalies,
      actorUserId: 'cli_migration_runner',
    });

    console.log('=================================================================');
    console.log('MIGRATION COMPLETED');
    console.log('=================================================================');
    console.log(`Run Identifier: ${result.runId}`);
    console.log(`Memberships Created: ${result.createdMembershipsCount}`);
    console.log(`Role Assignments Created: ${result.createdRoleAssignmentsCount}`);
    console.log(`Existing Skipped: ${result.skippedExistingCount}`);
    console.log(`Failed Records: ${result.failedRecordsCount}`);

    if (result.errors.length > 0) {
      console.log('\nErrors encountered:');
      for (const err of result.errors) {
        console.log(` - User ${err.userId}: ${err.error}`);
      }
    }
  } catch (err: any) {
    logger.error(`Migration script execution failed: ${err.message}`);
    console.error(`\n[FATAL ERROR] ${err.message}`);
    process.exitCode = 1;
  } finally {
    await disconnectDB();
  }
}

if (require.main === module) {
  main();
}
