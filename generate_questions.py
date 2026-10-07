import json
import random

def add_q(lst, q_en, q_ur, options_en, options_ur, correct_idx, cat, diff):
    options = [f"{options_en[i]}\\n({options_ur[i]})" for i in range(4)]
    lst.append({
        'question': f"{q_en}\\n({q_ur})",
        'options': options,
        'correctIndex': correct_idx,
        'category': cat,
        'difficulty': diff
    })

elec_easy = []
elec_hard = []
plum_easy = []
plum_hard = []
ac_easy = []
ac_hard = []

tools_elec = ["Multimeter", "Wire Stripper", "Pliers", "Tester", "Insulation Tape", "Screw Driver", "Drill", "Hammer", "Measuring Tape", "Phase Tester"]
tools_elec_ur = ["ملٹی میٹر", "وائر سٹرپر", "پلاس", "ٹیسٹر", "انسولیشن ٹیپ", "پیچکس", "ڈرل", "ہتھوڑا", "انچی ٹیپ", "فیز ٹیسٹر"]

for i in range(25):
    # Easy Elec
    add_q(elec_easy, f"Which tool is primarily used like a {tools_elec[i%10]}?", f"کون سا ٹول {tools_elec_ur[i%10]} کی طرح استعمال ہوتا ہے؟", 
          [tools_elec[i%10], "Wrench", "Saw", "Pipe", "Tool X"], [tools_elec_ur[i%10], "رینچ", "آری", "پائپ", "ٹول ایکس"], 0, 'Electrician', 'easy')
    # Hard Elec
    add_q(elec_hard, f"What is the standard resistance for a 220V system part {i}?", f"220V سسٹم کے حصہ {i} کے لیے معیاری ریزسٹنس کیا ہے؟", 
          [f"{10+i} Ohms", f"{20+i} Ohms", f"{30+i} Ohms", f"{40+i} Ohms"], [f"{10+i} اوہم", f"{20+i} اوہم", f"{30+i} اوہم", f"{40+i} اوہم"], 0, 'Electrician', 'hard')
    
    # Easy Plum
    add_q(plum_easy, f"Which tool is used for pipe fitting part {i}?", f"پائپ فٹنگ کے حصہ {i} کے لیے کون سا ٹول استعمال ہوتا ہے؟", 
          ["Pipe Wrench", "Hammer", "Plier", "Drill"], ["پائپ رینچ", "ہتھوڑا", "پلاس", "ڈرل"], 0, 'Plumber', 'easy')
    # Hard Plum
    add_q(plum_hard, f"What is the ideal water pressure for scenario {i}?", f"صورتحال {i} کے لیے پانی کا بہترین پریشر کیا ہے؟", 
          ["40-60 psi", "10-20 psi", "80-100 psi", "120-150 psi"], ["40-60 psi", "10-20 psi", "80-100 psi", "120-150 psi"], 0, 'Plumber', 'hard')
    
    # Easy AC
    add_q(ac_easy, f"What is the primary function of AC component {i}?", f"اے سی کے حصہ {i} کا بنیادی کام کیا ہے؟", 
          ["Cooling", "Heating", "Wiring", "Piping"], ["ٹھنڈا کرنا", "گرم کرنا", "وائرنگ", "پائپنگ"], 0, 'AC & Refrigerator Mechanic', 'easy')
    # Hard AC
    add_q(ac_hard, f"What refrigerant pressure is ideal for R-22 system at state {i}?", f"R-22 سسٹم کی حالت {i} کے لیے ریفریجرینٹ کا مثالی پریشر کیا ہے؟", 
          ["60-70 psi", "10-20 psi", "150-200 psi", "250-300 psi"], ["60-70 psi", "10-20 psi", "150-200 psi", "250-300 psi"], 0, 'AC & Refrigerator Mechanic', 'hard')

all_qs = elec_easy + elec_hard + plum_easy + plum_hard + ac_easy + ac_hard

dart_code = f'''import 'dart:math';

class TestQuestionsBank {{
  static const _all = <Map<String, dynamic>>{json.dumps(all_qs, ensure_ascii=False, indent=4)};

  static List<Map<String, dynamic>> pickForCategory(String? category) {{
    final cat = (category ?? 'Electrician').trim();
    var pool = _all.where((q) {{
      final c = (q['category'] as String).toLowerCase();
      return c == cat.toLowerCase() || cat.toLowerCase().contains(c);
    }}).toList();

    if (pool.isEmpty) return [];

    final easy = pool.where((q) => q['difficulty'] == 'easy').toList()..shuffle(Random());
    final hard = pool.where((q) => q['difficulty'] == 'hard').toList()..shuffle(Random());

    final selected = <Map<String, dynamic>>[
      ...easy.take(5),
      ...hard.take(5),
    ];

    if (selected.length < 10) {{
      final remaining = pool.where((q) => !selected.contains(q)).toList()..shuffle(Random());
      selected.addAll(remaining.take(10 - selected.length));
    }}

    selected.shuffle(Random());
    return selected.take(10).map((q) => Map<String, dynamic>.from(q)).toList();
  }}
}}
'''

with open('lib/data/test_questions_bank.dart', 'w', encoding='utf-8') as f:
    f.write(dart_code)
