class BatchInfo {
  final int id;
  final String name;

  BatchInfo({
    required this.id,
    required this.name,
  });

  factory BatchInfo.fromJson(Map<String, dynamic> json) {
    return BatchInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}

class Concept {
  final int id;
  final String title;
  final String videoUrl;
  final String thumbnailFileName;
  final String videoType;
  final List<BatchInfo> batchList;
  final List<String> supportingDocuments;

  Concept({
    required this.id,
    required this.title,
    required this.videoUrl,
    required this.thumbnailFileName,
    required this.videoType,
    required this.batchList,
    required this.supportingDocuments,
  });

  factory Concept.fromJson(Map<String, dynamic> json) {
    final batchListRaw = (json['batchList'] as List? ?? [])
        .map((b) => BatchInfo.fromJson(b))
        .toList();
    return Concept(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      thumbnailFileName: json['thumbnailFileName'] ?? '',
      videoType: json['videoType'] ?? '',
      batchList: batchListRaw,
      supportingDocuments: List<String>.from(json['supportingDocuments'] ?? []),
    );
  }
}

class Module {
  final int id;
  final String name;
  final String tier;
  final String description;
  final bool accessible;
  final List<Concept> concepts;
  final List<Concept> transactionConcepts;

  Module({
    required this.id,
    required this.name,
    required this.tier,
    required this.description,
    required this.accessible,
    required this.concepts,
    required this.transactionConcepts,
  });

  factory Module.fromJson(Map<String, dynamic> json) {
    final conceptsList = (json['concepts'] as List? ?? [])
        .map((c) => Concept.fromJson(c))
        .toList();
    final transactionConceptsList = (json['transactionConcepts'] as List? ?? [])
        .map((c) => Concept.fromJson(c))
        .toList();

    return Module(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      tier: json['tier'] ?? '',
      description: json['description'] ?? '',
      accessible: json['accessible'] ?? false,
      concepts: conceptsList,
      transactionConcepts: transactionConceptsList,
    );
  }
}
