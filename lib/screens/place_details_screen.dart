import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:top_places/models/place.dart';
import 'package:top_places/screens/not_found_screen.dart';
import 'package:top_places/services/gemini_service.dart';
import 'package:top_places/services/places_repository.dart';
import 'package:top_places/utils/links.dart';
import 'package:top_places/widgets/place_photo.dart';

/// WhatsApp's green. Black text on it is easy to read (10:1); the white text
/// of the old app was not (2:1).
const _whatsAppGreen = Color(0xFF25D366);

/// "Vibe" sentences written in advance. The old app asked Gemini for a vibe
/// and showed one of these when the call failed. Here they are shown when
/// Gemini can't answer (or there is no key), labelled as examples.
const _vibeExamplesRo = [
  'Atmosfera este electrică și primitoare, perfectă pentru o ieșire memorabilă.',
  'Un loc cu un vibe relaxat, unde te poți deconecta complet de agitația orașului.',
  'Energia locului te cucerește imediat, iar detaliile de design fac diferența.',
];

/// The same examples, for when the description is shown in English.
const _vibeExamplesEn = [
  'The atmosphere is electric and welcoming, perfect for a memorable night out.',
  'A place with a relaxed vibe, where you can switch off from the busy city.',
  'The energy of the place wins you over at once, and the design details '
      'make the difference.',
];

/// One place: a big photo that shrinks into the app bar when scrolling, then
/// the name, address, rating, description and the WhatsApp and directions
/// buttons.
class PlaceDetailsScreen extends StatelessWidget {
  const PlaceDetailsScreen({super.key, required this.placeId});

  final String placeId;

  @override
  Widget build(BuildContext context) {
    final place = context.watch<PlacesRepository>().placeById(placeId);
    if (place == null) {
      return const NotFoundScreen();
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 300,
            leading: Center(
              child: BackButton(
                // A filled circle keeps the arrow visible on any photo.
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                ),
                onPressed: () {
                  // A page opened from a link (on the web) has no page
                  // behind it, so the button leads to Explore instead.
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/explore');
                  }
                },
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: PlacePhoto(place: place, width: 1200),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              // On wide windows the text stays readable instead of stretching.
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                // Fades in and slides up once when the page opens. The old
                // app needed two Animated values and a useEffect for this.
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  // No motion when the system settings ask for less of it.
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 40 * (1 - value)),
                      child: child,
                    ),
                  ),
                  child: _PlaceInfo(place: place),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Everything below the photo. It keeps the language chosen under "Despre
/// locație", which the vibe follows too.
class _PlaceInfo extends StatefulWidget {
  const _PlaceInfo({required this.place});

  final Place place;

  @override
  State<_PlaceInfo> createState() => _PlaceInfoState();
}

class _PlaceInfoState extends State<_PlaceInfo> {
  bool _inRomanian = true;

