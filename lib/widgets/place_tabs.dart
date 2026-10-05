import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:top_places/l10n/l10n.dart';
import 'package:top_places/models/place.dart';
import 'package:top_places/services/gemini_service.dart';
import 'package:top_places/utils/links.dart';
import 'package:top_places/widgets/place_reviews.dart';

/// WhatsApp's green. Black text on it is easy to read (10:1); the white text
/// of the old app was not (2:1).
const _whatsAppGreen = Color(0xFF25D366);

/// Everything after the name of a place, on its page and in the sheet over
/// the map: the WhatsApp and directions buttons, then two tabs. "Descriere"
/// has the description and a vibe, "Recenzii" the reviews. A sliver, for a
/// CustomScrollView; the tabs stay at the top while the rest scrolls.
class PlaceTabs extends StatefulWidget {
  const PlaceTabs({super.key, required this.place});

  final Place place;

  @override
  State<PlaceTabs> createState() => _PlaceTabsState();
}

class _PlaceTabsState extends State<PlaceTabs>
    with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 2, vsync: this);

  /// The reviews load the first time their tab opens, not with every place.
  bool _reviewsOpened = false;

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;
    final onDescription = _tabs.index == 0;
    final l10n = context.l10n;

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            // Side by side when they fit, one under the other when they
            // don't.
            child: OverflowBar(
              spacing: 8,
              overflowSpacing: 8,
              children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _whatsAppGreen,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () => openLink(
                    context,
                    whatsAppUri(l10n.bookingMessage(place.name)),
                  ),
                  icon: const Icon(Icons.chat_outlined),
                  label: Text(l10n.bookOnWhatsApp),
                ),
                OutlinedButton.icon(
                  onPressed: () => openLink(context, directionsUri(place)),
                  icon: const Icon(Icons.directions),
                  label: Text(l10n.directions),
                ),
              ],
            ),
          ),
        ),
        PinnedHeaderSliver(
          child: ColoredBox(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              controller: _tabs,
              // There is no swiping between the tabs: a tap changes them.
              onTap: (index) => setState(() {
                if (index == 1) _reviewsOpened = true;
              }),
              tabs: [
                Tab(text: l10n.tabDescription),
                Tab(text: l10n.tabReviews),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            // Both tabs stay built once opened, so a vibe or a review being
            // written survives a look at the other one.
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Visibility(
                  visible: onDescription,
                  maintainState: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AboutSection(place: place),
                      const SizedBox(height: 16),
                      // In the language of the app; when it changes, the
                      // vibe is translated, not lost.
                      _VibeSection(
                        place: place,
                        inRomanian: l10n.localeName == 'ro',
                      ),
                    ],
                  ),
                ),
                if (_reviewsOpened)
                  Visibility(
                    visible: !onDescription,
                    maintainState: true,
                    child: PlaceReviews(place: place),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// "Despre locație": the description, in the language of the app.
class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            context.l10n.aboutPlace,
            style: theme.textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 8),
        Text(context.l10n.description(place), style: theme.textTheme.bodyLarge),
      ],
    );
  }
}

/// A button for a short "vibe" of the place: written by Gemini when the app
/// has a key, otherwise one of the examples written in advance, labelled as
/// such. It follows the language of the app.
class _VibeSection extends StatefulWidget {
  const _VibeSection({required this.place, required this.inRomanian});

  final Place place;

  /// The language of the vibe: the one of the app.
  final bool inRomanian;

  @override
  State<_VibeSection> createState() => _VibeSectionState();
}

class _VibeSectionState extends State<_VibeSection> {
  /// The example on screen, by its number, or null.
  int? _example;

  /// True when the example is shown because Gemini did not answer; false
  /// when there is no key.
  bool _aiDown = false;

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
      _showExample(aiDown: false);
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
      _showExample(aiDown: true);
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

  void _showExample({required bool aiDown}) {
    setState(() {
      // Drops a late answer about an AI vibe, if one is on its way.
      _vibeNumber++;
      _aiText.clear();
      _example = ((_example ?? -1) + 1) % 3;
      _aiDown = aiDown;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final withAi = context.watch<GeminiService?>() != null;
    final inRomanian = widget.inRomanian;
    final example = _example;
    // While a translation is on its way, the other language stays on screen.
    final (String? text, String note) = example != null
        ? (
            // Written in advance in both languages, so always in the right
            // one.
            [l10n.vibeExample1, l10n.vibeExample2, l10n.vibeExample3][example],
            _aiDown ? l10n.vibeExampleAiDown : l10n.vibeExampleNoAi,
          )
        : switch ((_aiText[inRomanian], _aiText[!inRomanian])) {
            (final String text, _) => (text, l10n.aiNote),
            (null, final String other) => (
              other,
              _translationFailed ? l10n.vibeNotTranslated : l10n.translating,
            ),
            _ => (null, ''),
          };
    final label = text == null
        ? (withAi ? l10n.vibeGenerate : l10n.vibeShowExample)
        : (withAi ? l10n.vibeAnother : l10n.vibeAnotherExample);

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
