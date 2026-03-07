import 'package:flutter/material.dart';
import '../services/geocoding_service.dart';

class AddressAutocomplete extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final Function(PlaceSuggestion) onPlaceSelected;
  final String? initialValue;

  const AddressAutocomplete({
    Key? key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.onPlaceSelected,
    this.initialValue,
  }) : super(key: key);

  @override
  State<AddressAutocomplete> createState() => _AddressAutocompleteState();
}

class _AddressAutocompleteState extends State<AddressAutocomplete> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<PlaceSuggestion> _suggestions = [];
  bool _isLoading = false;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialValue ?? '';
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (_controller.text.length >= 2) {
      _searchPlaces(_controller.text);
    } else {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
    }
  }

  void _onFocusChanged() {
    setState(() {
      _showSuggestions = _focusNode.hasFocus && _suggestions.isNotEmpty;
    });
  }

  Future<void> _searchPlaces(String query) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final suggestions = await GeocodingService.searchPlaces(query);
      setState(() {
        _suggestions = suggestions;
        _showSuggestions = _focusNode.hasFocus && suggestions.isNotEmpty;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _selectPlace(PlaceSuggestion place) {
    _controller.text = place.address;
    widget.onPlaceSelected(place);
    setState(() {
      _showSuggestions = false;
    });
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: widget.hint,
                prefixIcon: Icon(widget.icon),
                suffixIcon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _controller.clear();
                              setState(() {
                                _suggestions = [];
                                _showSuggestions = false;
                              });
                            },
                          )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            if (_showSuggestions && _suggestions.isNotEmpty)
              Positioned(
                top: 60,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 1,
                        color: Colors.grey[200],
                      ),
                      ...(_suggestions.map((suggestion) => _buildSuggestionItem(suggestion))),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuggestionItem(PlaceSuggestion suggestion) {
    return InkWell(
      onTap: () => _selectPlace(suggestion),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[100]!, width: 1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _getIconForType(suggestion.type),
              color: Colors.blue[600],
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    suggestion.address,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (suggestion.region != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  suggestion.region!,
                  style: TextStyle(
                    color: Colors.blue[600],
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'city':
        return Icons.location_city;
      case 'airport':
        return Icons.flight;
      case 'landmark':
        return Icons.place;
      case 'university':
        return Icons.school;
      case 'market':
        return Icons.store;
      case 'station':
        return Icons.train;
      case 'port':
        return Icons.dock;
      default:
        return Icons.location_on;
    }
  }
}
















