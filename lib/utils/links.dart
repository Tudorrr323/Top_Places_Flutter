import 'package:flutter/material.dart';
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

/// Opens [uri] outside the app and shows a message when that is not possible.
Future<void> openLink(BuildContext context, Uri uri) async {
  final messenger = ScaffoldMessenger.of(context);
  bool opened;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on Exception {
    opened = false;
  }
  if (!opened) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Nu am putut deschide linkul.')),
    );
  }
}
