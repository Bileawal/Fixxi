import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/diagnosis_result.dart';
import 'ai_learning_service.dart';
import 'diagnosis_i18n.dart';
import 'nlp_language.dart';

/// Appliance picker (chips) ke liye chhota view model.
class ApplianceOption {
  const ApplianceOption({
    required this.id,
    required this.label,
    required this.category,
  });

  final String id;
  final String label;
  final String category;
}

/// Rule-based diagnosis engine. Saara domain knowledge `assets/Dataset.json`
/// ke `diagnostic_engine` block mein hai — is class mein sirf reasoning hai:
///
///   clean -> appliance synonyms -> appliance resolve -> symptom synonyms
///        -> hazard match -> fault resolve -> risk -> cost branches
///
/// Do alag normalization passes JAAN BOOJH KAR hain: symptom synonyms
/// (jaise `tapak` -> `leak`) appliance detect hone ke BAAD chalti hain, warna
/// wo appliance detection ko gumraah kar deti hain.
class AiDiagnosisEngine {
  static const String _assetPath = 'assets/Dataset.json';
  static const _PriceRange _fallbackVisitFee = _PriceRange(300, 500);

  /// One shared engine so Dataset.json is parsed once, not on every screen open.
  static final AiDiagnosisEngine shared = AiDiagnosisEngine();

  bool _ready = false;
  final Map<String, _Trade> _trades = {};
  final List<_SynRule> _applianceSyn = [];
  final List<_SynRule> _symptomSyn = [];
  final List<_Hazard> _hazards = [];
  final List<_Appliance> _appliances = [];
  List<String> _hazardChecks = const [];

  bool get isReady => _ready;

  /// Customer ko dikhane wali appliance list (chips).
  List<ApplianceOption> get applianceCatalog => _appliances
      .map((a) => ApplianceOption(id: a.id, label: a.label, category: a.category))
      .toList(growable: false);

  /// [rawJson] sirf tests ke liye — is se `rootBundle` bypass ho jata hai.
  Future<void> initialize({String? rawJson}) async {
    if (_ready) return;

    final raw = rawJson ?? await rootBundle.loadString(_assetPath);
    final root = jsonDecode(raw) as Map<String, dynamic>;
    final engine = root['diagnostic_engine'] as Map<String, dynamic>;

    _loadTrades(root, engine);
    _loadNormalization(engine);
    _loadHazards(engine);
    _loadAppliances(engine);

    if (_appliances.isEmpty || _trades.isEmpty) {
      throw StateError('Dataset.json mein diagnostic_engine ka data adhoora hai.');
    }
    _ready = true;
  }

  Future<DiagnosisResult> analyze(
    String rawInput, {
    String? forcedApplianceId,
    AiLearningService? learningService,
  }) async {
    if (!_ready) {
      throw StateError('AiDiagnosisEngine.initialize() pehle call karein.');
    }

    final lang = NlpLanguage.detect(rawInput);
    final cleaned = _clean(rawInput);
    final applianceText = _applySynonyms(cleaned, _applianceSyn);

    final appliance = forcedApplianceId == null
        ? _resolveAppliance(applianceText)
        : _applianceById(forcedApplianceId);

    // Symptom pass ab safe hai — appliance already resolve ho chuka hai.
    final symptomText = _applySynonyms(applianceText, _symptomSyn);
    // Hazard original + synonym dono texts par — "dhuwa" miss na ho.
    final hazards = _uniqueHazards([
      ..._matchHazards(cleaned),
      ..._matchHazards(applianceText),
      ..._matchHazards(symptomText),
    ]);

    if (appliance == null) {
      return _applianceChoiceResult(rawInput, hazards, lang);
    }

    final match = _resolveFault(appliance, symptomText, hazards.isNotEmpty);
    final fault = match ?? _defaultFault(appliance, hazardous: hazards.isNotEmpty);
    if (fault == null) {
      return _applianceChoiceResult(rawInput, hazards, lang);
    }

    // Hazard risk ko upgrade kar sakta hai, KABHI downgrade nahi.
    final risk = hazards.isNotEmpty ? RiskLevel.high : fault.risk;
    final escalatedByHazard = hazards.isNotEmpty && fault.risk == RiskLevel.low;

    final trade = _trades[appliance.tradeId];
    final visitFee = trade == null ? _fallbackVisitFee : _visitFee(trade);
    final steps = escalatedByHazard
        ? _mergeSteps(_hazardChecks, _checksFor(appliance, fault))
        : _checksFor(appliance, fault);

    return DiagnosisResult(
      applianceName: appliance.label,
      category: appliance.category,
      riskLevel: risk,
      confidence: _confidence(
        forced: forcedApplianceId != null,
        specificFault: match != null,
      ),
      matchedFaultId: '${appliance.id}_${fault.symptom}',
      diagnosticSteps: DiagnosisI18n.lines(steps, lang),
      safetyPrecautions:
          DiagnosisI18n.lines(_safetyFor(appliance, fault, hazards), lang),
      possibleIssues:
          _buildIssues(appliance, fault, rawInput, learningService, lang),
      summary: _summaryFor(appliance, fault, risk, hazards, lang),
      rawInput: rawInput,
      symptomLabel: DiagnosisI18n.line(fault.label, lang),
      visitFeeLabel: 'Rs ${visitFee.min}–${visitFee.max} per visit',
      replyLang: lang,
    );
  }

