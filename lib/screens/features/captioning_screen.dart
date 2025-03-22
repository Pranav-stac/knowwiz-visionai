import 'package:flutter/material.dart';
import 'dart:async';

class CaptioningScreen extends StatefulWidget {
  const CaptioningScreen({super.key});

  @override
  State<CaptioningScreen> createState() => _CaptioningScreenState();
}

class _CaptioningScreenState extends State<CaptioningScreen> {
  bool _isListening = false;
  final List<CaptionItem> _captions = [];
  Timer? _timer;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // In a real app, you would initialize speech recognition here
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleListening() {
    setState(() {
      _isListening = !_isListening;
    });

    if (_isListening) {
      // Simulate real-time captioning with sample data
      _simulateCaptioning();
    } else {
      _timer?.cancel();
    }
  }

  void _simulateCaptioning() {
    final sampleTexts = [
      "Hello, how are you doing today?",
      "I'm doing well, thank you for asking.",
      "The weather is beautiful outside.",
      "Would you like to go for a walk later?",
      "That sounds like a great idea!",
      "What time would work best for you?",
      "I'm free after 5 PM this evening.",
      "Perfect, let's meet at the park entrance.",
      "Should I bring anything with me?",
      "Just bring some water and comfortable shoes.",
      "I'm looking forward to our walk!",
      "Me too, it will be nice to get some fresh air.",
    ];

    int index = 0;
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (index < sampleTexts.length && _isListening) {
        setState(() {
          _captions.add(
            CaptionItem(
              text: sampleTexts[index],
              timestamp: DateTime.now(),
              speaker: index % 2 == 0 ? 'Person 1' : 'Person 2',
            ),
          );
        });
        index++;
        
        // Auto-scroll to the bottom
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
    });
  }

  void _clearCaptions() {
    setState(() {
      _captions.clear();
    });
  }

  void _saveCaptions() {
    // In a real app, you would save the captions to a file or database
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Captions saved successfully'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-Time Captioning'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // Navigate to captioning settings
            },
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
              child: _captions.isEmpty
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
                            'Tap the microphone button to start captioning',
                            style: TextStyle(
                              fontSize: 16,
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
                        final isCurrentUser = caption.speaker == 'Person 2';
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            mainAxisAlignment: isCurrentUser
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            children: [
                              if (!isCurrentUser)
                                CircleAvatar(
                                  backgroundColor: Colors.blue[100],
                                  radius: 16,
                                  child: Text(
                                    caption.speaker[0],
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
                                    color: isCurrentUser
                                        ? colorScheme.primary
                                        : theme.brightness == Brightness.light
                                            ? Colors.white
                                            : Colors.grey[800],
                                    borderRadius: BorderRadius.circular(20),
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
                                      Text(
                                        caption.text,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: isCurrentUser
                                              ? colorScheme.onPrimary
                                              : theme.brightness == Brightness.light
                                                  ? Colors.black
                                                  : Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatTime(caption.timestamp),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isCurrentUser
                                              ? colorScheme.onPrimary.withOpacity(0.7)
                                              : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (isCurrentUser)
                                CircleAvatar(
                                  backgroundColor: Colors.green[100],
                                  radius: 16,
                                  child: Text(
                                    caption.speaker[0],
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
          ),

          // Control Panel
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                // Caption Settings
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSettingButton(
                      icon: Icons.text_fields,
                      label: 'Font Size',
                      onTap: () {
                        // Open font size settings
                      },
                    ),
                    _buildSettingButton(
                      icon: Icons.color_lens,
                      label: 'Theme',
                      onTap: () {
                        // Open theme settings
                      },
                    ),
                    _buildSettingButton(
                      icon: Icons.language,
                      label: 'Language',
                      onTap: () {
                        // Open language settings
                      },
                    ),
                    _buildSettingButton(
                      icon: Icons.save_alt,
                      label: 'Save',
                      onTap: _saveCaptions,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Microphone Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_captions.isNotEmpty)
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
                    if (_captions.isNotEmpty)
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
                            // Share captions
                          },
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Status Text
                Text(
                  _isListening
                      ? 'Listening... Tap to stop'
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

  Widget _buildSettingButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.grey[100]
                    : Colors.grey[800],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
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

  CaptionItem({
    required this.text,
    required this.timestamp,
    required this.speaker,
  });
} 