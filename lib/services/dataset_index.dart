import 'dart:convert';
import 'package:flutter/services.dart';

import '../models/dataset_catalog_entry.dart';

/// Builds a searchable catalog from every parts/labor row in Dataset.json.
class DatasetIndex {
  DatasetIndex._();
  static final DatasetIndex instance = DatasetIndex._();

  Map<String, dynamic>? _raw;
  List<DatasetCatalogEntry> _catalog = [];
  List<TradeDef> _trades = [];
  Map<String, ComponentClassDef> _classes = {};
  Map<String, String> _normalization = {};
  Map<String, ({List<String> strong, double weight})> _tradeDomains = {};
  List<String> _globalHighRisk = [];
  List<String> _globalLowRisk = [];
  Map<String, String> _laborToPart = {};
  bool _ready = false;

  List<DatasetCatalogEntry> get catalog => _catalog;
  List<TradeDef> get trades => _trades;
  bool get isReady => _ready;

  Future<void> build() async {
    if (_ready) return;

    final raw = await rootBundle.loadString('assets/Dataset.json');
    _raw = jsonDecode(raw) as Map<String, dynamic>;

    final engine = _raw!['diagnostic_engine'] as Map<String, dynamic>? ?? {};
    _loadEngineMeta(engine);
    _buildCatalog(engine);
    _ready = true;
  }

  void _loadEngineMeta(Map<String, dynamic> engine) {
    _trades = (engine['trades'] as List<dynamic>? ?? [])
        .map((t) => TradeDef(
              id: t['id'] as String,
              category: t['category'] as String,
              partsKey: t['parts_key'] as String,
              laborKey: t['labor_key'] as String,
              visitFeeMatch: t['visit_fee_match'] as String? ?? 'Diagnostic/site visit check fee',
            ))
        .toList();

    _classes = {};
    final classesRaw = engine['component_classes'] as Map<String, dynamic>? ?? {};
    for (final e in classesRaw.entries) {
      final v = e.value as Map<String, dynamic>;
      _classes[e.key] = ComponentClassDef(
        id: e.key,
        detectIn: (v['detect_in'] as List<dynamic>).cast<String>(),
        symptomTokens: (v['symptom_tokens'] as List<dynamic>).cast<String>(),
        risk: v['risk'] as String? ?? 'low',
        checks: (v['checks'] as List<dynamic>).cast<String>(),
        safety: (v['safety'] as List<dynamic>).cast<String>(),
        tradeId: v['trade_id'] as String?,
      );
    }

    _normalization = (engine['text_normalization'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k.toString(), v.toString()));

    _tradeDomains = {};
    final domainsRaw = engine['trade_domain_keywords'] as Map<String, dynamic>? ?? {};
    for (final e in domainsRaw.entries) {
      final v = e.value as Map<String, dynamic>;
      _tradeDomains[e.key] = (
        strong: (v['strong'] as List<dynamic>).cast<String>(),
        weight: (v['weight'] as num?)?.toDouble() ?? 4.0,
      );
    }

    _globalHighRisk = (engine['global_high_risk_tokens'] as List<dynamic>? ?? []).cast<String>();
    _globalLowRisk = (engine['global_low_risk_tokens'] as List<dynamic>? ?? []).cast<String>();

    _laborToPart = (engine['labor_to_part_hints'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k.toString(), v.toString()));
  }

