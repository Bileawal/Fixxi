import 'package:fixxi/services/nlp_language.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('English sentences stay English', () {
    expect(NlpLanguage.detect('My AC is not cooling'), ReplyLang.english);
    expect(NlpLanguage.detect('The fridge is leaking water'), ReplyLang.english);
    expect(NlpLanguage.detect('Please check my fan it stopped working'),
        ReplyLang.english);
    expect(NlpLanguage.detect('AC not cooling'), ReplyLang.english);
  });

  test('Roman Urdu and Urdu script stay Roman Urdu', () {
    expect(NlpLanguage.detect('AC nahi chal raha'), ReplyLang.romanUrdu);
    expect(NlpLanguage.detect('Mera pankha slow chal raha hai'),
        ReplyLang.romanUrdu);
    expect(NlpLanguage.detect('ای سی نہیں چل رہا'), ReplyLang.romanUrdu);
  });
}
