import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ImageCaptioningScreen extends StatefulWidget {
  const ImageCaptioningScreen({super.key});

  @override
  State<ImageCaptioningScreen> createState() => _ImageCaptioningScreenState();
}

class _ImageCaptioningScreenState extends State<ImageCaptioningScreen> with WidgetsBindingObserver {
  bool _isListening = false;
  final List<CaptionItem> _captions = [];
  final ScrollController _scrollController = ScrollController();
  
  // Speech to text variables
  late stt.SpeechToText _speech;
  bool _speechAvailable = false;
  String _currentVoiceText = '';
  String _speechLocale = 'en_US';
  
  // Image generation variables
  String? _generatedImageUrl;
  bool _isGeneratingImage = false;
  String _lastProcessedText = '';
  
  // Continuous streaming variables
  Timer? _streamProcessTimer;
  int _minWordsForProcessing = 2;
  int _streamProcessDelay = 1000; // milliseconds
  
  // Reliability tracking
  int _restartAttempts = 0;
  static const int _maxRestartAttempts = 3;
  DateTime? _lastRestartTime;
  
  // New variables for the improved restart strategy
  bool _restartPending = false;

  @override
  void initState() {
    super.initState();
    // Add app lifecycle observer
    WidgetsBinding.instance.addObserver(this);
    // Initialize speech recognition
    _speech = stt.SpeechToText();
    _initSpeech();
    _loadPreferences();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _speech.stop();
    _scrollController.dispose();
    _streamProcessTimer?.cancel();
    _listeningMonitorTimer?.cancel();
    _backupTimer?.cancel();
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app being paused or resumed
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (_isListening) {
        _stopListening();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_isListening) {
        _startListening();
      }
    }
  }
  
  // Initialize speech recognition
  void _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        print('Speech recognition status: $status');
        if (status == 'done' || status == 'notListening') {
          if (_isListening) {
            // Only attempt restart if we're not already in the middle of a restart
            if (_lastRestartTime == null || 
                DateTime.now().difference(_lastRestartTime!).inMilliseconds > 1500) {
              print('Status shows speech ended but we want to keep listening - scheduling restart');
              _scheduleRestart(500); // Use a moderate delay before restart
            } else {
              print('Ignoring status event as we recently tried to restart');
            }
          }
        }
      },
      onError: (errorNotification) {
        print('Speech recognition error: ${errorNotification.errorMsg}, permanent: ${errorNotification.permanent}');
        
        // Improve error handling based on error type
        if (_isListening) {
          // Don't restart for permanent errors repeatedly
          if (errorNotification.permanent) {
            if (_restartAttempts >= _maxRestartAttempts) {
              print('Too many permanent errors, temporarily pausing restarts');
              
              // Schedule a delayed restart with increasing backoff
              int delayMs = 2000 + (_restartAttempts * 500);
              _scheduleRestart(delayMs);
              return;
            }
          }
          
          // Handle network or temporary errors with shorter delays
          int delayMs = errorNotification.permanent ? 1200 : 500;
          _scheduleRestart(delayMs);
        }
      },
    );
    setState(() {});
  }
  
  // Schedule a restart with specific delay and tracking
  void _scheduleRestart(int delayMs) {
    // Check if we already have a pending restart
    if (_restartPending) {
      print('Restart already pending, ignoring new request');
      return;
    }
    
    _restartPending = true;
    print('Scheduling restart in ${delayMs}ms (attempt #${_restartAttempts + 1})');
    
    Future.delayed(Duration(milliseconds: delayMs), () {
      _forceRestart();
      _restartPending = false;
    });
  }
  
  // Force a complete restart of speech recognition 
  void _forceRestart() {
    // Cancel existing timers first
    _backupTimer?.cancel();
    _listeningMonitorTimer?.cancel();
    
    // Track restart attempts
    _restartAttempts++;
    _lastRestartTime = DateTime.now();
    
    // If we've been restarting too frequently, use progressive backoff
    int pauseDuration = 300;
    if (_restartAttempts > 1) {
      pauseDuration = 300 * _restartAttempts;
      if (pauseDuration > 2000) pauseDuration = 2000; // cap at 2 seconds
    }
    
    print('Forcing restart with ${pauseDuration}ms delay (attempt #$_restartAttempts)');
    
    // Stop the current speech recognition session
    _speech.stop().then((_) {
      // If user has turned off listening during the restart process, don't continue
      if (!_isListening) {
        print('User stopped listening during restart, aborting');
        return;
      }
      
      // Small additional pause for the system to clean up
      Future.delayed(Duration(milliseconds: pauseDuration), () {
        if (_isListening) {
          // Reset restart counter if it's been a while since our last restart
          if (_lastRestartTime != null && 
              DateTime.now().difference(_lastRestartTime!).inSeconds > 10) {
            print('Resetting restart attempt counter');
            _restartAttempts = 0;
          }
          
          // Max restart limit to prevent infinite loops
          if (_restartAttempts > _maxRestartAttempts * 2) {
            print('Too many restart attempts, forcing a longer pause');
            setState(() {
              _isListening = false;
            });
            
            // Auto-restart after a longer break
            Future.delayed(const Duration(seconds: 5), () {
              if (mounted) {
                setState(() {
                  _isListening = true;
                  _restartAttempts = 0;
                });
                _startSpeechRecognition();
              }
            });
            return;
          }
          
          _startSpeechRecognition();
        }
      });
    }).catchError((e) {
      print('Error stopping speech for restart: $e');
      // Still try to restart after a longer delay
      Future.delayed(Duration(milliseconds: pauseDuration + 500), () {
        if (_isListening) {
          _startSpeechRecognition();
        }
      });
    });
  }
  
  // Start listening without changing _isListening state
  void _startSpeechRecognition() {
    try {
      print('Starting fresh speech recognition');
      _speech.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 30), // Longer sessions
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: _speechLocale,
        listenMode: stt.ListenMode.dictation,
        cancelOnError: false,
      );
      
      // Set up monitoring to detect if speech stops
      _createListeningMonitor();
      
    } catch (e) {
      print('Error in _startSpeechRecognition: $e');
      // Try to restart after a delay
      Future.delayed(const Duration(seconds: 1), () {
        if (_isListening) {
          _scheduleRestart(1000);
        }
      });
    }
  }
  
  // Load user preferences
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _speechLocale = prefs.getString('speech_locale') ?? 'en_US';
      // Load user preference for word count if available
      _minWordsForProcessing = prefs.getInt('min_words_for_processing') ?? 2;
      _streamProcessDelay = prefs.getInt('stream_process_delay') ?? 1000;
    });
  }

  void _toggleListening() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
      // Reset restart attempts
      _restartAttempts = 0;
    }
  }

  // Timer for backup listening check
  Timer? _backupTimer;
  
  void _startListening() async {
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
    
    // Cancel any existing timers
    _streamProcessTimer?.cancel();
    _listeningMonitorTimer?.cancel();
    _backupTimer?.cancel();
    
    setState(() {
      _isListening = true;
      _currentVoiceText = '';
      _restartAttempts = 0;  // Reset restart counter
      _restartPending = false;
    });
    
    // Setup timer for continuous processing
    _streamProcessTimer = Timer.periodic(
      Duration(milliseconds: _streamProcessDelay), 
      (timer) {
        _processCurrentSpeechStream();
      }
    );
    
    // Create a backup timer that keeps checking if we need to restart
    _backupTimer = Timer.periodic(
      const Duration(seconds: 1), // Check more frequently
      (timer) {
        if (_isListening && !_speech.isListening && !_restartPending) {
          print('Backup timer detected speech not listening');
          _scheduleRestart(300); // Quick restart when backup timer detects issue
        }
      }
    );
    
    // Start speech recognition
    _startSpeechRecognition();
  }
  
  void _stopListening() async {
    _streamProcessTimer?.cancel();
    _listeningMonitorTimer?.cancel();
    _backupTimer?.cancel();
    
    setState(() {
      _isListening = false;
    });
    
    try {
      await _speech.stop();
      print('Stopped listening successfully');
    } catch (e) {
      print('Error stopping speech recognition: $e');
    }
    
    // Process one last time if needed
    if (_currentVoiceText.isNotEmpty && _currentVoiceText != _lastProcessedText) {
      _generateImageFromText(_currentVoiceText);
    }
  }
  
  // Process speech text during streaming
  void _processCurrentSpeechStream() {
    if (!_isListening || _currentVoiceText.isEmpty || _isGeneratingImage) {
      return;
    }
    
    // Count words to ensure we have enough content
    final wordCount = _currentVoiceText.trim().split(' ').where((word) => word.isNotEmpty).length;
    
    // Only process if we have new content and enough words
    if (_currentVoiceText != _lastProcessedText && wordCount >= _minWordsForProcessing) {
      print('Processing stream text: "$_currentVoiceText"');
      _generateImageFromText(_currentVoiceText);
      
      // Add to captions for real-time feedback
      _captions.add(
        CaptionItem(
          text: _currentVoiceText,
          timestamp: DateTime.now(),
          speaker: 'User',
          isPartial: true,
        ),
      );
      
      _lastProcessedText = _currentVoiceText;
      _scrollToBottom();
    }
  }
  
  // Handle speech recognition results
  void _onSpeechResult(SpeechRecognitionResult result) {
    // Check if we're still supposed to be listening. If not, ignore the result
    if (!_isListening) return;
    
    setState(() {
      _currentVoiceText = result.recognizedWords;
      
      // Add a new caption if this is a final result
      if (result.finalResult) {
        // Process the final result only if we have recognizable text
        if (_currentVoiceText.isNotEmpty) {
          // Update the last caption if it was partial with the same text
          bool updatedExisting = false;
          if (_captions.isNotEmpty && _captions.last.isPartial && 
              _captions.last.text.trim() == _currentVoiceText.trim()) {
            final updatedList = List<CaptionItem>.from(_captions);
            updatedList[updatedList.length - 1] = CaptionItem(
              text: _currentVoiceText,
              timestamp: DateTime.now(),
              speaker: 'User',
              isPartial: false,
            );
            _captions.clear();
            _captions.addAll(updatedList);
            updatedExisting = true;
          }
          
          // Only add new caption if we didn't update an existing one
          if (!updatedExisting) {
            _captions.add(
              CaptionItem(
                text: _currentVoiceText,
                timestamp: DateTime.now(),
                speaker: 'User',
                isPartial: false,
              ),
            );
          }
          
          // Generate image from the final text if it hasn't been processed already
          if (_currentVoiceText != _lastProcessedText) {
            _generateImageFromText(_currentVoiceText);
            _lastProcessedText = _currentVoiceText;
          }
          
          // Auto-scroll to the bottom
          _scrollToBottom();
          
          // Reset for the next utterance but continue listening
          _currentVoiceText = '';
          
          print('Final result processed, ensuring recognition continues');
        }
        
        // Some Android devices may stop listening after a final result
        // Only check if not already in the middle of a restart
        if (!_restartPending) {
          // Use a short timer to check if speech recognition has actually stopped
          Future.delayed(const Duration(milliseconds: 200), () {
            if (_isListening && !_speech.isListening && !_restartPending) {
              print('Recognition stopped after final result, scheduling restart');
              _scheduleRestart(500);
            }
          });
        }
      }
    });
  }
  
  // Generate image from text using the API
  Future<void> _generateImageFromText(String text) async {
    if (text.isEmpty || _isGeneratingImage) return;
    
    setState(() {
      _isGeneratingImage = true;
    });
    
    try {
      print('Generating image for text: "$text"');
      final response = await http.post(
        Uri.parse("https://pranavai.onrender.com/generate"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "prompt": text
        }),
      );
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        
        if (result.containsKey('images') && result['images'].isNotEmpty) {
          final imageData = result['images'][0];
          
          if (imageData.containsKey('url') && imageData['url'].toString().startsWith('data:image')) {
            setState(() {
              _generatedImageUrl = imageData['url'];
              _isGeneratingImage = false;
            });
            return;
          }
        }
      }
      
      print('Failed to generate image: ${response.statusCode} - ${response.body}');
    } catch (e) {
      print('Error generating image: $e');
    }
    
    setState(() {
      _isGeneratingImage = false;
    });
  }
  
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearCaptions() {
    setState(() {
      _captions.clear();
      _generatedImageUrl = null;
    });
  }

  void _showLanguageSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    final Map<String, String> languageOptions = {
      'English (US)': 'en_US',
      'English (UK)': 'en_GB',
      'Hindi': 'hi_IN',
      'Spanish': 'es_ES',
      'French': 'fr_FR',
      'German': 'de_DE',
    };
    
    // Find current language name from code
    String currentLanguage = 'English (US)';
    languageOptions.forEach((name, code) {
      if (code == _speechLocale) {
        currentLanguage = name;
      }
    });

    // Settings for streaming parameters
    int wordCount = _minWordsForProcessing;
    int delayMs = _streamProcessDelay;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Settings'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Recognition Language:'),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: currentLanguage,
                  isExpanded: true,
                  items: languageOptions.keys.map((name) {
                    return DropdownMenuItem<String>(
                      value: name,
                      child: Text(name),
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
                const Text('Minimum Words For Processing:'),
                Slider(
                  value: wordCount.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: wordCount.toString(),
                  onChanged: (value) {
                    setState(() {
                      wordCount = value.round();
                    });
                  },
                ),
                Text('Process after ${wordCount.toString()} words'),
                
                const SizedBox(height: 16),
                const Text('Processing Delay (ms):'),
                Slider(
                  value: delayMs.toDouble(),
                  min: 500,
                  max: 2000,
                  divisions: 6,
                  label: delayMs.toString(),
                  onChanged: (value) {
                    setState(() {
                      delayMs = value.round();
                    });
                  },
                ),
                Text('Check every ${(delayMs / 1000).toStringAsFixed(1)} seconds'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final code = languageOptions[currentLanguage] ?? 'en_US';
                  await prefs.setString('speech_locale', code);
                  await prefs.setInt('min_words_for_processing', wordCount);
                  await prefs.setInt('stream_process_delay', delayMs);
                  
                  if (mounted) {
                    setState(() {
                      _speechLocale = code;
                      _minWordsForProcessing = wordCount;
                      _streamProcessDelay = delayMs;
                    });
                    Navigator.pop(context);
                    
                    // Update timer if it's running
                    if (_streamProcessTimer != null && _streamProcessTimer!.isActive) {
                      _streamProcessTimer!.cancel();
                      _streamProcessTimer = Timer.periodic(
                        Duration(milliseconds: delayMs), 
                        (timer) => _processCurrentSpeechStream()
                      );
                    }
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Settings saved'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Timer to monitor if listening stopped unexpectedly
  Timer? _listeningMonitorTimer;
  
  void _createListeningMonitor() {
    // Cancel any existing timer
    _listeningMonitorTimer?.cancel();
    
    // Check more frequently if we're still listening
    _listeningMonitorTimer = Timer.periodic(const Duration(milliseconds: 750), (timer) {
      if (_isListening && !_speech.isListening && !_restartPending) {
        print('Monitor detected listening stopped unexpectedly');
        _scheduleRestart(500);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Speech to Image'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _showLanguageSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          // Caption Display Area
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.light
                    ? Colors.grey[100]
                    : Colors.grey[900],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  // Speech status indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: _isListening 
                          ? Colors.green.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isListening 
                            ? Colors.green.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isListening ? Icons.mic : Icons.mic_off,
                          size: 16,
                          color: _isListening ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isListening ? 'Listening continuously' : 'Microphone off',
                          style: TextStyle(
                            fontSize: 12,
                            color: _isListening ? Colors.green : Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Generated Image Section
                  if (_generatedImageUrl != null || _isGeneratingImage)
                    Container(
                      height: 250, // Increased height 
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.light
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
                      child: _isGeneratingImage
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const CircularProgressIndicator(),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Creating your image...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: _generatedImageUrl != null
                                  ? Image.memory(
                                      base64Decode(_generatedImageUrl!.split(',')[1]),
                                      fit: BoxFit.cover,
                                    )
                                  : const SizedBox(),
                            ),
                    ),
                  
                  // Captions
                  Expanded(
                    child: _captions.isEmpty && _currentVoiceText.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.mic_none,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Tap the microphone and start describing an image',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Images will be generated in real-time as you speak',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount: _captions.length,
                          padding: const EdgeInsets.only(bottom: 16),
                          itemBuilder: (context, index) {
                            final caption = _captions[index];
                            // Alternate sides based on index
                            final isLeftSide = index % 2 == 0;
                            
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                mainAxisAlignment: isLeftSide
                                    ? MainAxisAlignment.start
                                    : MainAxisAlignment.end,
                                children: [
                                  if (isLeftSide)
                                    CircleAvatar(
                                      backgroundColor: Colors.blue[100],
                                      radius: 16,
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: Colors.blue[800],
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isLeftSide
                                            ? Colors.blue[50]
                                            : Colors.green[50],
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 5,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                        // Add a special border for partial results
                                        border: caption.isPartial
                                            ? Border.all(
                                                color: Colors.grey.withOpacity(0.3),
                                                width: 1,
                                                style: BorderStyle.solid,
                                              )
                                            : null,
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            caption.text,
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: isLeftSide
                                                  ? Colors.blue[800]
                                                  : Colors.green[800],
                                              fontStyle: caption.isPartial
                                                  ? FontStyle.italic
                                                  : FontStyle.normal,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                _formatTime(caption.timestamp),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              if (caption.isPartial) ...[
                                                const SizedBox(width: 4),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 6, 
                                                    vertical: 2
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[200],
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Text(
                                                    'processing',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (!isLeftSide)
                                    CircleAvatar(
                                      backgroundColor: Colors.green[100],
                                      radius: 16,
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: Colors.green[800],
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                  ),
                  
                  // Display current voice text while listening
                  if (_isListening && _currentVoiceText.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _currentVoiceText,
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Microphone Control Panel
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                // Control Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_captions.isNotEmpty || _generatedImageUrl != null)
                      Container(
                        width: 60,
                        height: 60,
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: Colors.red[400],
                            size: 28,
                          ),
                          onPressed: _clearCaptions,
                        ),
                      ),
                    GestureDetector(
                      onTap: _toggleListening,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: _isListening
                              ? Colors.red
                              : colorScheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _isListening
                                  ? Colors.red.withOpacity(0.3)
                                  : colorScheme.primary.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isListening ? Icons.stop : Icons.mic,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                    if (_generatedImageUrl != null)
                      Container(
                        width: 60,
                        height: 60,
                        margin: const EdgeInsets.only(left: 16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.share,
                            color: Colors.blue[400],
                            size: 28,
                          ),
                          onPressed: () {
                            // Share image
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Sharing not implemented yet'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Status Text
                Text(
                  _isListening
                      ? 'Listening & generating in real-time...'
                      : 'Tap to start listening',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class CaptionItem {
  final String text;
  final DateTime timestamp;
  final String speaker;
  final bool isPartial;

  CaptionItem({
    required this.text,
    required this.timestamp,
    required this.speaker,
    this.isPartial = false,
  });
} 