/// Single searchable item built from Dataset.json parts or labor rows.
class DatasetCatalogEntry {
  DatasetCatalogEntry({
    required this.id,
    required this.tradeId,
    required this.category,
    required this.isPart,
    required this.name,
    required this.tokens,
    required this.priceMin,
    required this.priceMax,
    required this.priceLabel,
    required this.confidence,
    required this.componentClass,
    required this.defaultRisk,
    this.relatedPartName,
    this.relatedLaborName,
    this.unit,
  });

  final String id;
  final String tradeId;
  final String category;
  final bool isPart;
  final String name;
  final List<String> tokens;
  final int priceMin;
  final int priceMax;
  final String priceLabel;
  final String confidence;
  final String componentClass;
  final String defaultRisk; // low | high
  final String? relatedPartName;
  final String? relatedLaborName;
  final String? unit;

  bool get isHighRisk => defaultRisk == 'high';
}

class ComponentClassDef {
  ComponentClassDef({
    required this.id,
    required this.detectIn,
    required this.symptomTokens,
    required this.risk,
    required this.checks,
    required this.safety,
    this.tradeId,
  });

  final String id;
  final List<String> detectIn;
  final List<String> symptomTokens;
  final String risk;
  final List<String> checks;
  final List<String> safety;
  final String? tradeId;
}

class TradeDef {
  TradeDef({
    required this.id,
    required this.category,
    required this.partsKey,
    required this.laborKey,
    required this.visitFeeMatch,
  });

  final String id;
  final String category;
  final String partsKey;
  final String laborKey;
  final String visitFeeMatch;
}

class ScoredCatalogEntry {
  ScoredCatalogEntry({required this.entry, required this.score});

  final DatasetCatalogEntry entry;
  final double score;
}
