import 'package:flutter/material.dart';

class DyslexicLearningModel {
  final String id;
  final String title;
  final String description;
  final String modelUrl;
  final String thumbnailUrl;
  final List<String> labels;
  final DyslexicDifficulty difficulty;
  final DyslexicContentType contentType;
  final List<LearningSupportFeature> supportFeatures;
  final Map<String, String> modelLabels;
  final String? audioDescription;
  final List<DyslexicInteractionPoint>? interactionPoints;

  DyslexicLearningModel({
    required this.id,
    required this.title,
    required this.description,
    required this.modelUrl,
    required this.thumbnailUrl,
    required this.labels,
    required this.difficulty,
    required this.contentType,
    required this.supportFeatures,
    required this.modelLabels,
    this.audioDescription,
    this.interactionPoints,
  });

  // Create a model from json/map data
  factory DyslexicLearningModel.fromMap(Map<String, dynamic> map) {
    return DyslexicLearningModel(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      modelUrl: map['modelUrl'],
      thumbnailUrl: map['thumbnailUrl'],
      labels: List<String>.from(map['labels']),
      difficulty: DyslexicDifficulty.values.firstWhere(
        (e) => e.toString().split('.').last == map['difficulty'],
        orElse: () => DyslexicDifficulty.medium,
      ),
      contentType: DyslexicContentType.values.firstWhere(
        (e) => e.toString().split('.').last == map['contentType'],
        orElse: () => DyslexicContentType.letter,
      ),
      supportFeatures: (map['supportFeatures'] as List)
          .map((e) => LearningSupportFeature.values.firstWhere(
                (feature) => feature.toString().split('.').last == e,
                orElse: () => LearningSupportFeature.audioSupport,
              ))
          .toList(),
      modelLabels: Map<String, String>.from(map['modelLabels']),
      audioDescription: map['audioDescription'],
      interactionPoints: map['interactionPoints'] != null
          ? (map['interactionPoints'] as List)
              .map((e) => DyslexicInteractionPoint.fromMap(e))
              .toList()
          : null,
    );
  }

  // Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'modelUrl': modelUrl,
      'thumbnailUrl': thumbnailUrl,
      'labels': labels,
      'difficulty': difficulty.toString().split('.').last,
      'contentType': contentType.toString().split('.').last,
      'supportFeatures': supportFeatures
          .map((e) => e.toString().split('.').last)
          .toList(),
      'modelLabels': modelLabels,
      'audioDescription': audioDescription,
      'interactionPoints': interactionPoints?.map((e) => e.toMap()).toList(),
    };
  }
}

enum DyslexicDifficulty {
  easy,
  medium,
  hard
}

enum DyslexicContentType {
  letter,
  number,
  word,
  shape,
  concept,
  object
}

enum LearningSupportFeature {
  audioSupport,
  visualHighlighting,
  animatedGuides,
  interactivePoints,
  colorCoding,
  textToSpeech,
  simplifiedText,
  phoneticGuide
}

class DyslexicInteractionPoint {
  final String id;
  final String label;
  final String description;
  final Offset position; // Normalized position (0.0 to 1.0)
  final Color? highlightColor;
  final String? audioClip;

  DyslexicInteractionPoint({
    required this.id,
    required this.label,
    required this.description,
    required this.position,
    this.highlightColor,
    this.audioClip,
  });

  factory DyslexicInteractionPoint.fromMap(Map<String, dynamic> map) {
    return DyslexicInteractionPoint(
      id: map['id'],
      label: map['label'],
      description: map['description'],
      position: Offset(map['position'][0], map['position'][1]),
      highlightColor: map['highlightColor'] != null
          ? Color(int.parse(map['highlightColor'], radix: 16))
          : null,
      audioClip: map['audioClip'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'description': description,
      'position': [position.dx, position.dy],
      'highlightColor': highlightColor?.value.toRadixString(16),
      'audioClip': audioClip,
    };
  }
} 