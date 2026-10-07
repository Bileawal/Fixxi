import re

path = r'lib/screens/customer/ai_diagnosis_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    code = f.read()

code = re.sub(
    r"Text\(\s*highRisk\s*\?\s*'Safety follow kar li\? Kya masla abhi bhi hai aur technician chahiye\?'\s*:\s*'Kya in steps se problem solve ho gayi\?',",
    r"Text(\n              highRisk\n                  ? (eng ? 'Have you followed the safety steps? Do you still need a technician?' : 'کیا آپ نے احتیاطی تدابیر پر عمل کر لیا ہے؟ کیا ابھی بھی ٹیکنیشن کی ضرورت ہے؟')\n                  : (eng ? 'Did these steps solve the problem?' : 'کیا ان اقدامات سے مسئلہ حل ہو گیا؟'),",
    code
)
code = re.sub(
    r"label:\s*Text\(highRisk\s*\?\s*'Nahi, technician chahiye'\s*:\s*'Nahi'\),",
    r"label: Text(highRisk ? (eng ? 'No, need technician' : 'نہیں، ٹیکنیشن چاہیے') : (eng ? 'No' : 'نہیں')),",
    code
)
code = re.sub(
    r"label:\s*Text\(highRisk\s*\?\s*'Haan, control mein'\s*:\s*'Haan'\),",
    r"label: Text(highRisk ? (eng ? 'Yes, under control' : 'ہاں، قابو میں ہے') : (eng ? 'Yes' : 'ہاں')),",
    code
)

code = re.sub(
    r"Text\('Masla Solve Ho Gaya! [^']*',\s*style",
    r"Text(eng ? 'Problem Solved! 🎉' : 'مسئلہ حل ہو گیا! 🎉',\n                style",
    code
)
code = re.sub(
    r"Text\('Koi aur masla ho toh neeche describe karein\.',\s*style",
    r"Text(eng ? 'Describe below if you have any other issue.' : 'کوئی اور مسئلہ ہو تو نیچے تفصیل بتائیں۔',\n                style",
    code
)
code = re.sub(
    r"Widget _solvedCard\(\) \{",
    r"Widget _solvedCard() {\n    final eng = _isEnglish(_userMessage ?? '');",
    code
)

code = re.sub(
    r"hintText:\s*_result\s*!=\s*null\s*\?\s*'Koi aur masla describe karein[^']*'\s*:\s*'Masla likhein [^']*',",
    r"hintText: _result != null\n                      ? (eng ? 'Describe another issue...' : 'کوئی اور مسئلہ بتائیں...')\n                      : (eng ? 'Describe issue (e.g. AC not cooling)...' : 'مسئلہ لکھیں (جیسے AC ٹھنڈا نہیں کر رہا)...'),",
    code
)

code = re.sub(
    r"Text\('Analyze ho raha hai[^']*',\s*style",
    r"Text(eng ? 'Analyzing...' : 'تجزیہ ہو رہا ہے...', style",
    code
)
code = re.sub(
    r"Widget _loadingBubble\(\) \{",
    r"Widget _loadingBubble() {\n    final eng = _isEnglish(_userMessage ?? '');",
    code
)

code = re.sub(
    r"return _aiBubble\(\s*'Is \$\{r\.applianceName\} ke liye dataset mein specific part\+labor row nahi mili\. '\s*'Technician diagnostic visit: \$fee\. Site par exact issue confirm hoga\.',\s*\);",
    r"return _aiBubble(\n        eng ? 'No specific part+labor row found for this ${r.applianceName}. Technician diagnostic visit: $fee. Exact issue will be confirmed on site.'\n            : 'اس ${r.applianceName} کے لیے کوئی مخصوص قیمت نہیں ملی۔ ٹیکنیشن وزٹ چارجز: $fee۔ اصل مسئلہ ٹیکنیشن کے معائنے کے بعد کنفرم ہوگا۔',\n      );",
    code
)
code = re.sub(
    r"Widget _costEstimationSection\(DiagnosisResult r\) \{",
    r"Widget _costEstimationSection(DiagnosisResult r) {\n    final eng = _isEnglish(_userMessage ?? '');",
    code
)
code = re.sub(
    r"'Agar issue yeh hua: \$\{issue\.title\}'",
    r"eng ? 'If issue is: ${issue.title}' : 'اگر مسئلہ یہ ہوا: ${issue.title}'",
    code
)
code = re.sub(
    r"'to estimated cost Rs \$\{issue\.estimatedCostMin\}–\$\{issue\.estimatedCostMax\}'",
    r"eng ? 'Estimated cost Rs ${issue.estimatedCostMin}–${issue.estimatedCostMax}'\n                      : 'تو اندازاً خرچہ: روپے ${issue.estimatedCostMin}–${issue.estimatedCostMax}'",
    code
)

with open(path, 'w', encoding='utf-8') as f:
    f.write(code)
