import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ro.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ro'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ro, this message translates to:
  /// **'Top Places'**
  String get appTitle;

  /// No description provided for @tabExplore.
  ///
  /// In ro, this message translates to:
  /// **'Explorează'**
  String get tabExplore;

  /// No description provided for @tabAssistant.
  ///
  /// In ro, this message translates to:
  /// **'Asistent'**
  String get tabAssistant;

  /// No description provided for @tabProfile.
  ///
  /// In ro, this message translates to:
  /// **'Profil'**
  String get tabProfile;

  /// No description provided for @notFoundTitle.
  ///
  /// In ro, this message translates to:
  /// **'Pagină inexistentă'**
  String get notFoundTitle;

  /// No description provided for @notFoundMessage.
  ///
  /// In ro, this message translates to:
  /// **'Nu am găsit pagina căutată.'**
  String get notFoundMessage;

  /// No description provided for @notFoundBack.
  ///
  /// In ro, this message translates to:
  /// **'Înapoi la Explorează'**
  String get notFoundBack;

  /// No description provided for @filtersTitle.
  ///
  /// In ro, this message translates to:
  /// **'Filtrează & Sortează'**
  String get filtersTitle;

  /// No description provided for @filtersCity.
  ///
  /// In ro, this message translates to:
  /// **'Oraș'**
  String get filtersCity;

  /// No description provided for @filtersAllCities.
  ///
  /// In ro, this message translates to:
  /// **'Toate'**
  String get filtersAllCities;

  /// No description provided for @filtersMinRating.
  ///
  /// In ro, this message translates to:
  /// **'Rating minim'**
  String get filtersMinRating;

  /// No description provided for @filtersAnyRating.
  ///
  /// In ro, this message translates to:
  /// **'Oricare'**
  String get filtersAnyRating;

  /// No description provided for @filtersSort.
  ///
  /// In ro, this message translates to:
  /// **'Sortare'**
  String get filtersSort;

  /// No description provided for @sortRecommended.
  ///
  /// In ro, this message translates to:
  /// **'Recomandat'**
  String get sortRecommended;

  /// No description provided for @sortRatingDown.
  ///
  /// In ro, this message translates to:
  /// **'Rating ↓'**
  String get sortRatingDown;

  /// No description provided for @sortRatingUp.
  ///
  /// In ro, this message translates to:
  /// **'Rating ↑'**
  String get sortRatingUp;

  /// No description provided for @sortName.
  ///
  /// In ro, this message translates to:
  /// **'Nume (A-Z)'**
  String get sortName;

  /// No description provided for @filtersReset.
  ///
  /// In ro, this message translates to:
  /// **'Resetează'**
  String get filtersReset;

  /// No description provided for @filtersApply.
  ///
  /// In ro, this message translates to:
  /// **'Aplică filtre'**
  String get filtersApply;

  /// No description provided for @cancel.
  ///
  /// In ro, this message translates to:
  /// **'Renunță'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In ro, this message translates to:
  /// **'Salvează'**
  String get save;

  /// No description provided for @requiredField.
  ///
  /// In ro, this message translates to:
  /// **'Câmp obligatoriu.'**
  String get requiredField;

  /// No description provided for @changeName.
  ///
  /// In ro, this message translates to:
  /// **'Schimbă numele'**
  String get changeName;

  /// No description provided for @firstName.
  ///
  /// In ro, this message translates to:
  /// **'Prenume'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In ro, this message translates to:
  /// **'Nume'**
  String get lastName;

  /// No description provided for @reasonLabel.
  ///
  /// In ro, this message translates to:
  /// **'Motivul'**
  String get reasonLabel;

  /// No description provided for @reasonHelper.
  ///
  /// In ro, this message translates to:
  /// **'Îl vede și persoana în cauză.'**
  String get reasonHelper;

  /// No description provided for @reasonRequired.
  ///
  /// In ro, this message translates to:
  /// **'Scrie motivul.'**
  String get reasonRequired;

  /// No description provided for @bookingMessage.
  ///
  /// In ro, this message translates to:
  /// **'Rezervare la {place}'**
  String bookingMessage(String place);

  /// No description provided for @linkFailed.
  ///
  /// In ro, this message translates to:
  /// **'Nu am putut deschide linkul.'**
  String get linkFailed;

  /// No description provided for @clearSearch.
  ///
  /// In ro, this message translates to:
  /// **'Șterge căutarea'**
  String get clearSearch;

  /// No description provided for @ratingNew.
  ///
  /// In ro, this message translates to:
  /// **'Nou'**
  String get ratingNew;

  /// No description provided for @ratingNewLabel.
  ///
  /// In ro, this message translates to:
  /// **'local nou'**
  String get ratingNewLabel;

  /// No description provided for @ratingStarsLabel.
  ///
  /// In ro, this message translates to:
  /// **'{rating} stele'**
  String ratingStarsLabel(String rating);

  /// No description provided for @stars.
  ///
  /// In ro, this message translates to:
  /// **'{count, plural, =1{1 stea} other{{count} stele}}'**
  String stars(int count);

  /// No description provided for @results.
  ///
  /// In ro, this message translates to:
  /// **'{count, plural, =1{1 rezultat} few{{count} rezultate} other{{count} de rezultate}}'**
  String results(int count);

  /// No description provided for @reviewCount.
  ///
  /// In ro, this message translates to:
  /// **'{count, plural, =1{1 recenzie} few{{count} recenzii} other{{count} de recenzii}}'**
  String reviewCount(int count);

  /// No description provided for @placeCount.
  ///
  /// In ro, this message translates to:
  /// **'{count, plural, =1{1 local} few{{count} localuri} other{{count} de localuri}}'**
  String placeCount(int count);

  /// No description provided for @searchHint.
  ///
  /// In ro, this message translates to:
  /// **'Caută locații sau orașe...'**
  String get searchHint;

  /// No description provided for @filterTooltip.
  ///
  /// In ro, this message translates to:
  /// **'Filtrează și sortează'**
  String get filterTooltip;

  /// No description provided for @showList.
  ///
  /// In ro, this message translates to:
  /// **'Arată lista'**
  String get showList;

  /// No description provided for @showMap.
  ///
  /// In ro, this message translates to:
  /// **'Arată harta'**
  String get showMap;

  /// No description provided for @placesTitle.
  ///
  /// In ro, this message translates to:
  /// **'Locații'**
  String get placesTitle;

  /// No description provided for @filtersActive.
  ///
  /// In ro, this message translates to:
  /// **'Filtre active'**
  String get filtersActive;

  /// No description provided for @noPlaces.
  ///
  /// In ro, this message translates to:
  /// **'Nu am găsit locații.'**
  String get noPlaces;

  /// No description provided for @suggestionRated.
  ///
  /// In ro, this message translates to:
  /// **'{city} · ★ {rating}'**
  String suggestionRated(String city, String rating);

  /// No description provided for @suggestionNew.
  ///
  /// In ro, this message translates to:
  /// **'{city} · Nou'**
  String suggestionNew(String city);

  /// No description provided for @clusterLabel.
  ///
  /// In ro, this message translates to:
  /// **'{places} aici. Apasă ca să apropii harta.'**
  String clusterLabel(String places);

  /// No description provided for @locationServiceOff.
  ///
  /// In ro, this message translates to:
  /// **'Localizarea e oprită pe dispozitiv. Pornește-o și încearcă din nou.'**
  String get locationServiceOff;

  /// No description provided for @locationDenied.
  ///
  /// In ro, this message translates to:
  /// **'Fără permisiunea de localizare nu te pot arăta pe hartă.'**
  String get locationDenied;

  /// No description provided for @locationDeniedForever.
  ///
  /// In ro, this message translates to:
  /// **'Ai refuzat localizarea pentru Top Places. O poți permite din setările aplicației.'**
  String get locationDeniedForever;

  /// No description provided for @locationBlockedByBrowser.
  ///
  /// In ro, this message translates to:
  /// **'Browserul blochează localizarea. O poți permite din setările site-ului.'**
  String get locationBlockedByBrowser;

  /// No description provided for @locationAccuracyOff.
  ///
  /// In ro, this message translates to:
  /// **'Localizarea precisă a rămas oprită. Apasă din nou și accept-o când telefonul te întreabă.'**
  String get locationAccuracyOff;

  /// No description provided for @locationNotFound.
  ///
  /// In ro, this message translates to:
  /// **'Nu am putut afla unde ești. Încearcă din nou.'**
  String get locationNotFound;

  /// No description provided for @settings.
  ///
  /// In ro, this message translates to:
  /// **'Setări'**
  String get settings;

  /// No description provided for @myLocationTooltip.
  ///
  /// In ro, this message translates to:
  /// **'Arată-mi locația'**
  String get myLocationTooltip;

  /// No description provided for @myLocationLabel.
  ///
  /// In ro, this message translates to:
  /// **'Locația ta'**
  String get myLocationLabel;

  /// No description provided for @shrink.
  ///
  /// In ro, this message translates to:
  /// **'Micșorează'**
  String get shrink;

  /// No description provided for @allDetails.
  ///
  /// In ro, this message translates to:
  /// **'Toate detaliile'**
  String get allDetails;

  /// No description provided for @newPlaceNoReviews.
  ///
  /// In ro, this message translates to:
  /// **'Local nou, fără recenzii încă'**
  String get newPlaceNoReviews;

  /// No description provided for @bookOnWhatsApp.
  ///
  /// In ro, this message translates to:
  /// **'Rezervă pe WhatsApp'**
  String get bookOnWhatsApp;

  /// No description provided for @directions.
  ///
  /// In ro, this message translates to:
  /// **'Indicații'**
  String get directions;

  /// No description provided for @tabDescription.
  ///
  /// In ro, this message translates to:
  /// **'Descriere'**
  String get tabDescription;

  /// No description provided for @tabReviews.
  ///
  /// In ro, this message translates to:
  /// **'Recenzii'**
  String get tabReviews;

  /// No description provided for @aboutPlace.
  ///
  /// In ro, this message translates to:
  /// **'Despre locație'**
  String get aboutPlace;

  /// No description provided for @vibeExample1.
  ///
  /// In ro, this message translates to:
  /// **'Atmosfera este electrică și primitoare, perfectă pentru o ieșire memorabilă.'**
  String get vibeExample1;

  /// No description provided for @vibeExample2.
  ///
  /// In ro, this message translates to:
  /// **'Un loc cu un vibe relaxat, unde te poți deconecta complet de agitația orașului.'**
  String get vibeExample2;

  /// No description provided for @vibeExample3.
  ///
  /// In ro, this message translates to:
  /// **'Energia locului te cucerește imediat, iar detaliile de design fac diferența.'**
  String get vibeExample3;

  /// No description provided for @vibeExampleNoAi.
  ///
  /// In ro, this message translates to:
  /// **'Exemplu scris dinainte, nu generat de AI.'**
  String get vibeExampleNoAi;

  /// No description provided for @vibeExampleAiDown.
  ///
  /// In ro, this message translates to:
  /// **'Exemplu scris dinainte: AI-ul nu răspunde acum.'**
  String get vibeExampleAiDown;

  /// No description provided for @aiNote.
  ///
  /// In ro, this message translates to:
  /// **'Generat cu Gemini. Poate conține greșeli.'**
  String get aiNote;

  /// No description provided for @vibeNotTranslated.
  ///
  /// In ro, this message translates to:
  /// **'Generat cu Gemini. Nu l-am putut traduce acum.'**
  String get vibeNotTranslated;

  /// No description provided for @translating.
  ///
  /// In ro, this message translates to:
  /// **'Se traduce…'**
  String get translating;

  /// No description provided for @vibeGenerate.
  ///
  /// In ro, this message translates to:
  /// **'Generează un vibe cu AI'**
  String get vibeGenerate;

  /// No description provided for @vibeShowExample.
  ///
  /// In ro, this message translates to:
  /// **'Arată un exemplu de vibe'**
  String get vibeShowExample;

  /// No description provided for @vibeAnother.
  ///
  /// In ro, this message translates to:
  /// **'Alt vibe'**
  String get vibeAnother;

  /// No description provided for @vibeAnotherExample.
  ///
  /// In ro, this message translates to:
  /// **'Alt exemplu'**
  String get vibeAnotherExample;

  /// No description provided for @reviewsNeedSupabase.
  ///
  /// In ro, this message translates to:
  /// **'Recenziile se văd doar când aplicația e conectată la Supabase.'**
  String get reviewsNeedSupabase;

  /// No description provided for @ratingFromOldApp.
  ///
  /// In ro, this message translates to:
  /// **'Ratingul vine din aplicația originală, până la primele recenzii.'**
  String get ratingFromOldApp;

  /// No description provided for @noReviewsYet.
  ///
  /// In ro, this message translates to:
  /// **'Nicio recenzie încă.'**
  String get noReviewsYet;

  /// No description provided for @ratingFromOneReview.
  ///
  /// In ro, this message translates to:
  /// **'Ratingul vine dintr-o singură recenzie.'**
  String get ratingFromOneReview;

  /// No description provided for @ratingAverage.
  ///
  /// In ro, this message translates to:
  /// **'Ratingul e media celor {count, plural, few{{count} recenzii} other{{count} de recenzii}}.'**
  String ratingAverage(int count);

  /// No description provided for @reviewSignInFirst.
  ///
  /// In ro, this message translates to:
  /// **'Intră în cont, din tab-ul Profil, ca să scrii o recenzie.'**
  String get reviewSignInFirst;

  /// No description provided for @reviewSuspended.
  ///
  /// In ro, this message translates to:
  /// **'Contul tău e suspendat: nu poți scrie recenzii.'**
  String get reviewSuspended;

  /// No description provided for @reviewOwnPlace.
  ///
  /// In ro, this message translates to:
  /// **'Nu poți scrie recenzii la propriul local.'**
  String get reviewOwnPlace;

  /// No description provided for @reviewAcceptedByAdmin.
  ///
  /// In ro, this message translates to:
  /// **'Apare după ce o acceptă un administrator.'**
  String get reviewAcceptedByAdmin;

  /// No description provided for @reviewAcceptedByOperator.
  ///
  /// In ro, this message translates to:
  /// **'Apare după ce o acceptă operatorul localului.'**
  String get reviewAcceptedByOperator;

  /// No description provided for @reviewAdminAtOnce.
  ///
  /// In ro, this message translates to:
  /// **'Ca administrator, recenzia ta apare imediat.'**
  String get reviewAdminAtOnce;

  /// No description provided for @reviewPublished.
  ///
  /// In ro, this message translates to:
  /// **'Recenzia ta a fost publicată.'**
  String get reviewPublished;

  /// No description provided for @reviewSentWaiting.
  ///
  /// In ro, this message translates to:
  /// **'Recenzia ta a fost trimisă și e în așteptare.'**
  String get reviewSentWaiting;

  /// No description provided for @deleteReviewTitle.
  ///
  /// In ro, this message translates to:
  /// **'Ștergi recenzia?'**
  String get deleteReviewTitle;

  /// No description provided for @deleteReviewMessage.
  ///
  /// In ro, this message translates to:
  /// **'Nota și mesajul tău dispar de pe pagina localului.'**
  String get deleteReviewMessage;

  /// No description provided for @delete.
  ///
  /// In ro, this message translates to:
  /// **'Șterge'**
  String get delete;

  /// No description provided for @yourReview.
  ///
  /// In ro, this message translates to:
  /// **'Recenzia ta'**
  String get yourReview;

  /// No description provided for @reviewPending.
  ///
  /// In ro, this message translates to:
  /// **'În așteptare'**
  String get reviewPending;

  /// No description provided for @reviewPendingExplanation.
  ///
  /// In ro, this message translates to:
  /// **'{whenAccepted} Până atunci o vezi doar tu.'**
  String reviewPendingExplanation(String whenAccepted);

  /// No description provided for @reviewApproved.
  ///
  /// In ro, this message translates to:
  /// **'Publicată'**
  String get reviewApproved;

  /// No description provided for @reviewApprovedExplanation.
  ///
  /// In ro, this message translates to:
  /// **'O vede oricine deschide localul.'**
  String get reviewApprovedExplanation;

  /// No description provided for @reviewRejected.
  ///
  /// In ro, this message translates to:
  /// **'Respinsă'**
  String get reviewRejected;

  /// No description provided for @reviewRejectedExplanation.
  ///
  /// In ro, this message translates to:
  /// **'Motiv: {reason}. O poți modifica și trimite din nou.'**
  String reviewRejectedExplanation(String reason);

  /// No description provided for @deleteReview.
  ///
  /// In ro, this message translates to:
  /// **'Șterge recenzia'**
  String get deleteReview;

  /// No description provided for @editReview.
  ///
  /// In ro, this message translates to:
  /// **'Modifică'**
  String get editReview;

  /// No description provided for @reviewEditIntro.
  ///
  /// In ro, this message translates to:
  /// **'Schimbă ce trebuie, apoi trimite din nou. {whenPublic}'**
  String reviewEditIntro(String whenPublic);

  /// No description provided for @reviewNewIntro.
  ///
  /// In ro, this message translates to:
  /// **'Alege stelele și, dacă vrei, scrie câteva cuvinte. {whenPublic}'**
  String reviewNewIntro(String whenPublic);

  /// No description provided for @reviewMessage.
  ///
  /// In ro, this message translates to:
  /// **'Mesaj (opțional)'**
  String get reviewMessage;

  /// No description provided for @sendAgain.
  ///
  /// In ro, this message translates to:
  /// **'Trimite din nou'**
  String get sendAgain;

  /// No description provided for @sendReview.
  ///
  /// In ro, this message translates to:
  /// **'Trimite recenzia'**
  String get sendReview;

  /// No description provided for @othersSay.
  ///
  /// In ro, this message translates to:
  /// **'Ce spun ceilalți'**
  String get othersSay;

  /// No description provided for @noPublishedReviews.
  ///
  /// In ro, this message translates to:
  /// **'Nicio recenzie publicată încă.'**
  String get noPublishedReviews;

  /// No description provided for @errorSignInAgain.
  ///
  /// In ro, this message translates to:
  /// **'Intră din nou în cont.'**
  String get errorSignInAgain;

  /// No description provided for @errorWrongCredentials.
  ///
  /// In ro, this message translates to:
  /// **'Email sau parolă greșite.'**
  String get errorWrongCredentials;

  /// No description provided for @errorEmailNotConfirmed.
  ///
  /// In ro, this message translates to:
  /// **'Încă nu ți-ai confirmat emailul. Deschide linkul din emailul primit, apoi încearcă din nou.'**
  String get errorEmailNotConfirmed;

  /// No description provided for @errorTooManyEmails.
  ///
  /// In ro, this message translates to:
  /// **'S-au trimis prea multe emailuri. Încearcă din nou peste o oră.'**
  String get errorTooManyEmails;

  /// No description provided for @errorWeakPassword.
  ///
  /// In ro, this message translates to:
  /// **'Parola e prea slabă. Alege una mai lungă.'**
  String get errorWeakPassword;

  /// No description provided for @errorInvalidEmail.
  ///
  /// In ro, this message translates to:
  /// **'Adresa de email nu e acceptată.'**
  String get errorInvalidEmail;

  /// No description provided for @errorEmailTaken.
  ///
  /// In ro, this message translates to:
  /// **'Există deja un cont cu acest email.'**
  String get errorEmailTaken;

  /// No description provided for @errorNotSaved.
  ///
  /// In ro, this message translates to:
  /// **'Nu am putut salva: {detail}'**
  String errorNotSaved(String detail);

  /// No description provided for @errorFailed.
  ///
  /// In ro, this message translates to:
  /// **'Nu a mers: {detail}'**
  String errorFailed(String detail);

  /// No description provided for @errorOffline.
  ///
  /// In ro, this message translates to:
  /// **'Nu mă pot conecta. Verifică internetul și încearcă din nou.'**
  String get errorOffline;

  /// No description provided for @accountsUnavailable.
  ///
  /// In ro, this message translates to:
  /// **'Conturile nu sunt disponibile în această versiune a aplicației: lipsește configurarea Supabase.'**
  String get accountsUnavailable;

  /// No description provided for @signIn.
  ///
  /// In ro, this message translates to:
  /// **'Intră în cont'**
  String get signIn;

  /// No description provided for @newAccount.
  ///
  /// In ro, this message translates to:
  /// **'Cont nou'**
  String get newAccount;

  /// No description provided for @confirmationSent.
  ///
  /// In ro, this message translates to:
  /// **'Ți-am trimis un email la {email}. Deschide linkul din el, apoi intră în cont aici. Dacă nu îl vezi, caută și în Spam.'**
  String confirmationSent(String email);

  /// No description provided for @email.
  ///
  /// In ro, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @invalidEmail.
  ///
  /// In ro, this message translates to:
  /// **'Scrie o adresă de email validă.'**
  String get invalidEmail;

  /// No description provided for @password.
  ///
  /// In ro, this message translates to:
  /// **'Parolă'**
  String get password;

  /// No description provided for @passwordTooShort.
  ///
  /// In ro, this message translates to:
  /// **'Parola trebuie să aibă cel puțin 8 caractere.'**
  String get passwordTooShort;

  /// No description provided for @repeatPassword.
  ///
  /// In ro, this message translates to:
  /// **'Repetă parola'**
  String get repeatPassword;

  /// No description provided for @passwordsDiffer.
  ///
  /// In ro, this message translates to:
  /// **'Parolele nu sunt la fel.'**
  String get passwordsDiffer;

  /// No description provided for @createAccount.
  ///
  /// In ro, this message translates to:
  /// **'Creează contul'**
  String get createAccount;

  /// No description provided for @hidePassword.
  ///
  /// In ro, this message translates to:
  /// **'Ascunde parola'**
  String get hidePassword;

  /// No description provided for @showPassword.
  ///
  /// In ro, this message translates to:
  /// **'Arată parola'**
  String get showPassword;

  /// No description provided for @accountSuspended.
  ///
  /// In ro, this message translates to:
  /// **'Contul tău e suspendat'**
  String get accountSuspended;

  /// No description provided for @accountSuspendedDetails.
  ///
  /// In ro, this message translates to:
  /// **'Motiv: {reason}\nPoți vedea localurile, dar nu poți face modificări.'**
  String accountSuspendedDetails(String reason);

  /// No description provided for @noName.
  ///
  /// In ro, this message translates to:
  /// **'Fără nume'**
  String get noName;

  /// No description provided for @signOut.
  ///
  /// In ro, this message translates to:
  /// **'Ieși din cont'**
  String get signOut;

  /// No description provided for @reviewsAdmin.
  ///
  /// In ro, this message translates to:
  /// **'Recenzii: acceptări și ștergeri'**
  String get reviewsAdmin;

  /// No description provided for @reviewsOperator.
  ///
  /// In ro, this message translates to:
  /// **'Recenziile localurilor mele'**
  String get reviewsOperator;

  /// No description provided for @administration.
  ///
  /// In ro, this message translates to:
  /// **'Administrare'**
  String get administration;

  /// No description provided for @adminPlaces.
  ///
  /// In ro, this message translates to:
  /// **'Localuri: aprobări și suspendări'**
  String get adminPlaces;

  /// No description provided for @adminUsers.
  ///
  /// In ro, this message translates to:
  /// **'Utilizatori și operatori'**
  String get adminUsers;

  /// No description provided for @operatorRequestPending.
  ///
  /// In ro, this message translates to:
  /// **'Ai cerut să devii operator. Un administrator îți va răspunde.'**
  String get operatorRequestPending;

  /// No description provided for @operatorRequestRejected.
  ///
  /// In ro, this message translates to:
  /// **'Cererea ta de a deveni operator a fost respinsă. Motiv: {reason}'**
  String operatorRequestRejected(String reason);

  /// No description provided for @sendRequestAgain.
  ///
  /// In ro, this message translates to:
  /// **'Trimite din nou cererea'**
  String get sendRequestAgain;

  /// No description provided for @wantToAddPlaces.
  ///
  /// In ro, this message translates to:
  /// **'Vreau să adaug localuri'**
  String get wantToAddPlaces;

  /// No description provided for @roleUser.
  ///
  /// In ro, this message translates to:
  /// **'Utilizator'**
  String get roleUser;

  /// No description provided for @roleOperator.
  ///
  /// In ro, this message translates to:
  /// **'Operator de localuri'**
  String get roleOperator;

  /// No description provided for @roleAdmin.
  ///
  /// In ro, this message translates to:
  /// **'Administrator'**
  String get roleAdmin;

  /// No description provided for @language.
  ///
  /// In ro, this message translates to:
  /// **'Limba aplicației'**
  String get language;

  /// No description provided for @errorSignInToReview.
  ///
  /// In ro, this message translates to:
  /// **'Intră în cont ca să scrii o recenzie.'**
  String get errorSignInToReview;

  /// No description provided for @errorCannotDeleteReview.
  ///
  /// In ro, this message translates to:
  /// **'Nu ai voie să ștergi această recenzie.'**
  String get errorCannotDeleteReview;

  /// No description provided for @errorInvalidFields.
  ///
  /// In ro, this message translates to:
  /// **'Unele câmpuri nu sunt valide. Verifică-le și încearcă din nou.'**
  String get errorInvalidFields;

  /// No description provided for @errorNotAllowed.
  ///
  /// In ro, this message translates to:
  /// **'Nu ai voie să faci această modificare.'**
  String get errorNotAllowed;

  /// No description provided for @myPlaces.
  ///
  /// In ro, this message translates to:
  /// **'Localurile mele'**
  String get myPlaces;

  /// No description provided for @searchMyPlaces.
  ///
  /// In ro, this message translates to:
  /// **'Caută în localurile tale'**
  String get searchMyPlaces;

  /// No description provided for @noOwnPlaces.
  ///
  /// In ro, this message translates to:
  /// **'Încă nu ai adăugat niciun local.'**
  String get noOwnPlaces;

  /// No description provided for @noMatchingPlaces.
  ///
  /// In ro, this message translates to:
  /// **'Niciun local nu se potrivește căutării.'**
  String get noMatchingPlaces;

  /// No description provided for @editPlace.
  ///
  /// In ro, this message translates to:
  /// **'Editează {name}'**
  String editPlace(String name);

  /// No description provided for @addPlace.
  ///
  /// In ro, this message translates to:
  /// **'Adaugă un local'**
  String get addPlace;

  /// No description provided for @placePending.
  ///
  /// In ro, this message translates to:
  /// **'În așteptarea aprobării'**
  String get placePending;

  /// No description provided for @placeApproved.
  ///
  /// In ro, this message translates to:
  /// **'Aprobat: apare în Explorează'**
  String get placeApproved;

  /// No description provided for @placeRejected.
  ///
  /// In ro, this message translates to:
  /// **'Respins: {reason}'**
  String placeRejected(String reason);

  /// No description provided for @placeSuspended.
  ///
  /// In ro, this message translates to:
  /// **'Suspendat: {reason}'**
  String placeSuspended(String reason);

  /// No description provided for @reactivatePlaceTitle.
  ///
  /// In ro, this message translates to:
  /// **'Reactivezi „{name}”?'**
  String reactivatePlaceTitle(String name);

  /// No description provided for @approvePlaceTitle.
  ///
  /// In ro, this message translates to:
  /// **'Aprobi „{name}”?'**
  String approvePlaceTitle(String name);

  /// No description provided for @reactivatePlaceMessage.
  ///
  /// In ro, this message translates to:
  /// **'Localul apare din nou în Explorează.'**
  String get reactivatePlaceMessage;

  /// No description provided for @approvePlaceMessage.
  ///
  /// In ro, this message translates to:
  /// **'Localul apare în Explorează pentru toată lumea. Ratingul îl vor da cei care îl vizitează.'**
  String get approvePlaceMessage;

  /// No description provided for @reactivate.
  ///
  /// In ro, this message translates to:
  /// **'Reactivează'**
  String get reactivate;

  /// No description provided for @approve.
  ///
  /// In ro, this message translates to:
  /// **'Aprobă'**
  String get approve;

  /// No description provided for @rejectPlaceTitle.
  ///
  /// In ro, this message translates to:
  /// **'Respingi „{name}”?'**
  String rejectPlaceTitle(String name);

  /// No description provided for @reject.
  ///
  /// In ro, this message translates to:
  /// **'Respinge'**
  String get reject;

  /// No description provided for @suspendPlaceTitle.
  ///
  /// In ro, this message translates to:
  /// **'Suspenzi „{name}”?'**
  String suspendPlaceTitle(String name);

  /// No description provided for @suspend.
  ///
  /// In ro, this message translates to:
  /// **'Suspendă'**
  String get suspend;

  /// No description provided for @adminPlacesTitle.
  ///
  /// In ro, this message translates to:
  /// **'Localuri'**
  String get adminPlacesTitle;

  /// No description provided for @searchPlacesAdmin.
  ///
  /// In ro, this message translates to:
  /// **'Caută după nume, oraș sau adresă'**
  String get searchPlacesAdmin;

  /// No description provided for @noPlacesHere.
  ///
  /// In ro, this message translates to:
  /// **'Niciun local aici.'**
  String get noPlacesHere;

  /// No description provided for @edit.
  ///
  /// In ro, this message translates to:
  /// **'Editează'**
  String get edit;

  /// No description provided for @filterToCheck.
  ///
  /// In ro, this message translates to:
  /// **'De verificat'**
  String get filterToCheck;

  /// No description provided for @filterPublic.
  ///
  /// In ro, this message translates to:
  /// **'Publice'**
  String get filterPublic;

  /// No description provided for @filterRejected.
  ///
  /// In ro, this message translates to:
  /// **'Respinse'**
  String get filterRejected;

  /// No description provided for @filterSuspended.
  ///
  /// In ro, this message translates to:
  /// **'Suspendate'**
  String get filterSuspended;

  /// No description provided for @noRating.
  ///
  /// In ro, this message translates to:
  /// **'fără rating'**
  String get noRating;

  /// No description provided for @reason.
  ///
  /// In ro, this message translates to:
  /// **'Motiv: {reason}'**
  String reason(String reason);

  /// No description provided for @adminUsersTitle.
  ///
  /// In ro, this message translates to:
  /// **'Utilizatori'**
  String get adminUsersTitle;

  /// No description provided for @searchUsers.
  ///
  /// In ro, this message translates to:
  /// **'Caută după nume sau email'**
  String get searchUsers;

  /// No description provided for @filterRequests.
  ///
  /// In ro, this message translates to:
  /// **'Cereri de operator'**
  String get filterRequests;

  /// No description provided for @filterSuspendedUsers.
  ///
  /// In ro, this message translates to:
  /// **'Suspendați'**
  String get filterSuspendedUsers;

  /// No description provided for @filterAllUsers.
  ///
  /// In ro, this message translates to:
  /// **'Toți'**
  String get filterAllUsers;

  /// No description provided for @noAccountsHere.
  ///
  /// In ro, this message translates to:
  /// **'Niciun cont aici.'**
  String get noAccountsHere;

  /// No description provided for @makeUser.
  ///
  /// In ro, this message translates to:
  /// **'Fă-l utilizator'**
  String get makeUser;

  /// No description provided for @makeOperator.
  ///
  /// In ro, this message translates to:
  /// **'Fă-l operator'**
  String get makeOperator;

  /// No description provided for @makeAdmin.
  ///
  /// In ro, this message translates to:
  /// **'Fă-l administrator'**
  String get makeAdmin;

  /// No description provided for @suspendAccount.
  ///
  /// In ro, this message translates to:
  /// **'Suspendă contul'**
  String get suspendAccount;

  /// No description provided for @accountActions.
  ///
  /// In ro, this message translates to:
  /// **'Acțiuni pentru {name}'**
  String accountActions(String name);

  /// No description provided for @userSuspended.
  ///
  /// In ro, this message translates to:
  /// **'Suspendat: {reason}'**
  String userSuspended(String reason);

  /// No description provided for @wantsToBeOperator.
  ///
  /// In ro, this message translates to:
  /// **'Vrea să devină operator'**
  String get wantsToBeOperator;

  /// No description provided for @requestRejected.
  ///
  /// In ro, this message translates to:
  /// **'Cerere respinsă: {reason}'**
  String requestRejected(String reason);

  /// No description provided for @active.
  ///
  /// In ro, this message translates to:
  /// **'Activ'**
  String get active;

  /// No description provided for @makeOperatorTitle.
  ///
  /// In ro, this message translates to:
  /// **'Îl faci pe {name} operator?'**
  String makeOperatorTitle(String name);

  /// No description provided for @makeOperatorMessage.
  ///
  /// In ro, this message translates to:
  /// **'Va putea adăuga localuri, care apar după ce le aprobi.'**
  String get makeOperatorMessage;

  /// No description provided for @rejectRequestTitle.
  ///
  /// In ro, this message translates to:
  /// **'Respingi cererea lui {name}?'**
  String rejectRequestTitle(String name);

  /// No description provided for @reactivateAccountTitle.
  ///
  /// In ro, this message translates to:
  /// **'Reactivezi contul lui {name}?'**
  String reactivateAccountTitle(String name);

  /// No description provided for @reactivateAccountMessage.
  ///
  /// In ro, this message translates to:
  /// **'Va putea folosi din nou contul, iar localurile lui reapar în Explorează.'**
  String get reactivateAccountMessage;

  /// No description provided for @suspendAccountTitle.
  ///
  /// In ro, this message translates to:
  /// **'Suspenzi contul lui {name}?'**
  String suspendAccountTitle(String name);

  /// No description provided for @acceptReviewTitle.
  ///
  /// In ro, this message translates to:
  /// **'Accepți recenzia lui {author}?'**
  String acceptReviewTitle(String author);

  /// No description provided for @acceptReviewMessage.
  ///
  /// In ro, this message translates to:
  /// **'Apare pe pagina localului și intră în rating.'**
  String get acceptReviewMessage;

  /// No description provided for @accept.
  ///
  /// In ro, this message translates to:
  /// **'Acceptă'**
  String get accept;

  /// No description provided for @rejectReviewTitle.
  ///
  /// In ro, this message translates to:
  /// **'Respingi recenzia lui {author}?'**
  String rejectReviewTitle(String author);

  /// No description provided for @deleteOthersReviewTitle.
  ///
  /// In ro, this message translates to:
  /// **'Ștergi recenzia lui {author}?'**
  String deleteOthersReviewTitle(String author);

  /// No description provided for @deleteOthersReviewMessage.
  ///
  /// In ro, this message translates to:
  /// **'Nota și mesajul dispar definitiv.'**
  String get deleteOthersReviewMessage;

  /// No description provided for @reviewsTitle.
  ///
  /// In ro, this message translates to:
  /// **'Recenzii'**
  String get reviewsTitle;

  /// No description provided for @searchReviews.
  ///
  /// In ro, this message translates to:
  /// **'Caută după local, autor sau mesaj'**
  String get searchReviews;

  /// No description provided for @noReviewsHere.
  ///
  /// In ro, this message translates to:
  /// **'Nicio recenzie aici.'**
  String get noReviewsHere;

  /// No description provided for @filterAccepted.
  ///
  /// In ro, this message translates to:
  /// **'Acceptate'**
  String get filterAccepted;

  /// No description provided for @quoted.
  ///
  /// In ro, this message translates to:
  /// **'„{text}”'**
  String quoted(String text);

  /// No description provided for @newPlaceTitle.
  ///
  /// In ro, this message translates to:
  /// **'Local nou'**
  String get newPlaceTitle;

  /// No description provided for @editPlaceTitle.
  ///
  /// In ro, this message translates to:
  /// **'Editează localul'**
  String get editPlaceTitle;

  /// No description provided for @editGoesToReview.
  ///
  /// In ro, this message translates to:
  /// **'După ce salvezi, localul intră din nou în verificare și nu apare în Explorează până nu îl aprobă un administrator.'**
  String get editGoesToReview;

  /// No description provided for @placeName.
  ///
  /// In ro, this message translates to:
  /// **'Nume'**
  String get placeName;

  /// No description provided for @address.
  ///
  /// In ro, this message translates to:
  /// **'Adresă'**
  String get address;

  /// No description provided for @city.
  ///
  /// In ro, this message translates to:
  /// **'Oraș'**
  String get city;

  /// No description provided for @chooseCity.
  ///
  /// In ro, this message translates to:
  /// **'Alege orașul.'**
  String get chooseCity;

  /// No description provided for @tapMapToChoose.
  ///
  /// In ro, this message translates to:
  /// **'Atinge harta ca să alegi locul.'**
  String get tapMapToChoose;

  /// No description provided for @mustBeInRomania.
  ///
  /// In ro, this message translates to:
  /// **'Locul trebuie să fie în România.'**
  String get mustBeInRomania;

  /// No description provided for @photoLink.
  ///
  /// In ro, this message translates to:
  /// **'Link către o poză (opțional)'**
  String get photoLink;

  /// No description provided for @linkMustBeHttps.
  ///
  /// In ro, this message translates to:
  /// **'Linkul trebuie să înceapă cu https://'**
  String get linkMustBeHttps;

  /// No description provided for @descriptionRo.
  ///
  /// In ro, this message translates to:
  /// **'Descriere în română'**
  String get descriptionRo;

  /// No description provided for @descriptionEn.
  ///
  /// In ro, this message translates to:
  /// **'Descriere în engleză'**
  String get descriptionEn;

  /// No description provided for @descriptionHint.
  ///
  /// In ro, this message translates to:
  /// **'Ce face localul special?'**
  String get descriptionHint;

  /// No description provided for @translateToEnglish.
  ///
  /// In ro, this message translates to:
  /// **'Tradu în engleză'**
  String get translateToEnglish;

  /// No description provided for @translateToRomanian.
  ///
  /// In ro, this message translates to:
  /// **'Tradu în română'**
  String get translateToRomanian;

  /// No description provided for @translateNothingYet.
  ///
  /// In ro, this message translates to:
  /// **'Scrie descrierea într-o limbă, iar butonul o traduce în cealaltă.'**
  String get translateNothingYet;

  /// No description provided for @translateNeedsGemini.
  ///
  /// In ro, this message translates to:
  /// **'Traducerea automată are nevoie de cheia Gemini.'**
  String get translateNeedsGemini;

  /// No description provided for @translateFailed.
  ///
  /// In ro, this message translates to:
  /// **'Nu am putut traduce acum. Încearcă din nou.'**
  String get translateFailed;

  /// No description provided for @sendForApproval.
  ///
  /// In ro, this message translates to:
  /// **'Trimite spre aprobare'**
  String get sendForApproval;

  /// No description provided for @saveAndSendForApproval.
  ///
  /// In ro, this message translates to:
  /// **'Salvează și trimite spre aprobare'**
  String get saveAndSendForApproval;

  /// No description provided for @tooShort.
  ///
  /// In ro, this message translates to:
  /// **'Prea scurt: cel puțin {min} caractere.'**
  String tooShort(int min);

  /// No description provided for @tooLong.
  ///
  /// In ro, this message translates to:
  /// **'Prea lung: cel mult {max} caractere.'**
  String tooLong(int max);

  /// No description provided for @positionOnMap.
  ///
  /// In ro, this message translates to:
  /// **'Poziția pe hartă'**
  String get positionOnMap;

  /// No description provided for @tapMapWherePlaceIs.
  ///
  /// In ro, this message translates to:
  /// **'Atinge harta în locul unde este localul.'**
  String get tapMapWherePlaceIs;

  /// No description provided for @positionChosen.
  ///
  /// In ro, this message translates to:
  /// **'Poziție aleasă. Atinge din nou ca s-o schimbi.'**
  String get positionChosen;

  /// No description provided for @botNotUnderstood.
  ///
  /// In ro, this message translates to:
  /// **'Nu am înțeles întrebarea. Poți reformula, te rog? Pot răspunde la întrebări despre localuri, rezervări sau funcțiile aplicației.'**
  String get botNotUnderstood;

  /// No description provided for @botRecommend.
  ///
  /// In ro, this message translates to:
  /// **'Pentru a găsi localuri, folosește pagina „Explorează”. Poți căuta după nume sau oraș, iar filtrele sortează după rating.'**
  String get botRecommend;

  /// No description provided for @botBooking.
  ///
  /// In ro, this message translates to:
  /// **'Poți face o rezervare din pagina unui local, cu butonul „Rezervă pe WhatsApp”.'**
  String get botBooking;

  /// No description provided for @botMapList.
  ///
  /// In ro, this message translates to:
  /// **'Pe telefon, butonul de lângă căutare comută între listă și hartă. Pe un ecran lat le vezi pe amândouă.'**
  String get botMapList;

  /// No description provided for @botGreeting.
  ///
  /// In ro, this message translates to:
  /// **'Salut! Cu ce te pot ajuta astăzi? Poți să mă întrebi despre localuri sau despre cum funcționează aplicația.'**
  String get botGreeting;

  /// No description provided for @botWhichCityDrink.
  ///
  /// In ro, this message translates to:
  /// **'Sigur! În ce oraș ai vrea să bei ceva?'**
  String get botWhichCityDrink;

  /// No description provided for @botWhichCityFood.
  ///
  /// In ro, this message translates to:
  /// **'Sigur! În ce oraș ai vrea să mănânci?'**
  String get botWhichCityFood;

  /// No description provided for @botFound.
  ///
  /// In ro, this message translates to:
  /// **'Am găsit „{name}”.'**
  String botFound(String name);

  /// No description provided for @botFoundMatching.
  ///
  /// In ro, this message translates to:
  /// **'Am găsit „{name}”. Pare a fi ce căutai ({criteria}).'**
  String botFoundMatching(String name, String criteria);

  /// No description provided for @botNothingMatching.
  ///
  /// In ro, this message translates to:
  /// **'Din păcate, nu am găsit niciun local care să corespundă criteriilor tale: {criteria}.'**
  String botNothingMatching(String criteria);

  /// No description provided for @botNothingNamed.
  ///
  /// In ro, this message translates to:
  /// **'Nu am găsit niciun local care să corespundă căutării „{name}”.'**
  String botNothingNamed(String name);

  /// No description provided for @botCriterionDrink.
  ///
  /// In ro, this message translates to:
  /// **'baruri/cafenele'**
  String get botCriterionDrink;

  /// No description provided for @botCriterionFood.
  ///
  /// In ro, this message translates to:
  /// **'restaurante'**
  String get botCriterionFood;

  /// No description provided for @botCriterionCity.
  ///
  /// In ro, this message translates to:
  /// **'din {city}'**
  String botCriterionCity(String city);

  /// No description provided for @botCriterionItem.
  ///
  /// In ro, this message translates to:
  /// **'care servește {item}'**
  String botCriterionItem(String item);

  /// No description provided for @botCriterionBest.
  ///
  /// In ro, this message translates to:
  /// **'cu cel mai bun rating'**
  String get botCriterionBest;

  /// No description provided for @botCriterionWorst.
  ///
  /// In ro, this message translates to:
  /// **'cu cel mai slab rating'**
  String get botCriterionWorst;

  /// No description provided for @botNoDrinkIn.
  ///
  /// In ro, this message translates to:
  /// **'Din păcate, nu am găsit baruri sau cafenele în {city}.'**
  String botNoDrinkIn(String city);

  /// No description provided for @botNoFoodIn.
  ///
  /// In ro, this message translates to:
  /// **'Din păcate, nu am găsit restaurante în {city}.'**
  String botNoFoodIn(String city);

  /// No description provided for @botNoPlacesIn.
  ///
  /// In ro, this message translates to:
  /// **'Din păcate, nu am găsit localuri în {city}.'**
  String botNoPlacesIn(String city);

  /// No description provided for @botDrinkIn.
  ///
  /// In ro, this message translates to:
  /// **'În {city} poți bea ceva la: {names}.'**
  String botDrinkIn(String city, String names);

  /// No description provided for @botFoodIn.
  ///
  /// In ro, this message translates to:
  /// **'În {city} poți mânca la: {names}.'**
  String botFoodIn(String city, String names);

  /// No description provided for @botPlacesIn.
  ///
  /// In ro, this message translates to:
  /// **'În {city} am găsit: {names}.'**
  String botPlacesIn(String city, String names);

  /// No description provided for @botItemCoffee.
  ///
  /// In ro, this message translates to:
  /// **'cafea'**
  String get botItemCoffee;

  /// No description provided for @botItemTea.
  ///
  /// In ro, this message translates to:
  /// **'ceai'**
  String get botItemTea;

  /// No description provided for @botItemMatcha.
  ///
  /// In ro, this message translates to:
  /// **'matcha'**
  String get botItemMatcha;

  /// No description provided for @botItemPizza.
  ///
  /// In ro, this message translates to:
  /// **'pizza'**
  String get botItemPizza;

  /// No description provided for @botItemBurgers.
  ///
  /// In ro, this message translates to:
  /// **'burgeri'**
  String get botItemBurgers;

  /// No description provided for @botItemBeer.
  ///
  /// In ro, this message translates to:
  /// **'bere'**
  String get botItemBeer;

  /// No description provided for @botItemWine.
  ///
  /// In ro, this message translates to:
  /// **'vin'**
  String get botItemWine;

  /// No description provided for @botItemVegan.
  ///
  /// In ro, this message translates to:
  /// **'mâncare vegană'**
  String get botItemVegan;

  /// No description provided for @botItemSmoothie.
  ///
  /// In ro, this message translates to:
  /// **'smoothie'**
  String get botItemSmoothie;

  /// No description provided for @botItemPasta.
  ///
  /// In ro, this message translates to:
  /// **'paste'**
  String get botItemPasta;

  /// No description provided for @botItemSushi.
  ///
  /// In ro, this message translates to:
  /// **'sushi'**
  String get botItemSushi;

  /// No description provided for @chatSuggestion1.
  ///
  /// In ro, this message translates to:
  /// **'Vreau să beau ceva în Cluj-Napoca'**
  String get chatSuggestion1;

  /// No description provided for @chatSuggestion2.
  ///
  /// In ro, this message translates to:
  /// **'Cea mai bună cafea'**
  String get chatSuggestion2;

  /// No description provided for @chatSuggestion3.
  ///
  /// In ro, this message translates to:
  /// **'Caută Burger Shack'**
  String get chatSuggestion3;

  /// No description provided for @chatSuggestion4.
  ///
  /// In ro, this message translates to:
  /// **'Cum fac o rezervare?'**
  String get chatSuggestion4;

  /// No description provided for @chatWelcome.
  ///
  /// In ro, this message translates to:
  /// **'Salut! Sunt asistentul Top Places. Răspund pe loc la întrebări despre localuri, orașe și rezervări.'**
  String get chatWelcome;

  /// No description provided for @chatWelcomeWithAi.
  ///
  /// In ro, this message translates to:
  /// **'Salut! Sunt asistentul Top Places. Răspund pe loc la întrebări despre localuri, orașe și rezervări, iar ce nu știu întreb AI-ul (Gemini).'**
  String get chatWelcomeWithAi;

  /// No description provided for @chatAiQuota.
  ///
  /// In ro, this message translates to:
  /// **'Nu am înțeles întrebarea, iar AI-ul și-a atins limita gratuită pentru moment. Întreabă-mă despre localuri, orașe sau rezervări.'**
  String get chatAiQuota;

  /// No description provided for @chatAiDown.
  ///
  /// In ro, this message translates to:
  /// **'Nu am înțeles întrebarea, iar AI-ul nu răspunde acum (poate lipsește internetul). Întreabă-mă despre localuri, orașe sau rezervări.'**
  String get chatAiDown;

  /// No description provided for @chatGeminiWriting.
  ///
  /// In ro, this message translates to:
  /// **'Gemini scrie un răspuns'**
  String get chatGeminiWriting;

  /// No description provided for @chatHint.
  ///
  /// In ro, this message translates to:
  /// **'Scrie un mesaj...'**
  String get chatHint;

  /// No description provided for @chatSend.
  ///
  /// In ro, this message translates to:
  /// **'Trimite'**
  String get chatSend;

  /// No description provided for @chatYou.
  ///
  /// In ro, this message translates to:
  /// **'Tu'**
  String get chatYou;

  /// No description provided for @chatAssistant.
  ///
  /// In ro, this message translates to:
  /// **'Asistentul'**
  String get chatAssistant;

  /// No description provided for @showOnMap.
  ///
  /// In ro, this message translates to:
  /// **'Arată pe hartă'**
  String get showOnMap;

  /// No description provided for @theme.
  ///
  /// In ro, this message translates to:
  /// **'Tema'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In ro, this message translates to:
  /// **'Automată'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In ro, this message translates to:
  /// **'Luminoasă'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In ro, this message translates to:
  /// **'Întunecată'**
  String get themeDark;

  /// No description provided for @showMoreReviews.
  ///
  /// In ro, this message translates to:
  /// **'Vezi mai multe ({count})'**
  String showMoreReviews(int count);

  /// No description provided for @allReviewsTitle.
  ///
  /// In ro, this message translates to:
  /// **'Recenzii: {name}'**
  String allReviewsTitle(String name);

  /// No description provided for @filterAllStars.
  ///
  /// In ro, this message translates to:
  /// **'Toate ({count})'**
  String filterAllStars(int count);

  /// No description provided for @filterStars.
  ///
  /// In ro, this message translates to:
  /// **'{stars} ★ ({count})'**
  String filterStars(int stars, int count);

  /// No description provided for @noReviewsWithStars.
  ///
  /// In ro, this message translates to:
  /// **'{stars, plural, =1{Nicio recenzie cu o stea.} other{Nicio recenzie cu {stars} stele.}}'**
  String noReviewsWithStars(int stars);

  /// No description provided for @reviewAuthorYou.
  ///
  /// In ro, this message translates to:
  /// **'{author} (tu)'**
  String reviewAuthorYou(String author);

  /// No description provided for @seeAllPlaces.
  ///
  /// In ro, this message translates to:
  /// **'Vezi toate ({count})'**
  String seeAllPlaces(int count);

  /// No description provided for @withCount.
  ///
  /// In ro, this message translates to:
  /// **'{label} ({count})'**
  String withCount(String label, int count);

  /// No description provided for @all.
  ///
  /// In ro, this message translates to:
  /// **'Toate'**
  String get all;

  /// No description provided for @inReview.
  ///
  /// In ro, this message translates to:
  /// **'În verificare'**
  String get inReview;

  /// No description provided for @allCities.
  ///
  /// In ro, this message translates to:
  /// **'Toate orașele'**
  String get allCities;

  /// No description provided for @chatHistory.
  ///
  /// In ro, this message translates to:
  /// **'Conversații'**
  String get chatHistory;

  /// No description provided for @chatNew.
  ///
  /// In ro, this message translates to:
  /// **'Conversație nouă'**
  String get chatNew;

  /// No description provided for @chatHistorySignIn.
  ///
  /// In ro, this message translates to:
  /// **'Intră în cont ca să-ți păstrezi conversațiile cu asistentul, pe orice dispozitiv.'**
  String get chatHistorySignIn;

  /// No description provided for @chatHistoryEmpty.
  ///
  /// In ro, this message translates to:
  /// **'Nicio conversație încă. Ce scrii în chat se păstrează aici.'**
  String get chatHistoryEmpty;

  /// No description provided for @chatHistoryNotLoaded.
  ///
  /// In ro, this message translates to:
  /// **'Conversațiile nu s-au putut încărca.'**
  String get chatHistoryNotLoaded;

  /// No description provided for @tryAgain.
  ///
  /// In ro, this message translates to:
  /// **'Încearcă din nou'**
  String get tryAgain;

  /// No description provided for @chatNotSaved.
  ///
  /// In ro, this message translates to:
  /// **'Mesajele nu s-au putut salva în istoric. Verifică internetul.'**
  String get chatNotSaved;

  /// No description provided for @chatNotOpened.
  ///
  /// In ro, this message translates to:
  /// **'Conversația nu s-a putut deschide. Verifică internetul.'**
  String get chatNotOpened;

  /// No description provided for @chatNotChanged.
  ///
  /// In ro, this message translates to:
  /// **'Conversația nu s-a putut schimba. Verifică internetul.'**
  String get chatNotChanged;

  /// No description provided for @chatConversationActions.
  ///
  /// In ro, this message translates to:
  /// **'Opțiuni pentru conversație'**
  String get chatConversationActions;

  /// No description provided for @chatRename.
  ///
  /// In ro, this message translates to:
  /// **'Redenumește'**
  String get chatRename;

  /// No description provided for @chatRenameTitle.
  ///
  /// In ro, this message translates to:
  /// **'Redenumește conversația'**
  String get chatRenameTitle;

  /// No description provided for @chatTitleLabel.
  ///
  /// In ro, this message translates to:
  /// **'Titlu'**
  String get chatTitleLabel;

  /// No description provided for @chatDeleteTitle.
  ///
  /// In ro, this message translates to:
  /// **'Ștergi conversația?'**
  String get chatDeleteTitle;

  /// No description provided for @chatDeleteMessage.
  ///
  /// In ro, this message translates to:
  /// **'„{title}” dispare, cu toate mesajele ei.'**
  String chatDeleteMessage(String title);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ro'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ro':
      return AppLocalizationsRo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
