import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../models/dyslexic_learning_model.dart';
import '../../services/dyslexic_learning_service.dart';
import 'dyslexic_model_viewer_screen.dart';

class DyslexicLearningScreen extends StatefulWidget {
  const DyslexicLearningScreen({super.key});

  @override
  State<DyslexicLearningScreen> createState() => _DyslexicLearningScreenState();
}

class _DyslexicLearningScreenState extends State<DyslexicLearningScreen> with SingleTickerProviderStateMixin {
  final DyslexicLearningService _learningService = DyslexicLearningService();
  final FlutterTts _flutterTts = FlutterTts();
  
  late TabController _tabController;
  List<DyslexicLearningModel> _allModels = [];
  List<DyslexicLearningModel> _displayedModels = [];
  bool _isLoading = true;
  String _searchQuery = '';
  DyslexicContentType? _selectedType;
  DyslexicDifficulty? _selectedDifficulty;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeData();
    _initTts();
  }
  
  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    
    await _learningService.initialize();
    
    setState(() {
      _allModels = _learningService.getAllModels();
      _displayedModels = _allModels;
      _isLoading = false;
    });
  }
  
  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5); // Slower speech for dyslexic users
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }
  
  void _speakText(String text) async {
    await _flutterTts.speak(text);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _flutterTts.stop();
    super.dispose();
  }
  
  void _filterModels() {
    setState(() {
      _displayedModels = _allModels;
      
      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        _displayedModels = _displayedModels
            .where((model) => 
                model.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                model.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                model.labels.any((label) => label.toLowerCase().contains(_searchQuery.toLowerCase())))
            .toList();
      }
      
      // Apply type filter
      if (_selectedType != null) {
        _displayedModels = _displayedModels
            .where((model) => model.contentType == _selectedType)
            .toList();
      }
      
      // Apply difficulty filter
      if (_selectedDifficulty != null) {
        _displayedModels = _displayedModels
            .where((model) => model.difficulty == _selectedDifficulty)
            .toList();
      }
    });
  }
  
  void _openModelViewer(DyslexicLearningModel model) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DyslexicModelViewerScreen(model: model),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dyslexic Learning'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.book),
              text: 'Learn',
            ),
            Tab(
              icon: Icon(Icons.star),
              text: 'Favorites',
            ),
            Tab(
              icon: Icon(Icons.settings),
              text: 'Settings',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMainTab(colorScheme),
          _buildFavoritesTab(colorScheme),
          _buildSettingsTab(colorScheme),
        ],
      ),
    );
  }
  
  Widget _buildMainTab(ColorScheme colorScheme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Search bar
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search learning resources',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (value) {
                  _searchQuery = value;
                  _filterModels();
                },
              ),
              const SizedBox(height: 16),
              
              // Filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Type filter
                    DropdownButton<DyslexicContentType?>(
                      hint: const Text('Content Type'),
                      value: _selectedType,
                      items: [
                        const DropdownMenuItem<DyslexicContentType?>(
                          value: null,
                          child: Text('All Types'),
                        ),
                        ...DyslexicContentType.values.map((type) {
                          return DropdownMenuItem<DyslexicContentType>(
                            value: type,
                            child: Text(type.toString().split('.').last),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value;
                          _filterModels();
                        });
                      },
                    ),
                    const SizedBox(width: 16),
                    
                    // Difficulty filter
                    DropdownButton<DyslexicDifficulty?>(
                      hint: const Text('Difficulty'),
                      value: _selectedDifficulty,
                      items: [
                        const DropdownMenuItem<DyslexicDifficulty?>(
                          value: null,
                          child: Text('All Difficulties'),
                        ),
                        ...DyslexicDifficulty.values.map((difficulty) {
                          return DropdownMenuItem<DyslexicDifficulty>(
                            value: difficulty,
                            child: Text(difficulty.toString().split('.').last),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedDifficulty = value;
                          _filterModels();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Model grid
        Expanded(
          child: _displayedModels.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No learning resources found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Try changing your search or filters',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _displayedModels.length,
                  itemBuilder: (context, index) {
                    final model = _displayedModels[index];
                    return _buildModelCard(model, colorScheme);
                  },
                ),
        ),
      ],
    );
  }
  
  Widget _buildFavoritesTab(ColorScheme colorScheme) {
    final favoriteModels = _learningService.getFavoriteModels();
    
    if (favoriteModels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star_border,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No favorites yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add learning resources to your favorites',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: favoriteModels.length,
      itemBuilder: (context, index) {
        final model = favoriteModels[index];
        return _buildModelCard(model, colorScheme);
      },
    );
  }
  
  Widget _buildSettingsTab(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Learning Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Text to Speech Settings
          const Text(
            'Text to Speech',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            title: const Text('Speech Rate'),
            subtitle: const Text('Adjust how fast text is spoken'),
            trailing: Slider(
              value: 0.5,
              min: 0.1,
              max: 1.0,
              divisions: 9,
              label: 'Medium',
              onChanged: (value) async {
                await _flutterTts.setSpeechRate(value);
                // A simple test to demonstrate the new rate
                _speakText("This is a test of the speech rate");
              },
            ),
          ),
          
          const Divider(),
          
          // Accessibility Settings
          const Text(
            'Accessibility',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('High Contrast Mode'),
            subtitle: const Text('Enhance visibility with higher contrast colors'),
            value: false,
            onChanged: (value) {
              // Toggle high contrast mode
            },
          ),
          SwitchListTile(
            title: const Text('Auto-Read Descriptions'),
            subtitle: const Text('Automatically read descriptions when viewing models'),
            value: true,
            onChanged: (value) {
              // Toggle auto-read
            },
          ),
          
          const Divider(),
          
          // Test Section
          const Text(
            'Test Speech',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.volume_up),
            label: const Text('Test Text to Speech'),
            onPressed: () {
              _speakText('This is a test of the text to speech feature for dyslexic learning.');
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildModelCard(DyslexicLearningModel model, ColorScheme colorScheme) {
    final isFavorite = _learningService.isFavorite(model.id);
    final progress = _learningService.getProgress(model.id);
    
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _openModelViewer(model),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                // Displaying model thumbnail or placeholder
                Container(
                  height: 120,
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: model.thumbnailUrl.startsWith('assets/')
                      ? Image.asset(
                          model.thumbnailUrl,
                          fit: BoxFit.cover,
                        )
                      : const Icon(
                          Icons.view_in_ar,
                          size: 48,
                          color: Colors.grey,
                        ),
                ),
                
                // Difficulty badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: model.difficulty == DyslexicDifficulty.easy
                          ? Colors.green
                          : model.difficulty == DyslexicDifficulty.medium
                              ? Colors.orange
                              : Colors.red,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      model.difficulty.toString().split('.').last,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                // Favorite button
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                        color: isFavorite ? Colors.red : Colors.grey,
                      ),
                      onPressed: () async {
                        final result = await _learningService.toggleFavorite(model.id);
                        setState(() {});
                      },
                    ),
                  ),
                ),
              ],
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    model.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // Description
                  Text(
                    model.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // Type
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      model.contentType.toString().split('.').last,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Progress
                  if (progress > 0)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Progress: ${(progress * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 