  // ---------------------------------------------------------------- loading

  void _loadTrades(Map<String, dynamic> root, Map<String, dynamic> engine) {
    for (final t in _mapList(engine['trades'])) {
      final id = t['id'] as String?;
      if (id == null) continue;
      _trades[id] = _Trade(
        id: id,
        category: t['category'] as String? ?? '',
        visitFeeMatch: t['visit_fee_match'] as String? ?? '',
        parts: _indexRows(root[t['parts_key']], 'item'),
        labor: _indexRows(root[t['labor_key']], 'service'),
      );
    }
  }

  void _loadNormalization(Map<String, dynamic> engine) {
    final norm = engine['normalization'];
    if (norm is! Map<String, dynamic>) return;
    _readSynonyms(norm['appliance_synonyms'], _applianceSyn);
    _readSynonyms(norm['symptom_synonyms'], _symptomSyn);
  }

  void _readSynonyms(Object? src, List<_SynRule> into) {
    if (src is! Map) return;
    // Order matters: JSON ka order hi apply order hai (spelling pehle, phrase baad mein).
    src.forEach((from, to) {
      if (from is! String || to is! String) return;
      final re = _synonymRegex(from);
      if (re != null) into.add(_SynRule(re, to));
    });
  }

  void _loadHazards(Map<String, dynamic> engine) {
    for (final h in _mapList(engine['hazards'])) {
      final patterns = _compileAll(h['patterns']);
      if (patterns.isEmpty) continue;
      _hazards.add(_Hazard(
        id: h['id'] as String? ?? '',
        label: h['label'] as String? ?? '',
        patterns: patterns,
        safety: _stringList(h['safety']),
      ));
    }
    _hazardChecks = _stringList(engine['hazard_default_checks']);
  }

  void _loadAppliances(Map<String, dynamic> engine) {
    for (final a in _mapList(engine['appliances'])) {
      final id = a['id'] as String?;
      if (id == null) continue;
      final nouns = _compileAll(a['nouns']);
      if (nouns.isEmpty) continue;

      _appliances.add(_Appliance(
        id: id,
        label: a['label'] as String? ?? id,
        category: a['category'] as String? ?? '',
        tradeId: a['trade_id'] as String? ?? '',
        priority: (a['priority'] as num?)?.toInt() ?? 0,
        nouns: nouns,
        skipIf: _compileAll(a['skip_if']),
        hints: _stringList(a['hints']).map((h) => h.toLowerCase()).toList(),
        defaultSymptom: a['default_symptom'] as String? ?? '',
        commonChecks: _stringList(a['common_checks']),
        commonSafety: _stringList(a['common_safety']),
        faults: _mapList(a['faults']).map(_readFault).toList(),
      ));
    }
  }

