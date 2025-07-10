# Fonctionnalités de l'application MyListe

## Présentation générale
MyListe est une application collaborative permettant aux familles de créer, partager et gérer des listes (courses, tâches, etc.) de façon simple et organisée. L'application est pensée pour la collaboration familiale, la personnalisation et la gestion en temps réel.

---

## Authentification et gestion des utilisateurs
- **Connexion/Inscription** par e-mail/mot de passe ou via Google (Firebase Auth)
- **Gestion de session** : suivi de l'utilisateur connecté, déconnexion
- **Profil utilisateur** : email, nom, photo, familles associées, famille active

---

## Gestion des familles
- **Création d'une famille** (groupe d'utilisateurs)
- **Rejoindre une famille** via un code d'invitation ou un QR code
- **Changement de famille active** (pour les utilisateurs membres de plusieurs familles)
- **Gestion des membres** :
  - Promotion/rétrogradation admin
  - Suppression d'un membre
  - Quitter une famille
- **Personnalisation** : choix du dégradé de couleur pour chaque famille

---

## Superlistes et listes
- **Superlistes** : catégories principales de listes (ex : Courses, Projets, etc.)
  - Création, renommage, suppression
- **Listes** : sous-ensembles d'une superliste (ex : Semaine 25, Anniversaire...)
  - Création, fermeture/réouverture, suppression
  - Suivi des listes actives et fermées
- **Éléments de liste** (tags) :
  - Ajout rapide avec suggestions
  - Organisation par catégories personnalisables
  - Marquage comme fait/non fait
  - Suppression, édition

---

## Catégories
- **Gestion des catégories** pour chaque superliste
  - Création, édition, suppression, réorganisation (drag & drop)
  - Attribution d'une couleur/ordre

---

## Navigation et interface
- **Accueil** avec navigation par onglets :
  - Superlistes
  - Paramètres familles
  - Contact
  - À propos
- **Navigation fluide** entre les pages (GoRouter)
- **Mode sombre/clair**

---

## Partage et collaboration
- **Invitation par code ou QR code** pour rejoindre une famille
- **Gestion des droits** (admin, membre, propriétaire)
- **Mises à jour en temps réel** (Firestore streams)

---

## Pages d'information et support
- **Contact** : formulaire pour suggestions, bugs, questions
- **À propos** : présentation, équipe, liens utiles (CGU, confidentialité)

---

## Technologies utilisées
- **Flutter** (multi-plateforme)
- **Firebase Auth** (authentification)
- **Cloud Firestore** (base de données temps réel)
- **Riverpod** (gestion d'état)
- **GoRouter** (navigation)
- **Packages divers** : partage, QR code, etc.

---

## Résumé
MyListe vise à simplifier l'organisation familiale autour des listes partagées, avec une gestion fine des membres, des droits, des catégories et une expérience collaborative moderne et intuitive. 