import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../../models/scene_description.dart';
import '../../providers/scene_description_provider.dart';
import '../../services/camera_service.dart';
import '../../services/openai_service.dart';
import 'scene_question_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';

class SceneDescriptionScreen extends StatefulWidget {
  const SceneDescriptionScreen({super.key});

  @override
  State<SceneDescriptionScreen> createState() => _SceneDescriptionScreenState();
}

class _SceneDescriptionScreenState extends State<SceneDescriptionScreen> with SingleTickerProviderStateMixin {
  bool _isScanning = false;
  String _currentDescription = '';
  List<SceneItem> _sceneHistory = [];
  late AnimationController _animationController;
  late Animation<double> _animation;
  Timer? _scanTimer;
  bool _isLiveMode = true;
  
  // Camera Service
  final CameraService _cameraService = CameraService();
  FlutterTts? _flutterTts;
  bool _isSpeaking = false;
  
  // Speech to text variables
  late stt.SpeechToText _speech;
  bool _isListeningForVoiceCommand = false;
  bool _speechAvailable = false;
  
  final List<String> _sampleDescriptions = [
    "A spacious living room with a gray sofa, coffee table, and a TV mounted on the wall. There's a window on the left with natural light coming in.",
    "A kitchen with white cabinets, granite countertops, and stainless steel appliances. There's a fruit bowl on the island with apples and bananas.",
    "A bedroom with a queen-sized bed, two nightstands, and a dresser. The bed has blue bedding and white pillows.",
    "A bathroom with a shower, toilet, and sink. There's a mirror above the sink and a towel rack on the wall.",
    "A park with green grass, trees, and a playground. There are people walking on the paths and children playing on the swings.",
    "A busy street with cars, pedestrians, and storefronts. There's a traffic light at the intersection and a bus stop on the corner.",
    "A restaurant with tables, chairs, and customers. The tables have white tablecloths and there are waiters serving food.",
    "A grocery store with aisles of food, shopping carts, and customers. There's a produce section with fresh fruits and vegetables.",
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController)
      ..addListener(() {
        setState(() {});
      });
    
    _animationController.repeat(reverse: true);
    
    // Initialize camera and TTS
    _initCamera();
    _initTts();
    
    // Initialize speech to text
    _speech = stt.SpeechToText();
    _initSpeech();
    
