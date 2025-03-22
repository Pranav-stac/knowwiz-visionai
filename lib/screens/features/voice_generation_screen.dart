import 'package:flutter/material.dart';

class VoiceGenerationScreen extends StatefulWidget {
  const VoiceGenerationScreen({super.key});

  @override
  State<VoiceGenerationScreen> createState() => _VoiceGenerationScreenState();
}

class _VoiceGenerationScreenState extends State<VoiceGenerationScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _isSpeaking = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _speak() {
    if (_textController.text.isEmpty) return;
    
    setState(() {
      _isSpeaking = true;
    });
    
    // Simulate speech generation
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isSpeaking = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Generation'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _isSpeaking
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.volume_up,
                          size: 50,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('Speaking...'),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.record_voice_over,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Type a message to generate speech',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.light
                  ? Colors.white
                  : Colors.grey[900],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.light
                          ? Colors.grey[100]
                          : Colors.grey[800],
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                      ),
                      maxLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _speak(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isSpeaking ? Icons.stop : Icons.volume_up,
                      color: Colors.white,
                    ),
                    onPressed: _speak,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 