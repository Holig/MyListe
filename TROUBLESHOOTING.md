# Guide de dépannage - MyListe

## Problèmes d'authentification

### 1. Avertissement de hauteur du bouton Google Sign-In

**Problème :**
```
Height of Platform View type: [google-signin-button] may not be set. Defaulting to `height: 100%`.
```

**Solution :**
- Les styles CSS ont été ajoutés dans `web/index.html` pour définir la hauteur du bouton Google
- Le bouton est maintenant configuré avec une hauteur fixe de 48px

### 2. Erreur 400 (Bad Request) lors de l'authentification

**Problème :**
```
POST https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=... 400 (Bad Request)
```

**Causes possibles :**
1. **Identifiants incorrects** : Vérifiez que l'e-mail et le mot de passe sont corrects
2. **Configuration Firebase** : Assurez-vous que l'authentification par e-mail/mot de passe est activée dans Firebase Console
3. **Problème de réseau** : Vérifiez votre connexion internet

**Solutions :**

#### A. Vérifier la configuration Firebase
1. Allez dans [Firebase Console](https://console.firebase.google.com)
2. Sélectionnez votre projet `myliste-app`
3. Allez dans Authentication > Sign-in method
4. Assurez-vous que "Email/Password" est activé
5. Vérifiez que "Google" est également activé pour Google Sign-In

#### B. Vérifier les identifiants
- Assurez-vous que l'adresse e-mail est correctement formatée
- Vérifiez que le mot de passe respecte les critères de sécurité
- Pour l'inscription : mot de passe d'au moins 8 caractères avec majuscule et chiffre

#### C. Tester la connexion
1. Essayez de créer un nouveau compte avec une adresse e-mail différente
2. Vérifiez que vous recevez bien un e-mail de confirmation (si activé)
3. Testez la connexion avec Google Sign-In

### 3. Améliorations apportées

#### Gestion des erreurs améliorée
- Messages d'erreur plus clairs et en français
- Gestion spécifique des erreurs Firebase
- Validation des champs améliorée

#### Validation des mots de passe
- **Connexion** : minimum 6 caractères
- **Inscription** : minimum 8 caractères avec majuscule et chiffre

#### Styles du bouton Google
- Hauteur fixe de 48px
- Largeur de 240px
- Styles CSS pour éviter les avertissements

### 4. Commandes utiles

```bash
# Nettoyer et reconstruire l'application
flutter clean
flutter pub get
flutter run -d chrome

# Pour le développement
flutter run --web-renderer html

# Pour la production
flutter build web
```

### 5. Vérification de la configuration

Vérifiez que les fichiers suivants sont correctement configurés :

1. `lib/firebase_options.dart` - Configuration Firebase
2. `web/index.html` - Scripts Google Sign-In et styles CSS
3. `lib/services/auth_service.dart` - Service d'authentification
4. `lib/pages/auth_page.dart` - Page d'authentification

### 6. Support

Si les problèmes persistent :
1. Vérifiez les logs de la console du navigateur
2. Testez sur un autre navigateur
3. Vérifiez que toutes les dépendances sont à jour
4. Consultez la documentation Firebase pour l'authentification web 