// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Romanian Moldavian Moldovan (`ro`).
class AppLocalizationsRo extends AppLocalizations {
  AppLocalizationsRo([String locale = 'ro']) : super(locale);

  @override
  String get appTitle => 'Top Places';

  @override
  String get tabExplore => 'Explorează';

  @override
  String get tabAssistant => 'Asistent';

  @override
  String get tabProfile => 'Profil';

  @override
  String get notFoundTitle => 'Pagină inexistentă';

  @override
  String get notFoundMessage => 'Nu am găsit pagina căutată.';

  @override
  String get notFoundBack => 'Înapoi la Explorează';

  @override
  String get filtersTitle => 'Filtrează & Sortează';

  @override
  String get filtersCity => 'Oraș';

  @override
  String get filtersAllCities => 'Toate';

  @override
  String get filtersMinRating => 'Rating minim';

  @override
  String get filtersAnyRating => 'Oricare';

  @override
  String get filtersSort => 'Sortare';

  @override
  String get sortRecommended => 'Recomandat';

  @override
  String get sortRatingDown => 'Rating ↓';

  @override
  String get sortRatingUp => 'Rating ↑';

  @override
  String get sortName => 'Nume (A-Z)';

  @override
  String get filtersReset => 'Resetează';

  @override
  String get filtersApply => 'Aplică filtre';

  @override
  String get cancel => 'Renunță';

  @override
  String get save => 'Salvează';

  @override
  String get requiredField => 'Câmp obligatoriu.';

  @override
  String get changeName => 'Schimbă numele';

  @override
  String get firstName => 'Prenume';

  @override
  String get lastName => 'Nume';

  @override
  String get reasonLabel => 'Motivul';

  @override
  String get reasonHelper => 'Îl vede și persoana în cauză.';

  @override
  String get reasonRequired => 'Scrie motivul.';

  @override
  String bookingMessage(String place) {
    return 'Rezervare la $place';
  }

  @override
  String get linkFailed => 'Nu am putut deschide linkul.';

  @override
  String get clearSearch => 'Șterge căutarea';

  @override
  String get ratingNew => 'Nou';

  @override
  String get ratingNewLabel => 'local nou';

  @override
  String ratingStarsLabel(String rating) {
    return '$rating stele';
  }

