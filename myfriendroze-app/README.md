# MyFriendRoze Admin App

A Flutter admin application for managing products and events for MyFriendRoze. This app uses Firebase for authentication, Firestore for data storage, and Firebase Storage for image uploads.

## Features

- **Authentication**: Email/password login and registration
- **Product Management**: Add, edit, and delete products with image upload
- **Event Management**: Add, edit, and delete events with optional image upload
- **Speech-to-Text**: Voice input for product descriptions
- **Image Upload**: Camera and gallery support for product/event photos
- **Real-time Data**: Live updates from Firestore

## Setup Instructions

### 1. Flutter Setup
Make sure you have Flutter installed and configured. This project requires Flutter 3.0 or higher.

```bash
flutter doctor
```

### 2. Firebase Setup

1. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Enable the following services:
   - Authentication (Email/Password provider)
   - Firestore Database
   - Storage

3. Install Firebase CLI:
```bash
npm install -g firebase-tools
```

4. Login to Firebase:
```bash
firebase login
```

5. Install FlutterFire CLI:
```bash
dart pub global activate flutterfire_cli
```

6. Configure Firebase for your Flutter project:
```bash
flutterfire configure
```

This will generate the `firebase_options.dart` file with your project's configuration.

### 3. Dependencies

Install the project dependencies:
```bash
flutter pub get
```

### 4. Platform-specific Setup

#### Android
- Minimum SDK version: 21
- The app requires camera, storage, and microphone permissions

#### iOS
- Minimum iOS version: 12.0
- The app requires camera, photo library, and microphone permissions

### 5. Firestore Security Rules

Set up the following security rules in your Firestore console:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Products collection - only authenticated users can read/write
    match /products/{productId} {
      allow read, write: if request.auth != null;
    }
    
    // Events collection - only authenticated users can read/write
    match /events/{eventId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 6. Storage Security Rules

Set up the following security rules in your Firebase Storage console:

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

## Running the App

1. Make sure you have an emulator running or a device connected
2. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── firebase_options.dart     # Firebase configuration
├── models/                   # Data models
│   ├── product.dart
│   └── event.dart
├── providers/                # State management
│   ├── auth_provider.dart
│   ├── product_provider.dart
│   └── event_provider.dart
├── screens/                  # UI screens
│   ├── auth/
│   ├── home/
│   ├── products/
│   ├── events/
│   └── profile/
├── services/                 # Firebase services
│   ├── firestore_service.dart
│   └── storage_service.dart
├── widgets/                  # Reusable widgets
├── routes/                   # App routing
├── theme/                    # App theming
└── utils/                    # Utilities
```

## Usage

1. **First Time Setup**: Register a new admin account
2. **Login**: Use your email and password to access the admin panel
3. **Add Products**: 
   - Upload a product photo
   - Enter title, description, price, and weight
   - Use voice input for descriptions (tap the microphone icon)
4. **Add Events**:
   - Optionally upload an event photo
   - Enter title, description, location, and date/time
5. **Manage Data**: View, edit, and delete products and events

## Data Structure

### Products Collection
```json
{
  "title": "Product Name",
  "description": "Product description",
  "price": 29.99,
  "weight": 150.0,
  "imageUrl": "https://...",
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "isActive": true
}
```

### Events Collection
```json
{
  "title": "Event Name",
  "description": "Event description",
  "eventDate": "timestamp",
  "location": "Event location",
  "imageUrl": "https://... (optional)",
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "isActive": true
}
```

## Notes

- This admin app pushes data to Firebase, which your Astro site can pull at build time
- All images are optimized and stored in Firebase Storage
- The app includes proper error handling and loading states
- Speech-to-text requires microphone permissions
- Image upload requires camera and storage permissions
