import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Stores and retrieves learned patterns from customer reviews to improve AI accuracy.
class AiLearningService {
  AiLearningService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const _collection = 'ai_learning_data';

  List<Map<String, dynamic>> _cache = [];
  DateTime? _lastFetch;

  /// Load recent learning entries (cached 5 min).
  Future<List<Map<String, dynamic>>> getLearnedPatterns({bool force = false}) async {
    if (!force &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < const Duration(minutes: 5)) {
      return _cache;
    }
    try {
      final snap = await _firestore
          .collection(_collection)
          .orderBy('count', descending: true)
          .limit(200)
          .get();
      _cache = snap.docs.map((d) {
        final data = Map<String, dynamic>.from(d.data());
        data['id'] = d.id;
        return data;
      }).toList();
      _lastFetch = DateTime.now();
    } catch (e) {
      debugPrint('[AiLearning] fetch error: $e');
    }
    return _cache;
  }

  /// Called after each review — updates keyword→issue→cost mapping.
  Future<void> learnFromReview({
    required String actualIssue,
    required double repairCost,
    required String category,
    String? applianceHint,
  }) async {
    if (actualIssue.trim().isEmpty || repairCost <= 0) return;

    final keywords = _extractKeywords(actualIssue);
    if (keywords.isEmpty) return;

    final signature = keywords.take(5).join('_');
    final docId = '${category.toLowerCase().replaceAll(' ', '_')}_$signature';

    try {
      final ref = _firestore.collection(_collection).doc(docId);
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (snap.exists) {
          final data = snap.data()!;
          final count = (data['count'] as num? ?? 0).toInt() + 1;
          final prevAvg = (data['avgCost'] as num?)?.toDouble() ?? repairCost;
          final newAvg = ((prevAvg * (count - 1)) + repairCost) / count;
          tx.update(ref, {
            'count': count,
            'avgCost': newAvg.round(),
            'lastCost': repairCost,
            'lastIssue': actualIssue.trim(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          tx.set(ref, {
            'category': category,
            'applianceHint': applianceHint ?? '',
            'keywords': keywords,
            'issueText': actualIssue.trim(),
            'avgCost': repairCost.round(),
            'lastCost': repairCost.round(),
            'count': 1,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
      _lastFetch = null;
    } catch (e) {
      debugPrint('[AiLearning] learn error: $e');
    }
  }

  /// Boost score if learned patterns match input.
  double scoreWithLearning(String input, String faultId, String category) {
    if (_cache.isEmpty) return 0;
    final lower = input.toLowerCase();
    double boost = 0;
    for (final entry in _cache) {
      if ((entry['category'] as String? ?? '') != category) continue;
      final kws = (entry['keywords'] as List<dynamic>?)?.cast<String>() ?? [];
      int matches = 0;
      for (final kw in kws) {
        if (lower.contains(kw)) matches++;
      }
      if (matches >= 2) {
        boost += 0.15 * matches;
      } else if (matches == 1) {
        boost += 0.08;
      }
    }
    return boost.clamp(0, 0.4);
  }

  /// Adjust cost estimate using learned average for similar issues.
  (int min, int max)? learnedCostHint(String input, String category) {
    final lower = input.toLowerCase();
    for (final entry in _cache) {
      if ((entry['category'] as String? ?? '') != category) continue;
      final kws = (entry['keywords'] as List<dynamic>?)?.cast<String>() ?? [];
      int matches = 0;
      for (final kw in kws) {
        if (lower.contains(kw)) matches++;
      }
      if (matches >= 2) {
        final avg = (entry['avgCost'] as num?)?.toInt() ?? 0;
        if (avg > 0) {
          final variance = (avg * 0.15).round();
          return (avg - variance, avg + variance);
        }
      }
    }
    return null;
  }

  List<String> _extractKeywords(String text) {
    final stopWords = {
      'the', 'a', 'an', 'is', 'was', 'are', 'my', 'mera', 'meri', 'mere',
      'hai', 'ho', 'se', 'ka', 'ki', 'ke', 'mein', 'main', 'aur', 'or',
      'and', 'but', 'very', 'bohat', 'bahut', 'issue', 'problem', 'masla',
    };
    final words = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2 && !stopWords.contains(w))
        .toList();
    return words.toSet().toList();
  }

  /// Log diagnosis session for analytics.
  Future<void> logDiagnosis({
    required String input,
    required String appliance,
    required String risk,
    required String faultId,
    required double confidence,
    String? userId,
  }) async {
    try {
      await _firestore.collection('ai_diagnosis_logs').add({
        'input': input,
        'appliance': appliance,
        'risk': risk,
        'faultId': faultId,
        'confidence': confidence,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[AiLearning] log error: $e');
    }
  }
}
