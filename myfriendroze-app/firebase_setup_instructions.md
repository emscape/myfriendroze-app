# Firebase Setup Instructions

## Quick Setup Steps

### 1. Install Firebase CLI
```bash
npm install -g firebase-tools
firebase login
```

### 2. Install FlutterFire CLI
```bash
dart pub global activate flutterfire_cli
```

### 3. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Enter project name: `myfriendroze-admin`
4. Enable Google Analytics (optional)

### 4. Configure Firebase Services

#### Authentication
1. Go to Authentication > Sign-in method
2. Enable "Email/Password" provider
3. Click Save

#### Firestore Database
1. Go to Firestore Database
2. Click "Create database"
3. Choose "Start in test mode" (we'll add security rules later)
4. Select a location close to your users

#### Storage
1. Go to Storage
2. Click "Get started"
3. Choose "Start in test mode"
4. Select same location as Firestore

### 5. Configure Flutter App
Run this command in your project directory:
```bash
flutterfire configure
```

This will:
- Create `firebase_options.dart` with your project configuration
- Update Android and iOS configuration files
- Set up platform-specific Firebase configuration

### 6. Security Rules

#### Firestore Rules
Go to Firestore Database > Rules and replace with:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /products/{productId} {
      allow read, write: if request.auth != null;
    }
    match /events/{eventId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

#### Storage Rules
Go to Storage > Rules and replace with:
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /products/{allPaths=**} {
      allow read, write: if request.auth != null;
    }
    match /events/{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 7. Test the Setup
```bash
flutter run
```

## Troubleshooting

### Common Issues:
1. **Build errors**: Make sure you've run `flutterfire configure`
2. **Permission errors**: Check that Firebase services are enabled
3. **Authentication errors**: Verify Email/Password provider is enabled
4. **Network errors**: Check your internet connection and Firebase project settings

### Android Specific:
- Minimum SDK: 21
- Make sure `google-services.json` is in `android/app/`

### iOS Specific:
- Minimum iOS: 12.0
- Make sure `GoogleService-Info.plist` is in `ios/Runner/`
- Run `cd ios && pod install` if needed