  void _buildCatalog(Map<String, dynamic> engine) {
    _catalog = [];
    var idx = 0;

    for (final trade in _trades) {
      final parts = (_raw![trade.partsKey] as List<dynamic>? ?? []);
      for (final p in parts) {
        final map = p as Map<String, dynamic>;
        final name = map['item'] as String? ?? '';
        if (name.isEmpty) continue;
        final cls = _detectComponentClass(name, trade.id);
        final priceLabel = _partPriceLabel(map);
        final range = parsePriceRange(priceLabel);
        _catalog.add(DatasetCatalogEntry(
          id: 'part_${trade.id}_$idx',
          tradeId: trade.id,
          category: trade.category,
          isPart: true,
          name: name,
          tokens: _tokenize(name),
          priceMin: range.$1,
          priceMax: range.$2,
          priceLabel: priceLabel,
          confidence: map['confidence'] as String? ?? 'estimated',
          componentClass: cls,
          defaultRisk: _classes[cls]?.risk ?? 'low',
          relatedLaborName: _findLaborForPart(name, trade),
        ));
        idx++;
      }

      final labor = (_raw![trade.laborKey] as List<dynamic>? ?? []);
      for (final l in labor) {
        final map = l as Map<String, dynamic>;
        final name = map['service'] as String? ?? '';
        if (name.isEmpty) continue;
        final cls = _detectComponentClass(name, trade.id);
        final priceLabel = map['pkr'] as String? ?? '0';
        final range = parsePriceRange(priceLabel);
        _catalog.add(DatasetCatalogEntry(
          id: 'labor_${trade.id}_$idx',
          tradeId: trade.id,
          category: trade.category,
          isPart: false,
          name: name,
          tokens: _tokenize(name),
          priceMin: range.$1,
          priceMax: range.$2,
          priceLabel: priceLabel,
          confidence: map['confidence'] as String? ?? 'estimated',
          componentClass: cls,
          defaultRisk: _classes[cls]?.risk ?? 'low',
          unit: map['unit'] as String?,
          relatedPartName: _laborToPart[name],
        ));
        idx++;
      }
    }
  }

  /// Step 1: Detect which trade (Electrician / Plumber / AC) user is talking about.
  ({String tradeId, double score, String category}) detectTrade(String rawInput) {
    final normalized = normalizeText(rawInput);
    final scores = <String, double>{};

    for (final trade in _trades) {
      final domain = _tradeDomains[trade.id];
      if (domain == null) continue;
      double s = 0;
      for (final kw in domain.strong) {
        if (normalized.contains(kw.toLowerCase())) {
          s += domain.weight * (kw.split(' ').length > 1 ? 1.5 : 1.0);
        }
      }
      scores[trade.id] = s;
    }

    // Word-boundary match for short tokens like "ac"
    if (RegExp(r'\bac\b').hasMatch(normalized)) {
      scores['ac_refrigeration'] = (scores['ac_refrigeration'] ?? 0) + 8.0;
    }
    if (normalized.contains('ceiling fan') || RegExp(r'\bfan\b').hasMatch(normalized)) {
      if (!RegExp(r'\bac\b').hasMatch(normalized) && !normalized.contains('outdoor fan motor')) {
        scores['electrician'] = (scores['electrician'] ?? 0) + 3.0;
      }
    }

    if (scores.isEmpty || scores.values.every((v) => v <= 0)) {
      return (tradeId: 'electrician', score: 0, category: 'Electrician');
    }

    final best = scores.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final trade = tradeById(best.key)!;
    return (tradeId: best.key, score: best.value, category: trade.category);
  }

  String _partPriceLabel(Map<String, dynamic> map) {
    return map['standard_pkr'] as String? ??
        map['economy_pkr'] as String? ??
        map['premium_pkr'] as String? ??
        map['pkr'] as String? ??
        '0';
  }

  String? _findLaborForPart(String partName, TradeDef trade) {
    if (_laborToPart.containsValue(partName)) {
      for (final e in _laborToPart.entries) {
        if (e.value.toLowerCase() == partName.toLowerCase()) return e.key;
      }
    }
    final partLower = partName.toLowerCase();
    final laborList = (_raw![trade.laborKey] as List<dynamic>? ?? []);
    for (final l in laborList) {
      final svc = (l['service'] as String? ?? '').toLowerCase();
      for (final token in _tokenize(partName)) {
        if (token.length > 3 && svc.contains(token)) return l['service'] as String;
      }
    }
    for (final e in _laborToPart.entries) {
      if (partLower.contains(e.value.toLowerCase().split(' ').first)) return e.key;
    }
    return null;
  }

