# Script de déploiement pour MyListe sur Firebase Hosting
# Usage: .\deploy-prod.ps1

Write-Host "=== DEPLOIEMENT MYLISTE SUR FIREBASE HOSTING ===" -ForegroundColor Green

# Vérifier que Flutter est installé
try {
    $flutterVersion = flutter --version
    Write-Host "[OK] Flutter detecte" -ForegroundColor Green
} catch {
    Write-Host "[ERREUR] Flutter n'est pas installe ou n'est pas dans le PATH" -ForegroundColor Red
    exit 1
}

# Vérifier que Firebase CLI est installé
try {
    $firebaseVersion = firebase --version
    Write-Host "[OK] Firebase CLI detecte" -ForegroundColor Green
} catch {
    Write-Host "[ERREUR] Firebase CLI n'est pas installe." -ForegroundColor Yellow
    Write-Host "Installez Firebase CLI avec: npm install -g firebase-tools" -ForegroundColor Yellow
    exit 1
}

# Nettoyer le build précédent
Write-Host "[INFO] Nettoyage du build precedent..." -ForegroundColor Blue
flutter clean

# Récupérer les dépendances
Write-Host "[INFO] Recuperation des dependances..." -ForegroundColor Blue
flutter pub get

# Build de l'application web
Write-Host "[INFO] Build de l'application web..." -ForegroundColor Blue
flutter build web --release

# Vérifier que le build a réussi
if (-not (Test-Path "build/web")) {
    Write-Host "[ERREUR] Le build a echoue. Le dossier build/web n'existe pas." -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Build reussi!" -ForegroundColor Green

# Vérifier la connexion Firebase
Write-Host "[INFO] Verification de la connexion Firebase..." -ForegroundColor Blue
try {
    firebase projects:list
    Write-Host "[OK] Connexion Firebase etablie" -ForegroundColor Green
} catch {
    Write-Host "[ERREUR] Erreur de connexion Firebase. Verifiez votre authentification." -ForegroundColor Red
    Write-Host "Connectez-vous avec: firebase login" -ForegroundColor Yellow
    exit 1
}

# Déployer sur Firebase Hosting
Write-Host "[INFO] Deploiement sur Firebase Hosting..." -ForegroundColor Blue
firebase deploy --only hosting

# Vérifier le déploiement
if ($LASTEXITCODE -eq 0) {
    Write-Host "[SUCCES] Deploiement reussi!" -ForegroundColor Green
    Write-Host "[URL] Votre application est disponible sur: https://myliste-app.web.app" -ForegroundColor Cyan
    Write-Host "[URL] Vous pouvez egalement utiliser: https://myliste-app.firebaseapp.com" -ForegroundColor Cyan
} else {
    Write-Host "[ERREUR] Le deploiement a echoue." -ForegroundColor Red
    exit 1
}

Write-Host "=== DEPLOIEMENT TERMINE AVEC SUCCES ===" -ForegroundColor Green 