# Marketing KBM App

Marketing KBM is a comprehensive specialized application for **KBM Indonesia Group**, designed to facilitate marketing operations, sales entries, and administrative management for **Penerbitan** (Red) and **KBM Creator** (Blue).

## 🚀 Features

### for Marketing Agents (Users)
*   **Quick Sales Entry**: Dedicated forms for **Penerbitan** (Sales R1) and **KBM Creator** (Sales R2).
*   **Dual-Brand Catalog**: Browse products / packages with a dynamic UI that adapts to the selected category (Red/Blue theme).
*   **Link Bio**: Create and manage a professional "Digital Card" / Link in Bio to share with customers.
*   **Wallet & Withdrawals**: Track commissions, pulsa balance, and request withdrawals.
*   **Profile Management**: Manage personal details and bank account information.
*   **Dark Mode Support**: Fully responsive dark mode for comfortable usage in low light.

### for Admins
*   **Dashboard Overview**: Real-time stats on sales and user activity.
*   **Product Management**: Add, edit, and delete products in the Catalog.
*   **Transaction Management**: Verify and approve sales entries.
*   **User Management**: Manage registered agents.
*   **Withdrawal Processing**: Process payout requests.

## 🛠️ Tech Stack

*   **Framework**: Flutter (Web Optimized)
*   **Language**: Dart
*   **Backend**: Firebase (Auth, Firestore, Hosting)
*   **State Management**: Provider
*   **Design**: Custom "Outfit" Font, Dynamic Theming (Red/Blue/Dark)

## 📦 Setup & Installation

1.  **Clone the repository**
    ```bash
    git clone https://github.com/Start-KBM-Indonesia/marketing_kbm_app.git
    cd marketing_kbm_app
    ```

2.  **Install Dependencies**
    ```bash
    flutter pub get
    ```

3.  **Run Locally**
    ```bash
    flutter run -d chrome
    ```

## 🚀 Deployment

The application is deployed on Firebase Hosting.

**Live URL**: [https://marketing-kbm-app.web.app](https://marketing-kbm-app.web.app)

To deploy updates:
```bash
flutter build web --release
firebase deploy --only hosting
```

## 🔥 Firebase Configuration (For Open Source Usage)

This repository does **not** include the Firebase credential files (`google-services.json` and `firebase_options.dart`) for security reasons.

If you are cloning this repository to use for your own project, you must reconfigure Firebase:
1. Install Firebase CLI: `npm install -g firebase-tools`
2. Login to your Firebase account: `firebase login`
3. Activate FlutterFire CLI: `dart pub global activate flutterfire_cli`
4. Run configuration to generate credentials for your own Firebase project:
   ```bash
   flutterfire configure
   ```
   *This will automatically generate `lib/firebase_options.dart` and `android/app/google-services.json`.*

## 🔑 Google Sign-In Configuration

For Google Sign-In to work, the hosting domain requires specific configuration in Google Cloud Console:
*   **Console**: [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
*   **Authorized Redirect URI**: `https://marketing-kbm-app.web.app/__/auth/handler`

---
© 2025 KBM Indonesia Group