  String _detectComponentClass(String name, String tradeId) {
    final lower = name.toLowerCase();

    // Only match classes belonging to this trade (or universal ones without trade_id)
    final candidates = _classes.values.where((c) {
      if (c.tradeId != null && c.tradeId != tradeId) return false;
      return true;
    });

    String? best;
    int bestLen = 0;
    for (final cls in candidates) {
      for (final hint in cls.detectIn) {
        if (lower.contains(hint.toLowerCase()) && hint.length > bestLen) {
          best = cls.id;
          bestLen = hint.length;
        }
      }
    }

    if (best != null) return best;

    // Fallback per trade
    if (tradeId == 'ac_refrigeration') return 'ac_gas_cooling';
    if (tradeId == 'plumber') return 'plumbing_pipe';
    return 'switch_socket';
  }

  List<String> _tokenize(String text) {
    const stop = {'the', 'a', 'an', 'per', 'only', 'and', 'or', 'for', 'with', 'unit', 'job', 'service'};
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 1 && !stop.contains(w))
        .toSet()
        .toList();
  }

  String normalizeText(String input) {
    var text = input.toLowerCase();
    // Longest keys first to avoid partial replacement issues
    final keys = _normalization.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
    for (final key in keys) {
      text = text.replaceAll(key, _normalization[key]!);
    }
    return text.replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  List<String> inputTokens(String normalized) {
    const stop = {
      'the', 'a', 'an', 'is', 'was', 'are', 'my', 'mera', 'meri', 'mere', 'hai', 'ho', 'se', 'ka', 'ki', 'ke',
      'mein', 'main', 'aur', 'or', 'and', 'but', 'very', 'bohat', 'bahut', 'issue', 'problem', 'masla', 'ye', 'yeh',
    };
    return normalized.split(' ').where((w) => w.length > 1 && !stop.contains(w)).toList();
  }

  /// Score catalog entries — filtered to detected trade first.
  List<ScoredCatalogEntry> scoreInput(String rawInput, {double learningBoost = 0}) {
    final normalized = normalizeText(rawInput);
    final tokens = inputTokens(normalized);
    if (tokens.isEmpty) return [];

    final detected = detectTrade(rawInput);
    final primaryTrade = detected.tradeId;

    final scored = <ScoredCatalogEntry>[];

    for (final entry in _catalog) {
      // Skip entries from wrong trade unless they score very high
      final wrongTrade = entry.tradeId != primaryTrade;
      if (wrongTrade && detected.score >= 4.0) continue;

      double score = 0;

      for (final t in tokens) {
        if (entry.tokens.contains(t)) score += 1.5;
        if (entry.name.toLowerCase().contains(t)) score += 1.2;
        for (final et in entry.tokens) {
          if (et.length > 3 && (et.contains(t) || t.contains(et))) score += 0.5;
        }
      }

      final cls = _classes[entry.componentClass];
      if (cls != null) {
        for (final sym in cls.symptomTokens) {
          if (normalized.contains(sym.toLowerCase())) score += 2.0;
        }
      }

      // Boost same trade
      if (entry.tradeId == primaryTrade) score += detected.score * 0.5;

      // Penalize cross-trade confusion (e.g. fan when user said AC)
      if (wrongTrade) score *= 0.15;

      // Penalize ceiling fan entries when AC detected
      if (primaryTrade == 'ac_refrigeration' && entry.componentClass == 'fan_system') score = 0;

      if (score > 0) {
        scored.add(ScoredCatalogEntry(entry: entry, score: score + learningBoost));
      }
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored;
  }

  String? dominantTrade(List<ScoredCatalogEntry> scored) {
    if (scored.isEmpty) return null;
    final tally = <String, double>{};
    for (final s in scored.take(8)) {
      tally[s.entry.tradeId] = (tally[s.entry.tradeId] ?? 0) + s.score;
    }
    return tally.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  TradeDef? tradeById(String id) {
    for (final t in _trades) {
      if (t.id == id) return t;
    }
    return null;
  }

  ComponentClassDef? classDef(String id) => _classes[id];

  int countHighRiskHits(String normalized) {
    var n = 0;
    for (final t in _globalHighRisk) {
      if (normalized.contains(t.toLowerCase())) n++;
    }
    return n;
  }

  int countLowRiskHits(String normalized) {
    var n = 0;
    for (final t in _globalLowRisk) {
      if (normalized.contains(t.toLowerCase())) n++;
    }
    return n;
  }

  ({int min, int max, String partsLabel, String laborLabel}) estimateForEntry(DatasetCatalogEntry entry) {
    int pMin = 0, pMax = 0, lMin = 0, lMax = 0;
    String partsLabel = '';
    String laborLabel = '';

    if (entry.isPart) {
      partsLabel = entry.priceLabel;
      pMin = entry.priceMin;
      pMax = entry.priceMax;
      if (entry.relatedLaborName != null) {
        final labor = _findEntryByName(entry.relatedLaborName!, isPart: false);
        if (labor != null) {
          laborLabel = labor.priceLabel;
          lMin = labor.priceMin;
          lMax = labor.priceMax;
        }
      }
    } else {
      laborLabel = entry.priceLabel;
      lMin = entry.priceMin;
      lMax = entry.priceMax;
      if (entry.relatedPartName != null) {
        final part = _findEntryByName(entry.relatedPartName!, isPart: true);
        if (part != null) {
          partsLabel = part.priceLabel;
          pMin = part.priceMin;
          pMax = part.priceMax;
        }
      }
    }

    if (pMin == 0 && lMin == 0) {
      final trade = tradeById(entry.tradeId);
      if (trade != null) {
        final visit = _findEntryByName(trade.visitFeeMatch, isPart: false, tradeId: entry.tradeId);
        if (visit != null) {
          laborLabel = visit.priceLabel;
          lMin = visit.priceMin;
          lMax = visit.priceMax;
        }
      }
    }

    return (min: pMin + lMin, max: pMax + lMax, partsLabel: partsLabel, laborLabel: laborLabel);
  }

  DatasetCatalogEntry? _findEntryByName(String name, {required bool isPart, String? tradeId}) {
    for (final e in _catalog) {
      if (e.isPart == isPart &&
          e.name.toLowerCase() == name.toLowerCase() &&
          (tradeId == null || e.tradeId == tradeId)) {
        return e;
      }
    }
    for (final e in _catalog) {
      if (e.isPart == isPart &&
          e.name.toLowerCase().contains(name.toLowerCase()) &&
          (tradeId == null || e.tradeId == tradeId)) {
        return e;
      }
    }
    return null;
  }

  String domainLabel(DatasetCatalogEntry entry) {
    switch (entry.tradeId) {
      case 'ac_refrigeration':
        return 'AC / Refrigeration';
      case 'plumber':
        if (entry.componentClass == 'geyser') return 'Geyser / Water Heater';
        if (entry.componentClass == 'pump_tank') return 'Water Pump / Tank';
        if (entry.componentClass == 'plumbing_tap') return 'Tap / Faucet';
        if (entry.componentClass == 'plumbing_drain') return 'Drain / Sewage';
        return 'Plumbing / Water';
      case 'electrician':
        if (entry.componentClass == 'fan_system') return 'Ceiling Fan';
        if (entry.componentClass == 'lighting') return 'Lighting';
        if (entry.componentClass == 'wiring_protection') return 'Wiring / MCB';
        if (entry.componentClass == 'power_backup') return 'UPS / Inverter';
        if (entry.componentClass == 'switch_socket') return 'Switch / Socket';
        return 'Electrical';
      default:
        return entry.category;
    }
  }

  static (int, int) parsePriceRange(String? raw) {
    if (raw == null || raw.isEmpty) return (0, 0);
    final cleaned = raw.replaceAll(RegExp(r'[^0-9\-]'), ' ').trim();
    final parts = cleaned.split(RegExp(r'\s+|-')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return (0, 0);
    if (parts.length == 1) {
      final v = int.tryParse(parts.first) ?? 0;
      return (v, v);
    }
    final a = int.tryParse(parts.first) ?? 0;
    final b = int.tryParse(parts.last) ?? a;
    return (a < b ? a : b, a > b ? a : b);
  }

  int get catalogSize => _catalog.length;
  int get partsCount => _catalog.where((e) => e.isPart).length;
  int get laborCount => _catalog.where((e) => !e.isPart).length;
}
