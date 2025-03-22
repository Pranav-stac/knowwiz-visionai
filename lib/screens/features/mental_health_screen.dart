import 'package:flutter/material.dart';
import 'dart:async';

class MentalHealthScreen extends StatefulWidget {
  const MentalHealthScreen({super.key});

  @override
  State<MentalHealthScreen> createState() => _MentalHealthScreenState();
}

class _MentalHealthScreenState extends State<MentalHealthScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  String _selectedMood = 'Neutral';
  Timer? _typingTimer;

  final List<MoodOption> _moodOptions = [
    MoodOption(name: 'Happy', emoji: '😊', color: Colors.yellow),
    MoodOption(name: 'Calm', emoji: '😌', color: Colors.blue),
    MoodOption(name: 'Neutral', emoji: '😐', color: Colors.grey),
    MoodOption(name: 'Sad', emoji: '😔', color: Colors.indigo),
    MoodOption(name: 'Anxious', emoji: '😰', color: Colors.orange),
    MoodOption(name: 'Stressed', emoji: '😫', color: Colors.red),
  ];

  @override
  void initState() {
    super.initState();
    _addBotMessage("Hello! I'm your AI mental health assistant. How are you feeling today?");
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    setState(() {
      _messages.add(ChatMessage(
        text: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _messageController.clear();
      _isTyping = true;
    });

    _scrollToBottom();

    // Simulate AI response
    _typingTimer = Timer(const Duration(seconds: 1), () {
      _respondToUserMessage(userMessage);
    });
  }

  void _respondToUserMessage(String userMessage) {
    String botResponse = '';
    
    // Simple keyword-based responses
    final lowerCaseMessage = userMessage.toLowerCase();
    
    if (lowerCaseMessage.contains('sad') || 
        lowerCaseMessage.contains('depress') || 
        lowerCaseMessage.contains('unhappy')) {
      botResponse = "I'm sorry to hear you're feeling down. Remember that it's okay to feel sad sometimes. Would you like to talk about what's bothering you, or would you prefer some suggestions for mood-lifting activities?";
    } else if (lowerCaseMessage.contains('anxious') || 
               lowerCaseMessage.contains('worry') || 
               lowerCaseMessage.contains('stress')) {
      botResponse = "It sounds like you're feeling anxious. Let's take a moment to breathe deeply together. In for 4 counts, hold for 4, and out for 6. Would you like to try a quick grounding exercise?";
    } else if (lowerCaseMessage.contains('happy') || 
               lowerCaseMessage.contains('good') || 
               lowerCaseMessage.contains('great')) {
      botResponse = "I'm glad to hear you're feeling positive! What's contributing to your good mood today?";
    } else if (lowerCaseMessage.contains('help') || 
               lowerCaseMessage.contains('support')) {
      botResponse = "I'm here to support you. Would you like to talk about your feelings, try some relaxation techniques, or perhaps learn about coping strategies?";
    } else if (lowerCaseMessage.contains('thank')) {
      botResponse = "You're welcome! I'm here anytime you need to talk or need support.";
    } else {
      botResponse = "Thank you for sharing. How does talking about this make you feel? Remember, I'm here to listen and support you.";
    }

    setState(() {
      _isTyping = false;
      _addBotMessage(botResponse);
    });
  }

  void _addBotMessage(String message) {
    _messages.add(ChatMessage(
      text: message,
      isUser: false,
      timestamp: DateTime.now(),
    ));
    
    _scrollToBottom();
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

  void _updateMood(String mood) {
    setState(() {
      _selectedMood = mood;
    });
    
    // Respond to mood selection
    String response = '';
    switch (mood) {
      case 'Happy':
        response = "It's wonderful that you're feeling happy! What's bringing you joy today?";
        break;
      case 'Calm':
        response = "A calm mind is a powerful mind. Is there anything specific helping you feel centered today?";
        break;
      case 'Neutral':
        response = "Sometimes a neutral mood can be a good reset. How has your day been so far?";
        break;
      case 'Sad':
        response = "I'm sorry you're feeling sad. Would you like to talk about what's on your mind?";
        break;
      case 'Anxious':
        response = "I notice you're feeling anxious. Would you like to try a quick breathing exercise together?";
        break;
      case 'Stressed':
        response = "Stress can be challenging. What's causing you to feel stressed today?";
        break;
      default:
        response = "Thank you for sharing how you're feeling. Would you like to talk more about it?";
    }
    
    _addBotMessage(response);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mental Wellbeing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Show info about mental health features
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Mood Selector
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
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
            child: Column(
              children: [
                const Text(
                  'How are you feeling today?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _moodOptions.length,
                    itemBuilder: (context, index) {
                      final mood = _moodOptions[index];
                      final isSelected = mood.name == _selectedMood;
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: InkWell(
                          onTap: () => _updateMood(mood.name),
                          borderRadius: BorderRadius.circular(12),
                          child: Column(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? mood.color.withOpacity(0.2)
                                      : isDarkMode
                                          ? Colors.grey[800]
                                          : Colors.grey[100],
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? mood.color
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    mood.emoji,
                                    style: const TextStyle(
                                      fontSize: 30,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                mood.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? mood.color
                                      : null,
                                ),
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

          // Chat Messages
          Expanded(
            child: Container(
              color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _buildMessageBubble(message);
                },
              ),
            ),
          ),

          // Typing indicator
          if (_isTyping)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.psychology,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'AI is typing...',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

          // Message Input
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
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                      ),
                      maxLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
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
                    icon: const Icon(
                      Icons.send,
                      color: Colors.white,
                    ),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showResourcesBottomSheet(context);
        },
        backgroundColor: colorScheme.primary,
        child: const Icon(Icons.healing),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser)
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.psychology,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: message.isUser
                    ? colorScheme.primary
                    : isDarkMode
                        ? Colors.grey[800]
                        : Colors.white,
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
                    message.text,
                    style: TextStyle(
                      fontSize: 16,
                      color: message.isUser
                          ? colorScheme.onPrimary
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: message.isUser
                          ? colorScheme.onPrimary.withOpacity(0.7)
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser)
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.person,
                  color: Colors.grey,
                  size: 24,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showResourcesBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

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
                color: theme.scaffoldBackgroundColor,
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
                          'Mental Health Resources',
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
                  // Resources list
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildResourceCard(
                          title: 'Breathing Exercises',
                          description: 'Simple breathing techniques to help reduce anxiety and stress.',
                          icon: Icons.air,
                          color: Colors.blue,
                          onTap: () {
                            // Navigate to breathing exercises
                          },
                        ),
                        _buildResourceCard(
                          title: 'Guided Meditation',
                          description: 'Calming meditations to help clear your mind and relax.',
                          icon: Icons.self_improvement,
                          color: Colors.purple,
                          onTap: () {
                            // Navigate to guided meditation
                          },
                        ),
                        _buildResourceCard(
                          title: 'Mood Journal',
                          description: 'Track your moods and identify patterns to better understand your emotions.',
                          icon: Icons.book,
                          color: Colors.orange,
                          onTap: () {
                            // Navigate to mood journal
                          },
                        ),
                        _buildResourceCard(
                          title: 'Crisis Helplines',
                          description: 'Emergency contact information for immediate mental health support.',
                          icon: Icons.phone,
                          color: Colors.red,
                          onTap: () {
                            // Navigate to crisis helplines
                          },
                        ),
                        _buildResourceCard(
                          title: 'Positive Affirmations',
                          description: 'Daily affirmations to boost your mood and self-esteem.',
                          icon: Icons.favorite,
                          color: Colors.pink,
                          onTap: () {
                            // Navigate to positive affirmations
                          },
                        ),
                        _buildResourceCard(
                          title: 'Sleep Better',
                          description: 'Tips and techniques for improving your sleep quality.',
                          icon: Icons.nightlight,
                          color: Colors.indigo,
                          onTap: () {
                            // Navigate to sleep better
                          },
                        ),
                      ],
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

  Widget _buildResourceCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[800] : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: color,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
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

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class MoodOption {
  final String name;
  final String emoji;
  final Color color;

  MoodOption({
    required this.name,
    required this.emoji,
    required this.color,
  });
} 