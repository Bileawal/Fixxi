import 'diagnosis_en.dart';
import 'nlp_language.dart';

/// Local, offline content localizer.
/// Dataset strings are Roman Urdu. English replies use an exact dictionary
/// first (O(1)), then phrase replacements — no network translate.
class DiagnosisI18n {
  DiagnosisI18n._();

  static String line(String text, ReplyLang lang) {
    if (lang == ReplyLang.romanUrdu) return text;
    final phrased = _toEnglish(text);
    final exact = kDiagnosisEn[text] ?? kDiagnosisEn[text.trim()];
    if (exact == null) return phrased;
    // Dictionary is often still mixed; keep whichever has fewer Roman leftovers.
    return NlpLanguage.romanResidue(phrased) <= NlpLanguage.romanResidue(exact)
        ? phrased
        : exact;
  }

  static List<String> lines(List<String> items, ReplyLang lang) =>
      items.map((s) => line(s, lang)).toList(growable: false);

  static String _toEnglish(String text) {
    var out = text;
    for (final e in _replacements) {
      out = out.replaceAllMapped(e.key, (_) => e.value);
    }
    return out.replaceAll(RegExp(r'\s+'), ' ').replaceAll(' .', '.').trim();
  }

  static final List<MapEntry<RegExp, String>> _replacements = () {
    const phrases = <String, String>{
      'foran band karein': 'turn it off immediately',
      'foran band kar dein': 'turn it off immediately',
      'khud mat karein': 'do not do it yourself',
      'khud kuch mat karein': 'do not try anything yourself',
      'bina safety ke': 'without safety gear',
      'kam az kam': 'at least',
      'khaas taur par': 'especially',
      'qareeb na jayein': 'do not go near it',
      'andar capacitor charge rehta hai': 'the capacitor inside may still be charged',
      'haath sookhe hon': 'keep your hands dry',
      'plug nikaal dein': 'unplug it',
      'MCB / switch off karein': 'switch the MCB / breaker off',
      'MCB / isolator': 'MCB / isolator',
      'Agar yeh masla hai to': 'If this is the issue',
      'Agar yeh issue hua to estimated cost': 'If this is the issue, estimated cost is',
      'Part: technician site par quote karega':
          'Part: technician will quote on site',
      'Visit + diagnosis': 'Visit + diagnosis',
      'AI Learned Estimate': 'AI learned estimate',
      'based on recent similar repairs': 'based on recent similar repairs',
      'thanda nahi kar raha': 'not cooling',
      'cooling weak': 'weak cooling',
      'bilkul chal nahi raha': 'not turning on at all',
      'pani tapak raha hai': 'water is leaking',
      'awaz / vibration aa rahi hai': 'making noise / vibration',
      'gandi filter': 'dirty filter',
      'wapas lagayein': 'put it back',
      'pani se dhoein': 'wash with water',
      'sukha kar': 'dry it and',
      'nikaal kar': 'remove and',
      'band karke': 'after switching off',
      'chala kar': 'run it and',
      'dekhein ke': 'check whether',
      'confirm karein': 'confirm',
      'note karein': 'note it down',
      'try karein': 'try',
      'laga kar': 'connect and',
      'daal kar': 'insert and',
      'Indoor filter nikaal kar pani se dhoein aur sukha kar wapas lagayein':
          'Remove the indoor filter, wash with water, dry it and put it back',
      'gandi filter cooling 30–40% tak gira deti hai':
          'a dirty filter can cut cooling by 30–40%',
      'Remote COOL mode par ho': 'set the remote to COOL mode',
      'FAN/DRY par nahi': 'not FAN/DRY',
      'temperature 18–22°C set karein': 'set temperature to 18–22°C',
      'Fan speed HIGH par rakhein': 'keep fan speed on HIGH',
      'Outdoor unit ke aage-peeche kam az kam 1 foot jagah clear karein':
          'keep at least 1 foot of clear space around the outdoor unit',
      'Outdoor unit ka fan ghoom raha hai':
          'is the outdoor unit fan spinning',
      'Na ghoome to compressor load nahi le raha — foran band karein':
          'if not, the compressor is not loading — turn it off immediately',
      'Kamre ke darwaze/khirkiyan band karke':
          'close the room doors/windows and',
      'grill se nikalne wali hawa check karein':
          'check the air coming from the grill',
      'Gas refill KHUD kabhi mat karein':
          'never refill gas yourself',
      'yeh sirf certified HVAC technician ka kaam hai':
          'this is only a certified HVAC technician job',
      'Outdoor unit par cover chadha kar AC mat chalayein':
          'do not run the AC with a cover on the outdoor unit',
      'AC wala MCB / isolator ON hai': 'is the AC MCB / isolator ON',
      'DB board par jaa kar confirm karein': 'check it on the DB board',
      'Remote mein naye cell daal kar dekhein':
          'put new cells in the remote and check',
      'Us socket mein koi doosra appliance laga kar test karein':
          'test the socket with another appliance',
      'point mein current hai': 'the point has power',
      'Stabilizer laga ho to usay bypass karke direct try karein':
          'if a stabilizer is fitted, bypass it and try direct',
      'Indoor unit se koi beep ya blinking light aaye to uska pattern note karein':
          'if the indoor unit beeps or blinks, note the pattern',
      'yeh error code hota hai': 'this is an error code',
      'Drain pipe ka bahar wala sira dekhein':
          'check the outer end of the drain pipe',
      'pani aa raha hai ya bilkul ruk gaya hai':
          'is water coming out or fully blocked',
      'Drain pipe ko halka pressure/blow de kar saaf karein':
          'gently blow/pressure-clean the drain pipe',
      'Indoor unit seedhi (level) lagi hai':
          'is the indoor unit fitted level',
      'Tedhi hone se pani galat side gir jata hai':
          'if it is tilted, water falls the wrong way',
      'Coil par barf jami hai': 'is ice stuck on the coil',
      'Yeh gandi filter ya kam gas ki nishani hai':
          'this is a sign of a dirty filter or low gas',
      'Pani kisi socket, switch board ya extension ke qareeb gir raha ho':
          'if water is falling near a socket, switch board or extension',
      'us hisse ka MCB foran band karein':
          'switch that section MCB off immediately',
      'Tapakne wale pani ke neeche baalti rakhein aur farsh sukha rakhein':
          'put a bucket under the leak and keep the floor dry',
      'phisalne ka khatra hai': 'there is a slip hazard',
      'foran band karein aur khud kuch mat karein':
          'turn it off immediately and do not do anything yourself',
      'Deewar ka switch aur regulator dono ON hain':
          'are the wall switch and regulator both ON',
      'bina safety ke us tak mat charhein':
          'do not climb up to it without safety',
      'ki nishani hai': 'is a sign of',
      'ka kaam hai': 'job',
      'istemaal na karein': 'do not use',
      'geele haath se': 'with wet hands',
      'bilkul mat chhuein': 'do not touch at all',
      'thanda hone dein': 'let it cool down',
      'technician se check karwayein': 'have a technician inspect it',
      'bachon ko door rakhein': 'keep children away',
      'khirkiyan kholein': 'open the windows',
      'saaf karein': 'clean it',
      'band karein': 'turn it off',
      'band kar dein': 'turn it off',
      'check karein': 'check',
      'mat karein': 'do not',
      'mat chhuein': 'do not touch',
      'mat charhein': 'do not climb',
      'mat kholein': 'do not open',
      'na karein': 'do not',
    };

    const words = <String, String>{
      'karein': 'do',
      'karen': 'do',
      'karo': 'do',
      'karwayein': 'have it done',
      'dekhein': 'check',
      'dekho': 'check',
      'rakhein': 'keep',
      'lagayein': 'fit',
      'lagao': 'fit',
      'nikaalein': 'remove',
      'nikaal': 'remove',
      'nikal': 'come out',
      'chalayein': 'run',
      'chalao': 'run',
      'kholein': 'open',
      'daalein': 'pour',
      'lein': 'take',
      'dein': 'give',
      'chhuein': 'touch',
      'charhein': 'climb',
      'jayein': 'go',
      'bulayein': 'call',
      'hai': 'is',
      'hain': 'are',
      'hein': 'are',
      'nahin': 'not',
      'nahi': 'not',
      'nai': 'not',
      'nhi': 'not',
      'raha': '',
      'rahi': '',
      'rahe': '',
      'gaya': 'gone',
      'gayi': 'gone',
      'gai': 'gone',
      'gaye': 'gone',
      'gya': 'gone',
      'gyi': 'gone',
      'hua': '',
      'hui': '',
      'hue': '',
      'aur': 'and',
      'yeh': 'this',
      'woh': 'that',
      'koi': 'any',
      'kuch': 'some',
      'liye': 'for',
      'mein': 'in',
      'mai': 'in',
      'par': 'on',
      'se': 'from',
      'ka': 'of',
      'ki': 'of',
      'ke': 'of',
      'ko': 'to',
      'neeche': 'below',
      'ooper': 'above',
      'uper': 'above',
      'andar': 'inside',
      'bahar': 'outside',
      'pehle': 'first',
      'phir': 'then',
      'foran': 'immediately',
      'dobara': 'again',
      'khud': 'yourself',
      'mat': 'do not',
      'band': 'off',
      'chalu': 'on',
      'kharab': 'faulty',
      'khrab': 'faulty',
      'pani': 'water',
      'paani': 'water',
      'pankha': 'fan',
      'pankhe': 'fan',
      'bijli': 'electricity',
      'awaz': 'noise',
      'hawa': 'air',
      'mitti': 'dirt',
      'saaf': 'clean',
      'safai': 'cleaning',
      'garam': 'hot',
      'thanda': 'cold',
      'thandi': 'cold',
      'haath': 'hands',
      'ghar': 'home',
      'farsh': 'floor',
      'deewar': 'wall',
      'chhat': 'roof',
      'usay': 'it',
      'usko': 'it',
      'uska': 'its',
      'uski': 'its',
      'iski': 'its',
      'iska': 'its',
      'wali': '',
      'wala': '',
      'wale': '',
      'hisse': 'section',
      'hissa': 'section',
      'kaam': 'work',
      'masla': 'issue',
      'maslay': 'issues',
      'theek': 'ok',
      'zyada': 'too much',
      'kam': 'low',
      'dheela': 'loose',
      'jam': 'stuck',
      'jal': 'burn',
      'hone': 'being',
      'hota': 'happens',
      'hoti': 'happens',
      'hote': 'are',
      'bhi': 'also',
      'tak': 'until',
      'saath': 'with',
      'wajah': 'reason',
      'karke': 'after',
      'laga': 'installed',
      'lagi': 'fitted',
      'nal': 'tap',
      'agar': 'if',
      'lekin': 'but',
      'magar': 'but',
      'bohat': 'very',
      'bahut': 'very',
      'thoda': 'a little',
      'thora': 'a little',
      'poora': 'full',
      'sirf': 'only',
      'bilkul': 'completely',
      'abhi': 'now',
      'warna': 'otherwise',
      'isliye': 'so',
      'kyunki': 'because',
      'chal': 'run',
      'chalta': 'runs',
      'chalti': 'runs',
      'kya': 'what',
      'kyu': 'why',
      'kyun': 'why',
      'kaise': 'how',
      'kese': 'how',
      'aksar': 'often',
      'zaroor': 'definitely',
      'kabhi': 'never',
      'hamesha': 'always',
      'bachon': 'children',
      'nishani': 'sign',
      'khatarnak': 'dangerous',
      'jaanleva': 'life-threatening',
      'geele': 'wet',
      'geeli': 'wet',
      'sookhe': 'dry',
      'sookhi': 'dry',
      'khirki': 'window',
      'khirkiyan': 'windows',
      'darwaza': 'door',
      'darwaze': 'doors',
      'kamra': 'room',
      'kamre': 'room',
      'qareeb': 'near',
      'cheez': 'thing',
      'jagah': 'place',
      'baalti': 'bucket',
      'dhuwa': 'smoke',
      'dhuan': 'smoke',
      'chingari': 'spark',
      'jhatka': 'shock',
      'barf': 'ice',
      'gandi': 'dirty',
      'ganda': 'dirty',
      'ghoom': 'spin',
      'ghoome': 'spin',
      'tapak': 'leak',
      'istemaal': 'use',
      'taake': 'so that',
      'sira': 'end',
      'tedhi': 'tilted',
      'jami': 'stuck',
      'phisalne': 'slipping',
      'khatra': 'hazard',
      'wapas': 'back',
      'dhoein': 'wash',
      'sukha': 'dry',
      'krta': 'does',
      'krti': 'does',
      'krte': 'do',
      'kro': 'do',
      'apna': 'your',
      'apni': 'your',
      'apne': 'your',
      'mera': 'my',
      'meri': 'my',
      'mere': 'my',
      'mujhe': 'me',
      'aap': 'you',
      'nalka': 'tap',
      'toti': 'tap',
      'batti': 'light',
    };

    final raw = <String, String>{...phrases, ...words};
    final keys = raw.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    return [
      for (final k in keys)
        MapEntry(
          RegExp('\\b${RegExp.escape(k)}\\b', caseSensitive: false),
          raw[k]!,
        ),
    ];
  }();
}

