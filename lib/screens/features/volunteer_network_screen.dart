import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';

class VolunteerNetworkScreen extends StatefulWidget {
  const VolunteerNetworkScreen({super.key});

  @override
  State<VolunteerNetworkScreen> createState() => _VolunteerNetworkScreenState();
}

class _VolunteerNetworkScreenState extends State<VolunteerNetworkScreen> with SingleTickerProviderStateMixin {
  bool _isSearching = false;
  List<Volunteer> _nearbyVolunteers = [];
  List<Volunteer> _favoriteVolunteers = [];
  Timer? _searchTimer;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Navigation',
    'Reading',
    'Shopping',
    'Transport',
    'Medical',
    'Social',
  ];

  final List<Volunteer> _sampleVolunteers = [
    Volunteer(
      id: '1',
      name: 'Sarah Johnson',
      distance: 0.5,
      rating: 4.9,
      totalHelped: 128,
      categories: ['Navigation', 'Reading'],
      imageUrl: null,
      isOnline: true,
      lastActive: DateTime.now(),
    ),
    Volunteer(
      id: '2',
      name: 'Michael Chen',
      distance: 0.8,
      rating: 4.7,
      totalHelped: 95,
      categories: ['Shopping', 'Transport'],
      imageUrl: null,
      isOnline: true,
      lastActive: DateTime.now(),
    ),
    Volunteer(
      id: '3',
      name: 'Priya Sharma',
      distance: 1.2,
      rating: 4.8,
      totalHelped: 156,
      categories: ['Medical', 'Social'],
      imageUrl: null,
      isOnline: false,
      lastActive: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
    Volunteer(
      id: '4',
      name: 'David Wilson',
      distance: 1.5,
      rating: 4.6,
      totalHelped: 82,
      categories: ['Navigation', 'Transport'],
      imageUrl: null,
      isOnline: true,
      lastActive: DateTime.now(),
    ),
    Volunteer(
      id: '5',
      name: 'Aisha Patel',
      distance: 2.0,
      rating: 4.9,
      totalHelped: 210,
      categories: ['Reading', 'Social'],
      imageUrl: null,
      isOnline: false,
      lastActive: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Volunteer(
      id: '6',
      name: 'Carlos Rodriguez',
      distance: 2.3,
      rating: 4.8,
      totalHelped: 175,
      categories: ['Shopping', 'Medical'],
      imageUrl: null,
      isOnline: true,
      lastActive: DateTime.now(),
    ),
  ];

  // Firebase related variables
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  
  // Speech to text variables
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _transcription = '';
  final FlutterTts _flutterTts = FlutterTts();
  
  // For the help request
  String _requestTitle = '';
  List<String> _selectedRequirements = ['Patient'];
  String _selectedDisabilityType = 'visual_impairment';
  List<String> _selectedAssistanceTypes = ['reading'];
  DateTime _dateNeeded = DateTime.now().add(const Duration(days: 3));
  String _durationNeeded = '1 hour';
  String _requestLocation = '';
  String _requestPriority = 'normal';
  
  final List<String> _disabilityTypes = [
    'visual_impairment',
    'hearing_impairment',
    'mobility_impairment',
    'cognitive_impairment',
    'other'
  ];
  
  final List<String> _assistanceTypes = [
    'reading',
    'writing',
    'interpretation',
    'navigation',
    'shopping',
    'transport',
    'medical',
    'social'
  ];
  
  final List<String> _requirements = [
    'Patient',
    'Clear pronunciation',
    'Academic background',
    'ISL proficient',
    'Tech terminology knowledge',
    'Medical knowledge',
    'Driving license'
  ];
  
  final List<String> _durations = [
    '30 minutes',
    '1 hour',
    '2 hours',
    '3 hours',
    '4+ hours'
  ];
  
  final List<String> _priorities = [
    'low',
    'normal',
    'high',
    'urgent'
  ];

  // Add these stream controllers
  late final Stream<DatabaseEvent> _completedRequestsStream;

  // Add these variables at the top of the class
  bool _isProcessingSpeech = false;
  String _currentVoiceText = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Initialize stream for completed requests with broadcast
    _completedRequestsStream = _database.child('completed_requests')
        .onValue
        .asBroadcastStream();  // Add this to allow multiple listeners
    
    // Initialize with empty list
    _nearbyVolunteers = [];
    _favoriteVolunteers = [_sampleVolunteers[0], _sampleVolunteers[2]];
    
    // Initialize speech recognition
    _speech = stt.SpeechToText();
    _initSpeech();
    _initTts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    await _speech.initialize(
      onStatus: (status) {
        print('Speech recognition status: $status');
        if (status == 'done' && _isListening) {
          setState(() {
            _isListening = false;
          });
        }
      },
      onError: (error) => print('Speech recognition error: $error'),
    );
  }
  
  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }
  
  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  void _searchVolunteers() {
    setState(() {
      _isSearching = true;
    });

    // Simulate network request
    _searchTimer = Timer(const Duration(seconds: 2), () {
      setState(() {
        _isSearching = false;
        
        // Filter volunteers based on selected category
        if (_selectedCategory == 'All') {
          _nearbyVolunteers = List.from(_sampleVolunteers);
        } else {
          _nearbyVolunteers = _sampleVolunteers
              .where((volunteer) => volunteer.categories.contains(_selectedCategory))
              .toList();
        }
        
        // Sort by distance
        _nearbyVolunteers.sort((a, b) => a.distance.compareTo(b.distance));
      });
    });
  }

  void _toggleFavorite(Volunteer volunteer) {
    setState(() {
      if (_favoriteVolunteers.any((v) => v.id == volunteer.id)) {
        _favoriteVolunteers.removeWhere((v) => v.id == volunteer.id);
      } else {
        _favoriteVolunteers.add(volunteer);
      }
    });
  }

  void _requestHelp(Volunteer volunteer) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Request Help'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('You are about to request help from ${volunteer.name}.'),
                  const SizedBox(height: 16),
                  
                  // Title field
                  const Text('Title:'),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Brief title for your request',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    onChanged: (value) {
                      _requestTitle = value;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Assistance type
                  const Text('What type of assistance do you need?'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: volunteer.categories.contains(_selectedCategory) 
                            ? _selectedCategory
                            : volunteer.categories.first,
                        items: volunteer.categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                            // Add to assistance types
                            _selectedAssistanceTypes = [value.toLowerCase()];
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Disability type
                  const Text('Disability type:'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedDisabilityType,
                        items: _disabilityTypes.map((type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type.replaceAll('_', ' ')),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDisabilityType = value!;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Priority
                  const Text('Priority:'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _requestPriority,
                        items: _priorities.map((priority) {
                          return DropdownMenuItem<String>(
                            value: priority,
                            child: Text(priority),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _requestPriority = value!;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Duration
                  const Text('Duration needed:'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _durationNeeded,
                        items: _durations.map((duration) {
                          return DropdownMenuItem<String>(
                            value: duration,
                            child: Text(duration),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _durationNeeded = value!;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Location
                  const Text('Location:'),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Where do you need assistance?',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    onChanged: (value) {
                      _requestLocation = value;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Message description
                  const Text('Detailed description:'),
                  const SizedBox(height: 8),
                  TextField(
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: _isListening 
                          ? 'Listening...' 
                          : _transcription.isEmpty 
                              ? 'Describe what you need help with...'
                              : _transcription,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      suffixIcon: IconButton(
                        icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                        onPressed: () {
                          if (!_isListening) {
                            _startListening(setState);
                          } else {
                            _stopListening(setState);
                          }
                        },
                      ),
                    ),
                    controller: TextEditingController(text: _transcription),
                    onChanged: (value) {
                      setState(() {
                        _transcription = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Voice input available. Tap the microphone icon to use speech.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _transcription = '';
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  _submitHelpRequest(volunteer);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Send Request'),
              ),
            ],
          );
        }
      ),
    );
  }
  
  Future<void> _startListening(StateSetter setModalState) async {
    if (!_speech.isAvailable) {
      await _initSpeech();
    }
    
    if (await _speech.initialize()) {
      setModalState(() {
        _isListening = true;
        _transcription = '';
      });
      
      _speak("Please describe what you need help with");
      
      await _speech.listen(
        onResult: (result) {
          setModalState(() {
            _transcription = result.recognizedWords;
          });
        },
      );
    }
  }
  
  void _stopListening(StateSetter setModalState) {
    _speech.stop();
    setModalState(() {
      _isListening = false;
    });
  }
  
  void _submitHelpRequest([Volunteer? volunteer]) {
    // Generate a unique key for the new request
    final newRequestKey = _database.child('help_requests').push().key;
    
    if (newRequestKey == null) {
      _showErrorDialog('Failed to create request');
      return;
    }
    
    // Format the date for Firebase
    final dateFormat = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'");
    final formattedDate = dateFormat.format(_dateNeeded.toUtc());
    final now = dateFormat.format(DateTime.now().toUtc());
    
    // User information would normally come from authentication
    final userId = 'user123';
    
    // Create request object matching the desired format
    final helpRequest = {
      'title': _requestTitle.isEmpty 
          ? 'Need assistance with ${_selectedAssistanceTypes.join(", ")}' 
          : _requestTitle,
      'description': _transcription.isEmpty 
          ? 'Looking for assistance with ${_selectedAssistanceTypes.join(", ")}' 
          : _transcription,
      'user_id': userId,
      'created_at': now,
      'status': 'pending', // Changed from 'active' to 'pending' since no volunteer is assigned yet
      'priority': _requestPriority,
      'location': _requestLocation.isEmpty 
          ? 'Current location' 
          : _requestLocation,
      'date_needed': formattedDate,
      'duration': _durationNeeded,
      'requirements': _selectedRequirements,
      'disability_type': _selectedDisabilityType,
      'assistance_type': _selectedAssistanceTypes,
    };

    // If a specific volunteer is selected, add their information
    if (volunteer != null) {
      helpRequest.addAll({
        'volunteer_id': volunteer.id,
        'volunteer_name': volunteer.name,
        'status': 'active', // Set to active when volunteer is assigned
      });
    }
    
    // Save to Firebase under help_requests node
    _database.child('help_requests').child(newRequestKey).set(helpRequest)
    .then((_) {
      _showRequestSentDialog();
      _resetRequestForm();
    })
    .catchError((error) {
      _showErrorDialog('Failed to submit request: $error');
    });
  }
  
  void _resetRequestForm() {
    setState(() {
      _transcription = '';
      _requestTitle = '';
      _requestLocation = '';
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showRequestSentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Sent'),
        content: const Text(
          'Your help request has been submitted. Available volunteers will be notified and can accept your request.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _speak("Your help request has been submitted. You will be notified when a volunteer accepts.");
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Add this method to analyze speech and extract details
  void _analyzeSpeechAndCreateRequest(String speech) {
    // Simple duration detection
    final durationMatches = RegExp(r'(\d+)\s*(hour|hours|hr|hrs|minute|minutes|min|mins)')
        .allMatches(speech.toLowerCase());
    
    if (durationMatches.isNotEmpty) {
      final match = durationMatches.first;
      final number = int.parse(match.group(1)!);
      final unit = match.group(2)!;
      
      if (unit.contains('hour')) {
        _durationNeeded = '$number hour${number > 1 ? 's' : ''}';
      } else {
        if (number >= 60) {
          _durationNeeded = '${number ~/ 60} hour${(number ~/ 60) > 1 ? 's' : ''}';
        } else {
          _durationNeeded = '1 hour'; // Default to minimum 1 hour
        }
      }
    }

    // Priority detection
    if (speech.toLowerCase().contains('urgent') || 
        speech.toLowerCase().contains('emergency')) {
      _requestPriority = 'urgent';
    } else if (speech.toLowerCase().contains('important')) {
      _requestPriority = 'high';
    }

    // Assistance type detection
    for (final type in _assistanceTypes) {
      if (speech.toLowerCase().contains(type.toLowerCase())) {
        _selectedAssistanceTypes.add(type);
      }
    }

    // Create the request
    setState(() {
      _requestLocation = 'Mumbai'; // Automatic location
      _transcription = speech;
      _requestTitle = 'Voice Request: ${speech.split('.').first}'; // First sentence as title
    });

    // Submit the request
    _submitHelpRequest(null);
  }

  // Add this method for voice input request
  Future<void> _startVoiceRequest() async {
    if (!_speech.isAvailable) {
      await _initSpeech();
    }

    setState(() {
      _isProcessingSpeech = true;
      _currentVoiceText = '';
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Text(
              _isListening ? 'Listening...' : 'Voice Request',
              style: TextStyle(
                color: _isListening ? Colors.red : null,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isListening ? Colors.red : Theme.of(context).colorScheme.primary,
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: Colors.white,
                      size: 40,
                    ),
                    onPressed: () {
                      if (_isListening) {
                        _speech.stop();
                        setModalState(() {
                          _isListening = false;
                        });
                      } else {
                        _speech.listen(
                          onResult: (result) {
                            setModalState(() {
                              _currentVoiceText = result.recognizedWords;
                            });
                          },
                          listenFor: const Duration(seconds: 30),
                          pauseFor: const Duration(seconds: 3),
                          partialResults: true,
                          onSoundLevelChange: null,
                          cancelOnError: true,
                          listenMode: stt.ListenMode.confirmation,
                        );
                        setModalState(() {
                          _isListening = true;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _isListening 
                      ? 'Tap to stop when finished'
                      : 'Tap microphone and describe your request',
                  textAlign: TextAlign.center,
                ),
                if (_currentVoiceText.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _currentVoiceText,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _isProcessingSpeech = false;
                    _currentVoiceText = '';
                  });
                },
                child: const Text('Cancel'),
              ),
              if (!_isListening && _currentVoiceText.isNotEmpty)
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _analyzeSpeechAndCreateRequest(_currentVoiceText);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: const Text('Submit Request'),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Requests'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'New Request'),
            Tab(text: 'Accepted'),  // Updated tab name
          ],
          labelColor: colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: colorScheme.primary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // New Request Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Request Form Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create Help Request',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Title field
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Request Title',
                            hintText: 'Brief title for your request',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                          ),
                          onChanged: (value) {
                            _requestTitle = value;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Assistance Type Chips
                        Text(
                          'Type of Assistance',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _assistanceTypes.map((type) {
                            final isSelected = _selectedAssistanceTypes.contains(type);
                            return FilterChip(
                              label: Text(type),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedAssistanceTypes.add(type);
                                  } else {
                                    _selectedAssistanceTypes.remove(type);
                                  }
                                });
                              },
                              backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                              selectedColor: colorScheme.primary.withOpacity(0.2),
                              checkmarkColor: colorScheme.primary,
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        
                        // Requirements
                        Text(
                          'Requirements',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _requirements.map((req) {
                            final isSelected = _selectedRequirements.contains(req);
                            return FilterChip(
                              label: Text(req),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedRequirements.add(req);
                                  } else {
                                    _selectedRequirements.remove(req);
                                  }
                                });
                              },
                              backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                              selectedColor: colorScheme.primary.withOpacity(0.2),
                              checkmarkColor: colorScheme.primary,
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        
                        // Priority and Duration Row
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _requestPriority,
                                decoration: InputDecoration(
                                  labelText: 'Priority',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                                ),
                                items: _priorities.map((priority) {
                                  return DropdownMenuItem(
                                    value: priority,
                                    child: Text(priority),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _requestPriority = value!;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _durationNeeded,
                                decoration: InputDecoration(
                                  labelText: 'Duration',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                                ),
                                items: _durations.map((duration) {
                                  return DropdownMenuItem(
                                    value: duration,
                                    child: Text(duration),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _durationNeeded = value!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Location
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Location',
                            hintText: 'Where do you need assistance?',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                          ),
                          onChanged: (value) {
                            _requestLocation = value;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Description with Voice Input
                        TextField(
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Description',
                            hintText: _isListening 
                                ? 'Listening...' 
                                : 'Describe what you need help with...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                            suffixIcon: IconButton(
                              icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                              onPressed: () {
                                if (!_isListening) {
                                  _startListening(setState);
                                } else {
                                  _stopListening(setState);
                                }
                              },
                            ),
                          ),
                          controller: TextEditingController(text: _transcription),
                          onChanged: (value) {
                            _transcription = value;
                          },
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _submitHelpRequest(null),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Submit Request',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
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
          
          // Completed Requests Tab
          StreamBuilder<DatabaseEvent>(
            stream: _completedRequestsStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              
              if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.task_alt,  // Updated icon
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No accepted requests yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your accepted requests will appear here',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              // Convert data to list of requests
              final requestsMap = Map<String, dynamic>.from(
                snapshot.data!.snapshot.value as Map
              );
              
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: requestsMap.length,
                itemBuilder: (context, index) {
                  final request = requestsMap.entries.elementAt(index);
                  return _buildCompletedRequestCard(
                    request.key, 
                    Map<String, dynamic>.from(request.value)
                  );
                },
              );
            },
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'voice_request',
            onPressed: _startVoiceRequest,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.mic),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'emergency',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Emergency Help'),
                  content: const Text('This will send an urgent help request. Continue?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _sendEmergencyHelpRequest();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Send Emergency Request'),
                    ),
                  ],
                ),
              );
            },
            backgroundColor: Colors.red,
            icon: const Icon(Icons.sos),
            label: const Text('Emergency'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedRequestCard(String requestId, Map<String, dynamic> request) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Safely access request data with null checks and defaults
    final title = request['title'] as String? ?? 'Untitled Request';
    final description = request['description'] as String? ?? 'No description available';
    final location = request['location'] as String? ?? 'Location not specified';
    final duration = request['duration'] as String? ?? 'Duration not specified';
    final volunteerName = request['volunteer_name'] as String?;
    final completedAt = request['completed_at'] as String?;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[700],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Completed',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (volunteerName != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Completed by: $volunteerName',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Text(
              description,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Expanded(
                  flex: 2,
                  child: Text(
                    location,
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Duration: $duration',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Completed on: ${_formatDate(completedAt)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'Date not available';
    }
    
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM d, y').format(date);
    } catch (e) {
      print('Error parsing date: $dateString');
      return 'Invalid date';
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'normal':
        return Colors.blue;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Update the emergency help request method
  void _sendEmergencyHelpRequest() {
    // Generate a unique key for the emergency request
    final newRequestKey = _database.child('help_requests').push().key;
    
    if (newRequestKey == null) {
      _showErrorDialog('Failed to create emergency request');
      return;
    }
    
    // Format the date for Firebase
    final dateFormat = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'");
    final now = dateFormat.format(DateTime.now().toUtc());
    
    // User information would normally come from authentication
    final userId = 'user123';
    
    // Create emergency request object matching the desired format
    final emergencyRequest = {
      'title': 'EMERGENCY: Immediate assistance needed',
      'description': 'Emergency help request. Please respond immediately.',
      'user_id': userId,
      'created_at': now,
      'status': 'active',
      'priority': 'urgent',
      'location': 'Current location',
      'date_needed': now,
      'duration': '1 hour',
      'requirements': ['Immediate response'],
      'disability_type': _selectedDisabilityType,
      'assistance_type': ['emergency'],
    };
    
    // Save to Firebase under help_requests node
    _database.child('help_requests').child(newRequestKey).set(emergencyRequest)
    .then((_) {
      _showRequestSentDialog();
    })
    .catchError((error) {
      _showErrorDialog('Failed to submit emergency request: $error');
    });
  }
}

class Volunteer {
  final String id;
  final String name;
  final double distance;
  final double rating;
  final int totalHelped;
  final List<String> categories;
  final String? imageUrl;
  final bool isOnline;
  final DateTime lastActive;

  Volunteer({
    required this.id,
    required this.name,
    required this.distance,
    required this.rating,
    required this.totalHelped,
    required this.categories,
    this.imageUrl,
    required this.isOnline,
    required this.lastActive,
  });
} 