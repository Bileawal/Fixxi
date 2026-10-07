import re

path = r'lib/screens/customer/ai_diagnosis_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    code = f.read()

# Fix const Padding in _solvedCard
code = code.replace(
    "child: const Padding(",
    "child: Padding("
)

# Add eng to _solvedQuestion
code = re.sub(
    r"Widget _solvedQuestion\(\{bool highRisk = false\}\) \{",
    r"Widget _solvedQuestion({bool highRisk = false}) {\n    final eng = _isEnglish(_userMessage ?? '');",
    code
)

# Add eng to _inputBar
code = re.sub(
    r"Widget _inputBar\(\) \{",
    r"Widget _inputBar() {\n    final eng = _isEnglish(_userMessage ?? '');",
    code
)

with open(path, 'w', encoding='utf-8') as f:
    f.write(code)
