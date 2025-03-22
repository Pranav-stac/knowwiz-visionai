import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:math' as math;

class ARLearningScreen extends StatefulWidget {
  const ARLearningScreen({super.key});

  @override
  State<ARLearningScreen> createState() => _ARLearningScreenState();
}

class _ARLearningScreenState extends State<ARLearningScreen> with TickerProviderStateMixin {
  // TTS for accessibility
  late FlutterTts flutterTts;
  bool isSpeaking = false;
  
  // Animation controllers
  late AnimationController _pulseAnimationController;
  
  // UI State
  bool _isPlacingObject = false;
  bool _isPlanesDetected = false;
  String _statusMessage = "Preparing AR environment...";
  
  // Learning content
  final List<LearningObject> _learningObjects = [
    LearningObject(
      id: '1',
      name: 'Apple',
      description: 'This is an apple. It is a round fruit that grows on trees and is often red, green, or yellow.',
      assetPath: 'assets/images/apple.png',
      category: 'Fruits',
      funFact: 'Apples float in water because they are 25% air!',
      letterAssociation: 'A is for Apple',
    ),
    LearningObject(
      id: '2',
      name: 'Ball',
      description: 'This is a ball. It is round and you can play games with it.',
      assetPath: 'assets/images/ball.png',
      category: 'Toys',
      funFact: 'The oldest known ball was made over 3,000 years ago in Egypt!',
      letterAssociation: 'B is for Ball',
    ),
    LearningObject(
      id: '3',
      name: 'Cat',
      description: 'This is a cat. Cats are small furry animals that people keep as pets.',
      assetPath: 'assets/images/cat.png',
      category: 'Animals',
      funFact: 'Cats can make over 100 different vocal sounds!',
      letterAssociation: 'C is for Cat',
    ),
    LearningObject(
      id: '4',
      name: 'Dog',
      description: 'This is a dog. Dogs are friendly animals that are often kept as pets.',
      assetPath: 'assets/images/dog.png',
      category: 'Animals',
      funFact: 'Dogs have about 1,700 taste buds. Humans have about 9,000!',
      letterAssociation: 'D is for Dog',
    ),
    LearningObject(
      id: '5',
      name: 'Elephant',
      description: 'This is an elephant. Elephants are very large animals with long trunks.',
      assetPath: 'assets/images/elephant.png',
      category: 'Animals',
      funFact: 'Elephants are the only animals that cannot jump!',
      letterAssociation: 'E is for Elephant',
    ),
  ];
  
  LearningObject? _selectedObject;
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Animals', 'Fruits', 'Toys', 'Shapes', 'Letters'];
  
