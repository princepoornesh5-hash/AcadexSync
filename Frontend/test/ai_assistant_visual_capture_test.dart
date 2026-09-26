import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_management/features/ai_assistant/presentation/ai_assistant_screen.dart';
import 'package:campus_management/features/ai_assistant/presentation/providers/ai_providers.dart';
import 'package:campus_management/features/ai_assistant/data/repositories/mock_ai_repository.dart';
import 'package:campus_management/features/auth/domain/models/auth_state.dart';
import 'package:campus_management/features/auth/domain/models/user_model.dart';
import 'package:campus_management/features/auth/domain/models/role_enum.dart';
import 'package:campus_management/features/auth/presentation/providers/auth_provider.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testUser = UserModel(
    id: 'student_123',
    name: 'Aarav Patel',
    email: 'aarav@college.edu',
    role: AppRole.student,
    collegeId: 'college_abc',
    departmentId: 'dept_cse',
    instituteId: 'INST_01',
    accountStatus: AccountStatus.active,
  );

  final resolutions = [
    {'name': '360x800', 'size': const Size(360, 800)},
    {'name': '390x844', 'size': const Size(390, 844)},
    {'name': '412x915', 'size': const Size(412, 915)},
    {'name': '1280x800', 'size': const Size(1280, 800)},
    {'name': '1440x900', 'size': const Size(1440, 900)},
  ];

  for (final res in resolutions) {
    testWidgets('Capture AI Assistant at ${res['name']}', skip: true, (tester) async {
      final size = res['size'] as Size;
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final key = GlobalKey();

      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiRepositoryProvider.overrideWithValue(MockAiRepository()),
            authProvider.overrideWith((ref) => _FakeAuthNotifier(
              AuthAuthenticated(user: testUser, token: 'test_token'),
            )),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            home: MediaQuery(
              data: MediaQueryData(size: size),
              child: RepaintBoundary(
                key: key,
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: const AiAssistantScreen(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final outDir = Directory('/Users/poornesh/.gemini/antigravity-ide/brain/c5ccb28a-9da1-4bf4-8117-85837b1a738c/scratch');
      if (!outDir.existsSync()) {
        outDir.createSync(recursive: true);
      }
      final file = File('${outDir.path}/ai_assistant_${res['name']}.png');
      file.writeAsBytesSync(pngBytes);
      print('Captured: ${file.path} (${pngBytes.length} bytes)');
    });
  }
}
