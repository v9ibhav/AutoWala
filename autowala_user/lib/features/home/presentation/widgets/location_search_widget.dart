import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_constants.dart';
import '../../../../core/utils/logger.dart';

/// Premium location search widget with autocomplete
/// Allows users to search for pickup and dropoff locations
class LocationSearchWidget extends StatefulWidget {
  final Function(LatLng location, String address)? onLocationSelected;
  final String? initialLocation;
  final String hint;

  const LocationSearchWidget({
    super.key,
    this.onLocationSelected,
    this.initialLocation,
    this.hint = 'Where to?',
  });

  @override
  State<LocationSearchWidget> createState() => _LocationSearchWidgetState();
}

class _LocationSearchWidgetState extends State<LocationSearchWidget>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  late AnimationController _animationController;
  bool _isSearching = false;
  bool _isExpanded = false;
  List<LocationSuggestion> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupTextController();

    if (widget.initialLocation != null) {
      _searchController.text = widget.initialLocation!;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: AppConstants.animationDuration,
      vsync: this,
    );

    _focusNode.addListener(() {
      if (_focusNode.hasFocus && !_isExpanded) {
        _expandSearchWidget();
      } else if (!_focusNode.hasFocus && _isExpanded) {
        _collapseSearchWidget();
      }
    });
  }

  void _setupTextController() {
    _searchController.addListener(() {
      if (_searchController.text.length > 2) {
        _performSearch(_searchController.text);
      } else {
        setState(() {
          _suggestions.clear();
        });
      }
    });
  }

  void _expandSearchWidget() {
    setState(() {
      _isExpanded = true;
    });
    _animationController.forward();

    AppLogger.userAction('search_widget_expanded');
  }

  void _collapseSearchWidget() {
    setState(() {
      _isExpanded = false;
      _suggestions.clear();
    });
    _animationController.reverse();

    AppLogger.userAction('search_widget_collapsed');
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      // TODO: Replace with actual Google Places API or backend search
      await Future.delayed(const Duration(milliseconds: 500));

      final mockSuggestions = _getMockSuggestions(query);

      if (mounted) {
        setState(() {
          _suggestions = mockSuggestions;
          _isSearching = false;
        });
      }

      AppLogger.userAction('location_search', parameters: {
        'query': query,
        'suggestions_count': mockSuggestions.length,
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _suggestions.clear();
        });
      }

      AppLogger.error('Location search failed', error);
    }
  }

  List<LocationSuggestion> _getMockSuggestions(String query) {
    // Mock suggestions for demonstration
    final mockData = [
      LocationSuggestion(
        title: 'Andheri Station',
        subtitle: 'Mumbai, Maharashtra',
        location: const LatLng(19.1197, 72.8464),
        type: LocationType.transit,
      ),
      LocationSuggestion(
        title: 'Bandra-Kurla Complex',
        subtitle: 'Bandra East, Mumbai',
        location: const LatLng(19.0635, 72.8663),
        type: LocationType.business,
      ),
      LocationSuggestion(
        title: 'Phoenix Mall',
        subtitle: 'Lower Parel, Mumbai',
        location: const LatLng(19.0138, 72.8302),
        type: LocationType.shopping,
      ),
      LocationSuggestion(
        title: 'Mumbai Airport Terminal 1',
        subtitle: 'Vile Parle, Mumbai',
        location: const LatLng(19.0896, 72.8656),
        type: LocationType.transport,
      ),
      LocationSuggestion(
        title: 'Powai Lake',
        subtitle: 'Powai, Mumbai',
        location: const LatLng(19.1197, 72.9058),
        type: LocationType.landmark,
      ),
    ];

    return mockData
        .where((suggestion) =>
            suggestion.title.toLowerCase().contains(query.toLowerCase()) ||
            suggestion.subtitle.toLowerCase().contains(query.toLowerCase()))
        .take(5)
        .toList();
  }

  void _onSuggestionTapped(LocationSuggestion suggestion) {
    HapticFeedback.lightImpact();

    _searchController.text = suggestion.title;
    _focusNode.unfocus();

    widget.onLocationSelected?.call(suggestion.location, suggestion.title);

    AppLogger.userAction('location_suggestion_selected', parameters: {
      'title': suggestion.title,
      'type': suggestion.type.toString(),
    });
  }

  void _clearSearch() {
    HapticFeedback.lightImpact();
    _searchController.clear();
    _focusNode.unfocus();

    AppLogger.userAction('search_cleared');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppConstants.animationDuration,
      curve: Curves.easeInOut,
      child: Column(
        children: [
          _buildSearchField(),
          if (_isExpanded && _suggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildSuggestionsList(),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.medium,
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        style: AppTextStyles.bodyLarge,
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.gray400,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.gray500,
            size: 24,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: _clearSearch,
                  icon: Icon(
                    Icons.clear,
                    color: AppColors.gray500,
                    size: 20,
                  ),
                )
              : _isSearching
                  ? Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.all(14),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.accentGreen,
                        ),
                      ),
                    )
                  : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            _performSearch(value);
          }
        },
      ),
    );
  }

  Widget _buildSuggestionsList() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: AppColors.primaryWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.medium,
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          return _buildSuggestionItem(suggestion, index);
        },
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(
          begin: -0.1,
          end: 0.0,
          duration: 300.ms,
          curve: Curves.easeOut,
        );
  }

  Widget _buildSuggestionItem(LocationSuggestion suggestion, int index) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _getLocationTypeColor(suggestion.type).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          _getLocationTypeIcon(suggestion.type),
          color: _getLocationTypeColor(suggestion.type),
          size: 20,
        ),
      ),
      title: Text(
        suggestion.title,
        style: AppTextStyles.labelLarge,
      ),
      subtitle: Text(
        suggestion.subtitle,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.gray600,
        ),
      ),
      onTap: () => _onSuggestionTapped(suggestion),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
    ).animate(delay: (index * 50).ms).fadeIn(duration: 200.ms).slideX(
          begin: -0.1,
          end: 0.0,
          duration: 300.ms,
        );
  }

  IconData _getLocationTypeIcon(LocationType type) {
    switch (type) {
      case LocationType.transit:
        return Icons.train;
      case LocationType.business:
        return Icons.business;
      case LocationType.shopping:
        return Icons.shopping_bag;
      case LocationType.transport:
        return Icons.flight;
      case LocationType.landmark:
        return Icons.place;
      case LocationType.residential:
        return Icons.home;
    }
  }

  Color _getLocationTypeColor(LocationType type) {
    switch (type) {
      case LocationType.transit:
        return Colors.blue;
      case LocationType.business:
        return Colors.orange;
      case LocationType.shopping:
        return Colors.purple;
      case LocationType.transport:
        return Colors.green;
      case LocationType.landmark:
        return Colors.red;
      case LocationType.residential:
        return Colors.indigo;
    }
  }
}

/// Model for location suggestions
class LocationSuggestion {
  final String title;
  final String subtitle;
  final LatLng location;
  final LocationType type;
  final String? placeId;

  LocationSuggestion({
    required this.title,
    required this.subtitle,
    required this.location,
    required this.type,
    this.placeId,
  });
}

/// Types of locations for categorization
enum LocationType {
  transit,
  business,
  shopping,
  transport,
  landmark,
  residential,
}
