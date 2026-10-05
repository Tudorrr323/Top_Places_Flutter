import 'package:flutter/material.dart';
import 'package:top_places/utils/text_normalize.dart';

/// True when [query] appears in one of [texts], whatever the case and the
/// diacritics: "iasi" finds "Iași". An empty query matches everything.
bool matchesSearch(String query, Iterable<String> texts) {
  final wanted = normalize(query.trim());
  return wanted.isEmpty ||
      texts.any((text) => normalize(text).contains(wanted));
}

/// The search bar above a list. [onChanged] gets the text as it is typed.
class ListSearchField extends StatefulWidget {
  const ListSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
  });

  final String hint;
  final ValueChanged<String> onChanged;

  @override
  State<ListSearchField> createState() => _ListSearchFieldState();
}

class _ListSearchFieldState extends State<ListSearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _changed(String text) {
    // Rebuilds for the clear button, which shows only when there is text.
    setState(() {});
    widget.onChanged(text);
  }

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      controller: _controller,
      hintText: widget.hint,
      leading: const Icon(Icons.search),
      trailing: [
        if (_controller.text.isNotEmpty)
          IconButton(
            tooltip: 'Șterge căutarea',
            icon: const Icon(Icons.close),
            onPressed: () {
              _controller.clear();
              _changed('');
            },
          ),
      ],
      onChanged: _changed,
    );
  }
}
