# Script de déploiement rapide pour MyListe (développement)
# Usage: .\deploy-dev.ps1

Write-Host "🚀 Déploiement rapide de MyListe..." -ForegroundColor Green

# Build rapide sans nettoyage
Write-Host "🔨 Build rapide..." -ForegroundColor Blue
flutter build web --release

# Déployer directement
Write-Host "🚀 Déploiement..." -ForegroundColor Blue
firebase deploy --only hosting

Write-Host "✅ Déploiement terminé!" -ForegroundColor Green 