/// Screen chrome (buttons, headings) — never Nastaliq Urdu.
class AiCopy {
  const AiCopy(this.lang);
  final ReplyLang lang;

  bool get en => lang.isEnglish;

  String get analyzing => en ? 'Analyzing…' : 'Analyze ho raha hai…';
  String get simpleChecks =>
      en ? 'Simple checks (try these)' : 'Simple checks (yeh try karein)';
  String get safety => en ? 'Safety precautions' : 'Safety precautions';
  String get immediateSafety =>
      en ? 'Immediate actions (safety)' : 'Foran kya karein (safety)';
  String get diagnosticSteps =>
      en ? 'Diagnostic steps' : 'Checks / steps';
  String get contactTech =>
      en ? 'Contact nearby technician' : 'Qareebi technician se raabta karein';
  String get solvedQ =>
      en ? 'Did these steps solve the problem?' : 'Kya in steps se masla solve ho gaya?';
  String get safetyQ => en
      ? 'Have you followed the safety steps? Do you still need a technician?'
      : 'Safety steps follow kar liye? Abhi technician chahiye?';
  String get yes => en ? 'Yes' : 'Haan';
  String get no => en ? 'No' : 'Nahi';
  String get yesControl => en ? 'Yes, under control' : 'Haan, control mein hai';
  String get needTech => en ? 'No, need technician' : 'Nahi, technician chahiye';
  String get solvedTitle =>
      en ? 'Problem solved! 🎉' : 'Masla solve ho gaya! 🎉';
  String get solvedSub => en
      ? 'Describe below if you have any other issue.'
      : 'Koi aur masla ho to neeche likhein.';
  String get hintEmpty =>
      'English or Roman Urdu — e.g. AC not cooling / AC thanda nahi';
  String get listeningHint => en
      ? 'Listening… keep talking. Tap the mic when you finish.'
      : 'Sun raha hoon… baat poori karein, phir mic dabayein.';
  String get hintMore =>
      en ? 'Describe another issue…' : 'Koi aur masla likhein…';
  String get pickItem =>
      en ? 'Which item has the issue? Select it:' : 'Kis cheez ka masla hai? Sahi item select karein:';
  String get highPick =>
      en ? 'HIGH RISK — follow safety first, then pick the item' : 'HIGH RISK — pehle safety, phir item chunein';
  String get bookingTitle =>
      en ? 'Book a technician' : 'Technician book karein';
  String bookingSub(String appliance) => en
      ? 'How do you want a technician for $appliance?'
      : '$appliance ke liye kis tarah technician chahiye?';
  String get urgent =>
      en ? 'Urgent — available technician now' : 'Urgent — abhi available technician';
  String get schedule =>
      en ? 'Schedule — pick date & time' : 'Schedule — date & time select karein';
  String get lowChecksFailed => en
      ? 'Simple checks did not solve the problem. Estimated costs for possible issues are below.'
      : 'Simple checks se masla solve nahi hua. Neeche possible issues ki estimated cost hai.';
  String highCosts(String appliance) => en
      ? 'Possible issues for this $appliance and estimated costs are below.'
      : 'Neeche is $appliance ke possible issues aur estimated cost hai.';
  String ifIssue(String title) =>
      en ? 'If the issue is: $title' : 'Agar masla yeh hua: $title';
  String estCost(int min, int max) =>
      en ? 'Estimated cost Rs $min–$max' : 'Andazan kharcha: Rs $min–$max';
  String noCost(String appliance, String fee) => en
      ? 'No specific part+labor row found for this $appliance. Technician visit: $fee. The exact issue will be confirmed on site.'
      : 'Is $appliance ke liye specific price nahi mili. Technician visit: $fee. Asal masla site par confirm hoga.';
  String highWarn(String extra) => en
      ? '⚠️ This is a HIGH RISK issue$extra. Follow the safety precautions below immediately — do not repair it yourself.'
      : '⚠️ Yeh HIGH RISK masla hai$extra. Neeche safety steps foran follow karein — khud repair na karein.';
}
