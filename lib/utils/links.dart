import 'package:flutter/material.dart';
import 'package:top_places/l10n/l10n.dart';
import 'package:top_places/models/place.dart';
import 'package:url_launcher/url_launcher.dart';

/// Google Maps directions to [place]. Phones open the Maps app; Windows and
/// the browser open the website.
Uri directionsUri(Place place) {
  return Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'destination': '${place.lat},${place.lng}',
  });
}

/// A WhatsApp message with [text], e.g. asking for a table. There is no
/// phone number in the data, so WhatsApp asks who to send it to.
Uri whatsAppUri(String text) {
  // Spaces become %20, as in WhatsApp's own examples (Uri.https would use +).
  return Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
}

/// Opens [uri] outside the app and shows a message when that is not possible.
Future<void> openLink(BuildContext context, Uri uri) async {
  final messenger = ScaffoldMessenger.of(context);
  final failed = context.l10n.linkFailed;
  bool opened;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on Exception {
    opened = false;
  }
  if (!opened) {
    messenger.showSnackBar(SnackBar(content: Text(failed)));
  }
}