  @override
  String stars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stele',
      one: '1 stea',
    );
    return '$_temp0';
  }

  @override
  String results(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de rezultate',
      few: '$count rezultate',
      one: '1 rezultat',
    );
    return '$_temp0';
  }

  @override
  String reviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de recenzii',
      few: '$count recenzii',
      one: '1 recenzie',
    );
    return '$_temp0';
  }

  @override
  String placeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de localuri',
      few: '$count localuri',
      one: '1 local',
    );
    return '$_temp0';
  }

  @override
  String get searchHint => 'Caută locații sau orașe...';

  @override
  String get filterTooltip => 'Filtrează și sortează';

  @override
  String get showList => 'Arată lista';

  @override
  String get showMap => 'Arată harta';

  @override
  String get placesTitle => 'Locații';

  @override
  String get filtersActive => 'Filtre active';

  @override
  String get noPlaces => 'Nu am găsit locații.';

  @override
  String suggestionRated(String city, String rating) {
    return '$city · ★ $rating';
  }

  @override
  String suggestionNew(String city) {
    return '$city · Nou';
  }

  @override
  String clusterLabel(String places) {
    return '$places aici. Apasă ca să apropii harta.';
  }

  @override
  String get locationServiceOff =>
      'Localizarea e oprită pe dispozitiv. Pornește-o și încearcă din nou.';

  @override
  String get locationDenied =>
      'Fără permisiunea de localizare nu te pot arăta pe hartă.';

  @override
  String get locationDeniedForever =>
      'Ai refuzat localizarea pentru Top Places. O poți permite din setările aplicației.';

  @override
  String get locationBlockedByBrowser =>
      'Browserul blochează localizarea. O poți permite din setările site-ului.';

  @override
  String get locationAccuracyOff =>
      'Localizarea precisă a rămas oprită. Apasă din nou și accept-o când telefonul te întreabă.';

  @override
  String get locationNotFound =>
      'Nu am putut afla unde ești. Încearcă din nou.';

  @override
  String get settings => 'Setări';

  @override
  String get myLocationTooltip => 'Arată-mi locația';

  @override
  String get myLocationLabel => 'Locația ta';

  @override
  String get shrink => 'Micșorează';

  @override
  String get allDetails => 'Toate detaliile';

  @override
  String get newPlaceNoReviews => 'Local nou, fără recenzii încă';

  @override
  String get bookOnWhatsApp => 'Rezervă pe WhatsApp';

  @override
  String get directions => 'Indicații';

  @override
  String get tabDescription => 'Descriere';

  @override
  String get tabReviews => 'Recenzii';

  @override
  String get aboutPlace => 'Despre locație';

  @override
  String get vibeExample1 =>
      'Atmosfera este electrică și primitoare, perfectă pentru o ieșire memorabilă.';

  @override
  String get vibeExample2 =>
      'Un loc cu un vibe relaxat, unde te poți deconecta complet de agitația orașului.';

  @override
  String get vibeExample3 =>
      'Energia locului te cucerește imediat, iar detaliile de design fac diferența.';

  @override
  String get vibeExampleNoAi => 'Exemplu scris dinainte, nu generat de AI.';

  @override
  String get vibeExampleAiDown =>
      'Exemplu scris dinainte: AI-ul nu răspunde acum.';

  @override
  String get aiNote => 'Generat cu Gemini. Poate conține greșeli.';

  @override
  String get vibeNotTranslated =>
      'Generat cu Gemini. Nu l-am putut traduce acum.';

  @override
  String get translating => 'Se traduce…';

  @override
  String get vibeGenerate => 'Generează un vibe cu AI';

  @override
  String get vibeShowExample => 'Arată un exemplu de vibe';

  @override
  String get vibeAnother => 'Alt vibe';

  @override
  String get vibeAnotherExample => 'Alt exemplu';

  @override
  String get reviewsNeedSupabase =>
      'Recenziile se văd doar când aplicația e conectată la Supabase.';

  @override
  String get ratingFromOldApp =>
      'Ratingul vine din aplicația originală, până la primele recenzii.';

  @override
  String get noReviewsYet => 'Nicio recenzie încă.';

  @override
  String get ratingFromOneReview => 'Ratingul vine dintr-o singură recenzie.';

  @override
  String ratingAverage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de recenzii',
      few: '$count recenzii',
    );
    return 'Ratingul e media celor $_temp0.';
  }

  @override
  String get reviewSignInFirst =>
      'Intră în cont, din tab-ul Profil, ca să scrii o recenzie.';

  @override
  String get reviewSuspended =>
      'Contul tău e suspendat: nu poți scrie recenzii.';

  @override
  String get reviewOwnPlace => 'Nu poți scrie recenzii la propriul local.';

  @override
  String get reviewAcceptedByAdmin =>
      'Apare după ce o acceptă un administrator.';

  @override
  String get reviewAcceptedByOperator =>
      'Apare după ce o acceptă operatorul localului.';

  @override
  String get reviewAdminAtOnce =>
      'Ca administrator, recenzia ta apare imediat.';

  @override
  String get reviewPublished => 'Recenzia ta a fost publicată.';

  @override
  String get reviewSentWaiting =>
      'Recenzia ta a fost trimisă și e în așteptare.';

  @override
  String get deleteReviewTitle => 'Ștergi recenzia?';

  @override
  String get deleteReviewMessage =>
      'Nota și mesajul tău dispar de pe pagina localului.';

  @override
  String get delete => 'Șterge';

  @override
  String get yourReview => 'Recenzia ta';

  @override
  String get reviewPending => 'În așteptare';

  @override
  String reviewPendingExplanation(String whenAccepted) {
    return '$whenAccepted Până atunci o vezi doar tu.';
  }

  @override
  String get reviewApproved => 'Publicată';

  @override
  String get reviewApprovedExplanation => 'O vede oricine deschide localul.';

  @override
  String get reviewRejected => 'Respinsă';

  @override
  String reviewRejectedExplanation(String reason) {
    return 'Motiv: $reason. O poți modifica și trimite din nou.';
  }

  @override
  String get deleteReview => 'Șterge recenzia';

  @override
  String get editReview => 'Modifică';

  @override
  String reviewEditIntro(String whenPublic) {
    return 'Schimbă ce trebuie, apoi trimite din nou. $whenPublic';
  }

  @override
  String reviewNewIntro(String whenPublic) {
    return 'Alege stelele și, dacă vrei, scrie câteva cuvinte. $whenPublic';
  }

  @override
  String get reviewMessage => 'Mesaj (opțional)';

  @override
  String get sendAgain => 'Trimite din nou';

  @override
  String get sendReview => 'Trimite recenzia';

  @override
  String get othersSay => 'Ce spun ceilalți';

  @override
  String get noPublishedReviews => 'Nicio recenzie publicată încă.';

  @override
  String get errorSignInAgain => 'Intră din nou în cont.';

  @override
  String get errorWrongCredentials => 'Email sau parolă greșite.';

  @override
  String get errorEmailNotConfirmed =>
      'Încă nu ți-ai confirmat emailul. Deschide linkul din emailul primit, apoi încearcă din nou.';

  @override
  String get errorTooManyEmails =>
      'S-au trimis prea multe emailuri. Încearcă din nou peste o oră.';

  @override
  String get errorWeakPassword => 'Parola e prea slabă. Alege una mai lungă.';

  @override
  String get errorInvalidEmail => 'Adresa de email nu e acceptată.';

  @override
  String get errorEmailTaken => 'Există deja un cont cu acest email.';

  @override
  String errorNotSaved(String detail) {
    return 'Nu am putut salva: $detail';
  }

  @override
  String errorFailed(String detail) {
    return 'Nu a mers: $detail';
  }

  @override
  String get errorOffline =>
      'Nu mă pot conecta. Verifică internetul și încearcă din nou.';

  @override
  String get accountsUnavailable =>
      'Conturile nu sunt disponibile în această versiune a aplicației: lipsește configurarea Supabase.';

  @override
  String get signIn => 'Intră în cont';

  @override
  String get newAccount => 'Cont nou';

  @override
  String confirmationSent(String email) {
    return 'Ți-am trimis un email la $email. Deschide linkul din el, apoi intră în cont aici. Dacă nu îl vezi, caută și în Spam.';
  }

  @override
  String get email => 'Email';

  @override
  String get invalidEmail => 'Scrie o adresă de email validă.';

  @override
  String get password => 'Parolă';

  @override
  String get passwordTooShort =>
      'Parola trebuie să aibă cel puțin 8 caractere.';

  @override
  String get repeatPassword => 'Repetă parola';

  @override
  String get passwordsDiffer => 'Parolele nu sunt la fel.';

  @override
  String get createAccount => 'Creează contul';

  @override
  String get hidePassword => 'Ascunde parola';

  @override
  String get showPassword => 'Arată parola';

  @override
  String get accountSuspended => 'Contul tău e suspendat';

  @override
  String accountSuspendedDetails(String reason) {
    return 'Motiv: $reason\nPoți vedea localurile, dar nu poți face modificări.';
  }

  @override
  String get noName => 'Fără nume';

  @override
  String get signOut => 'Ieși din cont';

  @override
  String get reviewsAdmin => 'Recenzii: acceptări și ștergeri';

  @override
  String get reviewsOperator => 'Recenziile localurilor mele';

  @override
  String get administration => 'Administrare';

  @override
  String get adminPlaces => 'Localuri: aprobări și suspendări';

  @override
  String get adminUsers => 'Utilizatori și operatori';

  @override
  String get operatorRequestPending =>
      'Ai cerut să devii operator. Un administrator îți va răspunde.';

  @override
  String operatorRequestRejected(String reason) {
    return 'Cererea ta de a deveni operator a fost respinsă. Motiv: $reason';
  }

  @override
  String get sendRequestAgain => 'Trimite din nou cererea';

  @override
  String get wantToAddPlaces => 'Vreau să adaug localuri';

  @override
  String get roleUser => 'Utilizator';

  @override
  String get roleOperator => 'Operator de localuri';

  @override
  String get roleAdmin => 'Administrator';

  @override
  String get language => 'Limba aplicației';

  @override
  String get errorSignInToReview => 'Intră în cont ca să scrii o recenzie.';

  @override
  String get errorCannotDeleteReview =>
      'Nu ai voie să ștergi această recenzie.';

  @override
  String get errorInvalidFields =>
      'Unele câmpuri nu sunt valide. Verifică-le și încearcă din nou.';

  @override
  String get errorNotAllowed => 'Nu ai voie să faci această modificare.';

  @override
  String get myPlaces => 'Localurile mele';

  @override
  String get searchMyPlaces => 'Caută în localurile tale';

  @override
  String get noOwnPlaces => 'Încă nu ai adăugat niciun local.';

  @override
  String get noMatchingPlaces => 'Niciun local nu se potrivește căutării.';

  @override
  String editPlace(String name) {
    return 'Editează $name';
  }

  @override
  String get addPlace => 'Adaugă un local';

  @override
  String get placePending => 'În așteptarea aprobării';

  @override
  String get placeApproved => 'Aprobat: apare în Explorează';

  @override
  String placeRejected(String reason) {
    return 'Respins: $reason';
  }

  @override
  String placeSuspended(String reason) {
    return 'Suspendat: $reason';
  }

  @override
  String reactivatePlaceTitle(String name) {
    return 'Reactivezi „$name”?';
  }

  @override
  String approvePlaceTitle(String name) {
    return 'Aprobi „$name”?';
  }

  @override
  String get reactivatePlaceMessage => 'Localul apare din nou în Explorează.';

  @override
  String get approvePlaceMessage =>
      'Localul apare în Explorează pentru toată lumea. Ratingul îl vor da cei care îl vizitează.';

  @override
  String get reactivate => 'Reactivează';

  @override
  String get approve => 'Aprobă';

  @override
  String rejectPlaceTitle(String name) {
    return 'Respingi „$name”?';
  }

  @override
  String get reject => 'Respinge';

  @override
  String suspendPlaceTitle(String name) {
    return 'Suspenzi „$name”?';
  }

  @override
  String get suspend => 'Suspendă';

  @override
  String get adminPlacesTitle => 'Localuri';

  @override
  String get searchPlacesAdmin => 'Caută după nume, oraș sau adresă';

  @override
  String get noPlacesHere => 'Niciun local aici.';

  @override
  String get edit => 'Editează';

  @override
  String get filterToCheck => 'De verificat';

  @override
  String get filterPublic => 'Publice';

  @override
  String get filterRejected => 'Respinse';

  @override
  String get filterSuspended => 'Suspendate';

  @override
  String get noRating => 'fără rating';

  @override
  String reason(String reason) {
    return 'Motiv: $reason';
  }

  @override
  String get adminUsersTitle => 'Utilizatori';

  @override
  String get searchUsers => 'Caută după nume sau email';

  @override
  String get filterRequests => 'Cereri de operator';

  @override
  String get filterSuspendedUsers => 'Suspendați';

  @override
  String get filterAllUsers => 'Toți';

  @override
  String get noAccountsHere => 'Niciun cont aici.';

  @override
  String get makeUser => 'Fă-l utilizator';

  @override
  String get makeOperator => 'Fă-l operator';

  @override
  String get makeAdmin => 'Fă-l administrator';

  @override
  String get suspendAccount => 'Suspendă contul';

  @override
  String accountActions(String name) {
    return 'Acțiuni pentru $name';
  }

  @override
  String userSuspended(String reason) {
    return 'Suspendat: $reason';
  }

  @override
  String get wantsToBeOperator => 'Vrea să devină operator';

  @override
  String requestRejected(String reason) {
    return 'Cerere respinsă: $reason';
  }

  @override
  String get active => 'Activ';

  @override
  String makeOperatorTitle(String name) {
    return 'Îl faci pe $name operator?';
  }

  @override
  String get makeOperatorMessage =>
      'Va putea adăuga localuri, care apar după ce le aprobi.';

  @override
  String rejectRequestTitle(String name) {
    return 'Respingi cererea lui $name?';
  }

  @override
  String reactivateAccountTitle(String name) {
    return 'Reactivezi contul lui $name?';
  }

  @override
  String get reactivateAccountMessage =>
      'Va putea folosi din nou contul, iar localurile lui reapar în Explorează.';

  @override
  String suspendAccountTitle(String name) {
    return 'Suspenzi contul lui $name?';
  }

  @override
  String acceptReviewTitle(String author) {
    return 'Accepți recenzia lui $author?';
  }

  @override
  String get acceptReviewMessage =>
      'Apare pe pagina localului și intră în rating.';

  @override
  String get accept => 'Acceptă';

  @override
  String rejectReviewTitle(String author) {
    return 'Respingi recenzia lui $author?';
  }

  @override
  String deleteOthersReviewTitle(String author) {
    return 'Ștergi recenzia lui $author?';
  }

  @override
  String get deleteOthersReviewMessage => 'Nota și mesajul dispar definitiv.';

  @override
  String get reviewsTitle => 'Recenzii';

  @override
  String get searchReviews => 'Caută după local, autor sau mesaj';

  @override
  String get noReviewsHere => 'Nicio recenzie aici.';

  @override
  String get filterAccepted => 'Acceptate';

  @override
  String quoted(String text) {
    return '„$text”';
  }

  @override
  String get newPlaceTitle => 'Local nou';

  @override
  String get editPlaceTitle => 'Editează localul';

  @override
  String get editGoesToReview =>
      'După ce salvezi, localul intră din nou în verificare și nu apare în Explorează până nu îl aprobă un administrator.';

  @override
  String get placeName => 'Nume';

  @override
  String get address => 'Adresă';

  @override
  String get city => 'Oraș';

  @override
  String get chooseCity => 'Alege orașul.';

  @override
  String get tapMapToChoose => 'Atinge harta ca să alegi locul.';

  @override
  String get mustBeInRomania => 'Locul trebuie să fie în România.';

  @override
  String get photoLink => 'Link către o poză (opțional)';

  @override
  String get linkMustBeHttps => 'Linkul trebuie să înceapă cu https://';

  @override
  String get descriptionRo => 'Descriere în română';

  @override
  String get descriptionEn => 'Descriere în engleză';

  @override
  String get descriptionHint => 'Ce face localul special?';

  @override
  String get translateToEnglish => 'Tradu în engleză';

  @override
  String get translateToRomanian => 'Tradu în română';

  @override
  String get translateNothingYet =>
      'Scrie descrierea într-o limbă, iar butonul o traduce în cealaltă.';

  @override
  String get translateNeedsGemini =>
      'Traducerea automată are nevoie de cheia Gemini.';

  @override
  String get translateFailed => 'Nu am putut traduce acum. Încearcă din nou.';

  @override
  String get sendForApproval => 'Trimite spre aprobare';

  @override
  String get saveAndSendForApproval => 'Salvează și trimite spre aprobare';

  @override
  String tooShort(int min) {
    return 'Prea scurt: cel puțin $min caractere.';
  }

  @override
  String tooLong(int max) {
    return 'Prea lung: cel mult $max caractere.';
  }

  @override
  String get positionOnMap => 'Poziția pe hartă';

  @override
  String get tapMapWherePlaceIs => 'Atinge harta în locul unde este localul.';

  @override
  String get positionChosen => 'Poziție aleasă. Atinge din nou ca s-o schimbi.';

  @override
  String get botNotUnderstood =>
      'Nu am înțeles întrebarea. Poți reformula, te rog? Pot răspunde la întrebări despre localuri, rezervări sau funcțiile aplicației.';

  @override
  String get botRecommend =>
      'Pentru a găsi localuri, folosește pagina „Explorează”. Poți căuta după nume sau oraș, iar filtrele sortează după rating.';

  @override
  String get botBooking =>
      'Poți face o rezervare din pagina unui local, cu butonul „Rezervă pe WhatsApp”.';

  @override
  String get botMapList =>
      'Pe telefon, butonul de lângă căutare comută între listă și hartă. Pe un ecran lat le vezi pe amândouă.';

  @override
  String get botGreeting =>
      'Salut! Cu ce te pot ajuta astăzi? Poți să mă întrebi despre localuri sau despre cum funcționează aplicația.';

  @override
  String get botWhichCityDrink => 'Sigur! În ce oraș ai vrea să bei ceva?';

  @override
  String get botWhichCityFood => 'Sigur! În ce oraș ai vrea să mănânci?';

  @override
  String botFound(String name) {
    return 'Am găsit „$name”.';
  }

  @override
  String botFoundMatching(String name, String criteria) {
    return 'Am găsit „$name”. Pare a fi ce căutai ($criteria).';
  }

  @override
  String botNothingMatching(String criteria) {
    return 'Din păcate, nu am găsit niciun local care să corespundă criteriilor tale: $criteria.';
  }

  @override
  String botNothingNamed(String name) {
    return 'Nu am găsit niciun local care să corespundă căutării „$name”.';
  }

  @override
  String get botCriterionDrink => 'baruri/cafenele';

  @override
  String get botCriterionFood => 'restaurante';

  @override
  String botCriterionCity(String city) {
    return 'din $city';
  }

  @override
  String botCriterionItem(String item) {
    return 'care servește $item';
  }

  @override
  String get botCriterionBest => 'cu cel mai bun rating';

  @override
  String get botCriterionWorst => 'cu cel mai slab rating';

  @override
  String botNoDrinkIn(String city) {
    return 'Din păcate, nu am găsit baruri sau cafenele în $city.';
  }

  @override
  String botNoFoodIn(String city) {
    return 'Din păcate, nu am găsit restaurante în $city.';
  }

  @override
  String botNoPlacesIn(String city) {
    return 'Din păcate, nu am găsit localuri în $city.';
  }

  @override
  String botDrinkIn(String city, String names) {
    return 'În $city poți bea ceva la: $names.';
  }

  @override
  String botFoodIn(String city, String names) {
    return 'În $city poți mânca la: $names.';
  }

  @override
  String botPlacesIn(String city, String names) {
    return 'În $city am găsit: $names.';
  }

  @override
  String get botItemCoffee => 'cafea';

  @override
  String get botItemTea => 'ceai';

  @override
  String get botItemMatcha => 'matcha';

  @override
  String get botItemPizza => 'pizza';

  @override
  String get botItemBurgers => 'burgeri';

  @override
  String get botItemBeer => 'bere';

  @override
  String get botItemWine => 'vin';

  @override
  String get botItemVegan => 'mâncare vegană';

  @override
  String get botItemSmoothie => 'smoothie';

  @override
  String get botItemPasta => 'paste';

  @override
  String get botItemSushi => 'sushi';

  @override
  String get chatSuggestion1 => 'Vreau să beau ceva în Cluj-Napoca';

  @override
  String get chatSuggestion2 => 'Cea mai bună cafea';

  @override
  String get chatSuggestion3 => 'Caută Burger Shack';

  @override
  String get chatSuggestion4 => 'Cum fac o rezervare?';

  @override
  String get chatWelcome =>
      'Salut! Sunt asistentul Top Places. Răspund pe loc la întrebări despre localuri, orașe și rezervări. Răspunsurile AI (Gemini) sunt oprite în această versiune: ca să le încerci, rulează aplicația cu cheia ta Gemini, după pașii din README-ul proiectului.';

  @override
  String get chatAiOff =>
      'La asta ar fi răspuns AI-ul (Gemini), care e oprit în această versiune.';

  @override
  String get chatWelcomeWithAi =>
      'Salut! Sunt asistentul Top Places. Răspund pe loc la întrebări despre localuri, orașe și rezervări, iar ce nu știu întreb AI-ul (Gemini).';

  @override
  String get chatAiQuota =>
      'Nu am înțeles întrebarea, iar AI-ul și-a atins limita gratuită pentru moment. Întreabă-mă despre localuri, orașe sau rezervări.';

  @override
  String get chatAiDown =>
      'Nu am înțeles întrebarea, iar AI-ul nu răspunde acum (poate lipsește internetul). Întreabă-mă despre localuri, orașe sau rezervări.';

  @override
  String get chatGeminiWriting => 'Gemini scrie un răspuns';

  @override
  String get chatHint => 'Scrie un mesaj...';

  @override
  String get chatSend => 'Trimite';

  @override
  String get chatYou => 'Tu';

  @override
  String get chatAssistant => 'Asistentul';

  @override
  String get showOnMap => 'Arată pe hartă';

  @override
  String get theme => 'Tema';

  @override
  String get themeSystem => 'Automată';

  @override
  String get themeLight => 'Luminoasă';

  @override
  String get themeDark => 'Întunecată';

  @override
  String showMoreReviews(int count) {
    return 'Vezi mai multe ($count)';
  }

  @override
  String allReviewsTitle(String name) {
    return 'Recenzii: $name';
  }

  @override
  String filterAllStars(int count) {
    return 'Toate ($count)';
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
      other: 'Nicio recenzie cu $stars stele.',
      one: 'Nicio recenzie cu o stea.',
    );
    return '$_temp0';
  }

  @override
  String reviewAuthorYou(String author) {
    return '$author (tu)';
  }

  @override
  String seeAllPlaces(int count) {
    return 'Vezi toate ($count)';
  }

  @override
  String withCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String get all => 'Toate';

  @override
  String get inReview => 'În verificare';

  @override
  String get allCities => 'Toate orașele';

  @override
  String get chatHistory => 'Conversații';

  @override
  String get chatNew => 'Conversație nouă';

  @override
  String get chatHistorySignIn =>
      'Intră în cont ca să-ți păstrezi conversațiile cu asistentul, pe orice dispozitiv.';

  @override
  String get chatHistoryEmpty =>
      'Nicio conversație încă. Ce scrii în chat se păstrează aici.';

  @override
  String get chatHistoryNotLoaded => 'Conversațiile nu s-au putut încărca.';

  @override
  String get tryAgain => 'Încearcă din nou';

  @override
  String get chatNotSaved =>
      'Mesajele nu s-au putut salva în istoric. Verifică internetul.';

  @override
  String get chatNotOpened =>
      'Conversația nu s-a putut deschide. Verifică internetul.';

  @override
  String get chatNotChanged =>
      'Conversația nu s-a putut schimba. Verifică internetul.';

  @override
  String get chatConversationActions => 'Opțiuni pentru conversație';

  @override
  String get chatRename => 'Redenumește';

  @override
  String get chatRenameTitle => 'Redenumește conversația';

  @override
  String get chatTitleLabel => 'Titlu';

  @override
  String get chatDeleteTitle => 'Ștergi conversația?';

  @override
  String chatDeleteMessage(String title) {
    return '„$title” dispare, cu toate mesajele ei.';
  }
}
