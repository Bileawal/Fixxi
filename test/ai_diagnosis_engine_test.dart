import 'dart:io';

import 'package:fixxi/models/diagnosis_result.dart';
import 'package:fixxi/services/ai_diagnosis_engine.dart';
import 'package:fixxi/services/nlp_language.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AiDiagnosisEngine engine;

  setUpAll(() async {
    final file = File('assets/Dataset.json');
    engine = AiDiagnosisEngine();
    await engine.initialize(rawJson: file.readAsStringSync());
  });

  test('AC nahi chal raha → AC, not fan, low risk', () async {
    final r = await engine.analyze('AC nai chal raha');
    expect(r.needsApplianceChoice, isFalse);
    expect(r.applianceName.toLowerCase(), contains('ac'));
    expect(r.applianceName.toLowerCase(), isNot(contains('fan')));
    expect(r.riskLevel, RiskLevel.low);
    expect(r.diagnosticSteps.join(' ').toLowerCase(), isNot(contains('regulator')));
    expect(r.diagnosticSteps.join(' ').toLowerCase(), contains('mcb'));
  });

  test('pankha slow → ceiling fan', () async {
    final r = await engine.analyze('Mera pankha slow chal raha hai');
    expect(r.applianceName.toLowerCase(), contains('fan'));
    expect(r.riskLevel, RiskLevel.low);
  });

  test('AC se dhuwa → HIGH RISK + AC steps', () async {
    final r = await engine.analyze('AC se dhuwa nikal raha hai');
    expect(r.applianceName.toLowerCase(), contains('ac'));
    expect(r.riskLevel, RiskLevel.high);
    expect(r.safetyPrecautions, isNotEmpty);
    expect(r.possibleIssues, isNotEmpty);
  });

  test('sirf dhuwa, item nahi → high risk + appliance chips', () async {
    final r = await engine.analyze('is cheez mai sy dhuwa nikal raha hai');
    expect(r.needsApplianceChoice, isTrue);
    expect(r.riskLevel, RiskLevel.high);
    expect(r.safetyPrecautions, isNotEmpty);
  });

  test('forced appliance keeps AC after vague text', () async {
    final r = await engine.analyze(
      'dhuwa nikal raha hai',
      forcedApplianceId: 'ac',
    );
    expect(r.applianceName.toLowerCase(), contains('ac'));
    expect(r.riskLevel, RiskLevel.high);
  });

  test('tap leak → plumber not fan', () async {
    final r = await engine.analyze('kitchen tap se pani leak ho raha hai');
    expect(r.category, 'Plumber');
    expect(r.applianceName.toLowerCase(), isNot(contains('fan')));
  });

  test('English reply is not mixed Roman Urdu', () async {
    final r = await engine.analyze('My AC is not cooling');
    expect(r.replyLang, ReplyLang.english);
    final blob = [
      r.summary,
      r.symptomLabel ?? '',
      ...r.diagnosticSteps,
      ...r.safetyPrecautions,
    ].join(' ').toLowerCase();
    for (final w in ['karein', 'dekhein', 'nahi', 'yeh ', 'masla']) {
      expect(blob, isNot(contains(w)), reason: 'leftover "$w" in: $blob');
    }
  });

  test('Roman Urdu input gets Roman Urdu reply copy', () async {
    final r = await engine.analyze('AC nahi chal raha');
    expect(r.replyLang, ReplyLang.romanUrdu);
    expect(r.summary.toLowerCase(), contains('masla'));
  });
}
