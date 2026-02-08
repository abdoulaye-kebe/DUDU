import 'package:flutter/material.dart';
import '../services/places_service.dart';

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
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<PlaceSuggestion> _suggestions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialValue ?? '';
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;
    
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: renderBox.size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, renderBox.size.height + 5),
          child: Material(
            elevation: 12,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: _suggestions.length,
                separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[200]),
                itemBuilder: (context, index) {
                  return _buildSuggestionItem(_suggestions[index]);
                },
              ),
            ),
          ),
        ),
      ),
    );
    
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _onTextChanged() {
    final query = _controller.text.trim();
    if (query.length >= 1) {
      // Rechercher dès la première lettre
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_controller.text.trim() == query && mounted) {
          _searchPlaces(query);
        }
      });
    } else {
      setState(() {
        _suggestions = [];
      });
      _removeOverlay();
    }
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _removeOverlay();
    } else if (_suggestions.isNotEmpty) {
      _showOverlay();
    }
    // Si on prend le focus et qu'on a déjà du texte, rechercher
    if (_focusNode.hasFocus && _controller.text.trim().length >= 1) {
      _searchPlaces(_controller.text.trim());
    }
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _isLoading = false;
      });
      _removeOverlay();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final placeSuggestions = await PlacesService.getPlaceSuggestions(query);
      if (mounted) {
        // Convertir PlaceSuggestion en format attendu par le widget
        final suggestions = placeSuggestions.map((ps) {
          return PlaceSuggestion(
            name: ps.mainText,
            address: ps.description,
            latitude: ps.localLat ?? 0.0,
            longitude: ps.localLng ?? 0.0,
            type: 'place',
            placeId: ps.placeId,
            isLocal: ps.isLocal,
          );
        }).toList();
        
        setState(() {
          _suggestions = suggestions;
          _isLoading = false;
        });
        print('📍 ${suggestions.length} suggestions trouvées pour "$query"');
        
        // Afficher/masquer l'overlay
        if (_focusNode.hasFocus && suggestions.isNotEmpty) {
          _removeOverlay();
          _showOverlay();
        } else {
          _removeOverlay();
        }
      }
    } catch (e) {
      print('❌ Erreur recherche places: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _removeOverlay();
      }
    }
  }

  Future<void> _selectPlace(PlaceSuggestion place) async {
    // Mettre à jour le texte du champ AVANT de retirer le focus
    setState(() {
      _controller.text = place.address;
    });
    
    _removeOverlay();
    
    // Attendre un peu avant de retirer le focus pour que le texte soit bien affiché
    await Future.delayed(const Duration(milliseconds: 100));
    _focusNode.unfocus();
    
    // Si c'est une suggestion locale, on a déjà les coordonnées
    if (place.isLocal || (place.latitude != 0.0 && place.longitude != 0.0)) {
      print('✅ Adresse sélectionnée: ${place.address}');
      print('📍 Coordonnées: ${place.latitude}, ${place.longitude}');
      widget.onPlaceSelected(place);
      return;
    }
    
    // Sinon, récupérer les coordonnées via l'API
    if (place.placeId != null) {
      try {
        final details = await PlacesService.getPlaceDetails(place.placeId!);
        if (details != null) {
          final updatedPlace = PlaceSuggestion(
            name: place.name,
            address: place.address,
            latitude: details.latitude,
            longitude: details.longitude,
            type: place.type,
            region: place.region,
            placeId: place.placeId,
            isLocal: false,
          );
          print('✅ Adresse sélectionnée: ${updatedPlace.address}');
          print('📍 Coordonnées: ${updatedPlace.latitude}, ${updatedPlace.longitude}');
          widget.onPlaceSelected(updatedPlace);
        } else {
          widget.onPlaceSelected(place);
        }
      } catch (e) {
        print('❌ Erreur récupération coordonnées: $e');
        widget.onPlaceSelected(place);
      }
    } else {
      widget.onPlaceSelected(place);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty) ...[
          Text(
            widget.label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
        ],
        CompositedTransformTarget(
          link: _layerLink,
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            autofocus: false,
            decoration: InputDecoration(
              hintText: widget.hint,
              prefixIcon: Icon(widget.icon, color: const Color(0xFF1B5E20)),
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
                            });
                            _removeOverlay();
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
                borderSide: const BorderSide(color: Color(0xFF1B5E20), width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionItem(PlaceSuggestion suggestion) {
    return InkWell(
      onTap: () => _selectPlace(suggestion),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getIconForType(suggestion.type),
                color: const Color(0xFF1B5E20),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    suggestion.address,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (suggestion.region != null)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  suggestion.region!,
                  style: const TextStyle(
                    color: Color(0xFF1B5E20),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
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

/// Classe pour représenter une suggestion de lieu
class PlaceSuggestion {
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String type;
  final String? region;
  final String? placeId;
  final bool isLocal;

  PlaceSuggestion({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.type,
    this.region,
    this.placeId,
    this.isLocal = false,
  });
}












