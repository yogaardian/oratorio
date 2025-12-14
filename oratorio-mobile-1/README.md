# Oratorio Mobile

Oratorio Mobile is a Flutter application designed to provide a seamless user experience for managing personal profiles, logging in, and accessing augmented reality features. This project utilizes state management for user data and connects to a backend service for data persistence.

## Project Structure

```
oratorio-mobile
├── android               # Android platform-specific code
├── ios                   # iOS platform-specific code
├── lib                   # Main application code
│   ├── main.dart        # Entry point of the application
│   ├── profile.dart     # Profile management functionality
│   ├── login.dart       # User login functionality
│   ├── register.dart    # User registration functionality
│   ├── dashboard.dart    # Main dashboard after login
│   ├── ARGalleryPage.dart # Augmented reality gallery
│   ├── ScanARPage.dart   # Scanning augmented reality content
│   └── ARViewPage.dart   # Displaying augmented reality content
├── test                  # Unit and widget tests
├── pubspec.yaml          # Project dependencies and configuration
└── README.md             # Project documentation
```

## Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK
- An IDE (e.g., Visual Studio Code, Android Studio)

### Installation

1. Clone the repository:
   ```
   git clone <repository-url>
   cd oratorio-mobile
   ```

2. Install dependencies:
   ```
   flutter pub get
   ```

3. Run the application:
   ```
   flutter run
   ```

### Features

- **User Authentication**: Users can log in and register for an account.
- **Profile Management**: Users can view and edit their personal information.
- **Augmented Reality**: Access AR features through dedicated pages.

### Tailwind CSS Integration

While Tailwind CSS is primarily a web-based utility-first CSS framework, you can achieve similar styling in Flutter using custom themes or packages that mimic Tailwind's utility classes. For web applications, consider using a web view to integrate Tailwind CSS.

### Contributing

Contributions are welcome! Please open an issue or submit a pull request for any enhancements or bug fixes.

### License

This project is licensed under the MIT License. See the LICENSE file for details.