import re

file_path = "lib/features/academic_structure/domain/models/academic_models.dart"

with open(file_path, "r") as f:
    content = f.read()

# Models to modify
# Course: Add collegeId
# Semester, Section, Subject: Add collegeId, departmentId

# --- COURSE ---
content = re.sub(
    r'(class Course \{[\s\S]*?final String departmentId;)',
    r'\1\n  final String collegeId;',
    content,
    count=1
)
content = re.sub(
    r'(Course\(\{[\s\S]*?required this\.departmentId,)',
    r'\1\n    required this.collegeId,',
    content,
    count=1
)
content = re.sub(
    r'(Course copyWith\(\{[\s\S]*?String\? departmentId,)',
    r'\1\n    String? collegeId,',
    content,
    count=1
)
content = re.sub(
    r'(return Course\([\s\S]*?departmentId: departmentId \?\? this\.departmentId,)',
    r'\1\n      collegeId: collegeId ?? this.collegeId,',
    content,
    count=1
)
content = re.sub(
    r'(factory Course\.fromJson\(Map<String, dynamic> json\) \{[\s\S]*?return Course\([\s\S]*?departmentId: json\[\'departmentId\'\] as String\? \?\? \'\',)',
    r'\1\n      collegeId: json[\'collegeId\'] as String? ?? \'\',',
    content,
    count=1
)
content = re.sub(
    r'(\'departmentId\': departmentId,)',
    r'\1\n      \'collegeId\': collegeId,',
    content,
    count=1
)

# --- SEMESTER ---
content = re.sub(
    r'(class Semester \{[\s\S]*?final String courseId;)',
    r'\1\n  final String collegeId;\n  final String departmentId;',
    content,
    count=1
)
content = re.sub(
    r'(Semester\(\{[\s\S]*?required this\.courseId,)',
    r'\1\n    required this.collegeId,\n    required this.departmentId,',
    content,
    count=1
)
content = re.sub(
    r'(Semester copyWith\(\{[\s\S]*?String\? courseId,)',
    r'\1\n    String? collegeId,\n    String? departmentId,',
    content,
    count=1
)
content = re.sub(
    r'(return Semester\([\s\S]*?courseId: courseId \?\? this\.courseId,)',
    r'\1\n      collegeId: collegeId ?? this.collegeId,\n      departmentId: departmentId ?? this.departmentId,',
    content,
    count=1
)
content = re.sub(
    r'(factory Semester\.fromJson\(Map<String, dynamic> json\) \{[\s\S]*?return Semester\([\s\S]*?courseId: json\[\'courseId\'\] as String\? \?\? \'\',)',
    r'\1\n      collegeId: json[\'collegeId\'] as String? ?? \'\',\n      departmentId: json[\'departmentId\'] as String? ?? \'\',',
    content,
    count=1
)
content = re.sub(
    r'(\'courseId\': courseId,)',
    r'\1\n      \'collegeId\': collegeId,\n      \'departmentId\': departmentId,',
    content,
    count=1
)

# --- SECTION ---
content = re.sub(
    r'(class Section \{[\s\S]*?final String semesterId;)',
    r'\1\n  final String collegeId;\n  final String departmentId;',
    content,
    count=1
)
content = re.sub(
    r'(Section\(\{[\s\S]*?required this\.semesterId,)',
    r'\1\n    required this.collegeId,\n    required this.departmentId,',
    content,
    count=1
)
content = re.sub(
    r'(Section copyWith\(\{[\s\S]*?String\? semesterId,)',
    r'\1\n    String? collegeId,\n    String? departmentId,',
    content,
    count=1
)
content = re.sub(
    r'(return Section\([\s\S]*?semesterId: semesterId \?\? this\.semesterId,)',
    r'\1\n      collegeId: collegeId ?? this.collegeId,\n      departmentId: departmentId ?? this.departmentId,',
    content,
    count=1
)
content = re.sub(
    r'(factory Section\.fromJson\(Map<String, dynamic> json\) \{[\s\S]*?return Section\([\s\S]*?semesterId: json\[\'semesterId\'\] as String\? \?\? \'\',)',
    r'\1\n      collegeId: json[\'collegeId\'] as String? ?? \'\',\n      departmentId: json[\'departmentId\'] as String? ?? \'\',',
    content,
    count=1
)
content = re.sub(
    r'(\'semesterId\': semesterId,)',
    r'\1\n      \'collegeId\': collegeId,\n      \'departmentId\': departmentId,',
    content,
    count=1
)

# --- SUBJECT ---
content = re.sub(
    r'(class Subject \{[\s\S]*?final String courseId;)',
    r'\1\n  final String collegeId;\n  final String departmentId;',
    content,
    count=1
)
content = re.sub(
    r'(Subject\(\{[\s\S]*?required this\.courseId,)',
    r'\1\n    required this.collegeId,\n    required this.departmentId,',
    content,
    count=1
)
content = re.sub(
    r'(Subject copyWith\(\{[\s\S]*?String\? courseId,)',
    r'\1\n    String? collegeId,\n    String? departmentId,',
    content,
    count=1
)
content = re.sub(
    r'(return Subject\([\s\S]*?courseId: courseId \?\? this\.courseId,)',
    r'\1\n      collegeId: collegeId ?? this.collegeId,\n      departmentId: departmentId ?? this.departmentId,',
    content,
    count=1
)
content = re.sub(
    r'(factory Subject\.fromJson\(Map<String, dynamic> json\) \{[\s\S]*?return Subject\([\s\S]*?courseId: json\[\'courseId\'\] as String\? \?\? \'\',)',
    r'\1\n      collegeId: json[\'collegeId\'] as String? ?? \'\',\n      departmentId: json[\'departmentId\'] as String? ?? \'\',',
    content,
    count=1
)
content = re.sub(
    r'(\'courseId\': courseId,)',
    r'\1\n      \'collegeId\': collegeId,\n      \'departmentId\': departmentId,',
    content,
    count=1
)

with open(file_path, "w") as f:
    f.write(content)
print("Done modifying academic models.")
