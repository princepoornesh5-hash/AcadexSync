import os
import re

auth_file = "lib/features/auth/presentation/providers/auth_provider.dart"
storage_file = "lib/features/storage/presentation/providers/storage_providers.dart"
main_file = "lib/main.dart"
note_form = "lib/features/notes/presentation/screens/note_form_screen.dart"

# 1. Fix auth_provider.dart
with open(auth_file, "r") as f:
    auth_content = f.read()

auth_content = auth_content.replace("import '../../../../core/firebase/firebase_providers.dart';", "")
auth_content = re.sub(r"await _firestoreService\.setDocument\('users', uid, \{'fcmTokens': tokens\}, merge: true\);", 
                      r"final mergedData = Map<String, dynamic>.from(doc);\n              mergedData['fcmTokens'] = tokens;\n              await _firestoreService.setDocument('users', uid, mergedData);", 
                      auth_content)

with open(auth_file, "w") as f:
    f.write(auth_content)

# 2. Fix storage_providers.dart
with open(storage_file, "r") as f:
    storage_content = f.read()

storage_content = storage_content.replace("import '../../../../core/firebase/firebase_providers.dart';", "import '../../../../core/firebase/firebase_services.dart';")

with open(storage_file, "w") as f:
    f.write(storage_content)

# 3. Fix main.dart imports
with open(main_file, "r") as f:
    main_content = f.read()

# Move firebase_config, firebase_initializer, firebase_error_screen to top
main_content = main_content.replace("import 'core/firebase/firebase_config.dart';", "")
main_content = main_content.replace("import 'core/firebase/firebase_initializer.dart';", "")
main_content = main_content.replace("import 'core/presentation/screens/firebase_error_screen.dart';", "")

new_imports = """import 'core/firebase/firebase_config.dart';
import 'core/firebase/firebase_initializer.dart';
import 'core/presentation/screens/firebase_error_screen.dart';
"""
main_content = new_imports + main_content

with open(main_file, "w") as f:
    f.write(main_content)

# 4. Fix note_form_screen.dart Radio properties (groupValue -> ignore warning or fix it. Actually it's just a warning. Let's fix it by suppressing the warning)
# I will just run flutter analyze again to check if errors are gone. Warnings can stay.
