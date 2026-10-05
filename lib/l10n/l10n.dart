import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:top_places/l10n/app_localizations.dart';
import 'package:top_places/models/place.dart';
import 'package:top_places/services/account_service.dart';
import 'package:top_places/services/place_service.dart';

export 'package:top_places/l10n/app_localizations.dart';

/// The texts of the app in the chosen language: `context.l10n.tabExplore`.
extension L10n on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Texts made from the data, in the chosen language.
extension DataTexts on AppLocalizations {
  /// "4.7", or "Nou" for a place nobody has rated yet.
  String placeRating(Place place) =>
      place.isRated ? place.rating.toStringAsFixed(1) : ratingNew;

  /// What a screen reader says instead: "4.7 stele", or "local nou".
  String placeRatingLabel(Place place) => place.isRated
      ? ratingStarsLabel(place.rating.toStringAsFixed(1))
      : ratingNewLabel;

  /// The description in this language: the Romanian one, or the original
  /// in English.
  String description(Place place) => localeName == 'ro'
      ? place.descriptionRo ?? place.description
      : place.description;

  /// What went wrong with an account action.
  String accountError(AccountException error) => switch (error.problem) {
    AccountProblem.signInAgain => errorSignInAgain,
    AccountProblem.wrongCredentials => errorWrongCredentials,
    AccountProblem.emailNotConfirmed => errorEmailNotConfirmed,
    AccountProblem.tooManyEmails => errorTooManyEmails,
    AccountProblem.weakPassword => errorWeakPassword,
    AccountProblem.invalidEmail => errorInvalidEmail,
    AccountProblem.emailTaken => errorEmailTaken,
    AccountProblem.notSaved => errorNotSaved(error.detail ?? ''),
    AccountProblem.failed => errorFailed(error.detail ?? ''),
    AccountProblem.offline => errorOffline,
  };

  /// What went wrong with an action on places.
  String placeError(PlaceException error) => switch (error.problem) {
    PlaceProblem.signInToReview => errorSignInToReview,
    PlaceProblem.cannotDeleteReview => errorCannotDeleteReview,
    PlaceProblem.invalidFields => errorInvalidFields,
    PlaceProblem.notAllowed => errorNotAllowed,
    PlaceProblem.notSaved => errorNotSaved(error.detail ?? ''),
    PlaceProblem.offline => errorOffline,
  };

  /// What went wrong, for an error a list could not load.
  String error(Object error) => switch (error) {
    PlaceException() => placeError(error),
    AccountException() => accountError(error),
    _ => error.toString(),
  };

  /// "5 oct. 2026" or "Oct 5, 2026"; nothing when the date is unknown.
  String date(DateTime? date) =>
      date == null ? '' : DateFormat.yMMMd(localeName).format(date);
}
