/// Reply language for the AI module.
/// Spoken/typed Urdu (script or Roman) → Roman Urdu.
/// Spoken/typed English → English.
enum ReplyLang { english, romanUrdu }

extension ReplyLangX on ReplyLang {
  bool get isEnglish => this == ReplyLang.english;
}

/// Lightweight NLP language ID: English vs Roman Urdu vs Urdu script.
/// Domain nouns (fan, ac, leak) do NOT vote — only grammar/function words.
/// So "AC is not cooling" stays English and "AC nahi chal raha" stays Roman.
class NlpLanguage {
  NlpLanguage._();

  static final _urduScript = RegExp(r'[\u0600-\u06FF]');
  static final _token = RegExp(r"[a-zA-Z']+");

  static const _englishFunc = {
    'the', 'this', 'that', 'these', 'those', 'is', 'are', 'was', 'were',
    'am', 'be', 'been', 'being', 'not', 'no', 'my', 'mine', 'me', 'it', 'its',
    'please', 'does', "doesn't", 'dont', "don't", "won't", 'wont', 'cannot',
    "can't", 'could', 'would', 'should', 'have', 'has', 'had', 'with',
    'from', 'your', 'you', 'when', 'what', 'why', 'how', 'which', 'because',
    'after', 'before', 'about', 'into', 'just', 'only', 'still', 'very',
    'also', 'then', 'them', 'they', 'their', 'our', 'and', 'but', 'if',
    'doesnt', 'isnt', "isn't", 'wasnt', "wasn't", 'need', 'needs', 'help',
    'something', 'wrong', 'kindly', 'hello', 'hi', 'can', 'will', 'do',
    'did', 'now', 'again', 'any', 'some', 'all', 'more', 'too', 'much',
    'want', 'wants', 'tell', 'show', 'give', 'there', 'here', 'problem',
    'issue', 'working', 'leaking', 'cooling', 'heating', 'spinning',
    'stopped', 'broken', 'making', 'dripping', 'turning', 'turned',
    'running', 'getting', 'keep', 'keeps', 'coming', 'started',
    'suddenly',
  };

  static const _romanFunc = {
    'nahi', 'nai', 'nhi', 'naii', 'hai', 'hain', 'tha', 'thi', 'thy',
    'kya', 'kia', 'kyu', 'kyun', 'kaise', 'kese', 'kesy', 'masla',
    'kharab', 'khrab', 'chal', 'chala', 'chalu', 'raha', 'rahi', 'rahe',
    'rha', 'rhe', 'rhi', 'karein', 'karen', 'karo', 'gaya', 'gayi',
    'gaye', 'gya', 'gyi', 'mera', 'meri', 'mere', 'apka', 'apki', 'apke',
    'yeh', 'woh', 'aur', 'lekin', 'magar', 'bohat', 'bahut', 'zyada',
    'nikal', 'nikaal', 'foran', 'pehle', 'phir', 'usay', 'usko', 'iski',
    'iska', 'wala', 'wali', 'wale', 'hua', 'hui', 'hue', 'hogaya',
    'hogayi', 'bilkul', 'dekho', 'dekhein', 'lagao', 'lagayein', 'kholo',
    'band', 'chalao', 'krta', 'krti', 'krte', 'hein', 'mujhe', 'mujh',
    'hamara', 'hamari', 'andar', 'bahar', 'neeche', 'ooper', 'uper',
    'saath', 'liye', 'wajah', 'theek', 'khud', 'mat', 'dobara', 'hota',
    'hoti', 'hone', 'kro', 'krna', 'krne', 'batao', 'samajh', 'samjh',
    'poora', 'thora', 'thoda', 'pani', 'pankha', 'bijli', 'tapak',
    'thanda', 'thandi', 'garam', 'sard', 'awaz', 'ghar', 'haath',
    'se', 'ka', 'ki', 'ke', 'ko', 'mein', 'mai', 'sy', 'par', 'pe',
    'ho', 'kr', 'krke',
  };

  static ReplyLang detect(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return ReplyLang.english;

    if (_urduScript.hasMatch(text)) return ReplyLang.romanUrdu;

    final tokens = _token
        .allMatches(text.toLowerCase())
        .map((m) => m.group(0)!)
        .where((t) => t.length > 1)
        .toList();

    var en = 0;
    var ru = 0;
    var enHits = 0;
    var ruHits = 0;
    for (final t in tokens) {
      if (_romanFunc.contains(t)) {
        ru += 3;
        ruHits++;
      } else if (_englishFunc.contains(t)) {
        en += 2;
        enHits++;
      }
    }

    // No Roman grammar words → English (covers "AC not cooling").
    if (ruHits == 0) return ReplyLang.english;
    if (enHits == 0) return ReplyLang.romanUrdu;
    if (ruHits >= 2 && ru >= en + 2) return ReplyLang.romanUrdu;
    return ReplyLang.english;
  }

  /// How many Roman-Urdu function words remain (used to pick a clean English line).
  static int romanResidue(String raw) {
    var n = 0;
    for (final m in _token.allMatches(raw.toLowerCase())) {
      final t = m.group(0)!;
      if (t.length > 1 && _romanFunc.contains(t)) n++;
    }
    return n;
  }

  /// Nastaliq / Arabic-script Urdu → approximate Roman Urdu so the
  /// diagnostic matcher (latin dataset) still finds the appliance/symptom.
  static String toRomanUrdu(String text) {
    if (!_urduScript.hasMatch(text)) return text;
    const map = <String, String>{
      'آ': 'aa',
      'ا': 'a',
      'ب': 'b',
      'پ': 'p',
      'ت': 't',
      'ٹ': 't',
      'ث': 's',
      'ج': 'j',
      'چ': 'ch',
      'ح': 'h',
      'خ': 'kh',
      'د': 'd',
      'ڈ': 'd',
      'ذ': 'z',
      'ر': 'r',
      'ڑ': 'r',
      'ز': 'z',
      'ژ': 'zh',
      'س': 's',
      'ش': 'sh',
      'ص': 's',
      'ض': 'z',
      'ط': 't',
      'ظ': 'z',
      'ع': 'a',
      'غ': 'gh',
      'ف': 'f',
      'ق': 'q',
      'ک': 'k',
      'گ': 'g',
      'ل': 'l',
      'م': 'm',
      'ن': 'n',
      'ں': 'n',
      'و': 'o',
      'ہ': 'h',
      'ھ': 'h',
      'ء': '',
      'ی': 'i',
      'ے': 'e',
      'ئ': 'i',
      'ؤ': 'o',
      'ة': 'h',
      'ۀ': 'h',
      'ِ': 'i',
      'َ': 'a',
      'ُ': 'u',
      'ْ': '',
      'ٰ': 'a',
      'ّ': '',
      'ٔ': '',
      'ٖ': '',
      'ٗ': '',
    };
    final buf = StringBuffer();
    for (final rune in text.runes) {
      final ch = String.fromCharCode(rune);
      buf.write(map[ch] ?? ch);
    }
    return buf.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
