// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'PharmaAI';

  @override
  String get appVersion => 'PharmaAI v1.0.0';

  @override
  String get version => 'Version 1.0.0';

  @override
  String get pharmaAIAdmin => 'PharmaAI Admin';

  @override
  String get settings => 'Paramètres';

  @override
  String get signOut => 'Déconnexion';

  @override
  String get signOutConfirm => 'Êtes-vous sûr de vouloir vous déconnecter ?';

  @override
  String get confirm => 'Confirmer';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get edit => 'Modifier';

  @override
  String get delete => 'Supprimer';

  @override
  String get add => 'Ajouter';

  @override
  String get back => 'Retour';

  @override
  String get error => 'Erreur';

  @override
  String get success => 'Succès';

  @override
  String get loading => 'Chargement...';

  @override
  String get saving => 'Sauvegarde...';

  @override
  String get sending => 'Envoi en cours...';

  @override
  String get signIn => 'Se connecter';

  @override
  String get signInSubtitle => 'Connectez-vous à votre compte';

  @override
  String get email => 'Email';

  @override
  String get emailHint => 'exemple@email.com';

  @override
  String get password => 'Mot de passe';

  @override
  String get passwordMin => 'Minimum 6 caractères';

  @override
  String get continueWithGoogle => 'Continuer avec Google';

  @override
  String get noAccount => 'Pas encore de compte ? ';

  @override
  String get createAccount => 'Créer un nouveau compte';

  @override
  String get alreadyAccount => 'Vous avez déjà un compte ? ';

  @override
  String get signUp => 'S\'inscrire';

  @override
  String get fullName => 'Nom complet';

  @override
  String get fullNameHint => 'Ex : Ahmed Benali';

  @override
  String get phone => 'Téléphone (optionnel)';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get accountCreated =>
      'Compte créé avec succès ! Vous pouvez vous connecter.';

  @override
  String get enterEmail => 'Veuillez entrer votre email';

  @override
  String get invalidEmail => 'Format email invalide';

  @override
  String get enterPassword => 'Veuillez entrer un mot de passe';

  @override
  String get enterName => 'Veuillez entrer votre nom';

  @override
  String get nameTooShort => 'Le nom doit contenir au moins 3 caractères';

  @override
  String get nameRequired => 'Le nom est requis';

  @override
  String get confirmPasswordRequired => 'Veuillez confirmer votre mot de passe';

  @override
  String get passwordMismatch => 'Les mots de passe ne correspondent pas';

  @override
  String get passwordTooWeak =>
      'Le mot de passe est trop faible (min. 6 caractères).';

  @override
  String get fieldRequired => 'Champ requis';

  @override
  String get fillAllFields => 'Veuillez remplir tous les champs';

  @override
  String get emailAlreadyUsed =>
      'Cet email est déjà utilisé par un autre compte.';

  @override
  String get noAccountFound => 'Aucun compte trouvé avec cet email.';

  @override
  String get wrongPassword => 'Mot de passe incorrect.';

  @override
  String get invalidEmailAddress => 'Adresse email invalide.';

  @override
  String get unexpectedError => 'Une erreur inattendue est survenue.';

  @override
  String get anErrorOccurred => 'Une erreur est survenue.';

  @override
  String get userNotFound => 'Utilisateur introuvable dans la base de données.';

  @override
  String get userNotSignedIn => 'Utilisateur non connecté';

  @override
  String get helloPharmacie => 'Bonjour, Pharmacien 👨‍⚕️';

  @override
  String get pharmacySummary => 'Voici le résumé de votre pharmacie';

  @override
  String get statistics => 'Statistiques';

  @override
  String get quickActions => 'Actions rapides';

  @override
  String get medications => 'Médicaments';

  @override
  String get pending => 'En attente';

  @override
  String get criticalStock => 'Stock critique';

  @override
  String get clients => 'Clients';

  @override
  String get manageMedications => 'Gérer les médicaments';

  @override
  String get addEditDelete => 'Ajouter, modifier, supprimer';

  @override
  String get viewPrescriptions => 'Voir les ordonnances';

  @override
  String get stockAlerts => 'Alertes de stock';

  @override
  String get goodMorning => 'Bonjour,';

  @override
  String get goodAfternoon => 'Bon après-midi,';

  @override
  String get goodEvening => 'Bonsoir,';

  @override
  String get medicationCatalog => 'Catalogue médicaments';

  @override
  String get scanPrescription => 'Scanner une ordonnance';

  @override
  String get scanBarcode => 'Scanner Code-barres';

  @override
  String get myPrescriptions => 'Mes Ordonnances';

  @override
  String get myReminders => 'Mes Rappels';

  @override
  String get myProfile => 'Mon Profil';

  @override
  String get searchInfo => 'Recherche & infos';

  @override
  String get identifyMedication => 'Identifier un médicament';

  @override
  String get medicationIntake => 'Prise de médicaments';

  @override
  String get fullHistory => 'Historique complet';

  @override
  String get howItWorks => 'Comment ça marche ?';

  @override
  String get remindersAndAlerts => 'Rappels médicaments et alertes stock';

  @override
  String get comingSoon => 'Bientôt disponible';

  @override
  String get scanYourPrescription => 'Scanner votre ordonnance';

  @override
  String get takePhoto => 'Prendre une photo';

  @override
  String get importFromGallery => 'Importer depuis la galerie';

  @override
  String get chooseExistingImage => 'Choisir une image existante';

  @override
  String get analysisInProgress => 'Analyse en cours...';

  @override
  String get textExtractedSuccess => 'Texte extrait avec succès';

  @override
  String get noText => 'Aucun texte';

  @override
  String get noTextDetected =>
      'Aucun texte détecté. Essayez avec une image plus nette.';

  @override
  String get extractedTextPlaceholder => 'Le texte extrait apparaît ici...';

  @override
  String get noMedicationDetected =>
      'Aucun médicament automatiquement détecté.';

  @override
  String get checkAndCorrect => 'Vérifiez et corrigez si nécessaire';

  @override
  String get sendToPharmacy => 'Envoyer à la pharmacie';

  @override
  String get prescriptionSent => 'Ordonnance envoyée !';

  @override
  String get prescriptionTransmitted =>
      'Votre ordonnance a été transmise au pharmacien.';

  @override
  String get scanAnotherPrescription => 'Scanner une autre ordonnance';

  @override
  String get startOver => 'Recommencer';

  @override
  String get scanTips => 'Conseils pour un bon scan';

  @override
  String get takeClearPhoto => 'Prenez une photo claire de votre ordonnance';

  @override
  String get whiteBgDarkText => 'Fond blanc, texte sombre';

  @override
  String get whatDoYouWant => 'Que voulez-vous faire ?';

  @override
  String get chooseAction => 'Choisissez une action ci-dessous';

  @override
  String get noPrescription => 'Aucune ordonnance';

  @override
  String get prescriptionValidated => 'Votre ordonnance a été validée.';

  @override
  String get prescriptionRejected => 'Votre ordonnance a été rejetée.';

  @override
  String get awaitingValidation =>
      'En attente de validation par le pharmacien.';

  @override
  String get validated => 'Validée';

  @override
  String get rejected => 'Rejetée';

  @override
  String get all => 'Toutes';

  @override
  String get validatedPlural => 'Validées';

  @override
  String get rejectedPlural => 'Rejetées';

  @override
  String get processedOn => 'Traitée le : ';

  @override
  String get canPickUp => 'Vous pouvez récupérer vos médicaments.';

  @override
  String get reminders => 'Rappels';

  @override
  String get addReminder => 'Ajouter un rappel';

  @override
  String get addReminderBtn => 'Ajouter le rappel';

  @override
  String get noReminders => 'Aucun rappel configuré';

  @override
  String get deleteReminder => 'Supprimer le rappel';

  @override
  String get medication => 'Médicament';

  @override
  String get medicationNameHint => 'Ex : Doliprane 500mg';

  @override
  String get reminderTime => 'Heure du rappel *';

  @override
  String get frequency => 'Fréquence *';

  @override
  String get everyDay => 'Chaque jour';

  @override
  String get everyWeek => 'Chaque semaine';

  @override
  String get asNeeded => 'Si besoin';

  @override
  String get dosage => 'Dosage (optionnel)';

  @override
  String get dosageHint => 'Ex : 1 comprimé';

  @override
  String get notes => 'Notes (optionnel)';

  @override
  String get notesHint => 'Ex : Prendre après le repas';

  @override
  String get reminderActive => 'Rappel actif';

  @override
  String get medicationName => 'Nom du médicament *';

  @override
  String get medicationHint => 'Ex : Paracétamol 500mg';

  @override
  String get price => 'Prix (DZD) *';

  @override
  String get stock => 'Stock *';

  @override
  String get description => 'Description';

  @override
  String get descriptionHint => 'Posologie, indications...';

  @override
  String get category => 'Catégorie *';

  @override
  String get selectCategory => 'Sélectionner une catégorie';

  @override
  String get expiryDate => 'Date d\'expiration';

  @override
  String get chooseCategory => 'Veuillez choisir une catégorie';

  @override
  String get addMedication => 'Ajouter un médicament';

  @override
  String get editMedication => 'Modifier le médicament';

  @override
  String get noMedications => 'Aucun médicament enregistré';

  @override
  String get searchMedication => 'Rechercher un médicament...';

  @override
  String get noResults => 'Aucun résultat pour';

  @override
  String get confirmDelete => 'Confirmer la suppression';

  @override
  String get medicationAdded => 'Médicament ajouté avec succès ✓';

  @override
  String get medicationUpdated => 'Médicament mis à jour avec succès ✓';

  @override
  String stockUnits(int stock) {
    return 'Stock : $stock unités';
  }

  @override
  String get profileTitle => 'Mon Profil';

  @override
  String get personalInfo => 'Informations personnelles';

  @override
  String get accountInfo => 'Informations du compte';

  @override
  String get myInfo => 'Mes informations';

  @override
  String get role => 'Rôle';

  @override
  String get memberSince => 'Membre depuis';

  @override
  String get adminRole => 'Administrateur';

  @override
  String get clientRole => 'Client';

  @override
  String get unknown => 'Inconnu';

  @override
  String get notDefined => 'Non défini';

  @override
  String get saveChanges => 'Sauvegarder les modifications';

  @override
  String get profileUpdated => 'Profil mis à jour avec succès ✓';

  @override
  String get saveError => 'Erreur lors de la sauvegarde';

  @override
  String get profileLoadError => 'Erreur lors du chargement du profil';

  @override
  String get security => 'Sécurité';

  @override
  String get changePassword => 'Changer le mot de passe';

  @override
  String get changePasswordSubtitle =>
      'Modifier votre mot de passe de connexion';

  @override
  String get currentPassword => 'Mot de passe actuel';

  @override
  String get newPassword => 'Nouveau mot de passe';

  @override
  String get confirmNewPassword => 'Confirmer le nouveau mot de passe';

  @override
  String get newPasswordTooShort =>
      'Le nouveau mot de passe doit avoir au moins 6 caractères';

  @override
  String get wrongCurrentPassword => 'Mot de passe actuel incorrect';

  @override
  String get passwordChanged => 'Mot de passe changé avec succès ✓';

  @override
  String get changePasswordError => 'Erreur lors du changement de mot de passe';

  @override
  String get appearance => 'Apparence';

  @override
  String get light => 'Clair';

  @override
  String get dark => 'Sombre';

  @override
  String get automatic => 'Automatique';

  @override
  String get followDevice => 'Suit les réglages du téléphone';

  @override
  String get lightDesc => 'Fond blanc, texte sombre';

  @override
  String get darkDesc => 'Fond noir, texte clair';

  @override
  String get language => 'Langue';

  @override
  String get french => 'Français';

  @override
  String get english => 'English';

  @override
  String get arabic => 'العربية';

  @override
  String get notifications => 'Notifications';

  @override
  String get enableNotifications => 'Activer les notifications';

  @override
  String get notificationsComingSoon => 'Notifications — bientôt disponible';

  @override
  String get about => 'À propos';

  @override
  String get privacyPolicy => 'Politique de confidentialité';
}