  _Fault _readFault(Map<String, dynamic> f) => _Fault(
        symptom: f['symptom'] as String? ?? '',
        label: f['label'] as String? ?? '',
        match: _compileAll(f['match']),
        risk: (f['risk'] as String?) == 'high' ? RiskLevel.high : RiskLevel.low,
        checks: _stringList(f['checks']),
        safety: _stringList(f['safety']),
        issues: _mapList(f['issues'])
            .map((i) => _IssueSpec(
                  title: i['title'] as String? ?? '',
                  cause: i['cause'] as String? ?? '',
                  partRow: i['part_row'] as String?,
                  laborRow: i['labor_row'] as String?,
                  tradeId: i['trade_id'] as String?,
                  visitOnly: i['visit_only'] == true,
                ))
            .toList(),
      );

  // ------------------------------------------------------------ text passes

  String _clean(String s) => NlpLanguage.toRomanUrdu(s)
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  String _applySynonyms(String input, List<_SynRule> rules) {
    var out = input;
    for (final r in rules) {
      out = out.replaceAll(r.pattern, r.replacement);
    }
    return out.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Har synonym word-boundary regex banti hai — raw `replaceAll` se
  /// "pani" -> "panahi" jaisi corruption hoti thi.
  /// Trailing `*` = prefix match (aakhir mein boundary nahi lagti).
  RegExp? _synonymRegex(String from) {
    final isPrefix = from.endsWith('*');
    final core = isPrefix ? from.substring(0, from.length - 1) : from;
    if (core.isEmpty) return null;
    final body = core
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map(RegExp.escape)
        .join(r'\s+');
    if (body.isEmpty) return null;
    try {
      // Prefix (*) last word ke baqi letters bhi kha jaye — warna
      // "nahi chal rah*" se "raha" ka trailing "a" reh jata tha.
      return RegExp('\\b$body${isPrefix ? r'\w*' : r'\b'}', caseSensitive: false);
    } catch (_) {
      return null;
    }
  }

  // -------------------------------------------------------------- resolvers

  _Appliance? _applianceById(String id) {
    for (final a in _appliances) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// `nouns` appliance ko IDENTIFY karte hain; `hints` akele kaafi nahi.
  /// AC vs fan: "AC nahi chal raha" mein `\bfan\b` nahi, lekin "AC ka fan"
  /// dono match kare — skip_if aur AC noun bonus se AC jeetega.
  _Appliance? _resolveAppliance(String text) {
    _Appliance? best;
    var bestScore = -1.0;
    final acMentioned = RegExp(r'\bac\b', caseSensitive: false).hasMatch(text);

    for (final a in _appliances) {
      if (a.skipIf.any((r) => r.hasMatch(text))) continue;

      final hits = a.nouns.where((r) => r.hasMatch(text)).toList();
      if (hits.isEmpty) continue;

      var score = 10.0 * hits.length;
      score += 2.0 * a.hints.where((h) => text.contains(h)).length;
      score += 0.3 * a.priority;
      score += 0.05 * _longest(hits);
      if (a.id == 'ac' && acMentioned) score += 40;

      if (score > bestScore) {
        bestScore = score;
        best = a;
      }
    }
    return best;
  }

  _Fault? _resolveFault(_Appliance a, String text, bool hazardous) {
    _Fault? best;
    var bestScore = -1.0;

    for (final f in a.faults) {
      final hits = f.match.where((r) => r.hasMatch(text)).toList();
      if (hits.isEmpty) continue;

      var score = 12.0 * hits.length + 0.05 * _longest(hits);
      if (f.risk == RiskLevel.high && hazardous) score += 20;
      if (f.risk == RiskLevel.low && hazardous) score -= 8;

      if (score > bestScore) {
        bestScore = score;
        best = f;
      }
    }
    return best;
  }

  _Fault? _defaultFault(_Appliance a, {bool hazardous = false}) {
    if (hazardous) {
      for (final f in a.faults) {
        if (f.risk == RiskLevel.high) return f;
      }
    }
    for (final f in a.faults) {
      if (f.symptom == a.defaultSymptom) return f;
    }
    return a.faults.isEmpty ? null : a.faults.first;
  }

  List<_Hazard> _matchHazards(String text) => _hazards
      .where((h) => h.patterns.any((r) => r.hasMatch(text)))
      .toList(growable: false);

  List<_Hazard> _uniqueHazards(List<_Hazard> list) {
    final seen = <String>{};
    return list.where((h) => seen.add(h.id)).toList(growable: false);
  }

  double _confidence({required bool forced, required bool specificFault}) {
    if (forced) return specificFault ? 0.95 : 0.72;
    return specificFault ? 0.92 : 0.65;
  }

  // ---------------------------------------------------------------- content

  List<String> _checksFor(_Appliance a, _Fault f) {
    if (f.checks.isNotEmpty) return List<String>.from(f.checks);
    if (a.commonChecks.isNotEmpty) return List<String>.from(a.commonChecks);
    final fallback = _defaultFault(a);
    if (fallback != null && fallback.symptom != f.symptom && fallback.checks.isNotEmpty) {
      return List<String>.from(fallback.checks);
    }
    return const [];
  }

  List<String> _mergeSteps(List<String> first, List<String> second) {
    final seen = <String>{};
    return [...first, ...second].where(seen.add).toList(growable: false);
  }

  List<String> _safetyFor(_Appliance a, _Fault f, List<_Hazard> hazards) {
    final out = <String>[];
    for (final h in hazards) {
      out.addAll(h.safety); // Hazard ki lines sab se ooper.
    }
    out.addAll(f.safety);
    out.addAll(a.commonSafety);

    final seen = <String>{};
    return out.where(seen.add).toList(growable: false);
  }

  String _summaryFor(
    _Appliance a,
    _Fault f,
    RiskLevel risk,
    List<_Hazard> hazards,
    ReplyLang lang,
  ) {
    final label = DiagnosisI18n.line(f.label, lang);
    if (risk == RiskLevel.high) {
      final flags = hazards
          .map((h) => DiagnosisI18n.line(h.label, lang))
          .where((l) => l.isNotEmpty);
      final reason = flags.isEmpty ? '' : ' (${flags.join(', ')})';
      return lang.isEnglish
          ? '${a.label} — $label.$reason This is a HIGH RISK issue: follow the safety precautions below immediately and do not repair it yourself.'
          : '${a.label} — $label.$reason Yeh HIGH RISK masla hai: neeche safety steps foran follow karein aur khud repair na karein.';
    }
    return lang.isEnglish
        ? '${a.label} — $label. This is usually a LOW RISK issue. Try the simple checks below yourself.'
        : '${a.label} — $label. Yeh normally LOW RISK masla hai. Neeche diye gaye simple checks khud try karein.';
  }

  DiagnosisResult _applianceChoiceResult(
    String raw,
    List<_Hazard> hazards,
    ReplyLang lang,
  ) {
    final safety = <String>[];
    for (final h in hazards) {
      safety.addAll(h.safety);
    }
    final seen = <String>{};

    final flags = hazards
        .map((h) => DiagnosisI18n.line(h.label, lang))
        .where((l) => l.isNotEmpty)
        .toList();

    final summary = flags.isEmpty
        ? (lang.isEnglish
            ? 'Could not identify the appliance. Please select an item below for exact diagnostic steps.'
            : 'Appliance samajh nahi aayi. Sahi item neeche se select karein taake exact steps mil sakein.')
        : (lang.isEnglish
            ? '⚠️ Safety hazards detected: ${flags.join(', ')}. Follow the safety steps first, then select your appliance.'
            : '⚠️ Safety ki nishani mili: ${flags.join(', ')}. Pehle safety steps follow karein, phir item select karein.');

    return DiagnosisResult(
      applianceName: lang.isEnglish ? 'Select item' : 'Item select karein',
      category: '',
      riskLevel: hazards.isEmpty ? RiskLevel.unknown : RiskLevel.high,
      confidence: 0,
      matchedFaultId: 'unknown',
      diagnosticSteps: hazards.isEmpty
          ? const []
          : DiagnosisI18n.lines(_hazardChecks, lang),
      safetyPrecautions: DiagnosisI18n.lines(
        safety.where(seen.add).toList(growable: false),
        lang,
      ),
      summary: summary,
      rawInput: raw,
      needsApplianceChoice: true,
      replyLang: lang,
    );
  }

  // ----------------------------------------------------------------- pricing

  List<PossibleIssue> _buildIssues(
    _Appliance a,
    _Fault f,
    String rawInput,
    AiLearningService? learningService,
    ReplyLang lang,
  ) {
    final out = <PossibleIssue>[];

    for (var i = 0; i < f.issues.length; i++) {
      final spec = f.issues[i];
      final trade = _trades[spec.tradeId ?? a.tradeId] ?? _trades[a.tradeId];
      if (trade == null) continue;

      final part = spec.partRow == null ? null : _partPrice(trade, spec.partRow!);
      final labor = spec.laborRow == null ? null : _laborPrice(trade, spec.laborRow!);

      final cause = DiagnosisI18n.line(spec.cause, lang);
      final causes = <String>[
        lang.isEnglish
            ? 'If this is the issue: $cause'
            : 'Agar yeh masla hai to: $cause',
      ];
      _PriceRange total;
      String? partsLabel;
      String? laborLabel;

      if (part == null && labor == null) {
        if (!spec.visitOnly) continue; // Bina price row ke chup chaap skip.
        final visit = _visitFee(trade);
        total = visit;
        partsLabel = lang.isEnglish
            ? 'Part: technician will quote on site'
            : 'Part: technician site par quote karega';
        laborLabel = 'Visit + diagnosis: Rs ${visit.min}–${visit.max}';
        causes.add(
          lang.isEnglish
              ? 'If this is the issue, estimated cost is Rs ${total.min}–${total.max}.'
              : 'Agar yeh issue hua to estimated cost Rs ${total.min}–${total.max}.',
        );
      } else {
        total = _PriceRange(
          (part?.min ?? 0) + (labor?.min ?? 0),
          (part?.max ?? 0) + (labor?.max ?? 0),
        );
        if (part != null) partsLabel = 'Part: Rs ${part.min}–${part.max}';
        if (labor != null) laborLabel = 'Labor: Rs ${labor.min}–${labor.max}';
        causes.add(
          lang.isEnglish
              ? 'If this is the issue, estimated cost is Rs ${total.min}–${total.max}.'
              : 'Agar yeh issue hua to estimated cost Rs ${total.min}–${total.max}.',
        );
      }

      double boost = learningService?.scoreWithLearning(rawInput, f.symptom, a.category) ?? 0.0;
      var hint = learningService?.learnedCostHint(rawInput, a.category);

      if (hint != null) {
        total = _PriceRange(hint.$1, hint.$2);
        partsLabel = null;
        laborLabel = null;
        causes.add('AI Learned Estimate: Rs ${total.min}–${total.max} based on recent similar repairs.');
      }

      out.add(PossibleIssue(
        title: DiagnosisI18n.line(spec.title, lang),
        causes: causes,
        estimatedCostMin: total.min,
        estimatedCostMax: total.max,
        // Dataset ka order = kitna aam masla hai (pehla sab se aam).
        confidence: ((0.9 - i * 0.18).clamp(0.35, 0.9)) + boost,
        partsCost: partsLabel,
        laborCost: laborLabel,
      ));
    }

    out.sort((x, y) => x.estimatedCostMin.compareTo(y.estimatedCostMin));
    return out;
  }

  /// EXACT name lookup. Pehle `contains` fallback tha jis se
  /// "New Fan Motor" dhoondte waqt "Fan Regulator/Dimmer" ki price aati thi.
  _PriceRange? _partPrice(_Trade trade, String rowName) {
    final row = trade.parts[rowName];
    if (row == null) return null;
    for (final key in const [
      'standard_pkr',
      'economy_pkr',
      'premium_pkr',
      'pkr',
    ]) {
      final range = _parseRange(row[key]?.toString());
      if (range != null) return range;
    }
    return null;
  }

  _PriceRange? _laborPrice(_Trade trade, String rowName) {
    final row = trade.labor[rowName];
    if (row == null) return null;
    return _parseRange(row['pkr']?.toString());
  }

  _PriceRange _visitFee(_Trade trade) =>
      _laborPrice(trade, trade.visitFeeMatch) ?? _fallbackVisitFee;

  /// Pehle DO numbers leti hai. `parts.first`/`parts.last` wala purana code
  /// "250-400 (GI 8SWG/kg)" par (8, 250) return karta tha.
  _PriceRange? _parseRange(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final nums = RegExp(r'\d+')
        .allMatches(raw)
        .map((m) => int.tryParse(m.group(0)!) ?? 0)
        .toList();
    if (nums.isEmpty) return null;
    final min = nums.first;
    final max = nums.length > 1 ? nums[1] : nums.first;
    return _PriceRange(min < max ? min : max, min < max ? max : min);
  }

  // ------------------------------------------------------------------ utils

  int _longest(List<RegExp> patterns) {
    var longest = 0;
    for (final p in patterns) {
      if (p.pattern.length > longest) longest = p.pattern.length;
    }
    return longest;
  }

  List<Map<String, dynamic>> _mapList(Object? src) => src is List
      ? src.whereType<Map<String, dynamic>>().toList(growable: false)
      : const [];

  List<String> _stringList(Object? src) =>
      src is List ? src.whereType<String>().toList(growable: false) : const [];

  List<RegExp> _compileAll(Object? src) {
    final out = <RegExp>[];
    for (final p in _stringList(src)) {
      try {
        out.add(RegExp(p, caseSensitive: false));
      } catch (_) {
        // Dataset ki ek kharab pattern poore engine ko na girae.
      }
    }
    return out;
  }

  Map<String, Map<String, dynamic>> _indexRows(Object? rows, String nameKey) {
    final out = <String, Map<String, dynamic>>{};
    if (rows is! List) return out;
    for (final row in rows) {
      if (row is! Map<String, dynamic>) continue;
      final name = row[nameKey];
      if (name is String && name.isNotEmpty) out[name] = row;
    }
    return out;
  }
}

// ------------------------------------------------------------ internal types

class _SynRule {
  const _SynRule(this.pattern, this.replacement);
  final RegExp pattern;
  final String replacement;
}

class _PriceRange {
  const _PriceRange(this.min, this.max);
  final int min;
  final int max;
}

class _Trade {
  const _Trade({
    required this.id,
    required this.category,
    required this.visitFeeMatch,
    required this.parts,
    required this.labor,
  });

  final String id;
  final String category;
  final String visitFeeMatch;
  final Map<String, Map<String, dynamic>> parts;
  final Map<String, Map<String, dynamic>> labor;
}

class _Hazard {
  const _Hazard({
    required this.id,
    required this.label,
    required this.patterns,
    required this.safety,
  });

  final String id;
  final String label;
  final List<RegExp> patterns;
  final List<String> safety;
}

class _IssueSpec {
  const _IssueSpec({
    required this.title,
    required this.cause,
    this.partRow,
    this.laborRow,
    this.tradeId,
    this.visitOnly = false,
  });

  final String title;
  final String cause;
  final String? partRow;
  final String? laborRow;
  final String? tradeId;
  final bool visitOnly;
}

class _Fault {
  const _Fault({
    required this.symptom,
    required this.label,
    required this.match,
    required this.risk,
    required this.checks,
    required this.safety,
    required this.issues,
  });

  final String symptom;
  final String label;
  final List<RegExp> match;
  final RiskLevel risk;
  final List<String> checks;
  final List<String> safety;
  final List<_IssueSpec> issues;
}

class _Appliance {
  const _Appliance({
    required this.id,
    required this.label,
    required this.category,
    required this.tradeId,
    required this.priority,
    required this.nouns,
    required this.skipIf,
    required this.hints,
    required this.defaultSymptom,
    required this.commonChecks,
    required this.commonSafety,
    required this.faults,
  });

  final String id;
  final String label;
  final String category;
  final String tradeId;
  final int priority;
  final List<RegExp> nouns;
  final List<RegExp> skipIf;
  final List<String> hints;
  final String defaultSymptom;
  final List<String> commonChecks;
  final List<String> commonSafety;
  final List<_Fault> faults;
}
