import 'package:flutter/material.dart';
import 'package:pamigay/utils/constants.dart';
import 'package:intl/intl.dart';

/// A reusable search and filter bar component with expandable filters.
///
/// This component provides a search input along with filters for status and date,
/// with an expandable/collapsible design for better space usage.
class SearchFilterBar extends StatefulWidget {
  /// Controller for the search text field
  final TextEditingController searchController;
  
  /// Currently selected status filter
  final String selectedStatus;
  
  /// Currently selected date filter
  final DateTime? selectedDate;
  
  /// Available status options for filtering
  final List<String> statusOptions;
  
  /// Callback when search text changes
  final Function(String) onSearchChanged;
  
  /// Callback when status filter changes
  final Function(String) onStatusChanged;
  
  /// Callback when date filter changes
  final Function(DateTime?) onDateChanged;
  
  /// Callback when filters are cleared
  final Function() onClearFilters;
  
  /// Count of items after filtering
  final int filteredCount;
  
  /// Total count of items before filtering
  final int totalCount;
  
  /// Primary color for active elements
  final Color primaryColor;
  
  /// Whether to initially show expanded filters
  final bool initiallyExpanded;
  
  /// Backward compatibility: Alternative name for searchController
  final TextEditingController? controller;
  
  /// Backward compatibility: Alternative name for selectedStatus
  final String? categoryFilter;
  
  /// Backward compatibility: Alternative name for statusOptions
  final List<String>? categoryOptions;
  
  /// Backward compatibility: Alternative name for onStatusChanged
  final Function(String)? onCategoryChanged;

  const SearchFilterBar({
    Key? key,
    required this.searchController,
    required this.selectedStatus,
    required this.selectedDate,
    required this.statusOptions,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onDateChanged,
    required this.onClearFilters,
    required this.filteredCount,
    required this.totalCount,
    this.primaryColor = PamigayColors.primary,
    this.initiallyExpanded = false,
    this.controller, // For backward compatibility
    this.categoryFilter, // For backward compatibility
    this.categoryOptions, // For backward compatibility
    this.onCategoryChanged, // For backward compatibility
  }) : super(key: key);

  @override
  State<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends State<SearchFilterBar> {
  late bool _isExpanded;
  
  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }
  
  @override
  Widget build(BuildContext context) {
    final bool hasActiveFilters = widget.selectedStatus != 'All' || widget.selectedDate != null;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact search row with filter toggle
          Row(
            children: [
              // Search TextField
              Expanded(
                child: _buildSearchField(),
              ),
              
              const SizedBox(width: 8),
              
              // Filter toggle button with indicator
              _buildFilterToggle(hasActiveFilters),
            ],
          ),
          
          // Expanded filter section
          if (_isExpanded)
            _buildExpandedFilters(),
          
          // Show count row when collapsed
          if (!_isExpanded && hasActiveFilters)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Showing ${widget.filteredCount} of ${widget.totalCount} items',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Builds the search text field
  Widget _buildSearchField() {
    return TextField(
      controller: widget.controller ?? widget.searchController,
      onChanged: widget.onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Search...',
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        suffixIcon: (widget.controller ?? widget.searchController).text.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.clear, color: Colors.grey),
              onPressed: () {
                (widget.controller ?? widget.searchController).clear();
                widget.onSearchChanged('');
              },
            )
          : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: widget.primaryColor),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        fillColor: Colors.white,
        filled: true,
      ),
    );
  }

  /// Builds the filter toggle button
  Widget _buildFilterToggle(bool hasActiveFilters) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _isExpanded 
                ? widget.primaryColor
                : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.filter_list,
              color: _isExpanded ? Colors.white : Colors.grey[700],
            ),
          ),
        ),
        if (hasActiveFilters)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
            ),
          ),
      ],
    );
  }

  /// Builds the expanded filters section
  Widget _buildExpandedFilters() {
    // Use compatibility parameter if provided
    final displayStatusOptions = widget.categoryOptions ?? widget.statusOptions;
    final selectedFilter = widget.categoryFilter ?? widget.selectedStatus;
    final onStatusChangedCallback = widget.onCategoryChanged ?? widget.onStatusChanged;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
        
          // Status filter section
          const Text(
            'Status',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          // Status filter chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: displayStatusOptions.map((status) {
              final isSelected = selectedFilter == status;
              return FilterChip(
                label: Text(
                  status,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontSize: 12,
                  ),
                ),
                selected: isSelected,
                onSelected: (bool selected) {
                  if (selected) {
                    onStatusChangedCallback(status);
                  }
                },
                selectedColor: widget.primaryColor,
                backgroundColor: Colors.grey[200],
                checkmarkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 12),
          
          // Date filter
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Date:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.selectedDate == null
                            ? 'Select Date'
                            : DateFormat('MMM d, yyyy').format(widget.selectedDate!),
                          style: TextStyle(
                            color: widget.selectedDate == null ? Colors.grey[600] : Colors.black,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.selectedDate != null)
                        InkWell(
                          onTap: () {
                            widget.onDateChanged(null);
                          },
                          child: const Icon(Icons.clear, size: 16, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Results count and clear filters
          Row(
            children: [
              // Filter results count
              Expanded(
                child: Text(
                  'Showing ${widget.filteredCount} of ${widget.totalCount} items',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              
              // Clear filters button
              if (widget.selectedStatus != 'All' || widget.selectedDate != null)
                TextButton.icon(
                  onPressed: () {
                    widget.onClearFilters();
                    // Close the filter panel after clearing
                    setState(() {
                      _isExpanded = false;
                    });
                  },
                  icon: const Icon(Icons.filter_list_off, size: 16),
                  label: const Text('Clear Filters'),
                  style: TextButton.styleFrom(
                    foregroundColor: widget.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Opens a date picker dialog
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != widget.selectedDate) {
      widget.onDateChanged(picked);
    }
  }
}
