# EasyMeal - iOS Fitness & Nutrition App

EasyMeal is a comprehensive iOS application designed to help users track their fitness goals, nutrition, and daily activities. Built with SwiftUI and leveraging Firebase for backend services.

## Features

- User Authentication (Email, Google Sign-In)
- Personalized User Profiles
- Workout Tracking
- Meal Planning and Recipes
- Progress Monitoring
- Daily Activity Tracking
- Customizable Goals

## Technical Stack

- SwiftUI
- Firebase (Authentication, Firestore, Storage)
- Core Data
- Google Sign-In
- Swift Package Manager for Dependencies

## Requirements

- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+

## Installation

1. Clone the repository
```bash
git clone https://github.com/YOUR_USERNAME/EasyMeal.git
```

2. Open `EasyMeal.xcodeproj` in Xcode

3. Install dependencies via Swift Package Manager

4. Add your `GoogleService-Info.plist` file to the project

5. Build and run the project

## Configuration

Make sure to configure the following:

1. Firebase setup in your project
2. Google Sign-In credentials
3. Core Data model
4. Required API keys and configurations

## Architecture

The app follows MVVM architecture pattern and uses:
- SwiftUI for UI
- Core Data for local storage
- Firebase for backend services
- Combine for reactive programming

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details 