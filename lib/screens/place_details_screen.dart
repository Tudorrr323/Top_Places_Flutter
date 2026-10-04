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
const _vibeExamples = [
  'Atmosfera este electrică și primitoare, perfectă pentru o ieșire memorabilă.',
  'Un loc cu un vibe relaxat, unde te poți deconecta complet de agitația orașului.',
  'Energia locului te cucerește imediat, iar detaliile de design fac diferența.',
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

/// Everything below the photo.
class _PlaceInfo extends StatelessWidget {
  const _PlaceInfo({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
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
          _AboutSection(place: place),
          const SizedBox(height: 16),
          _VibeSection(place: place),
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
class _AboutSection extends StatefulWidget {
  const _AboutSection({required this.place});

  final Place place;

  @override
  State<_AboutSection> createState() => _AboutSectionState();
}

class _AboutSectionState extends State<_AboutSection> {
  bool _inRomanian = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final translation = widget.place.descriptionRo;
    // A record: the text and its note are chosen together.
    final (text, note) = _inRomanian && translation != null
        ? (translation, 'Traducere din engleză, inclusă în aplicație.')
        : (widget.place.description, 'Textul original, în engleză.');

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
                selected: {_inRomanian},
                showSelectedIcon: false,
                onSelectionChanged: (selection) =>
                    setState(() => _inRomanian = selection.single),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(text, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 4),
        Text(
          note,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// A button for a short "vibe" of the place: written by Gemini when the app
/// has a key, otherwise one of the examples, labelled as such.
class _VibeSection extends StatefulWidget {
  const _VibeSection({required this.place});

  final Place place;

  @override
  State<_VibeSection> createState() => _VibeSectionState();
}

class _VibeSectionState extends State<_VibeSection> {
  /// The text on screen and the note under it, or null before the first tap.
  ({String text, String note})? _vibe;
  int _exampleIndex = -1;
  bool _loading = false;

  Future<void> _showVibe() async {
    final gemini = context.read<GeminiService?>();
    if (gemini == null) {
      _showExample('Exemplu scris dinainte, nu generat de AI.');
      return;
    }
    setState(() => _loading = true);
    try {
      final place = widget.place;
      final text = await gemini.generate(
        'Scrie o descriere scurtă și creativă (un „vibe”), de cel mult două '
        'propoziții, pentru „${place.name}” din ${place.city}. Ce știm '
        'despre loc: ${place.description}',
        instructions:
            'Scrii în română, cu un ton modern și un emoji, fără Markdown. '
            'Nu inventa prețuri, adrese sau meniuri.',
      );
      if (!mounted) return;
      setState(() {
        _vibe = (text: text, note: 'Generat cu Gemini. Poate conține greșeli.');
        _loading = false;
      });
    } on GeminiException {
      if (!mounted) return;
      _showExample('Exemplu scris dinainte: AI-ul nu răspunde acum.');
    }
  }

  void _showExample(String note) {
    setState(() {
      _exampleIndex = (_exampleIndex + 1) % _vibeExamples.length;
      _vibe = (text: _vibeExamples[_exampleIndex], note: note);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final withAi = context.watch<GeminiService?>() != null;
    final vibe = _vibe;
    final label = vibe == null
        ? (withAi ? 'Generează un vibe cu AI' : 'Arată un exemplu de vibe')
        : (withAi ? 'Alt vibe' : 'Alt exemplu');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (vibe != null)
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
                        vibe.text,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(vibe.note, style: theme.textTheme.bodySmall),
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