  @override
  void initState() {
    super.initState();
    
    // Initialize TTS
    _initTts();
    
    // Initialize animation controllers
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    // Simulate AR environment ready after a brief delay
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isPlanesDetected = true;
        _statusMessage = "AR environment ready! Select an object below.";
      });
      _speak('AR environment ready! Select an object below to learn about it.');
    });
  }
  
  Future<void> _initTts() async {
    flutterTts = FlutterTts();
    await flutterTts.setLanguage('en-US');
    await flutterTts.setSpeechRate(0.5); // Slower rate for dyslexic kids
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
    
    flutterTts.setStartHandler(() {
      setState(() {
        isSpeaking = true;
      });
    });
    
    flutterTts.setCompletionHandler(() {
      setState(() {
        isSpeaking = false;
      });
    });
    
    flutterTts.setErrorHandler((message) {
      setState(() {
        isSpeaking = false;
      });
    });
  }
  
  void _speak(String text) async {
    if (isSpeaking) {
      await flutterTts.stop();
    }
    
    await flutterTts.speak(text);
  }
  
  @override
  void dispose() {
    flutterTts.stop();
    _pulseAnimationController.dispose();
    super.dispose();
  }
  
  void _showObjectDetails(LearningObject object) {
    _speak('${object.name}. ${object.description}');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    object.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'OpenDyslexic', // Dyslexic-friendly font
                    ),
                  ),
                  IconButton(
                    icon: Icon(isSpeaking ? Icons.stop : Icons.volume_up),
                    onPressed: () {
                      if (isSpeaking) {
                        flutterTts.stop();
                      } else {
                        _speak('${object.name}. ${object.description}');
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                object.letterAssociation,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                  fontFamily: 'OpenDyslexic',
                ),
              ),
              const SizedBox(height: 16),
              // Image of the object
              Center(
                child: Image.asset(
                  object.assetPath,
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                object.description,
                style: const TextStyle(
                  fontSize: 18,
                  height: 1.5, // More spacing between lines for dyslexic readers
                  fontFamily: 'OpenDyslexic',
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Fun Fact: ${object.funFact}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'OpenDyslexic',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  _speak('Let\'s learn about ${object.name}. ${object.description} Here\'s a fun fact: ${object.funFact}');
                },
                icon: const Icon(Icons.play_circle),
                label: const Text(
                  'Learn with Audio',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'OpenDyslexic',
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Interactive 3D visualization space
  Widget _buildARSimulationView() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue.shade200, Colors.blue.shade50],
        ),
      ),
      child: Stack(
        children: [
          // Grid pattern to simulate AR space
          Positioned.fill(
            child: CustomPaint(
              painter: GridPainter(),
            ),
          ),
          
          // Selected object if any
          if (_selectedObject != null)
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.8, end: 1.2),
                duration: const Duration(seconds: 2),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Image.asset(
                      _selectedObject!.assetPath,
                      width: 200,
                      height: 200,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AR Learning for Dyslexic Kids',
          style: TextStyle(fontFamily: 'OpenDyslexic'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              _showHelpDialog();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildARSimulationView(),
          
          // Status message at the top
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'OpenDyslexic',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(isSpeaking ? Icons.volume_off : Icons.volume_up, 
                      color: Colors.white, 
                      size: 20,
                    ),
                    onPressed: () {
                      if (isSpeaking) {
                        flutterTts.stop();
                      } else {
                        _speak(_statusMessage);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom object selection panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Category selection
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final category in _categories)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(
                                category,
                                style: TextStyle(
                                  fontFamily: 'OpenDyslexic',
                                  color: _selectedCategory == category
                                      ? Colors.white
                                      : null,
                                ),
                              ),
                              selected: _selectedCategory == category,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedCategory = category;
                                  });
                                }
                              },
                              selectedColor: Colors.purple,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Object selection
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _learningObjects.length,
                      itemBuilder: (context, index) {
                        final object = _learningObjects[index];
                        
                        // Filter by category
                        if (_selectedCategory != 'All' && 
                            object.category != _selectedCategory) {
                          return const SizedBox.shrink();
                        }
                        
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedObject = object;
                              _statusMessage = "Selected ${object.name}. Tap on it to learn more.";
                            });
                            _speak("Selected ${object.name}. Tap on it to learn more.");
                            
                            // Show details after a brief delay to simulate interaction
                            Future.delayed(const Duration(seconds: 1), () {
                              _showObjectDetails(object);
                            });
                          },
                          child: Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: _selectedObject?.id == object.id
                                  ? Colors.purple.withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedObject?.id == object.id
                                    ? Colors.purple
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      object.name.substring(0, 1),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'OpenDyslexic',
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  object.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'OpenDyslexic',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Loading indicator
          if (_isPlacingObject)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
  
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'How to Use AR Learning',
          style: TextStyle(fontFamily: 'OpenDyslexic'),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              _HelpItem(
                icon: Icons.view_in_ar,
                title: 'Explore AR Objects',
                description: 'Select items from the menu below to see them in 3D space and learn about them.',
              ),
              SizedBox(height: 16),
              _HelpItem(
                icon: Icons.category,
                title: 'Choose a Category',
                description: 'Filter objects by selecting different categories.',
              ),
              SizedBox(height: 16),
              _HelpItem(
                icon: Icons.touch_app,
                title: 'Interactive Learning',
                description: 'Tap on objects to hear audio descriptions and learn interesting facts.',
              ),
              SizedBox(height: 16),
              _HelpItem(
                icon: Icons.volume_up,
                title: 'Audio Support',
                description: 'All content can be read aloud to support different learning styles.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              'Got it!',
              style: TextStyle(fontFamily: 'OpenDyslexic'),
            ),
          ),
        ],
      ),
    );
  }
}

// Grid painter for AR simulation
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    // Draw horizontal lines
    final horizontalLineCount = 20;
    final horizontalSpacing = size.height / horizontalLineCount;
    
    for (int i = 0; i <= horizontalLineCount; i++) {
      final y = i * horizontalSpacing;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    
    // Draw vertical lines
    final verticalLineCount = 20;
    final verticalSpacing = size.width / verticalLineCount;
    
    for (int i = 0; i <= verticalLineCount; i++) {
      final x = i * verticalSpacing;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class _HelpItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  
  const _HelpItem({
    required this.icon,
    required this.title,
    required this.description,
  });
  
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.purple),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFamily: 'OpenDyslexic',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  fontFamily: 'OpenDyslexic',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class LearningObject {
  final String id;
  final String name;
  final String description;
  final String assetPath;
  final String category;
  final String funFact;
  final String letterAssociation;
  
  LearningObject({
    required this.id,
    required this.name,
    required this.description,
    required this.assetPath,
    required this.category,
    required this.funFact,
    required this.letterAssociation,
  });
} 