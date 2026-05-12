# Application de réservation de ressources

Ce dépôt contient une application Flutter de gestion de réservations avec trois rôles : `user`, `manager` et `admin`.
Ce README guide pour cloner, configurer, exécuter et comprendre rapidement le projet.


## Prérequis
- Flutter SDK 
- Dart 
- Un compte Firebase 
- Git


## Mise en place (rapide)

1. Cloner le dépôt

git clone <url-du-depot>
cd projet

2. Installer les dépendances


flutter pub get


3. Préparer Firebase
- Le projet contient `lib/firebase_options.dart`. Si tu dois connecter ton propre projet Firebase, génère et remplace ce fichier .

4. Lancer l'application

flutter run

## Structure du projet (essentiel)

- `lib/`
  - `main.dart` : point d'entrée de l'app
  - `firebase_options.dart` : config Firebase 
  - `models/` : définitions de `Reservation`, `User`, `Resource`, etc.
  - `providers/` : providers `ReservationProvider`, `AuthProvider` 
  - `services/` : logique d'accès , notifications
  - `views/` : écrans (calendar, reservations, manager)
  - `widgets/` : composants réutilisables (`reservation_card.dart`, `app_colors.dart`)
- `assets/` : images et ressources
- `android/`, `ios/`, `windows/`, `macos/` : fichiers de plateforme


## Fonctionnalités (liste complète)

Voici l'ensemble des fonctionnalités prises en charge par l'application :

- Authentification & rôles
  - Inscription / connexion des utilisateurs.
  - Trois rôles : `user` (utilisateur standard), `manager` (peut approuver/refuser) et `admin` (gestion complète).
  - Les comptes `manager` sont créés par l'`admin`.

- Réservations (utilisateur)
  - Sélection d'un jour via un calendrier (`TableCalendar`).
  - Sélection d'un créneau horaire (heures entières) et durée configurable.
  - Validation côté UI et côté service : impossible de réserver un créneau passé.
  - Gestion des conflits : transactions Firestore pour empêcher les chevauchements.

- Flow d'approbation (manager)
  - Liste des demandes en attente (`pending`).
  - Le manager peut `Approuver` ou `Refuser` une demande avec un commentaire optionnel.
  - Lors de l'action, la base vérifie en transaction que la réservation est toujours `pending`.
  - Après approbation/rejet, le champ `managerId` et `managerComment` sont enregistrés.

- Règles de statut et édition
  - Si une réservation est `rejected` puis modifiée par l'utilisateur, son statut repasse à `pending` et les métadonnées manager sont supprimées.
  - Les réservations approuvées peuvent être bloquées pour l'édition côté UI .

- Interface Admin
  - Gestion des ressources (ajout, édition, suppression).
  - Gestion des comptes `manager` (création / suppression / modification).
  - Accès aux vues statistiques et aux outils d'administration .

- Notifications
  - Notifications  (ex : confirmation, modification, annulation).

- UI & Composants
  - Cartes de réservation (`reservation_card`) affichant statut, ressource, utilisateur, début/fin.
  - Écrans séparés : calendrier / mes réservations / en attente / traitées / admin.

- Sécurité & validation
  - Validation côté client  et côté service .
  - Messages d'erreur propagés et affichés dans l'UI .



## Fichiers importants à connaître

- `lib/views/calendar/reservation_screen.dart` : écran de création de réservation (TableCalendar)
- `lib/views/reservations/edit_reservation_screen.dart` : écran d'édition
- `lib/views/manager/pending_reservations_screen.dart` : listes des demandes pour le manager
- `lib/providers/reservation_provider.dart` : logique côté client (création, approbation)
- `lib/services/reservation_service.dart` : transactions Firestore (création, approbation, rejet)
- `lib/widgets/reservation_card.dart` : rendu d'une carte de réservation



## Conseils 

- Lire d'abord `main.dart` pour comprendre l'architecture et les providers injectés.
- Exécuter l'app localement et naviguer dans les onglets: `Réservations`, `En attente`, `Traitées`.
-- Pour tester les différents rôles :
  - Créer ou configurer trois comptes (utilisateur, manager et admin) .
  - Créer une réservation avec un compte utilisateur, puis approuver avec le manager.
  - Se connecter en `admin` pour gérer ressources et managers depuis l'onglet Admin.



## Personnalisation rapide

- Changer les couleurs : fichier `lib/widgets/app_colors.dart`.
- Ajouter un champ à `Reservation` : modifier `lib/models/reservation.dart`.

