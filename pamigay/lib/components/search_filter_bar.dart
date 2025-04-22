import 'package:flutter/material.dart';
import 'package:pamigay/utils/constants.dart';
import 'package:intl/intl.dart';

class SearchFilterBar extends StatefulWidget {
  final TextEditingController searchController;
  final String selectedStatus;
  final DateTime? selectedDate;
  final List<String> statusOptions;
  final Function(String) onSearchChanged;
  final Function(String) onStatusChanged;
  final Function(DateTime?) onDateChanged;
  final Function() onClearFilters;
  final int filteredCount;
  final int totalCount;

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
  }) : super(key: key);

  @override
  State<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends State<SearchFilterBar> {
  bool _isExpanded = false;
  
  @override
  Widget build(BuildContext context) {
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
                child: TextField(
                  controller: widget.searchController,
                  onChanged: widget.onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: widget.searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            widget.searchController.clear();
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
                      borderSide: BorderSide(color: PamigayColors.primary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Filter toggle button with indicator
              Stack(
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
                          ? PamigayColors.primary
                          : PamigayColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.filter_list,
                        color: _isExpanded ? Colors.white : PamigayColors.primary,
                        size: 24,
                      ),
                    ),
                  ),
                  // Show indicator if filters are active
                  if (widget.selectedStatus != 'All' || widget.selectedDate != null)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          
          // Expandable filter options
          if (_isExpanded) ...[
            const SizedBox(height: 12),
            
            // Status filter
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: widget.selectedStatus,
                  isExpanded: true,
                  hint: const Text('Status'),
                  icon: const Icon(Icons.arrow_drop_down),
                  items: widget.statusOptions.map((String status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      widget.onStatusChanged(newValue);
                    }
                  },
                ),
              ),
            ),
            
            // Date filter
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
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
            ),
            
            // Clear filters button and count row
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
                      foregroundColor: PamigayColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
          ],
          
          // Show count row when collapsed
          if (!_isExpanded && (widget.selectedStatus != 'All' || widget.selectedDate != null))
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
              primary: PamigayColors.primary,
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
