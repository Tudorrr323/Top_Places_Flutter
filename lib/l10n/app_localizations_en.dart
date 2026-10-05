// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Top Places';

  @override
  String get tabExplore => 'Explore';

  @override
  String get tabAssistant => 'Assistant';

  @override
  String get tabProfile => 'Profile';

  @override
  String get notFoundTitle => 'Page not found';

  @override
  String get notFoundMessage => 'We couldn\'t find that page.';

  @override
  String get notFoundBack => 'Back to Explore';

  @override
  String get filtersTitle => 'Filter & sort';

  @override
  String get filtersCity => 'City';

  @override
  String get filtersAllCities => 'All';

  @override
  String get filtersMinRating => 'Minimum rating';

  @override
  String get filtersAnyRating => 'Any';

  @override
  String get filtersSort => 'Sort by';

  @override
  String get sortRecommended => 'Recommended';

  @override
  String get sortRatingDown => 'Rating ↓';

  @override
  String get sortRatingUp => 'Rating ↑';

  @override
  String get sortName => 'Name (A-Z)';

  @override
  String get filtersReset => 'Reset';

  @override
  String get filtersApply => 'Apply filters';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get requiredField => 'Required.';

  @override
  String get changeName => 'Change the name';

  @override
  String get firstName => 'First name';

  @override
  String get lastName => 'Last name';

  @override
  String get reasonLabel => 'Reason';

  @override
  String get reasonHelper => 'The person concerned sees it too.';

  @override
  String get reasonRequired => 'Write the reason.';

  @override
  String bookingMessage(String place) {
    return 'Booking at $place';
  }

  @override
  String get linkFailed => 'Couldn\'t open the link.';

  @override
  String get clearSearch => 'Clear the search';

  @override
  String get ratingNew => 'New';

  @override
  String get ratingNewLabel => 'new place';

  @override
  String ratingStarsLabel(String rating) {
    return '$rating stars';
  }

  @override
  String stars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stars',
      one: '1 star',
    );
    return '$_temp0';
  }

  @override
  String results(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
    );
    return '$_temp0';
  }

  @override
  String reviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews',
      one: '1 review',
    );
    return '$_temp0';
  }

  @override
  String placeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places',
      one: '1 place',
    );
    return '$_temp0';
  }

  @override
  String get searchHint => 'Search places or cities...';

  @override
  String get filterTooltip => 'Filter and sort';

  @override
  String get showList => 'Show the list';

  @override
  String get showMap => 'Show the map';

  @override
  String get placesTitle => 'Places';

  @override
  String get filtersActive => 'Filters on';

  @override
  String get noPlaces => 'We couldn\'t find any places.';

  @override
  String suggestionRated(String city, String rating) {
    return '$city · ★ $rating';
  }

  @override
  String suggestionNew(String city) {
    return '$city · New';
  }

  @override
  String clusterLabel(String places) {
    return '$places here. Tap to zoom in.';
  }

  @override
  String get locationServiceOff =>
      'Location is off on this device. Turn it on and try again.';

  @override
  String get locationDenied =>
      'Without the location permission I can\'t show you on the map.';

  @override
  String get locationDeniedForever =>
      'You turned location off for Top Places. You can allow it in the app settings.';

  @override
  String get locationBlockedByBrowser =>
      'The browser blocks the location. You can allow it in the site settings.';

  @override
  String get locationAccuracyOff =>
      'Precise location is still off. Tap again and accept it when the phone asks.';

  @override
  String get locationNotFound => 'We couldn\'t find where you are. Try again.';

  @override
  String get settings => 'Settings';

  @override
  String get myLocationTooltip => 'Show my location';

  @override
  String get myLocationLabel => 'Your location';

  @override
  String get shrink => 'Shrink';

  @override
  String get allDetails => 'All the details';

  @override
  String get newPlaceNoReviews => 'New place, no reviews yet';

  @override
  String get bookOnWhatsApp => 'Book on WhatsApp';

  @override
  String get directions => 'Directions';

  @override
  String get tabDescription => 'Description';

  @override
  String get tabReviews => 'Reviews';

  @override
  String get aboutPlace => 'About the place';

  @override
  String get vibeExample1 =>
      'The atmosphere is electric and welcoming, perfect for a memorable night out.';

  @override
  String get vibeExample2 =>
      'A place with a relaxed vibe, where you can switch off from the busy city.';

  @override
  String get vibeExample3 =>
      'The energy of the place wins you over at once, and the design details make the difference.';

  @override
  String get vibeExampleNoAi => 'An example written in advance, not by AI.';

  @override
  String get vibeExampleAiDown =>
      'An example written in advance: the AI isn\'t answering right now.';

  @override
  String get aiNote => 'Written by Gemini. It may contain mistakes.';

  @override
  String get vibeNotTranslated =>
      'Written by Gemini. We couldn\'t translate it right now.';

  @override
  String get translating => 'Translating…';

  @override
  String get vibeGenerate => 'Generate a vibe with AI';

  @override
  String get vibeShowExample => 'Show an example vibe';

  @override
  String get vibeAnother => 'Another vibe';

  @override
  String get vibeAnotherExample => 'Another example';

  @override
  String get reviewsNeedSupabase =>
      'Reviews show only when the app is connected to Supabase.';

  @override
  String get ratingFromOldApp =>
      'The rating comes from the original app, until the first reviews.';

  @override
  String get noReviewsYet => 'No reviews yet.';

  @override
  String get ratingFromOneReview => 'The rating comes from a single review.';

  @override
  String ratingAverage(int count) {
    return 'The rating is the average of $count reviews.';
  }

  @override
  String get reviewSignInFirst =>
      'Sign in, on the Profile tab, to write a review.';

  @override
  String get reviewSuspended =>
      'Your account is suspended: you can\'t write reviews.';

  @override
  String get reviewOwnPlace => 'You can\'t review your own place.';

  @override
  String get reviewAcceptedByAdmin => 'It shows once an admin accepts it.';

  @override
  String get reviewAcceptedByOperator =>
      'It shows once the place\'s operator accepts it.';

  @override
  String get reviewAdminAtOnce => 'As an admin, your review shows at once.';

  @override
  String get reviewPublished => 'Your review is published.';

  @override
  String get reviewSentWaiting => 'Your review is sent and waiting.';

  @override
  String get deleteReviewTitle => 'Delete the review?';

  @override
  String get deleteReviewMessage =>
      'Your stars and message disappear from the place\'s page.';

  @override
  String get delete => 'Delete';

  @override
  String get yourReview => 'Your review';

  @override
  String get reviewPending => 'Waiting';

  @override
  String reviewPendingExplanation(String whenAccepted) {
    return '$whenAccepted Until then only you see it.';
  }

  @override
  String get reviewApproved => 'Published';

  @override
  String get reviewApprovedExplanation => 'Anyone who opens the place sees it.';

  @override
  String get reviewRejected => 'Rejected';

  @override
  String reviewRejectedExplanation(String reason) {
    return 'Reason: $reason. You can change it and send it again.';
  }

  @override
  String get deleteReview => 'Delete the review';

  @override
  String get editReview => 'Edit';

  @override
  String reviewEditIntro(String whenPublic) {
    return 'Change what is needed, then send it again. $whenPublic';
  }

  @override
  String reviewNewIntro(String whenPublic) {
    return 'Choose the stars and, if you like, write a few words. $whenPublic';
  }

  @override
  String get reviewMessage => 'Message (optional)';

  @override
  String get sendAgain => 'Send again';

  @override
  String get sendReview => 'Send the review';

  @override
  String get othersSay => 'What others say';

  @override
  String get noPublishedReviews => 'No published reviews yet.';

  @override
  String get errorSignInAgain => 'Sign in again.';

  @override
  String get errorWrongCredentials => 'Wrong email or password.';

  @override
  String get errorEmailNotConfirmed =>
      'You haven\'t confirmed your email yet. Open the link in the email you got, then try again.';

  @override
  String get errorTooManyEmails =>
      'Too many emails were sent. Try again in an hour.';

  @override
  String get errorWeakPassword =>
      'The password is too weak. Choose a longer one.';

  @override
  String get errorInvalidEmail => 'The email address isn\'t accepted.';

  @override
  String get errorEmailTaken => 'There is already an account with this email.';

  @override
  String errorNotSaved(String detail) {
    return 'Couldn\'t save: $detail';
  }

  @override
  String errorFailed(String detail) {
    return 'It didn\'t work: $detail';
  }

  @override
  String get errorOffline =>
      'I can\'t connect. Check the internet and try again.';

  @override
  String get accountsUnavailable =>
      'Accounts aren\'t available in this version of the app: the Supabase settings are missing.';

  @override
  String get signIn => 'Sign in';

  @override
  String get newAccount => 'New account';

  @override
  String confirmationSent(String email) {
    return 'We sent an email to $email. Open the link in it, then sign in here. If you don\'t see it, look in Spam too.';
  }

  @override
  String get email => 'Email';

  @override
  String get invalidEmail => 'Write a valid email address.';

  @override
  String get password => 'Password';

  @override
  String get passwordTooShort => 'The password needs at least 8 characters.';

  @override
  String get repeatPassword => 'Repeat the password';

  @override
  String get passwordsDiffer => 'The passwords don\'t match.';

  @override
  String get createAccount => 'Create the account';

  @override
  String get hidePassword => 'Hide the password';

  @override
  String get showPassword => 'Show the password';

  @override
  String get accountSuspended => 'Your account is suspended';

  @override
  String accountSuspendedDetails(String reason) {
    return 'Reason: $reason\nYou can see the places, but you can\'t make changes.';
  }

  @override
  String get noName => 'No name';

  @override
  String get signOut => 'Sign out';

  @override
  String get reviewsAdmin => 'Reviews: accept and delete';

  @override
  String get reviewsOperator => 'Reviews of my places';

  @override
  String get administration => 'Administration';

  @override
  String get adminPlaces => 'Places: approvals and suspensions';

  @override
  String get adminUsers => 'Users and operators';

  @override
  String get operatorRequestPending =>
      'You asked to become an operator. An admin will answer you.';

  @override
  String operatorRequestRejected(String reason) {
    return 'Your request to become an operator was rejected. Reason: $reason';
  }

  @override
  String get sendRequestAgain => 'Send the request again';

  @override
  String get wantToAddPlaces => 'I want to add places';

  @override
  String get roleUser => 'User';

  @override
  String get roleOperator => 'Place operator';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get language => 'Language of the app';

  @override
  String get errorSignInToReview => 'Sign in to write a review.';

  @override
  String get errorCannotDeleteReview =>
      'You aren\'t allowed to delete this review.';

  @override
  String get errorInvalidFields =>
      'Some fields aren\'t valid. Check them and try again.';

  @override
  String get errorNotAllowed => 'You aren\'t allowed to make this change.';

  @override
  String get myPlaces => 'My places';

  @override
  String get searchMyPlaces => 'Search your places';

  @override
  String get noOwnPlaces => 'You haven\'t added any places yet.';

  @override
  String get noMatchingPlaces => 'No place matches the search.';

  @override
  String editPlace(String name) {
    return 'Edit $name';
  }

  @override
  String get addPlace => 'Add a place';

  @override
  String get placePending => 'Waiting for approval';

  @override
  String get placeApproved => 'Approved: it shows in Explore';

  @override
  String placeRejected(String reason) {
    return 'Rejected: $reason';
  }

  @override
  String placeSuspended(String reason) {
    return 'Suspended: $reason';
  }

  @override
  String reactivatePlaceTitle(String name) {
    return 'Reactivate “$name”?';
  }

  @override
  String approvePlaceTitle(String name) {
    return 'Approve “$name”?';
  }

  @override
  String get reactivatePlaceMessage => 'The place shows in Explore again.';

  @override
  String get approvePlaceMessage =>
      'The place shows in Explore for everyone. Its rating will come from those who visit it.';

  @override
  String get reactivate => 'Reactivate';

  @override
  String get approve => 'Approve';

  @override
  String rejectPlaceTitle(String name) {
    return 'Reject “$name”?';
  }

  @override
  String get reject => 'Reject';

  @override
  String suspendPlaceTitle(String name) {
    return 'Suspend “$name”?';
  }

  @override
  String get suspend => 'Suspend';

  @override
  String get adminPlacesTitle => 'Places';

  @override
  String get searchPlacesAdmin => 'Search by name, city or address';

  @override
  String get noPlacesHere => 'No places here.';

  @override
  String get edit => 'Edit';

  @override
  String get filterToCheck => 'To check';

  @override
  String get filterPublic => 'Public';

  @override
  String get filterRejected => 'Rejected';

  @override
  String get filterSuspended => 'Suspended';

  @override
  String get noRating => 'no rating';

  @override
  String reason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get adminUsersTitle => 'Users';

  @override
  String get searchUsers => 'Search by name or email';

  @override
  String get filterRequests => 'Operator requests';

  @override
  String get filterSuspendedUsers => 'Suspended';

  @override
  String get filterAllUsers => 'All';

  @override
  String get noAccountsHere => 'No accounts here.';

  @override
  String get makeUser => 'Make them a user';

  @override
  String get makeOperator => 'Make them an operator';

  @override
  String get makeAdmin => 'Make them an admin';

  @override
  String get suspendAccount => 'Suspend the account';

  @override
  String accountActions(String name) {
    return 'Actions for $name';
  }

  @override
  String userSuspended(String reason) {
    return 'Suspended: $reason';
  }

  @override
  String get wantsToBeOperator => 'Wants to become an operator';

  @override
  String requestRejected(String reason) {
    return 'Request rejected: $reason';
  }

  @override
  String get active => 'Active';

  @override
  String makeOperatorTitle(String name) {
    return 'Make $name an operator?';
  }

  @override
  String get makeOperatorMessage =>
      'They will be able to add places, which show once you approve them.';

  @override
  String rejectRequestTitle(String name) {
    return 'Reject $name\'s request?';
  }

  @override
  String reactivateAccountTitle(String name) {
    return 'Reactivate $name\'s account?';
  }

  @override
  String get reactivateAccountMessage =>
      'They can use the account again, and their places show in Explore again.';

  @override
  String suspendAccountTitle(String name) {
    return 'Suspend $name\'s account?';
  }

  @override
  String acceptReviewTitle(String author) {
    return 'Accept $author\'s review?';
  }

  @override
  String get acceptReviewMessage =>
      'It shows on the place\'s page and counts in the rating.';

  @override
  String get accept => 'Accept';

  @override
  String rejectReviewTitle(String author) {
    return 'Reject $author\'s review?';
  }

  @override
  String deleteOthersReviewTitle(String author) {
    return 'Delete $author\'s review?';
  }

  @override
  String get deleteOthersReviewMessage =>
      'The stars and the message are gone for good.';

  @override
  String get reviewsTitle => 'Reviews';

  @override
  String get searchReviews => 'Search by place, author or message';

  @override
  String get noReviewsHere => 'No reviews here.';

  @override
  String get filterAccepted => 'Accepted';

  @override
  String quoted(String text) {
    return '“$text”';
  }

  @override
  String get newPlaceTitle => 'New place';

  @override
  String get editPlaceTitle => 'Edit the place';

  @override
  String get editGoesToReview =>
      'Once you save, the place goes back to review and doesn\'t show in Explore until an admin approves it.';

  @override
  String get placeName => 'Name';

  @override
  String get address => 'Address';

  @override
  String get city => 'City';

  @override
  String get chooseCity => 'Choose the city.';

  @override
  String get tapMapToChoose => 'Tap the map to choose the spot.';

  @override
  String get mustBeInRomania => 'The spot must be in Romania.';

  @override
  String get photoLink => 'Link to a photo (optional)';

  @override
  String get linkMustBeHttps => 'The link must start with https://';

  @override
  String get descriptionRo => 'Description in Romanian';

  @override
  String get descriptionEn => 'Description in English';

  @override
  String get descriptionHint => 'What makes the place special?';

  @override
  String get translateToEnglish => 'Translate into English';

  @override
  String get translateToRomanian => 'Translate into Romanian';

  @override
  String get translateNothingYet =>
      'Write the description in one language, and the button translates it into the other.';

  @override
  String get translateNeedsGemini =>
      'Automatic translation needs the Gemini key.';

  @override
  String get translateFailed =>
      'We couldn\'t translate it right now. Try again.';

  @override
  String get sendForApproval => 'Send for approval';

  @override
  String get saveAndSendForApproval => 'Save and send for approval';

  @override
  String tooShort(int min) {
    return 'Too short: at least $min characters.';
  }

  @override
  String tooLong(int max) {
    return 'Too long: at most $max characters.';
  }

  @override
  String get positionOnMap => 'Position on the map';

  @override
  String get tapMapWherePlaceIs => 'Tap the map where the place is.';

  @override
  String get positionChosen => 'Position chosen. Tap again to change it.';

  @override
  String get botNotUnderstood =>
      'I didn\'t understand the question. Could you rephrase it, please? I can answer questions about places, bookings or what the app does.';

  @override
  String get botRecommend =>
      'To find places, use the “Explore” page. You can search by name or city, and the filters sort by rating.';

  @override
  String get botBooking =>
      'You can book from the page of a place, with the “Book on WhatsApp” button.';

  @override
  String get botMapList =>
      'On a phone, the button next to the search switches between the list and the map. On a wide screen you see both.';

  @override
  String get botGreeting =>
      'Hi! How can I help you today? You can ask me about places or about how the app works.';

  @override
  String get botWhichCityDrink => 'Sure! In which city would you like a drink?';

  @override
  String get botWhichCityFood => 'Sure! In which city would you like to eat?';

  @override
  String botFound(String name) {
    return 'I found “$name”.';
  }

  @override
  String botFoundMatching(String name, String criteria) {
    return 'I found “$name”. It looks like what you wanted ($criteria).';
  }

  @override
  String botNothingMatching(String criteria) {
    return 'Sorry, I couldn\'t find any place that matches: $criteria.';
  }

  @override
  String botNothingNamed(String name) {
    return 'I couldn\'t find any place matching “$name”.';
  }

  @override
  String get botCriterionDrink => 'bars/cafés';

  @override
  String get botCriterionFood => 'restaurants';

  @override
  String botCriterionCity(String city) {
    return 'in $city';
  }

  @override
  String botCriterionItem(String item) {
    return 'serving $item';
  }

  @override
  String get botCriterionBest => 'with the best rating';

  @override
  String get botCriterionWorst => 'with the lowest rating';

  @override
  String botNoDrinkIn(String city) {
    return 'Sorry, I couldn\'t find bars or cafés in $city.';
  }

  @override
  String botNoFoodIn(String city) {
    return 'Sorry, I couldn\'t find restaurants in $city.';
  }

  @override
  String botNoPlacesIn(String city) {
    return 'Sorry, I couldn\'t find places in $city.';
  }

  @override
  String botDrinkIn(String city, String names) {
    return 'In $city you can have a drink at: $names.';
  }

  @override
  String botFoodIn(String city, String names) {
    return 'In $city you can eat at: $names.';
  }

  @override
  String botPlacesIn(String city, String names) {
    return 'In $city I found: $names.';
  }

  @override
  String get botItemCoffee => 'coffee';

  @override
  String get botItemTea => 'tea';

  @override
  String get botItemMatcha => 'matcha';

  @override
  String get botItemPizza => 'pizza';

  @override
  String get botItemBurgers => 'burgers';

  @override
  String get botItemBeer => 'beer';

  @override
  String get botItemWine => 'wine';

  @override
  String get botItemVegan => 'vegan food';

  @override
  String get botItemSmoothie => 'smoothies';

  @override
  String get botItemPasta => 'pasta';

  @override
  String get botItemSushi => 'sushi';

  @override
  String get chatSuggestion1 => 'I want a drink in Cluj-Napoca';

  @override
  String get chatSuggestion2 => 'The best coffee';

  @override
  String get chatSuggestion3 => 'Find Burger Shack';

  @override
  String get chatSuggestion4 => 'How do I book?';

  @override
  String get chatWelcome =>
      'Hi! I\'m the Top Places assistant. I answer questions about places, cities and bookings right away.';

  @override
  String get chatWelcomeWithAi =>
      'Hi! I\'m the Top Places assistant. I answer questions about places, cities and bookings right away, and ask the AI (Gemini) what I don\'t know.';

  @override
  String get chatAiQuota =>
      'I didn\'t understand the question, and the AI has reached its free limit for now. Ask me about places, cities or bookings.';

  @override
  String get chatAiDown =>
      'I didn\'t understand the question, and the AI isn\'t answering right now (maybe the internet is down). Ask me about places, cities or bookings.';

  @override
  String get chatGeminiWriting => 'Gemini is writing an answer';

  @override
  String get chatHint => 'Write a message...';

  @override
  String get chatSend => 'Send';

  @override
  String get chatYou => 'You';

  @override
  String get chatAssistant => 'The assistant';

  @override
  String get showOnMap => 'Show on the map';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'Automatic';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String showMoreReviews(int count) {
    return 'Show more ($count)';
  }

  @override
  String allReviewsTitle(String name) {
    return 'Reviews: $name';
  }

  @override
  String filterAllStars(int count) {
    return 'All ($count)';
  }

  @override
  String filterStars(int stars, int count) {
    return '$stars ★ ($count)';
  }

  @override
  String noReviewsWithStars(int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: 'No $stars-star reviews.',
      one: 'No 1-star reviews.',
    );
    return '$_temp0';
  }

  @override
  String reviewAuthorYou(String author) {
    return '$author (you)';
  }
}