    // Initialize the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SceneDescriptionProvider>(context, listen: false).init();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scanTimer?.cancel();
    _speech.stop();
    super.dispose();
  }

  void _toggleScanning() {
    setState(() {
      _isScanning = !_isScanning;
    });

    if (_isScanning) {
      _startScanning();
    } else {
      _scanTimer?.cancel();
    }
  }

  void _startScanning() {
    // In a real app, you would use camera and AI to analyze the scene
    
    if (_isLiveMode) {
      // Generate first description immediately
      _generateDescription();
      
      // Start the scanning timer
      _startScanningTimer();
    } else {
      // Single scan mode
      _generateDescription();
      setState(() {
        _isScanning = false;
      });
    }
  }

  void _startScanningTimer() {
    // In live mode, we'll wait for speech to finish before scanning again
    _scanTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      // Only generate a new description if not currently speaking
      if (!_isSpeaking && !Provider.of<SceneDescriptionProvider>(context, listen: false).isLoading) {
        _generateDescription();
      }
    });
  }

  void _generateDescription() async {
    setState(() {
      // Show loading state
      Provider.of<SceneDescriptionProvider>(context, listen: false).setLoading(true);
    });

    try {
      // Take a picture
      final imageFile = await _cameraService.takePicture();
      if (imageFile == null) {
        throw Exception('Failed to capture image');
      }

      print('Image captured successfully: ${imageFile.path}');

      // Use OpenAI to analyze the image
      final openAIService = OpenAIService();
      final description = await openAIService.analyzeImage(imageFile.path);

      print('Got description: ${description.substring(0, min(50, description.length))}...');

      if (description.isNotEmpty) {
        final provider = Provider.of<SceneDescriptionProvider>(context, listen: false);
        // Save to history with the provider
        final scene = await provider.addScene(description, imageFile.path);

        setState(() {
          _currentDescription = description;
        });

        // Speak the description automatically
        print('Speaking description...');
        _speakDescription(description);
      }
    } catch (e) {
      print('Error generating description: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error analyzing image. Using offline mode.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        Provider.of<SceneDescriptionProvider>(context, listen: false).setLoading(false);
      });
    }
  }

  void _toggleMode() {
    setState(() {
      _isLiveMode = !_isLiveMode;
      if (_isScanning && !_isLiveMode) {
        _isScanning = false;
        _scanTimer?.cancel();
      }
    });
  }

  void _clearHistory() {
    setState(() {
      _sceneHistory.clear();
      _currentDescription = '';
    });
  }

  Future<void> _initCamera() async {
    await _cameraService.initialize();
    setState(() {});
  }
  
  Future<void> _initTts() async {
    _flutterTts = FlutterTts();
    
    // Get saved settings or use defaults
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String language = prefs.getString('tts_language') ?? 'en-US';
    double speechRate = prefs.getDouble('tts_speech_rate') ?? 0.5;
    double volume = prefs.getDouble('tts_volume') ?? 1.0;
    double pitch = prefs.getDouble('tts_pitch') ?? 1.0;
    
    // Debug: Print all available languages and voices
    try {
      var availableLanguages = await _flutterTts!.getLanguages;
      print('Available TTS languages: $availableLanguages');
      
      var availableVoices = await _flutterTts!.getVoices;
      print('Available TTS voices: $availableVoices');
      
      // First set language to ensure it's supported
      await _flutterTts!.setLanguage(language);
      
      // For Hindi specifically, explicitly set voice if we can find one
      if (language == 'hi-IN') {
        var voices = await _flutterTts!.getVoices;
        var hindiVoice = voices.where((voice) => 
            voice.toString().toLowerCase().contains('hindi') || 
            voice.toString().contains('hi-IN'));
        
        if (hindiVoice.isNotEmpty) {
          print('Setting Hindi voice: ${hindiVoice.first}');
          await _flutterTts!.setVoice({"name": hindiVoice.first.toString(), "locale": "hi-IN"});
        }
      }
    } catch (e) {
      print('Error setting TTS language: $e');
      // Fallback to English if there's an error
      await _flutterTts!.setLanguage('en-US');
    }
    
    await _flutterTts!.setSpeechRate(speechRate);
    await _flutterTts!.setVolume(volume);
    await _flutterTts!.setPitch(pitch);
    
    // Configure error and completion handlers
    _flutterTts!.setStartHandler(() {
      print('TTS started speaking');
      setState(() {
        _isSpeaking = true;
      });
    });
    
    _flutterTts!.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
        print('TTS completed speaking');
      });
    });
    
    _flutterTts!.setErrorHandler((error) {
      print('TTS error: $error');
      setState(() {
        _isSpeaking = false;
      });
    });
    
    print('TTS initialized with language: $language, rate: $speechRate');
  }

  // Initialize speech recognition
  void _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) => print('Speech recognition status: $status'),
      onError: (error) => print('Speech recognition error: $error'),
    );
    setState(() {});
  }
  
  // Start listening for voice commands
  void _startListeningForVoiceCommand() async {
    if (!_speechAvailable) {
      print('Speech recognition not available');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech recognition not available on this device'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    setState(() {
      _isListeningForVoiceCommand = true;
    });
    
    // Get the current language from preferences
    final prefs = await SharedPreferences.getInstance();
    String languageCode = prefs.getString('tts_language') ?? 'en-US';
    String speechLocale = 'en_US';
    
    // Map TTS language code to STT locale
    if (languageCode == 'hi-IN') {
      speechLocale = 'hi_IN';
    } else if (languageCode == 'es-ES') {
      speechLocale = 'es_ES';
    } else if (languageCode == 'fr-FR') {
      speechLocale = 'fr_FR';
    } else if (languageCode == 'de-DE') {
      speechLocale = 'de_DE';
    }
    
    await _speech.listen(
      onResult: _onVoiceCommandResult,
      listenFor: const Duration(seconds: 5),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      localeId: speechLocale,
    );
  }
  
  // Stop listening for voice commands
  void _stopListeningForVoiceCommand() async {
    await _speech.stop();
    setState(() {
      _isListeningForVoiceCommand = false;
    });
  }
  
  // Handle voice command results
  void _onVoiceCommandResult(SpeechRecognitionResult result) {
    print('Voice command recognized: ${result.recognizedWords}');
    if (result.finalResult) {
      setState(() {
        _isListeningForVoiceCommand = false;
      });
      
      // Process the voice command
      _processVoiceCommand(result.recognizedWords.toLowerCase());
    }
  }
  
  // Process voice command
  void _processVoiceCommand(String command) {
    // Handle different commands
    if (command.contains('describe') || command.contains('scan') || 
        command.contains('what do you see') || command.contains('tell me') ||
        command.contains('batao') || command.contains('dekho')) {
      
      // Generate description
      _generateDescription();
    } 
    // Handle text recognition commands in Hindi and English
    else if (command.contains('text') || command.contains('likha') || 
             command.contains('likha hua') || command.contains('kya likha') ||
             command.contains('read') || command.contains('padho')) {
      
      // Analyze text in the scene
      _analyzeSpecificInfo('text');
    }
    // Handle questions about specific objects
    else if (command.contains('laptop') || command.contains('phone') || 
             command.contains('screen') || command.contains('tv') ||
             command.contains('mobile') || command.contains('computer')) {
      
      // If it seems like a question about what's written on a device
      if (command.contains('kya likha') || command.contains('what') || 
          command.contains('written') || command.contains('show')) {
        _analyzeSpecificInfo('text');
      }
      // For general object identification
      else {
        _analyzeSpecificInfo('location');
      }
    }
    // Handle questions about people
    else if (command.contains('who') || command.contains('person') || 
             command.contains('people') || command.contains('kaun') ||
             command.contains('log') || command.contains('aadmi')) {
      
      _analyzeSpecificInfo('people');
    }
    // Handle hazard questions
    else if (command.contains('hazard') || command.contains('danger') || 
             command.contains('safe') || command.contains('khatra')) {
      
      _analyzeSpecificInfo('hazards');
    }
    // Handle location/setting questions
    else if (command.contains('where') || command.contains('place') || 
             command.contains('location') || command.contains('kahan') ||
             command.contains('jagah')) {
      
      _analyzeSpecificInfo('location');
    }
    else if (command.contains('stop') || command.contains('cancel') || 
             command.contains('ruko') || command.contains('band karo')) {
      
      // Stop scanning/speaking
      if (_isScanning) {
        _toggleScanning();
      }
      if (_isSpeaking) {
        _flutterTts?.stop();
        setState(() {
          _isSpeaking = false;
        });
      }
    }
    else if (command.contains('live') || command.contains('live mode') || 
             command.contains('start live') || command.contains('live scan')) {
      
      // Start live mode
      if (!_isLiveMode) {
        _toggleMode();
      }
      if (!_isScanning) {
        _toggleScanning();
      }
    }
    else if (command.contains('single') || command.contains('single scan') || 
             command.contains('once')) {
      
      // Switch to single scan mode
      if (_isLiveMode) {
        _toggleMode();
      }
      _generateDescription();
    }
    // If no specific command is recognized but it sounds like a question
    // (ends with a question word or has question structure)
    else if (command.contains('?') || command.contains('kya') || 
            command.contains('kaun') || command.contains('kahan') ||
            command.contains('kitna') || command.contains('kaise') ||
            command.contains('what') || command.contains('who') ||
            command.contains('where') || command.contains('when') ||
            command.contains('how') || command.contains('why')) {
      
      // If we have a current scene, navigate to question screen
      final provider = Provider.of<SceneDescriptionProvider>(context, listen: false);
      if (provider.currentScene != null) {
        _navigateToQuestionScreen(provider.currentScene!.id);
        
        // Show a message that they can ask the question in the question screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please ask your question in the question screen'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        // If no scene yet, generate one first
        _generateDescription();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scene Description'),
        actions: [
          IconButton(
            icon: Icon(_isListeningForVoiceCommand ? Icons.mic_off : Icons.mic),
            tooltip: 'Voice commands',
            color: _isListeningForVoiceCommand ? Colors.red : null,
            onPressed: _isListeningForVoiceCommand 
                ? _stopListeningForVoiceCommand 
                : _startListeningForVoiceCommand,
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              _showHistoryBottomSheet(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // Navigate to scene description settings
              _showSettingsDialog();
            },
          ),
        ],
      ),
      body: Consumer<SceneDescriptionProvider>(
        builder: (context, provider, child) {
          final isLoading = provider.isLoading;
          
          return Column(
            children: [
              // Mode Selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[900] : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildModeButton(
                      icon: Icons.videocam,
                      label: 'Live Mode',
                      isSelected: _isLiveMode,
                      onTap: () {
                        if (!_isLiveMode) _toggleMode();
                      },
                    ),
                    const SizedBox(width: 16),
                    _buildModeButton(
                      icon: Icons.camera_alt,
                      label: 'Single Scan',
                      isSelected: !_isLiveMode,
                      onTap: () {
                        if (_isLiveMode) _toggleMode();
                      },
                    ),
                  ],
                ),
              ),

              // Camera Preview / Current Scene
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Camera preview
                    if (_cameraService.isInitialized && _cameraService.controller != null)
                      GestureDetector(
                        onTap: () {
                          // If currently scanning, stop the current description and scan now
                          if (_isSpeaking) {
                            _flutterTts?.stop();
                          }
                          // Cancel existing timer
                          _scanTimer?.cancel();
                          // Generate new description immediately
                          _generateDescription();
                          // If in live mode, restart the timer
                          if (_isLiveMode && _isScanning) {
                            _startScanningTimer();
                          }
                        },
                        child: SizedBox(
                          width: double.infinity,
                          height: double.infinity,
                          child: AspectRatio(
                            aspectRatio: _cameraService.controller!.value.aspectRatio,
                            child: CameraPreview(_cameraService.controller!),
                          ),
                        ),
                      )
                    // Placeholder when camera not available
                    else
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: Colors.black,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt,
                                size: 80,
                                color: Colors.white.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Camera not available',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Loading indicator
                    if (isLoading)
                      Container(
                        color: Colors.black.withOpacity(0.5),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),

                    // Scanning animation
                    if (_isScanning && !isLoading)
                      Container(
                        width: double.infinity,
                        height: 2,
                        margin: EdgeInsets.only(top: size.height * 0.3 * _animation.value),
                        color: colorScheme.primary,
                      ),

                    // Current description overlay
                    if (_currentDescription.isNotEmpty)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.8),
                                Colors.black.withOpacity(0.0),
                              ],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Scene Description',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onPrimary,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: Icon(
                                      _isSpeaking ? Icons.stop : Icons.volume_up,
                                      color: Colors.white,
                                    ),
                                    onPressed: () => _speakDescription(_currentDescription),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.question_answer,
                                      color: Colors.white,
                                    ),
                                    onPressed: provider.currentScene != null
                                        ? () => _navigateToQuestionScreen(provider.currentScene!.id)
                                        : null,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _currentDescription,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  height: 1.4,
                                ),
                                maxLines: 5,
                                overflow: TextOverflow.ellipsis,
                              ),
                              TextButton(
                                onPressed: () {
                                  _showFullDescriptionDialog(_currentDescription);
                                },
                                child: const Text(
                                  'Read More',
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Controls
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[900] : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Feature buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildFeatureButton(
                          icon: Icons.location_on,
                          label: 'Location',
                          onTap: () => _analyzeSpecificInfo('location'),
                        ),
                        _buildFeatureButton(
                          icon: Icons.people,
                          label: 'People',
                          onTap: () => _analyzeSpecificInfo('people'),
                        ),
                        _buildFeatureButton(
                          icon: Icons.text_fields,
                          label: 'Text',
                          onTap: () => _analyzeSpecificInfo('text'),
                        ),
                        _buildFeatureButton(
                          icon: Icons.warning,
                          label: 'Hazards',
                          onTap: () => _analyzeSpecificInfo('hazards'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Main action button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: isLoading ? null : _toggleScanning,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: isLoading
                                  ? Colors.grey
                                  : _isScanning
                                      ? Colors.red
                                      : colorScheme.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: isLoading
                                      ? Colors.grey.withOpacity(0.3)
                                      : _isScanning
                                          ? Colors.red.withOpacity(0.3)
                                          : colorScheme.primary.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : Icon(
                                    _isLiveMode
                                        ? (_isScanning ? Icons.stop : Icons.videocam)
                                        : Icons.camera_alt,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Status text
                    Text(
                      isLoading
                          ? 'Processing image...'
                          : _isScanning
                              ? _isLiveMode
                                  ? 'Live description active... Tap to stop'
                                  : 'Scanning scene...'
                              : _isLiveMode
                                  ? 'Tap to start live description'
                                  : 'Tap to scan the scene',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModeButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary
              : theme.brightness == Brightness.light
                  ? Colors.grey[100]
                  : Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? colorScheme.onPrimary
                  : theme.brightness == Brightness.light
                      ? Colors.black
                      : Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? colorScheme.onPrimary
                    : theme.brightness == Brightness.light
                        ? Colors.black
                        : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.light
                    ? Colors.grey[100]
                    : Colors.grey[800],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 24,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHistoryBottomSheet(BuildContext context) {
    final provider = Provider.of<SceneDescriptionProvider>(context, listen: false);
    final sceneHistory = provider.sceneHistory;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Scene History',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  // History list
                  Expanded(
                    child: sceneHistory.isEmpty
                        ? Center(
                            child: Text(
                              'No scene history yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: sceneHistory.length,
                            itemBuilder: (context, index) {
                              final scene = sceneHistory[index];
                              
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).brightness == Brightness.light
                                        ? Colors.white
                                        : Colors.grey[800],
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Scene image
                                      if (scene.imagePath != null)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.file(
                                            File(scene.imagePath!),
                                            height: 120,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _formatDateTime(scene.timestamp),
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.volume_up,
                                                  color: Colors.blue,
                                                ),
                                                onPressed: () => _speakDescription(scene.description),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.question_answer,
                                                  color: Colors.green,
                                                ),
                                                onPressed: () => _navigateToQuestionScreen(scene.id),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        scene.description,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          height: 1.4,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _showFullDescriptionDialog(scene.description);
                                        },
                                        child: const Text('Read More'),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  if (sceneHistory.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showClearHistoryDialog();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Clear History'),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showFullDescriptionDialog(String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scene Description'),
        content: SingleChildScrollView(
          child: Text(description),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              _speakDescription(description);
              Navigator.pop(context);
            },
            child: Text(
              _isSpeaking ? 'Stop Speaking' : 'Read Aloud',
            ),
          ),
        ],
      ),
    );
  }
  
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scene Description Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.api),
              title: const Text('OpenAI API Key'),
              subtitle: const Text('Set your OpenAI API key for image analysis'),
              onTap: () {
                Navigator.pop(context);
                _showApiKeyDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.mic),
              title: const Text('Speech Settings'),
              subtitle: const Text('Configure text-to-speech options'),
              onTap: () {
                Navigator.pop(context);
                _showTtsSettingsDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera Settings'),
              subtitle: const Text('Configure camera and resolution'),
              onTap: () {
                Navigator.pop(context);
                // Show camera settings
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _showApiKeyDialog() {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set OpenAI API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your OpenAI API key to enable image analysis. Your key is stored securely on your device.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'API Key',
                border: OutlineInputBorder(),
                hintText: 'sk-...',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final provider = Provider.of<SceneDescriptionProvider>(context, listen: false);
                final openAIService = OpenAIService();
                await openAIService.setApiKey(controller.text);
                if (mounted) Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('API key saved'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to clear all scene history? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await Provider.of<SceneDescriptionProvider>(context, listen: false).clearHistory();
              if (mounted) {
                Navigator.pop(context);
                setState(() {
                  _currentDescription = '';
                });
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
  
  void _navigateToQuestionScreen(String sceneId) {
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => SceneQuestionScreen(sceneId: sceneId),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    
    return '$day/$month ${hour}:$minute';
  }

  void _analyzeSpecificInfo(String infoType) async {
    if (!_cameraService.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera is not available'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    final provider = Provider.of<SceneDescriptionProvider>(context, listen: false);
    
    // If we don't have a current scene, take a picture first
    if (provider.currentScene == null) {
      try {
        setState(() {
          provider.setLoading(true);
        });
        
        // Take a picture
        final imageFile = await _cameraService.takePicture();
        if (imageFile == null) {
          throw Exception('Failed to capture image');
        }
        
        // Set the image file in the provider
        provider.setImageFile(imageFile);
        
        // Generate a basic description first
        await provider.generateDescription();
      } catch (e) {
        print('Error capturing image: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          provider.setLoading(false);
        });
        return;
      }
    }
    
    // Now analyze for specific info
    try {
      await provider.analyzeSceneForInfo(infoType);
      
      // Get the analysis result
      final result = provider.currentScene?.analysisResults?[infoType];
      
      if (result != null) {
        // Update the current description
        setState(() {
          _currentDescription = result;
        });
        
        // Speak the result
        _speakDescription(result);
      }
    } catch (e) {
      print('Error analyzing for $infoType: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error analyzing for $infoType: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        provider.setLoading(false);
      });
    }
  }

  void _speakDescription(String description) async {
    if (_flutterTts == null) {
      print('TTS not initialized');
      return;
    }

    try {
      if (_isSpeaking) {
        print('Stopping current speech');
        await _flutterTts!.stop();
        setState(() {
          _isSpeaking = false;
        });
        return;
      }
      
      print('Starting speech');
      // Get current language
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String language = prefs.getString('tts_language') ?? 'en-US';
      
      // Make sure language is set correctly
      await _flutterTts!.setLanguage(language);
      
      // For Hindi specifically, try to set the voice directly
      if (language == 'hi-IN') {
        try {
          var voices = await _flutterTts!.getVoices;
          var hindiVoice = voices.where((voice) => 
              voice.toString().toLowerCase().contains('hindi') || 
              voice.toString().contains('hi-IN'));
          
          if (hindiVoice.isNotEmpty) {
            print('Setting Hindi voice before speaking: ${hindiVoice.first}');
            await _flutterTts!.setVoice({"name": hindiVoice.first.toString(), "locale": "hi-IN"});
          }
        } catch (e) {
          print('Error setting Hindi voice: $e');
        }
      }
      
      // For debugging
      print('Speaking text: ${description.substring(0, min(50, description.length))}...');
      print('With language: $language');
      
      setState(() {
        _isSpeaking = true;
      });
      
      // Speak the text
      var result = await _flutterTts!.speak(description);
      print('TTS speak result: $result');
      // The _isSpeaking will be set to false by the completion handler in _initTts
    } catch (e) {
      print('Error with text-to-speech: $e');
      setState(() {
        _isSpeaking = false;
      });
      
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Speech error: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showTtsSettingsDialog() async {
    if (_flutterTts == null) {
      await _initTts();
    }
    
    // Define common languages that work well with TTS
    final List<Map<String, String>> commonLanguages = [
      {'name': 'English (US)', 'code': 'en-US'},
      {'name': 'English (UK)', 'code': 'en-GB'},
      {'name': 'Hindi', 'code': 'hi-IN'},
      {'name': 'Spanish', 'code': 'es-ES'},
      {'name': 'French', 'code': 'fr-FR'},
      {'name': 'German', 'code': 'de-DE'},
      {'name': 'Italian', 'code': 'it-IT'},
      {'name': 'Japanese', 'code': 'ja-JP'},
      {'name': 'Korean', 'code': 'ko-KR'},
      {'name': 'Chinese', 'code': 'zh-CN'},
    ];
    
    // Get available voices for displaying
    List<dynamic> availableVoices = [];
    try {
      availableVoices = await _flutterTts!.getVoices;
      print('Dialog - Available voices: ${availableVoices.length}');
    } catch (e) {
      print('Error getting voices: $e');
    }
    
    // Get current settings from preferences, or use defaults
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String savedLangCode = prefs.getString('tts_language') ?? 'en-US';
    
    // Find the language name from the code
    String currentLanguage = 'English (US)';
    for (var lang in commonLanguages) {
      if (lang['code'] == savedLangCode) {
        currentLanguage = lang['name']!;
        break;
      }
    }
    
    double speechRate = prefs.getDouble('tts_speech_rate') ?? 0.5;
    double volume = prefs.getDouble('tts_volume') ?? 1.0;
    double pitch = prefs.getDouble('tts_pitch') ?? 1.0;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Speech Settings'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Language:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  DropdownButton<String>(
                    value: currentLanguage,
                    isExpanded: true,
                    items: commonLanguages.map((language) {
                      return DropdownMenuItem<String>(
                        value: language['name'],
                        child: Text(language['name']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          currentLanguage = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Speech Rate:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    value: speechRate,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    label: speechRate.toStringAsFixed(1),
                    onChanged: (value) {
                      setState(() {
                        speechRate = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Volume:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    value: volume,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    label: volume.toStringAsFixed(1),
                    onChanged: (value) {
                      setState(() {
                        volume = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pitch:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    value: pitch,
                    min: 0.5,
                    max: 2.0,
                    divisions: 15,
                    label: pitch.toStringAsFixed(1),
                    onChanged: (value) {
                      setState(() {
                        pitch = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      // Find the language code for the selected language
                      String langCode = 'en-US';
                      for (var lang in commonLanguages) {
                        if (lang['name'] == currentLanguage) {
                          langCode = lang['code']!;
                          break;
                        }
                      }
                      
                      // Test the current settings
                      if (_flutterTts != null) {
                        await _flutterTts!.setLanguage(langCode);
                        
                        // For Hindi specifically, we need to explicitly set a voice
                        if (langCode == 'hi-IN') {
                          var hindiVoices = availableVoices.where((voice) => 
                              voice.toString().toLowerCase().contains('hindi') || 
                              voice.toString().contains('hi-IN'));
                          
                          if (hindiVoices.isNotEmpty) {
                            print('Testing with Hindi voice: ${hindiVoices.first}');
                            await _flutterTts!.setVoice({"name": hindiVoices.first.toString(), "locale": "hi-IN"});
                          }
                        }
                        
                        await _flutterTts!.setSpeechRate(speechRate);
                        await _flutterTts!.setVolume(volume);
                        await _flutterTts!.setPitch(pitch);
                        
                        // Use a language-specific test message
                        String testMessage = "This is a test of the speech settings.";
                        if (langCode == 'hi-IN') {
                          testMessage = "यह वाक् सेटिंग्स का एक परीक्षण है।";
                        } else if (langCode == 'es-ES') {
                          testMessage = "Esta es una prueba de la configuración de voz.";
                        } else if (langCode == 'fr-FR') {
                          testMessage = "Ceci est un test des paramètres vocaux.";
                        } else if (langCode == 'de-DE') {
                          testMessage = "Dies ist ein Test der Spracheinstellungen.";
                        } else if (langCode == 'it-IT') {
                          testMessage = "Questo è un test delle impostazioni vocali.";
                        } else if (langCode == 'ja-JP') {
                          testMessage = "これは音声設定のテストです。";
                        } else if (langCode == 'ko-KR') {
                          testMessage = "이것은 음성 설정 테스트입니다.";
                        } else if (langCode == 'zh-CN') {
                          testMessage = "这是语音设置测试。";
                        }
                        
                        _flutterTts!.speak(testMessage);
                      }
                    },
                    child: const Text('Test Speech'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  // Find the language code for the selected language
                  String langCode = 'en-US';
                  for (var lang in commonLanguages) {
                    if (lang['name'] == currentLanguage) {
                      langCode = lang['code']!;
                      break;
                    }
                  }
                  
                  // Save settings
                  await _flutterTts!.setLanguage(langCode);
                  
                  // For Hindi specifically, we need to explicitly set a voice
                  if (langCode == 'hi-IN') {
                    var hindiVoices = availableVoices.where((voice) => 
                        voice.toString().toLowerCase().contains('hindi') || 
                        voice.toString().contains('hi-IN'));
                    
                    if (hindiVoices.isNotEmpty) {
                      print('Saving Hindi voice: ${hindiVoices.first}');
                      await _flutterTts!.setVoice({"name": hindiVoices.first.toString(), "locale": "hi-IN"});
                    }
                  }
                  
                  await _flutterTts!.setSpeechRate(speechRate);
                  await _flutterTts!.setVolume(volume);
                  await _flutterTts!.setPitch(pitch);
                  
                  // Save to preferences
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('tts_language', langCode);
                  await prefs.setDouble('tts_speech_rate', speechRate);
                  await prefs.setDouble('tts_volume', volume);
                  await prefs.setDouble('tts_pitch', pitch);
                  
                  Navigator.pop(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Speech settings saved'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Text('Save'),
              ),
            ],
          );
        }
      ),
    );
  }
}

class SceneItem {
  final String description;
  final DateTime timestamp;
  final String? imageUrl;

  SceneItem({
    required this.description,
    required this.timestamp,
    this.imageUrl,
  });
} 