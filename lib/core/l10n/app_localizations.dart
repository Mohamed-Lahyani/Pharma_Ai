import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

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
    Locale('ar'),
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @appName.
  ///
  /// In fr, this message translates to:
  /// **'PharmaAI'**
  String get appName;

  /// No description provided for @appVersion.
  ///
  /// In fr, this message translates to:
  /// **'PharmaAI v1.0.0'**
  String get appVersion;

  /// No description provided for @version.
  ///
  /// In fr, this message translates to:
  /// **'Version 1.0.0'**
  String get version;

  /// No description provided for @pharmaAIAdmin.
  ///
  /// In fr, this message translates to:
  /// **'PharmaAI Admin'**
  String get pharmaAIAdmin;

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settings;

  /// No description provided for @signOut.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get signOut;

  /// No description provided for @signOutConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir vous déconnecter ?'**
  String get signOutConfirm;

  /// No description provided for @confirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @edit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @add.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get add;

  /// No description provided for @back.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get back;

  /// No description provided for @error.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get error;

  /// No description provided for @success.
  ///
  /// In fr, this message translates to:
  /// **'Succès'**
  String get success;

  /// No description provided for @loading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement...'**
  String get loading;

  /// No description provided for @saving.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde...'**
  String get saving;

  /// No description provided for @sending.
  ///
  /// In fr, this message translates to:
  /// **'Envoi en cours...'**
  String get sending;

  /// No description provided for @signIn.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get signIn;

  /// No description provided for @signInSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous à votre compte'**
  String get signInSubtitle;

  /// No description provided for @email.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailHint.
  ///
  /// In fr, this message translates to:
  /// **'exemple@email.com'**
  String get emailHint;

  /// No description provided for @password.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get password;

  /// No description provided for @passwordMin.
  ///
  /// In fr, this message translates to:
  /// **'Minimum 6 caractères'**
  String get passwordMin;

  /// No description provided for @continueWithGoogle.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Google'**
  String get continueWithGoogle;

  /// No description provided for @noAccount.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de compte ? '**
  String get noAccount;

  /// No description provided for @createAccount.
  ///
  /// In fr, this message translates to:
  /// **'Créer un nouveau compte'**
  String get createAccount;

  /// No description provided for @alreadyAccount.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez déjà un compte ? '**
  String get alreadyAccount;

  /// No description provided for @signUp.
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire'**
  String get signUp;

  /// No description provided for @fullName.
  ///
  /// In fr, this message translates to:
  /// **'Nom complet'**
  String get fullName;

  /// No description provided for @fullNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex : Ahmed Benali'**
  String get fullNameHint;

  /// No description provided for @phone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone (optionnel)'**
  String get phone;

  /// No description provided for @confirmPassword.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le mot de passe'**
  String get confirmPassword;

  /// No description provided for @accountCreated.
  ///
  /// In fr, this message translates to:
  /// **'Compte créé avec succès ! Vous pouvez vous connecter.'**
  String get accountCreated;

  /// No description provided for @enterEmail.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer votre email'**
  String get enterEmail;

  /// No description provided for @invalidEmail.
  ///
  /// In fr, this message translates to:
  /// **'Format email invalide'**
  String get invalidEmail;

  /// No description provided for @enterPassword.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer un mot de passe'**
  String get enterPassword;

  /// No description provided for @enterName.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer votre nom'**
  String get enterName;

  /// No description provided for @nameTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Le nom doit contenir au moins 3 caractères'**
  String get nameTooShort;

  /// No description provided for @nameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le nom est requis'**
  String get nameRequired;

  /// No description provided for @confirmPasswordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez confirmer votre mot de passe'**
  String get confirmPasswordRequired;

  /// No description provided for @passwordMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas'**
  String get passwordMismatch;

  /// No description provided for @passwordTooWeak.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe est trop faible (min. 6 caractères).'**
  String get passwordTooWeak;

  /// No description provided for @fieldRequired.
  ///
  /// In fr, this message translates to:
  /// **'Champ requis'**
  String get fieldRequired;

  /// No description provided for @fillAllFields.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez remplir tous les champs'**
  String get fillAllFields;

  /// No description provided for @emailAlreadyUsed.
  ///
  /// In fr, this message translates to:
  /// **'Cet email est déjà utilisé par un autre compte.'**
  String get emailAlreadyUsed;

  /// No description provided for @noAccountFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun compte trouvé avec cet email.'**
  String get noAccountFound;

  /// No description provided for @wrongPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe incorrect.'**
  String get wrongPassword;

  /// No description provided for @invalidEmailAddress.
  ///
  /// In fr, this message translates to:
  /// **'Adresse email invalide.'**
  String get invalidEmailAddress;

  /// No description provided for @unexpectedError.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur inattendue est survenue.'**
  String get unexpectedError;

  /// No description provided for @anErrorOccurred.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue.'**
  String get anErrorOccurred;

  /// No description provided for @userNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur introuvable dans la base de données.'**
  String get userNotFound;

  /// No description provided for @userNotSignedIn.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur non connecté'**
  String get userNotSignedIn;

  /// No description provided for @helloPharmacie.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour, Pharmacien 👨‍⚕️'**
  String get helloPharmacie;

  /// No description provided for @pharmacySummary.
  ///
  /// In fr, this message translates to:
  /// **'Voici le résumé de votre pharmacie'**
  String get pharmacySummary;

  /// No description provided for @statistics.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques'**
  String get statistics;

  /// No description provided for @quickActions.
  ///
  /// In fr, this message translates to:
  /// **'Actions rapides'**
  String get quickActions;

  /// No description provided for @medications.
  ///
  /// In fr, this message translates to:
  /// **'Médicaments'**
  String get medications;

  /// No description provided for @pending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get pending;

  /// No description provided for @criticalStock.
  ///
  /// In fr, this message translates to:
  /// **'Stock critique'**
  String get criticalStock;

  /// No description provided for @clients.
  ///
  /// In fr, this message translates to:
  /// **'Clients'**
  String get clients;

  /// No description provided for @manageMedications.
  ///
  /// In fr, this message translates to:
  /// **'Gérer les médicaments'**
  String get manageMedications;

  /// No description provided for @addEditDelete.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter, modifier, supprimer'**
  String get addEditDelete;

  /// No description provided for @viewPrescriptions.
  ///
  /// In fr, this message translates to:
  /// **'Voir les ordonnances'**
  String get viewPrescriptions;

  /// No description provided for @stockAlerts.
  ///
  /// In fr, this message translates to:
  /// **'Alertes de stock'**
  String get stockAlerts;

  /// No description provided for @goodMorning.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour,'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In fr, this message translates to:
  /// **'Bon après-midi,'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In fr, this message translates to:
  /// **'Bonsoir,'**
  String get goodEvening;

  /// No description provided for @medicationCatalog.
  ///
  /// In fr, this message translates to:
  /// **'Catalogue médicaments'**
  String get medicationCatalog;

  /// No description provided for @scanPrescription.
  ///
  /// In fr, this message translates to:
  /// **'Scanner une ordonnance'**
  String get scanPrescription;

  /// No description provided for @scanBarcode.
  ///
  /// In fr, this message translates to:
  /// **'Scanner Code-barres'**
  String get scanBarcode;

  /// No description provided for @myPrescriptions.
  ///
  /// In fr, this message translates to:
  /// **'Mes Ordonnances'**
  String get myPrescriptions;

  /// No description provided for @myReminders.
  ///
  /// In fr, this message translates to:
  /// **'Mes Rappels'**
  String get myReminders;

  /// No description provided for @myProfile.
  ///
  /// In fr, this message translates to:
  /// **'Mon Profil'**
  String get myProfile;

  /// No description provided for @searchInfo.
  ///
  /// In fr, this message translates to:
  /// **'Recherche & infos'**
  String get searchInfo;

  /// No description provided for @identifyMedication.
  ///
  /// In fr, this message translates to:
  /// **'Identifier un médicament'**
  String get identifyMedication;

  /// No description provided for @medicationIntake.
  ///
  /// In fr, this message translates to:
  /// **'Prise de médicaments'**
  String get medicationIntake;

  /// No description provided for @fullHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique complet'**
  String get fullHistory;

  /// No description provided for @howItWorks.
  ///
  /// In fr, this message translates to:
  /// **'Comment ça marche ?'**
  String get howItWorks;

  /// No description provided for @remindersAndAlerts.
  ///
  /// In fr, this message translates to:
  /// **'Rappels médicaments et alertes stock'**
  String get remindersAndAlerts;

  /// No description provided for @comingSoon.
  ///
  /// In fr, this message translates to:
  /// **'Bientôt disponible'**
  String get comingSoon;

  /// No description provided for @scanYourPrescription.
  ///
  /// In fr, this message translates to:
  /// **'Scanner votre ordonnance'**
  String get scanYourPrescription;

  /// No description provided for @takePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get takePhoto;

  /// No description provided for @importFromGallery.
  ///
  /// In fr, this message translates to:
  /// **'Importer depuis la galerie'**
  String get importFromGallery;

  /// No description provided for @chooseExistingImage.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une image existante'**
  String get chooseExistingImage;

  /// No description provided for @analysisInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Analyse en cours...'**
  String get analysisInProgress;

  /// No description provided for @textExtractedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Texte extrait avec succès'**
  String get textExtractedSuccess;

  /// No description provided for @noText.
  ///
  /// In fr, this message translates to:
  /// **'Aucun texte'**
  String get noText;

  /// No description provided for @noTextDetected.
  ///
  /// In fr, this message translates to:
  /// **'Aucun texte détecté. Essayez avec une image plus nette.'**
  String get noTextDetected;

  /// No description provided for @extractedTextPlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'Le texte extrait apparaît ici...'**
  String get extractedTextPlaceholder;

  /// No description provided for @noMedicationDetected.
  ///
  /// In fr, this message translates to:
  /// **'Aucun médicament automatiquement détecté.'**
  String get noMedicationDetected;

  /// No description provided for @checkAndCorrect.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez et corrigez si nécessaire'**
  String get checkAndCorrect;

  /// No description provided for @sendToPharmacy.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer à la pharmacie'**
  String get sendToPharmacy;

  /// No description provided for @prescriptionSent.
  ///
  /// In fr, this message translates to:
  /// **'Ordonnance envoyée !'**
  String get prescriptionSent;

  /// No description provided for @prescriptionTransmitted.
  ///
  /// In fr, this message translates to:
  /// **'Votre ordonnance a été transmise au pharmacien.'**
  String get prescriptionTransmitted;

  /// No description provided for @scanAnotherPrescription.
  ///
  /// In fr, this message translates to:
  /// **'Scanner une autre ordonnance'**
  String get scanAnotherPrescription;

  /// No description provided for @startOver.
  ///
  /// In fr, this message translates to:
  /// **'Recommencer'**
  String get startOver;

  /// No description provided for @scanTips.
  ///
  /// In fr, this message translates to:
  /// **'Conseils pour un bon scan'**
  String get scanTips;

  /// No description provided for @takeClearPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Prenez une photo claire de votre ordonnance'**
  String get takeClearPhoto;

  /// No description provided for @whiteBgDarkText.
  ///
  /// In fr, this message translates to:
  /// **'Fond blanc, texte sombre'**
  String get whiteBgDarkText;

  /// No description provided for @whatDoYouWant.
  ///
  /// In fr, this message translates to:
  /// **'Que voulez-vous faire ?'**
  String get whatDoYouWant;

  /// No description provided for @chooseAction.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez une action ci-dessous'**
  String get chooseAction;

  /// No description provided for @noPrescription.
  ///
  /// In fr, this message translates to:
  /// **'Aucune ordonnance'**
  String get noPrescription;

  /// No description provided for @prescriptionValidated.
  ///
  /// In fr, this message translates to:
  /// **'Votre ordonnance a été validée.'**
  String get prescriptionValidated;

  /// No description provided for @prescriptionRejected.
  ///
  /// In fr, this message translates to:
  /// **'Votre ordonnance a été rejetée.'**
  String get prescriptionRejected;

  /// No description provided for @awaitingValidation.
  ///
  /// In fr, this message translates to:
  /// **'En attente de validation par le pharmacien.'**
  String get awaitingValidation;

  /// No description provided for @validated.
  ///
  /// In fr, this message translates to:
  /// **'Validée'**
  String get validated;

  /// No description provided for @rejected.
  ///
  /// In fr, this message translates to:
  /// **'Rejetée'**
  String get rejected;

  /// No description provided for @all.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get all;

  /// No description provided for @validatedPlural.
  ///
  /// In fr, this message translates to:
  /// **'Validées'**
  String get validatedPlural;

  /// No description provided for @rejectedPlural.
  ///
  /// In fr, this message translates to:
  /// **'Rejetées'**
  String get rejectedPlural;

  /// No description provided for @processedOn.
  ///
  /// In fr, this message translates to:
  /// **'Traitée le : '**
  String get processedOn;

  /// No description provided for @canPickUp.
  ///
  /// In fr, this message translates to:
  /// **'Vous pouvez récupérer vos médicaments.'**
  String get canPickUp;

  /// No description provided for @reminders.
  ///
  /// In fr, this message translates to:
  /// **'Rappels'**
  String get reminders;

  /// No description provided for @addReminder.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un rappel'**
  String get addReminder;

  /// No description provided for @addReminderBtn.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter le rappel'**
  String get addReminderBtn;

  /// No description provided for @noReminders.
  ///
  /// In fr, this message translates to:
  /// **'Aucun rappel configuré'**
  String get noReminders;

  /// No description provided for @deleteReminder.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le rappel'**
  String get deleteReminder;

  /// No description provided for @medication.
  ///
  /// In fr, this message translates to:
  /// **'Médicament'**
  String get medication;

  /// No description provided for @medicationNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex : Doliprane 500mg'**
  String get medicationNameHint;

  /// No description provided for @reminderTime.
  ///
  /// In fr, this message translates to:
  /// **'Heure du rappel *'**
  String get reminderTime;

  /// No description provided for @frequency.
  ///
  /// In fr, this message translates to:
  /// **'Fréquence *'**
  String get frequency;

  /// No description provided for @everyDay.
  ///
  /// In fr, this message translates to:
  /// **'Chaque jour'**
  String get everyDay;

  /// No description provided for @everyWeek.
  ///
  /// In fr, this message translates to:
  /// **'Chaque semaine'**
  String get everyWeek;

  /// No description provided for @asNeeded.
  ///
  /// In fr, this message translates to:
  /// **'Si besoin'**
  String get asNeeded;

  /// No description provided for @dosage.
  ///
  /// In fr, this message translates to:
  /// **'Dosage (optionnel)'**
  String get dosage;

  /// No description provided for @dosageHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex : 1 comprimé'**
  String get dosageHint;

  /// No description provided for @notes.
  ///
  /// In fr, this message translates to:
  /// **'Notes (optionnel)'**
  String get notes;

  /// No description provided for @notesHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex : Prendre après le repas'**
  String get notesHint;

  /// No description provided for @reminderActive.
  ///
  /// In fr, this message translates to:
  /// **'Rappel actif'**
  String get reminderActive;

  /// No description provided for @medicationName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du médicament *'**
  String get medicationName;

  /// No description provided for @medicationHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex : Paracétamol 500mg'**
  String get medicationHint;

  /// No description provided for @price.
  ///
  /// In fr, this message translates to:
  /// **'Prix (DZD) *'**
  String get price;

  /// No description provided for @stock.
  ///
  /// In fr, this message translates to:
  /// **'Stock *'**
  String get stock;

  /// No description provided for @description.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @descriptionHint.
  ///
  /// In fr, this message translates to:
  /// **'Posologie, indications...'**
  String get descriptionHint;

  /// No description provided for @category.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie *'**
  String get category;

  /// No description provided for @selectCategory.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner une catégorie'**
  String get selectCategory;

  /// No description provided for @expiryDate.
  ///
  /// In fr, this message translates to:
  /// **'Date d\'expiration'**
  String get expiryDate;

  /// No description provided for @chooseCategory.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez choisir une catégorie'**
  String get chooseCategory;

  /// No description provided for @addMedication.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un médicament'**
  String get addMedication;

  /// No description provided for @editMedication.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le médicament'**
  String get editMedication;

  /// No description provided for @noMedications.
  ///
  /// In fr, this message translates to:
  /// **'Aucun médicament enregistré'**
  String get noMedications;

  /// No description provided for @searchMedication.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un médicament...'**
  String get searchMedication;

  /// No description provided for @noResults.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat pour'**
  String get noResults;

  /// No description provided for @confirmDelete.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la suppression'**
  String get confirmDelete;

  /// No description provided for @medicationAdded.
  ///
  /// In fr, this message translates to:
  /// **'Médicament ajouté avec succès ✓'**
  String get medicationAdded;

  /// No description provided for @medicationUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Médicament mis à jour avec succès ✓'**
  String get medicationUpdated;

  /// No description provided for @stockUnits.
  ///
  /// In fr, this message translates to:
  /// **'Stock : {stock} unités'**
  String stockUnits(int stock);

  /// No description provided for @profileTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mon Profil'**
  String get profileTitle;

  /// No description provided for @personalInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations personnelles'**
  String get personalInfo;

  /// No description provided for @accountInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations du compte'**
  String get accountInfo;

  /// No description provided for @myInfo.
  ///
  /// In fr, this message translates to:
  /// **'Mes informations'**
  String get myInfo;

  /// No description provided for @role.
  ///
  /// In fr, this message translates to:
  /// **'Rôle'**
  String get role;

  /// No description provided for @memberSince.
  ///
  /// In fr, this message translates to:
  /// **'Membre depuis'**
  String get memberSince;

  /// No description provided for @adminRole.
  ///
  /// In fr, this message translates to:
  /// **'Administrateur'**
  String get adminRole;

  /// No description provided for @clientRole.
  ///
  /// In fr, this message translates to:
  /// **'Client'**
  String get clientRole;

  /// No description provided for @unknown.
  ///
  /// In fr, this message translates to:
  /// **'Inconnu'**
  String get unknown;

  /// No description provided for @notDefined.
  ///
  /// In fr, this message translates to:
  /// **'Non défini'**
  String get notDefined;

  /// No description provided for @saveChanges.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarder les modifications'**
  String get saveChanges;

  /// No description provided for @profileUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Profil mis à jour avec succès ✓'**
  String get profileUpdated;

  /// No description provided for @saveError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la sauvegarde'**
  String get saveError;

  /// No description provided for @profileLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du chargement du profil'**
  String get profileLoadError;

  /// No description provided for @security.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité'**
  String get security;

  /// No description provided for @changePassword.
  ///
  /// In fr, this message translates to:
  /// **'Changer le mot de passe'**
  String get changePassword;

  /// No description provided for @changePasswordSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier votre mot de passe de connexion'**
  String get changePasswordSubtitle;

  /// No description provided for @currentPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe actuel'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le nouveau mot de passe'**
  String get confirmNewPassword;

  /// No description provided for @newPasswordTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Le nouveau mot de passe doit avoir au moins 6 caractères'**
  String get newPasswordTooShort;

  /// No description provided for @wrongCurrentPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe actuel incorrect'**
  String get wrongCurrentPassword;

  /// No description provided for @passwordChanged.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe changé avec succès ✓'**
  String get passwordChanged;

  /// No description provided for @changePasswordError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du changement de mot de passe'**
  String get changePasswordError;

  /// No description provided for @appearance.
  ///
  /// In fr, this message translates to:
  /// **'Apparence'**
  String get appearance;

  /// No description provided for @light.
  ///
  /// In fr, this message translates to:
  /// **'Clair'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get dark;

  /// No description provided for @automatic.
  ///
  /// In fr, this message translates to:
  /// **'Automatique'**
  String get automatic;

  /// No description provided for @followDevice.
  ///
  /// In fr, this message translates to:
  /// **'Suit les réglages du téléphone'**
  String get followDevice;

  /// No description provided for @lightDesc.
  ///
  /// In fr, this message translates to:
  /// **'Fond blanc, texte sombre'**
  String get lightDesc;

  /// No description provided for @darkDesc.
  ///
  /// In fr, this message translates to:
  /// **'Fond noir, texte clair'**
  String get darkDesc;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @french.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get french;

  /// No description provided for @english.
  ///
  /// In fr, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In fr, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @notifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @enableNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Activer les notifications'**
  String get enableNotifications;

  /// No description provided for @notificationsComingSoon.
  ///
  /// In fr, this message translates to:
  /// **'Notifications — bientôt disponible'**
  String get notificationsComingSoon;

  /// No description provided for @about.
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get about;

  /// No description provided for @privacyPolicy.
  ///
  /// In fr, this message translates to:
  /// **'Politique de confidentialité'**
  String get privacyPolicy;

  /// No description provided for @notificationActive.
  ///
  /// In fr, this message translates to:
  /// **'Notif active'**
  String get notificationActive;

  /// No description provided for @noRemindersDescription.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez vos rappels pour ne jamais oublier de prendre vos médicaments.'**
  String get noRemindersDescription;

  /// No description provided for @reminderAdded.
  ///
  /// In fr, this message translates to:
  /// **'✅ Rappel ajouté avec succès'**
  String get reminderAdded;

  /// No description provided for @reminderUpdated.
  ///
  /// In fr, this message translates to:
  /// **'✅ Rappel mis à jour'**
  String get reminderUpdated;

  /// No description provided for @reminderDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Rappel supprimé'**
  String get reminderDeleted;

  /// No description provided for @deleteReminderConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le rappel pour'**
  String get deleteReminderConfirm;

  /// No description provided for @newReminder.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau rappel'**
  String get newReminder;

  /// No description provided for @editReminder.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le rappel'**
  String get editReminder;

  /// No description provided for @modify.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get modify;

  /// No description provided for @errorOccurred.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue.'**
  String get errorOccurred;

  /// No description provided for @dosageOptional.
  ///
  /// In fr, this message translates to:
  /// **'Dosage (optionnel)'**
  String get dosageOptional;

  /// No description provided for @notesOptional.
  ///
  /// In fr, this message translates to:
  /// **'Notes (optionnel)'**
  String get notesOptional;

  /// No description provided for @frequencyDaily.
  ///
  /// In fr, this message translates to:
  /// **'Chaque jour'**
  String get frequencyDaily;

  /// No description provided for @frequencyTwice.
  ///
  /// In fr, this message translates to:
  /// **'2 fois par jour'**
  String get frequencyTwice;

  /// No description provided for @frequencyThrice.
  ///
  /// In fr, this message translates to:
  /// **'3 fois par jour'**
  String get frequencyThrice;

  /// No description provided for @frequencyWeekly.
  ///
  /// In fr, this message translates to:
  /// **'Chaque semaine'**
  String get frequencyWeekly;

  /// No description provided for @frequencyAsNeeded.
  ///
  /// In fr, this message translates to:
  /// **'Si besoin'**
  String get frequencyAsNeeded;

  /// No description provided for @notifInfoDaily.
  ///
  /// In fr, this message translates to:
  /// **'1 notification planifiée par jour à cette heure.'**
  String get notifInfoDaily;

  /// No description provided for @notifInfoTwice.
  ///
  /// In fr, this message translates to:
  /// **'2 notifications : à cette heure et 8h plus tard.'**
  String get notifInfoTwice;

  /// No description provided for @notifInfoThrice.
  ///
  /// In fr, this message translates to:
  /// **'3 notifications : à cette heure, +6h et +12h.'**
  String get notifInfoThrice;

  /// No description provided for @notifInfoWeekly.
  ///
  /// In fr, this message translates to:
  /// **'1 notification planifiée par semaine à cette heure.'**
  String get notifInfoWeekly;
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
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
