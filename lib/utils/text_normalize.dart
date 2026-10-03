/// Lower-cases text and removes diacritics, so that "București",
/// "Bucuresti" and "BUCUREȘTI" match the same search.
String normalize(String text) {
  const replacements = {
    'ă': 'a',
    'â': 'a',
    'î': 'i',
    'ș': 's',
    'ş': 's',
    'ț': 't',
    'ţ': 't',
    'é': 'e',
    'ö': 'o',
  };
  final buffer = StringBuffer();
  for (final char in text.toLowerCase().split('')) {
    buffer.write(replacements[char] ?? char);
  }
  return buffer.toString();
}

/// Turns a name into a stable id: "Café 'New World'" -> "cafe-new-world".
String slugify(String text) {
  return normalize(text)
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}