  @override
  Widget build(BuildContext context) {
    final place = widget.place;
    final theme = Theme.of(context);
    final rating = place.rating.toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        place.name,
                        style: theme.textTheme.headlineSmall,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      place.address,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Read as "4.7 stele" instead of only "4.7".
              Semantics(
                label: '$rating stele',
                excludeSemantics: true,
                child: Chip(
                  avatar: const Icon(Icons.star),
                  label: Text(rating),
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          _AboutSection(
            place: place,
            inRomanian: _inRomanian,
            onLanguageChanged: (inRomanian) =>
                setState(() => _inRomanian = inRomanian),
          ),
          const SizedBox(height: 16),
          // The vibe follows the language too: it is translated, not lost.
          _VibeSection(place: place, inRomanian: _inRomanian),
          const SizedBox(height: 24),
          // Side by side when they fit, one under the other when they don't.
          OverflowBar(
            spacing: 8,
            overflowSpacing: 8,
            children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _whatsAppGreen,
                  foregroundColor: Colors.black,
                ),
                onPressed: () => openLink(context, whatsAppUri(place)),
                icon: const Icon(Icons.chat_outlined),
                label: const Text('Rezervă pe WhatsApp'),
              ),
              OutlinedButton.icon(
                onPressed: () => openLink(context, directionsUri(place)),
                icon: const Icon(Icons.directions),
                label: const Text('Indicații'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Despre locație": the description in Romanian or in the original English.
class _AboutSection extends StatelessWidget {
  const _AboutSection({
    required this.place,
    required this.inRomanian,
    required this.onLanguageChanged,
  });

  final Place place;
  final bool inRomanian;
  final ValueChanged<bool> onLanguageChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final translation = place.descriptionRo;
    // A record: the text and its note are chosen together.
    final (text, note) = switch ((translation, inRomanian)) {
      (final romanian?, true) => (
        romanian,
        'Traducere din engleză, inclusă în aplicație.',
      ),
      (_?, false) => (place.description, 'Textul original, în engleză.'),
      // One language only, e.g. an operator's own text: nothing to tell.
      (null, _) => (place.description, null),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  'Despre locație',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
            if (translation != null)
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: true,
                    label: Text('RO'),
                    tooltip: 'În română',
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text('EN'),
                    tooltip: 'Originalul, în engleză',
                  ),
                ],
                selected: {inRomanian},
                showSelectedIcon: false,
                onSelectionChanged: (selection) =>
                    onLanguageChanged(selection.single),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(text, style: theme.textTheme.bodyLarge),
        if (note != null) ...[
          const SizedBox(height: 4),
          Text(
            note,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// A button for a short "vibe" of the place: written by Gemini when the app
/// has a key, otherwise one of the examples, labelled as such. It follows
/// the language chosen for the description.
class _VibeSection extends StatefulWidget {
  const _VibeSection({required this.place, required this.inRomanian});

  final Place place;

  /// The language of the vibe: the one chosen for the description.
  final bool inRomanian;

  @override
  State<_VibeSection> createState() => _VibeSectionState();
}

class _VibeSectionState extends State<_VibeSection> {
  /// The example on screen, by its number in both lists, or null.
  int? _example;

  /// Why an example is shown: there is no key, or Gemini did not answer.
  String _exampleNote = '';

  /// The vibe from Gemini in the languages it has been shown in, by
  /// language (true for Romanian). Empty when there is none.
  final _aiText = <bool, String>{};

  /// Counts the vibes, so that a late answer about an older one is dropped.
  int _vibeNumber = 0;

  bool _loading = false;
  bool _translationFailed = false;

  @override
  void didUpdateWidget(_VibeSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // An example comes in both languages already; an AI vibe is translated.
    if (widget.inRomanian != oldWidget.inRomanian &&
        _aiText.isNotEmpty &&
        !_aiText.containsKey(widget.inRomanian)) {
      _translate();
    }
  }

  Future<void> _showVibe() async {
    final gemini = context.read<GeminiService?>();
    if (gemini == null) {
      _showExample('Exemplu scris dinainte, nu generat de AI.');
      return;
    }
    final inRomanian = widget.inRomanian;
    final number = ++_vibeNumber;
    setState(() => _loading = true);
    final place = widget.place;
    // The question, the instructions and the description all in the same
    // language, so the model answers in it too.
    final (prompt, instructions) = inRomanian
        ? (
            'Scrie o descriere scurtă și creativă (un „vibe”), de cel mult '
                'două propoziții, pentru „${place.name}” din ${place.city}. '
                'Ce știm despre loc: '
                '${place.descriptionRo ?? place.description}',
            'Scrii doar în română, cu un ton modern și un emoji, fără '
                'Markdown. Nu inventa prețuri, adrese sau meniuri.',
          )
        : (
            'Write a short, creative description (a "vibe") of at most two '
                'sentences for "${place.name}" in ${place.city}. What we '
                'know about it: ${place.description}',
            'Write only in English, with a modern tone and one emoji, '
                'without Markdown. Do not invent prices, addresses or menus.',
          );
    try {
      final text = await gemini.generate(prompt, instructions: instructions);
      if (!mounted || number != _vibeNumber) return;
      setState(() {
        _example = null;
        _aiText
          ..clear()
          ..[inRomanian] = text;
        _translationFailed = false;
        _loading = false;
      });
      // The language may have changed while Gemini was writing.
      if (widget.inRomanian != inRomanian) _translate();
    } on GeminiException {
      if (!mounted || number != _vibeNumber) return;
      _showExample('Exemplu scris dinainte: AI-ul nu răspunde acum.');
    }
  }

  /// Asks Gemini to translate the vibe on screen into the chosen language.
  Future<void> _translate() async {
    final gemini = context.read<GeminiService?>();
    final toRomanian = widget.inRomanian;
    final source = _aiText[!toRomanian];
    if (gemini == null || source == null) return;
    final number = _vibeNumber;
    setState(() {
      _loading = true;
      _translationFailed = false;
    });
    final (prompt, instructions) = toRomanian
        ? (
            'Tradu în română textul de mai jos. Păstrează tonul și '
                'emoji-ul.\n\n$source',
            'Răspunzi doar cu traducerea, fără Markdown.',
          )
        : (
            'Translate the text below into English. Keep the tone and the '
                'emoji.\n\n$source',
            'Reply only with the translation, without Markdown.',
          );
    try {
      final text = await gemini.generate(prompt, instructions: instructions);
      if (!mounted || number != _vibeNumber) return;
      setState(() {
        _aiText[toRomanian] = text;
        _loading = false;
      });
    } on GeminiException {
      if (!mounted || number != _vibeNumber) return;
      setState(() {
        _translationFailed = true;
        _loading = false;
      });
    }
  }

  void _showExample(String note) {
    setState(() {
      // Drops a late answer about an AI vibe, if one is on its way.
      _vibeNumber++;
      _aiText.clear();
      _example = ((_example ?? -1) + 1) % _vibeExamplesRo.length;
      _exampleNote = note;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final withAi = context.watch<GeminiService?>() != null;
    final inRomanian = widget.inRomanian;
    final example = _example;
    // While a translation is on its way, the other language stays on screen.
    final (String? text, String note) = example != null
        ? (
            (inRomanian ? _vibeExamplesRo : _vibeExamplesEn)[example],
            _exampleNote,
          )
        : switch ((_aiText[inRomanian], _aiText[!inRomanian])) {
            (final String text, _) => (
              text,
              'Generat cu Gemini. Poate conține greșeli.',
            ),
            (null, final String other) => (
              other,
              _translationFailed
                  ? 'Generat cu Gemini. Nu l-am putut traduce acum.'
                  : 'Se traduce…',
            ),
            _ => (null, ''),
          };
    final label = text == null
        ? (withAi ? 'Generează un vibe cu AI' : 'Arată un exemplu de vibe')
        : (withAi ? 'Alt vibe' : 'Alt exemplu');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (text != null)
          // Screen readers read the new text each time it changes.
          Semantics(
            liveRegion: true,
            child: SizedBox(
              width: double.infinity,
              child: Card.filled(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(note, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            ),
          ),
        TextButton.icon(
          onPressed: _loading ? null : _showVibe,
          icon: _loading
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome),
          label: Text(label),
        ),
      ],
    );
  }
}
