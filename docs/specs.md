# 📘 Spécifications – MyListe (App Flutter Web & Mobile)

## 🧩 Objectif

Créer une application **Flutter/Dart** connectée à **Firebase** (auth, base de données, hébergement) permettant à plusieurs utilisateurs d’une même **famille** de créer, partager et gérer des **listes collaboratives** (courses, séries, tâches, etc.).

---

## 🔧 Stack technique

- **Frontend** : Flutter (responsive web & mobile)
- **Backend** : Firebase (Auth, Firestore, Hosting)
- **Déploiement** :
  - Web : Firebase Hosting
  - Mobile : Play Store, App Store

---

## 🔐 Authentification

- Connexion par :
  - Compte Google
  - E-mail/mot de passe
- Authentification persistante
- À la 1ʳᵉ connexion :
  - Rejoindre une **famille existante** via un **code** ou **QR Code**
  - Ou créer une **nouvelle famille**
- Génération automatique de :
  - Code famille unique
  - Lien de partage
  - QR Code

---

## ��‍👩‍👧‍👦 Famille & Superlistes

### Superlistes (types de listes)

- Exemples : Courses, Séries, Activités, To-do
- Chaque superliste contient ses **propres listes**
- Accès direct depuis l’accueil à toutes les superlistes

---

## 📋 Gestion des listes

### Propriétés d’une liste

- Titre
- Date
- État : **ouverte** / **fermée**
- Liste d’**éléments** (tags), regroupés par **catégories**

### Fonctionnalités

- Saisie libre et auto-alimentée des éléments
- Base de tags réutilisables avec autocomplétion
- Tags associés à des catégories personnalisables
- Affichage trié par catégorie (ordre personnalisable)

### Modes d’utilisation

- **Édition** :
  - Ajout d’éléments
  - Glisser-déposer les catégories
  - Réorganisation manuelle ou via la page "Catégories"
- **Utilisation** :
  - ✅ Like (trouvé) : barré + fond vert pâle
  - ❌ Dislike (non trouvé) : non barré + fond rouge pâle

### Historique

- Accès via une icône dédiée
- Affiche :
  - Modifications (ajouts, suppressions, likes/dislikes)
  - Timestamp + nom de l’utilisateur ayant modifié

---

## 🧭 Navigation – Pages principales

1. **Accueil**
   - Liste des superlistes
   - Bouton "Créer une superliste"

2. **Page d’une superliste**
   - Listes **actives** (en haut)
   - Listes **fermées** (en bas, grisé)
     - Réactivation = duplication avec date du jour

3. **Gestion des aliments (tags)**
   - Liste des tags connus
   - Assignation d’une **catégorie par défaut** par tag

4. **Gestion des catégories**
   - Liste et ordre des catégories
   - Ajout / suppression / réorganisation
   - Catégories **communes** ou **spécifiques à une famille**

5. **Paramétrage de la famille**
   - Affichage du code
   - Lien de partage
   - QR Code à scanner

6. **Contact**
   - Formulaire de feedback (bug, suggestion)
   - Liens vers les réseaux sociaux

7. **À propos**
   - Description et objectifs de l’application

---

## 💡 Scénario utilisateur

1. 👩 L’utilisateur A crée une superliste "Courses" et une liste "Semaine 25"
2. 👨 L’utilisateur B ajoute des éléments à la liste
3. 👦 L’utilisateur C utilise la liste en magasin :
   - ✅ Like les éléments trouvés
   - ❌ Dislike ceux qu’il ne trouve pas
4. ✅ Les modifications sont **synchronisées en temps réel** entre les membres

---

## 📝 TODO (à transformer en tickets Cursor)

- [ ] Authentification Firebase (Google + email)
- [ ] Création / Rejoindre famille avec code ou QR
- [ ] Page Accueil avec liste des superlistes
- [ ] Création de superlistes
- [ ] Page d’une superliste : listes ouvertes / fermées
- [ ] Création de liste
- [ ] Saisie d’éléments avec autocomplétion
- [ ] Base de tags réutilisables
- [ ] Association d’éléments à une catégorie
- [ ] Tri par catégorie et affichage stylé
- [ ] Like / Dislike des éléments
- [ ] Affichage de l’historique
- [ ] Gestion des catégories
- [ ] Gestion des tags
- [ ] Paramétrage de la famille
- [ ] Partage : lien + QR Code
- [ ] Formulaire contact
- [ ] Page À propos

--- 