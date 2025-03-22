import 'package:flutter/material.dart';
import 'dart:async';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Initialize with empty list
    _nearbyVolunteers = [];
    _favoriteVolunteers = [_sampleVolunteers[0], _sampleVolunteers[2]];
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchTimer?.cancel();
    super.dispose();
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
      builder: (context) => AlertDialog(
        title: const Text('Request Help'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You are about to request help from ${volunteer.name}.'),
            const SizedBox(height: 16),
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
                  value: volunteer.categories.first,
                  items: volunteer.categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    // Update selected category
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Add a message (optional):'),
            const SizedBox(height: 8),
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Describe what you need help with...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showRequestSentDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send Request'),
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
        content: const Text('Your help request has been sent. A volunteer will respond shortly.'),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Volunteer Network'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Nearby'),
            Tab(text: 'Favorites'),
          ],
          labelColor: colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: colorScheme.primary,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // Navigate to request history
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter
          Container(
            padding: const EdgeInsets.all(16),
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
                // Search Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search volunteers...',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Categories
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = category == _selectedCategory;
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedCategory = category;
                            });
                            _searchVolunteers();
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.primary
                                  : isDarkMode
                                      ? Colors.grey[800]
                                      : Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? colorScheme.primary
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                category,
                                style: TextStyle(
                                  color: isSelected
                                      ? colorScheme.onPrimary
                                      : null,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Nearby Volunteers Tab
                _isSearching
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Searching for nearby volunteers...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _nearbyVolunteers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 80,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No volunteers found nearby',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap the search button to find volunteers',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: _searchVolunteers,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.primary,
                                    foregroundColor: colorScheme.onPrimary,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: const Text(
                                    'Search Now',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _nearbyVolunteers.length,
                            itemBuilder: (context, index) {
                              final volunteer = _nearbyVolunteers[index];
                              return _buildVolunteerCard(volunteer);
                            },
                          ),

                // Favorite Volunteers Tab
                _favoriteVolunteers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.favorite_border,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No favorite volunteers yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add volunteers to your favorites list',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _favoriteVolunteers.length,
                        itemBuilder: (context, index) {
                          final volunteer = _favoriteVolunteers[index];
                          return _buildVolunteerCard(volunteer);
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Emergency help request
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Emergency Help'),
              content: const Text('This will send an urgent help request to all nearby volunteers. Continue?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showRequestSentDialog();
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
    );
  }

  Widget _buildVolunteerCard(Volunteer volunteer) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    final isFavorite = _favoriteVolunteers.any((v) => v.id == volunteer.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Profile Image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      volunteer.name[0],
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            volunteer.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: volunteer.isOnline ? Colors.green : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            volunteer.rating.toString(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${volunteer.distance} km away',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Helped ${volunteer.totalHelped} people',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Favorite Button
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.grey,
                  ),
                  onPressed: () => _toggleFavorite(volunteer),
                ),
              ],
            ),
          ),
          // Categories
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  'Specialties:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 30,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: volunteer.categories.length,
                      itemBuilder: (context, index) {
                        final category = volunteer.categories[index];
                        
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Status and Action
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Status
                Expanded(
                  child: Text(
                    volunteer.isOnline
                        ? 'Available now'
                        : 'Last active ${_formatLastActive(volunteer.lastActive)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: volunteer.isOnline ? Colors.green : Colors.grey[600],
                      fontWeight: volunteer.isOnline ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
                // Request Help Button
                ElevatedButton(
                  onPressed: () => _requestHelp(volunteer),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Request Help',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastActive(DateTime lastActive) {
    final now = DateTime.now();
    final difference = now.difference(lastActive);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
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