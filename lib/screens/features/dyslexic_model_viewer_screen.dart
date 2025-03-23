import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../models/dyslexic_learning_model.dart';

class DyslexicModelViewerScreen extends StatefulWidget {
  final DyslexicLearningModel model;

  const DyslexicModelViewerScreen({
    super.key,
    required this.model,
  });

  @override
  State<DyslexicModelViewerScreen> createState() => _DyslexicModelViewerScreenState();
}

class _DyslexicModelViewerScreenState extends State<DyslexicModelViewerScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isLoading = true;
  bool _arMode = false;
  bool _showLabels = true;
  int _currentStep = 0;
  List<String> _learningSteps = [];

  late DyslexicLearningModel _model;

  @override
  void initState() {
    super.initState();
    _model = widget.model;
    _initTts();
    _generateLearningSteps();
    
    // Assume model loading takes about 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
    
    // Speak the description after a short delay
    Future.delayed(const Duration(seconds: 1), () {
      _speakText(_model.audioDescription ?? _model.description);
    });
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  void _speakText(String text) async {
    await _flutterTts.speak(text);
  }

  void _generateLearningSteps() {
    // Create learning steps based on the model type
    switch (_model.contentType) {
      case DyslexicContentType.letter:
        _learningSteps = [
          "This is the letter ${_model.modelLabels['main']}",
          "It's pronounced ${_model.modelLabels['pronunciation']}",
          "A word that starts with this letter is ${_model.modelLabels['example']}",
          "Try tracing the letter with your finger",
          "Now, try to say a different word that starts with this letter",
        ];
        break;
      case DyslexicContentType.number:
        _learningSteps = [
          "This is the number ${_model.modelLabels['main']}",
          "It's pronounced ${_model.modelLabels['pronunciation']}",
          "${_model.modelLabels['fact']}",
          "Try counting to this number",
          "Now, try to identify this number of objects around you",
        ];
        break;
      default:
        _learningSteps = [
          "This is a ${_model.modelLabels['main']}",
          "It's ${_model.modelLabels['color']} in color",
          "It belongs to the category: ${_model.modelLabels['category']}",
          "Try to describe this object",
          "Can you think of other objects like this?",
        ];
        break;
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_model.title),
        actions: [
          IconButton(
            icon: Icon(_arMode ? Icons.view_in_ar : Icons.view_in_ar),
            onPressed: () {
              setState(() {
                _arMode = !_arMode;
              });
            },
            tooltip: _arMode ? 'Exit AR Mode' : 'Enter AR Mode',
          ),
          IconButton(
            icon: Icon(_showLabels ? Icons.label_off : Icons.label),
            onPressed: () {
              setState(() {
                _showLabels = !_showLabels;
              });
            },
            tooltip: _showLabels ? 'Hide Labels' : 'Show Labels',
          ),
        ],
      ),
      body: Column(
        children: [
          // Model Viewer
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                // 3D Model Viewer
                ModelViewer(
                  src: _model.modelUrl,
                  alt: 'A 3D model of ${_model.title}',
                  ar: _arMode,
                  arModes: const ['scene-viewer', 'webxr', 'quick-look'],
                  autoRotate: !_arMode,
                  cameraControls: true,
                  backgroundColor: const Color.fromARGB(0xFF, 0xEE, 0xEE, 0xEE),
                  disableZoom: false,
                ),
                
                // Loading indicator
                if (_isLoading)
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Loading 3D Model...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Interaction Points for the 3D model
                if (_showLabels && _model.interactionPoints != null && !_arMode)
                  ..._model.interactionPoints!.map((point) {
                    // Note: This is a simplified representation.
                    // In a real implementation, you would calculate the actual
                    // screen position based on the 3D model's current orientation
                    return Positioned(
                      left: MediaQuery.of(context).size.width * point.position.dx,
                      top: MediaQuery.of(context).size.height * 0.3 * point.position.dy,
                      child: GestureDetector(
                        onTap: () {
                          _speakText(point.description);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(point.description),
                              backgroundColor: point.highlightColor ?? colorScheme.primary,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: point.highlightColor?.withOpacity(0.8) ?? 
                                  colorScheme.primary.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            point.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
          
          // Learning Content Section
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step-by-Step Learning
                  Text(
                    'Learning Step ${_currentStep + 1}/${_learningSteps.length}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Current Step Content
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _learningSteps[_currentStep],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.volume_up),
                            onPressed: () {
                              _speakText(_learningSteps[_currentStep]);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Navigation Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Previous'),
                        onPressed: _currentStep > 0
                            ? () {
                                setState(() {
                                  _currentStep--;
                                });
                                _speakText(_learningSteps[_currentStep]);
                              }
                            : null,
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Next'),
                        onPressed: _currentStep < _learningSteps.length - 1
                            ? () {
                                setState(() {
                                  _currentStep++;
                                });
                                _speakText(_learningSteps[_currentStep]);
                              }
                            : null,
                      ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Support features badges
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _model.supportFeatures.map((feature) {
                      return Chip(
                        backgroundColor: colorScheme.primaryContainer,
                        label: Text(
                          feature.toString().split('.').last,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.primary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _speakText(_model.audioDescription ?? _model.description);
        },
        child: const Icon(Icons.play_arrow),
        tooltip: 'Listen to description',
      ),
    );
  }
} 