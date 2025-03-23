import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dyslexic_learning_model.dart';

class DyslexicLearningService {
  static const String _favoritesKey = 'dyslexic_learning_favorites';
  static const String _progressKey = 'dyslexic_learning_progress';
  
  List<DyslexicLearningModel> _models = [];
  final Set<String> _favorites = {};
  final Map<String, double> _learningProgress = {};
  
  // Singleton pattern
  static final DyslexicLearningService _instance = DyslexicLearningService._internal();
  
  factory DyslexicLearningService() {
    return _instance;
  }
  
  DyslexicLearningService._internal();
  
  Future<void> initialize() async {
    await _loadModels();
    await _loadFavorites();
    await _loadProgress();
  }
  
  Future<void> _loadModels() async {
    try {
      // Load models from a JSON file in the assets
      final String jsonString = await rootBundle.loadString('assets/data/dyslexic_learning_models.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      
      _models = jsonList.map((json) => DyslexicLearningModel.fromMap(json)).toList();
    } catch (e) {
      // In case there's no file yet, create some sample models
      _models = _getSampleModels();
    }
  }
  
  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? favorites = prefs.getStringList(_favoritesKey);
    
    if (favorites != null) {
      _favorites.addAll(favorites);
    }
  }
  
  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final String? progressJson = prefs.getString(_progressKey);
    
    if (progressJson != null) {
      final Map<String, dynamic> progressMap = json.decode(progressJson);
      progressMap.forEach((key, value) {
        _learningProgress[key] = value.toDouble();
      });
    }
  }
  
  Future<void> saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesKey, _favorites.toList());
  }
  
  Future<void> saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final String progressJson = json.encode(_learningProgress);
    await prefs.setString(_progressKey, progressJson);
  }
  
  // Get all models
  List<DyslexicLearningModel> getAllModels() {
    return _models;
  }
  
  // Get models by type
  List<DyslexicLearningModel> getModelsByType(DyslexicContentType type) {
    return _models.where((model) => model.contentType == type).toList();
  }
  
  // Get models by difficulty
  List<DyslexicLearningModel> getModelsByDifficulty(DyslexicDifficulty difficulty) {
    return _models.where((model) => model.difficulty == difficulty).toList();
  }
  
  // Get model by ID
  DyslexicLearningModel? getModelById(String id) {
    try {
      return _models.firstWhere((model) => model.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // Toggle favorite status
  Future<bool> toggleFavorite(String modelId) async {
    if (_favorites.contains(modelId)) {
      _favorites.remove(modelId);
    } else {
      _favorites.add(modelId);
    }
    
    await saveFavorites();
    return _favorites.contains(modelId);
  }
  
  // Check if a model is favorite
  bool isFavorite(String modelId) {
    return _favorites.contains(modelId);
  }
  
  // Get favorite models
  List<DyslexicLearningModel> getFavoriteModels() {
    return _models.where((model) => _favorites.contains(model.id)).toList();
  }
  
  // Update learning progress
  Future<void> updateProgress(String modelId, double progress) async {
    _learningProgress[modelId] = progress;
    await saveProgress();
  }
  
  // Get learning progress
  double getProgress(String modelId) {
    return _learningProgress[modelId] ?? 0.0;
  }
  
  // Get sample models for testing
  List<DyslexicLearningModel> _getSampleModels() {
    return [
      DyslexicLearningModel(
        id: '1',
        title: 'Letter A',
        description: 'Learn the letter A in 3D',
        modelUrl: 'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
        thumbnailUrl: 'assets/images/apple.png',
        labels: ['letter', 'alphabet', 'beginner'],
        difficulty: DyslexicDifficulty.easy,
        contentType: DyslexicContentType.letter,
        supportFeatures: [
          LearningSupportFeature.audioSupport,
          LearningSupportFeature.animatedGuides,
          LearningSupportFeature.visualHighlighting,
        ],
        modelLabels: {
          'main': 'A',
          'pronunciation': 'ay',
          'example': 'Apple',
        },
        audioDescription: 'This is the letter A. It makes the sound "ay" as in "apple".',
        interactionPoints: [
          DyslexicInteractionPoint(
            id: 'a1',
            label: 'Top',
            description: 'This is the top point of the letter A',
            position: const Offset(0.5, 0.1),
            highlightColor: const Color(0xFFFF5252),
          ),
          DyslexicInteractionPoint(
            id: 'a2',
            label: 'Middle',
            description: 'This is the middle bar of the letter A',
            position: const Offset(0.5, 0.5),
            highlightColor: const Color(0xFF4CAF50),
          ),
        ],
      ),
      DyslexicLearningModel(
        id: '2',
        title: 'Number 8',
        description: 'Learn the number 8 in 3D',
        modelUrl: 'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
        thumbnailUrl: 'assets/images/apple.png',
        labels: ['number', 'counting', 'math'],
        difficulty: DyslexicDifficulty.medium,
        contentType: DyslexicContentType.number,
        supportFeatures: [
          LearningSupportFeature.audioSupport,
          LearningSupportFeature.colorCoding,
        ],
        modelLabels: {
          'main': '8',
          'pronunciation': 'eight',
          'fact': 'Eight has two circles',
        },
        audioDescription: 'This is the number 8. It is pronounced "eight".',
      ),
      DyslexicLearningModel(
        id: '3',
        title: 'Apple',
        description: 'Learn about apples in 3D',
        modelUrl: 'https://modelviewer.dev/shared-assets/models/Horse.glb', 
        thumbnailUrl: 'assets/images/apple.png',
        labels: ['fruit', 'food', 'object'],
        difficulty: DyslexicDifficulty.medium,
        contentType: DyslexicContentType.object,
        supportFeatures: [
          LearningSupportFeature.interactivePoints,
          LearningSupportFeature.textToSpeech,
        ],
        modelLabels: {
          'main': 'Apple',
          'color': 'Red',
          'category': 'Fruit',
        },
        audioDescription: 'This is an apple. Apples are fruits that grow on trees.',
        interactionPoints: [
          DyslexicInteractionPoint(
            id: 'ap1',
            label: 'Stem',
            description: 'This is the stem of the apple, which connects it to the tree.',
            position: const Offset(0.5, 0.1),
            highlightColor: const Color(0xFF795548),
          ),
        ],
      ),
    ];
  }
} 