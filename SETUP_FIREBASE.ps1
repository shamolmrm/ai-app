# ============================================================
#  AI Assistant — Automatic Firebase Setup Script
#  Double-click this file OR run in PowerShell as Admin
# ============================================================
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

$ProjectBase = "d:\devloper\app\ai-app"
$PackageName = "com.aiassistant.ai_assistant"

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "   AI Assistant - Firebase Auto Setup   " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# ── Step 1: Add FlutterFire to PATH ──────────────────────────
$env:PATH += ";C:\Users\$env:USERNAME\AppData\Local\Pub\Cache\bin"

# ── Step 2: Firebase Login ────────────────────────────────────
Write-Host "STEP 1: Firebase Login" -ForegroundColor Yellow
Write-Host "  A browser window will open. Sign in with your Google account." -ForegroundColor White
Write-Host ""
firebase login
if ($LASTEXITCODE -ne 0) { Write-Host "Login failed. Please try again." -ForegroundColor Red; Read-Host "Press Enter to exit"; exit 1 }
Write-Host "  Login successful!" -ForegroundColor Green
Write-Host ""

# ── Step 3: Create Firebase Project ──────────────────────────
Write-Host "STEP 2: Creating Firebase Project..." -ForegroundColor Yellow
$ProjectId = "ai-assistant-app-" + (Get-Random -Minimum 1000 -Maximum 9999)
firebase projects:create $ProjectId --display-name "AI Assistant"
if ($LASTEXITCODE -ne 0) { Write-Host "Project creation failed." -ForegroundColor Red; Read-Host "Press Enter to exit"; exit 1 }
Write-Host "  Project created: $ProjectId" -ForegroundColor Green
Write-Host ""

# ── Step 4: Add Android App ───────────────────────────────────
Write-Host "STEP 3: Adding Android App to Firebase..." -ForegroundColor Yellow
$AppOutput = firebase apps:create ANDROID --package-name $PackageName --project $ProjectId 2>&1
Write-Host $AppOutput
# Extract Android App ID from output
$AndroidAppId = ($AppOutput | Select-String "1:").ToString().Trim().Split(" ") | Where-Object { $_ -match "^1:" } | Select-Object -First 1
if (-not $AndroidAppId) {
    # Try alternative extraction
    $AndroidAppId = ($AppOutput | Select-String "appId").ToString() -replace ".*appId[:\s]+([^\s,}]+).*", '$1'
}
Write-Host "  Android App added!" -ForegroundColor Green
Write-Host ""

# ── Step 5: Download google-services.json ────────────────────
Write-Host "STEP 4: Downloading google-services.json..." -ForegroundColor Yellow
Set-Location $ProjectBase
if ($AndroidAppId) {
    firebase apps:sdkconfig ANDROID $AndroidAppId --project $ProjectId --out "android\app\google-services.json"
} else {
    # Fallback: list apps and download
    $AppsJson = firebase apps:list --project $ProjectId --json 2>&1 | ConvertFrom-Json
    $App = $AppsJson.result | Where-Object { $_.platform -eq "ANDROID" } | Select-Object -First 1
    if ($App) {
        firebase apps:sdkconfig ANDROID $App.appId --project $ProjectId --out "android\app\google-services.json"
    }
}
Write-Host "  google-services.json saved!" -ForegroundColor Green
Write-Host ""

# ── Step 6: Create Firestore Database ────────────────────────
Write-Host "STEP 5: Creating Firestore Database..." -ForegroundColor Yellow
firebase firestore:databases:create --project $ProjectId --location us-central1
Write-Host "  Firestore ready!" -ForegroundColor Green
Write-Host ""

# ── Step 7: Set Firestore Security Rules ─────────────────────
Write-Host "STEP 6: Applying Firestore Security Rules..." -ForegroundColor Yellow
$RulesContent = @'
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      match /chats/{chatId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
        match /messages/{messageId} {
          allow read, write: if request.auth != null && request.auth.uid == userId;
        }
      }
    }
  }
}
'@
$RulesContent | Out-File -FilePath "firestore.rules" -Encoding utf8
$FirebaseJson = @"
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  }
}
"@
$FirebaseJson | Out-File -FilePath "firebase.json" -Encoding utf8
'[]' | Out-File -FilePath "firestore.indexes.json" -Encoding utf8
firebase deploy --only firestore:rules --project $ProjectId
Write-Host "  Security rules applied!" -ForegroundColor Green
Write-Host ""

# ── Step 8: Enable Email/Password Auth via REST API ──────────
Write-Host "STEP 7: Enabling Email/Password Authentication..." -ForegroundColor Yellow
$Token = (firebase auth:export --format=json --project $ProjectId 2>&1)
# Use gcloud approach via firebase management API
$AuthConfig = @{
    signIn = @{
        email = @{
            enabled = $true
            passwordRequired = $true
        }
    }
} | ConvertTo-Json -Depth 5

$AccessToken = (firebase --version 2>&1 | Out-Null; node -e "
const { execSync } = require('child_process');
try {
  const token = execSync('firebase auth:print-access-token --project $ProjectId', {encoding: 'utf8'}).trim();
  console.log(token);
} catch(e) { console.log(''); }
" 2>&1)

if ($AccessToken -and $AccessToken.Length -gt 10) {
    try {
        Invoke-RestMethod -Uri "https://identitytoolkit.googleapis.com/admin/v2/projects/$ProjectId/config?updateMask=signIn.email.enabled,signIn.email.passwordRequired" `
            -Method PATCH `
            -Headers @{ Authorization = "Bearer $AccessToken"; "Content-Type" = "application/json" } `
            -Body $AuthConfig | Out-Null
        Write-Host "  Email/Password Auth enabled!" -ForegroundColor Green
    } catch {
        Write-Host "  Auth will be enabled via Firebase Console (manual step needed)" -ForegroundColor Yellow
        Write-Host "  Go to: https://console.firebase.google.com/project/$ProjectId/authentication/providers" -ForegroundColor Cyan
    }
} else {
    Write-Host "  Please enable Email/Password manually:" -ForegroundColor Yellow
    Write-Host "  https://console.firebase.google.com/project/$ProjectId/authentication/providers" -ForegroundColor Cyan
}
Write-Host ""

# ── Step 9: Run FlutterFire Configure ────────────────────────
Write-Host "STEP 8: Linking Flutter app to Firebase (flutterfire configure)..." -ForegroundColor Yellow
Set-Location $ProjectBase
flutterfire configure --project $ProjectId --platforms android,ios --yes --out lib/firebase_options.dart
Write-Host "  firebase_options.dart generated!" -ForegroundColor Green
Write-Host ""

# ── Step 10: Final flutter run ────────────────────────────────
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "   Setup Complete! Launching App...     " -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Project ID: $ProjectId" -ForegroundColor White
Write-Host ""
Write-Host "NOTE: If Email/Password auth was not auto-enabled," -ForegroundColor Yellow
Write-Host "enable it at:" -ForegroundColor Yellow
Write-Host "https://console.firebase.google.com/project/$ProjectId/authentication/providers" -ForegroundColor Cyan
Write-Host ""
Read-Host "Press Enter to launch the app on your phone"
flutter run -d e1b436da
