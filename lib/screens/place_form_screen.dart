import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:top_places/l10n/l10n.dart';
import 'package:top_places/models/place.dart';
import 'package:top_places/services/gemini_service.dart';
import 'package:top_places/services/place_service.dart';
import 'package:top_places/services/places_repository.dart';

/// Adds a place, or edits one when [place] is given. The checks are the same
/// as in the database, so a mistake shows here instead of as an error from
/// the server. The description is written in Romanian and in English; a
/// button translates one into the other.
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
  late final _descriptionRo = TextEditingController(
    text: widget.place?.descriptionRo,
  );
  late final _descriptionEn = TextEditingController(
    text: widget.place?.description,
  );

  /// True when the Romanian description was the last one changed: the
  /// button translates from it when both are written.
  bool _romanianLast = true;

  bool _translating = false;
  String? _translationError;
  late String? _city = widget.place?.city;

  /// Where the place is; set by a tap on the map.
  late LatLng? _position = switch (widget.place) {
    final place? => LatLng(place.lat, place.lng),
    null => null,
  };
  bool _saving = false;
  PlaceException? _error;

  @override
  void dispose() {
    for (final controller in [
      _name,
      _address,
      _imageUrl,
      _descriptionRo,
      _descriptionEn,
    ]) {
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
      description: _descriptionEn.text,
      descriptionRo: _descriptionRo.text,
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
        _error = error;
        _saving = false;
      });
    }
  }

  /// Which way the button translates: into English (true) or Romanian
  /// (false), from the description written last or the only one written;
  /// null while both are empty.
  bool? get _toEnglish {
    final romanian = _descriptionRo.text.trim().isNotEmpty;
    final english = _descriptionEn.text.trim().isNotEmpty;
    if (romanian && english) return _romanianLast;
    if (romanian) return true;
    if (english) return false;
    return null;
  }

  Future<void> _translate(GeminiService gemini, bool toEnglish) async {
    final source = (toEnglish ? _descriptionRo : _descriptionEn).text.trim();
    final target = toEnglish ? _descriptionEn : _descriptionRo;
    // Faithful, not creative: the same description in the other language.
    final (prompt, instructions) = toEnglish
        ? (
            'Translate into English the description of a place in Romania. '
                'Keep exactly the same meaning.\n\n$source',
            'Reply only with the translation, in at most 300 characters, '
                'without Markdown or quotes. Add nothing.',
          )
        : (
            'Tradu în română descrierea unui local din România. Păstrează '
                'exact același sens.\n\n$source',
            'Răspunzi doar cu traducerea, în cel mult 300 de caractere, fără '
                'Markdown sau ghilimele. Nu adăuga nimic.',
          );
    setState(() {
      _translating = true;
      _translationError = null;
    });
    try {
      final text = await gemini.generate(prompt, instructions: instructions);
      if (!mounted) return;
      setState(() {
        target.text = text.trim();
        _translating = false;
      });
    } on GeminiException {
      if (!mounted) return;
      setState(() {
        _translationError = context.l10n.translateFailed;
        _translating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cities = context.read<PlacesRepository>().cities;
    final place = widget.place;
    final l10n = context.l10n;
    String? length(String? value, int min, int max) {
      final length = value?.trim().length ?? 0;
      if (length == 0) return l10n.requiredField;
      if (length < min) return l10n.tooShort(min);
      if (length > max) return l10n.tooLong(max);
      return null;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(place == null ? l10n.newPlaceTitle : l10n.editPlaceTitle),
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
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(l10n.editGoesToReview),
                  ),
                TextFormField(
                  controller: _name,
                  decoration: InputDecoration(labelText: l10n.placeName),
                  validator: (value) => length(value, 2, 80),
                ),
                TextFormField(
                  controller: _address,
                  decoration: InputDecoration(
                    labelText: l10n.address,
                    // An address in Romania, written the same way in both
                    // languages.
                    hintText: 'Str. Lăpușneanu, Nr. 12',
                  ),
                  validator: (value) => length(value, 3, 120),
                ),
                DropdownButtonFormField<String>(
                  initialValue: _city,
                  decoration: InputDecoration(labelText: l10n.city),
                  items: [
                    for (final city in cities)
                      DropdownMenuItem(
                        value: city.name,
                        child: Text(city.name),
                      ),
                  ],
                  validator: (value) => value == null ? l10n.chooseCity : null,
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
                    null => l10n.tapMapToChoose,
                    LatLng(:final latitude, :final longitude)
                        when latitude < 43.5 ||
                            latitude > 48.5 ||
                            longitude < 20 ||
                            longitude > 30 =>
                      l10n.mustBeInRomania,
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
                  decoration: InputDecoration(
                    labelText: l10n.photoLink,
                    hintText: 'https://…',
                  ),
                  keyboardType: TextInputType.url,
                  validator: (value) {
                    final url = value!.trim();
                    return url.isEmpty || url.startsWith('https://')
                        ? null
                        : l10n.linkMustBeHttps;
                  },
                ),
                // Both are required: the app shows the one of its language.
                for (final (controller, label, romanian) in [
                  (_descriptionRo, l10n.descriptionRo, true),
                  (_descriptionEn, l10n.descriptionEn, false),
                ])
                  TextFormField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: label,
                      hintText: l10n.descriptionHint,
                    ),
                    minLines: 3,
                    maxLines: 6,
                    maxLength: 300,
                    validator: (value) => length(value, 10, 300),
                    onChanged: (_) => setState(() => _romanianLast = romanian),
                  ),
                _TranslateButton(
                  toEnglish: _toEnglish,
                  busy: _translating,
                  error: _translationError,
                  onTranslate: _translate,
                ),
                if (_error case final error?)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      l10n.placeError(error),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(switch ((place, widget.asAdmin)) {
                    (null, _) => l10n.sendForApproval,
                    (_, true) => l10n.save,
                    _ => l10n.saveAndSendForApproval,
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The button that writes the description in the other language, with
/// Gemini. Without a key, it says so instead.
class _TranslateButton extends StatelessWidget {
  const _TranslateButton({
    required this.toEnglish,
    required this.busy,
    required this.error,
    required this.onTranslate,
  });

  /// Into English, into Romanian, or null with nothing to translate yet.
  final bool? toEnglish;
  final bool busy;
  final String? error;
  final void Function(GeminiService gemini, bool toEnglish) onTranslate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final gemini = context.watch<GeminiService?>();
    final toEnglish = this.toEnglish;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    if (gemini == null) return Text(l10n.translateNeedsGemini, style: muted);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: busy || toEnglish == null
              ? null
              : () => onTranslate(gemini, toEnglish),
          icon: busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.translate),
          label: Text(
            toEnglish == false
                ? l10n.translateToRomanian
                : l10n.translateToEnglish,
          ),
        ),
        if (toEnglish == null) Text(l10n.translateNothingYet, style: muted),
        if (error case final error?)
          Text(
            error,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
      ],
    );
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
        Text(context.l10n.positionOnMap, style: theme.textTheme.bodySmall),
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
                  ? context.l10n.tapMapWherePlaceIs
                  : context.l10n.positionChosen),
          style: theme.textTheme.bodySmall?.copyWith(
            color: error == null ? null : theme.colorScheme.error,
          ),
        ),
        Text('© OpenStreetMap contributors', style: theme.textTheme.labelSmall),
      ],
    );
  }
}
