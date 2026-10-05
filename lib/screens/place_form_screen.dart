import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:top_places/models/place.dart';
import 'package:top_places/services/place_service.dart';
import 'package:top_places/services/places_repository.dart';

/// Adds a place, or edits one when [place] is given. The checks are the same
/// as in the database, so a mistake shows here instead of as an error from
/// the server.
class PlaceFormScreen extends StatefulWidget {
  const PlaceFormScreen({super.key, this.place, this.asAdmin = false});

  final Place? place;

  /// An admin's edits keep the place where it is in the review.
  final bool asAdmin;

  @override
  State<PlaceFormScreen> createState() => _PlaceFormScreenState();
}

class _PlaceFormScreenState extends State<PlaceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mapController = MapController();
  late final _name = TextEditingController(text: widget.place?.name);
  late final _address = TextEditingController(text: widget.place?.address);
  late final _imageUrl = TextEditingController(text: widget.place?.imageUrl);
  late final _description = TextEditingController(
    text: widget.place?.description,
  );
  late String? _city = widget.place?.city;

  /// Where the place is; set by a tap on the map.
  late LatLng? _position = switch (widget.place) {
    final place? => LatLng(place.lat, place.lng),
    null => null,
  };
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in [_name, _address, _imageUrl, _description]) {
      controller.dispose();
    }
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final service = context.read<PlaceService?>();
    final position = _position;
    if (service == null || position == null) return;
    final draft = PlaceDraft(
      name: _name.text,
      address: _address.text,
      city: _city!,
      lat: position.latitude,
      lng: position.longitude,
      imageUrl: _imageUrl.text,
      description: _description.text,
    );
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final place = widget.place;
      if (place == null) {
        await service.addPlace(draft);
      } else {
        await service.updatePlace(place.id, draft);
      }
      if (mounted) Navigator.of(context).pop();
    } on PlaceException catch (error) {
      setState(() {
        _error = error.message;
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cities = context.read<PlacesRepository>().cities;
    final place = widget.place;

    return Scaffold(
      appBar: AppBar(
        title: Text(place == null ? 'Local nou' : 'Editează localul'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (place?.status == PlaceStatus.approved && !widget.asAdmin)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'După ce salvezi, localul intră din nou în verificare și '
                      'nu apare în Explorează până nu îl aprobă un '
                      'administrator.',
                    ),
                  ),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Nume'),
                  validator: (value) => _length(value, 2, 80),
                ),
                TextFormField(
                  controller: _address,
                  decoration: const InputDecoration(
                    labelText: 'Adresă',
                    hintText: 'Str. Lăpușneanu, Nr. 12',
                  ),
                  validator: (value) => _length(value, 3, 120),
                ),
                DropdownButtonFormField<String>(
                  initialValue: _city,
                  decoration: const InputDecoration(labelText: 'Oraș'),
                  items: [
                    for (final city in cities)
                      DropdownMenuItem(
                        value: city.name,
                        child: Text(city.name),
                      ),
                  ],
                  validator: (value) => value == null ? 'Alege orașul.' : null,
                  onChanged: (name) {
                    setState(() => _city = name);
                    // Shows the chosen city, ready for a tap on the place.
                    final city = cities.firstWhere((city) => city.name == name);
                    _mapController.move(LatLng(city.lat, city.lng), 13);
                  },
                ),
                const SizedBox(height: 16),
                FormField<LatLng>(
                  initialValue: _position,
                  validator: (value) => switch (value) {
                    null => 'Atinge harta ca să alegi locul.',
                    LatLng(:final latitude, :final longitude)
                        when latitude < 43.5 ||
                            latitude > 48.5 ||
                            longitude < 20 ||
                            longitude > 30 =>
                      'Locul trebuie să fie în România.',
                    _ => null,
                  },
                  builder: (field) => _PositionPicker(
                    controller: _mapController,
                    position: field.value,
                    error: field.errorText,
                    onChanged: (point) {
                      field.didChange(point);
                      _position = point;
                    },
                  ),
                ),
                TextFormField(
                  controller: _imageUrl,
                  decoration: const InputDecoration(
                    labelText: 'Link către o poză (opțional)',
                    hintText: 'https://…',
                  ),
                  keyboardType: TextInputType.url,
                  validator: (value) {
                    final url = value!.trim();
                    return url.isEmpty || url.startsWith('https://')
                        ? null
                        : 'Linkul trebuie să înceapă cu https://';
                  },
                ),
                TextFormField(
                  controller: _description,
                  decoration: const InputDecoration(
                    labelText: 'Descriere',
                    hintText: 'Ce face localul special?',
                  ),
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 300,
                  validator: (value) => _length(value, 10, 300),
                ),
                if (_error case final error?)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      error,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(switch ((place, widget.asAdmin)) {
                    (null, _) => 'Trimite spre aprobare',
                    (_, true) => 'Salvează',
                    _ => 'Salvează și trimite spre aprobare',
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String? _length(String? value, int min, int max) {
    final length = value?.trim().length ?? 0;
    if (length == 0) return 'Câmp obligatoriu.';
    if (length < min) return 'Prea scurt: cel puțin $min caractere.';
    if (length > max) return 'Prea lung: cel mult $max caractere.';
    return null;
  }
}

/// A small map where a tap sets the position of the place.
class _PositionPicker extends StatelessWidget {
  const _PositionPicker({
    required this.controller,
    required this.position,
    required this.error,
    required this.onChanged,
  });

  final MapController controller;
  final LatLng? position;
  final String? error;
  final ValueChanged<LatLng> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final position = this.position;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Poziția pe hartă', style: theme.textTheme.bodySmall),
        const SizedBox(height: 4),
        SizedBox(
          height: 260,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: FlutterMap(
              mapController: controller,
              options: MapOptions(
                // The place being edited, otherwise the middle of Romania.
                initialCenter: position ?? const LatLng(45.9, 24.9),
                initialZoom: position == null ? 6 : 15,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  keyboardOptions: KeyboardOptions(autofocus: false),
                ),
                onTap: (tapPosition, point) => onChanged(point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.tudorrrr.top_places',
                ),
                if (position != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: position,
                        width: 40,
                        height: 40,
                        alignment: Alignment.topCenter,
                        child: Icon(
                          Icons.location_on,
                          size: 40,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          error ??
              (position == null
                  ? 'Atinge harta în locul unde este localul.'
                  : 'Poziție aleasă. Atinge din nou ca s-o schimbi.'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: error == null ? null : theme.colorScheme.error,
          ),
        ),
        Text('© OpenStreetMap contributors', style: theme.textTheme.labelSmall),
      ],
    );
  }
}
