import '../services/nlp_language.dart';

enum RiskLevel { low, high, unknown }

class PossibleIssue {
  const PossibleIssue({
    required this.title,
    required this.causes,
    required this.estimatedCostMin,
    required this.estimatedCostMax,
    required this.confidence,
    this.partsCost,
    this.laborCost,
  });

  final String title;
  final List<String> causes;
  final int estimatedCostMin;
  final int estimatedCostMax;
  final double confidence;
  final String? partsCost;
  final String? laborCost;
}

class DiagnosisResult {
  const DiagnosisResult({
    required this.applianceName,
    required this.category,
    required this.riskLevel,
    required this.confidence,
    required this.matchedFaultId,
    this.diagnosticSteps = const [],
    this.safetyPrecautions = const [],
    this.possibleIssues = const [],
    this.summary = '',
    this.rawInput = '',
    this.needsApplianceChoice = false,
    this.symptomLabel,
    this.visitFeeLabel,
    this.replyLang = ReplyLang.romanUrdu,
  });

  final String applianceName;
  final String category;
  final RiskLevel riskLevel;
  final double confidence;
  final String matchedFaultId;
  final List<String> diagnosticSteps;
  final List<String> safetyPrecautions;
  final List<PossibleIssue> possibleIssues;
  final String summary;
  final String rawInput;

  /// True jab engine appliance identify nahi kar saka — customer khud chunega.
  final bool needsApplianceChoice;

  /// Matched fault ka human label, e.g. "Thanda nahi kar raha".
  final String? symptomLabel;

  /// Trade ki diagnostic visit fee, e.g. "Rs 500–800 per visit".
  final String? visitFeeLabel;

  /// English input → English copy. Urdu / Roman Urdu input → Roman Urdu copy.
  final ReplyLang replyLang;

  bool get isEnglish => replyLang.isEnglish;
  bool get isLowRisk => riskLevel == RiskLevel.low;
  bool get isHighRisk => riskLevel == RiskLevel.high;
  bool get needsTechnician => riskLevel == RiskLevel.high || riskLevel == RiskLevel.unknown;
}
