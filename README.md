# Vision AI

Vision AI is an AI-powered assistive platform designed to enhance accessibility and independence for specially-abled individuals. Instead of relying on fragmented tools, Vision AI integrates multiple adaptive features into a single, real-time support system, addressing challenges related to communication, navigation, learning, and mental well-being.

## Key Features

- **Real-Time Captioning for Audio-Impaired Users**: Converts speech into text for seamless communication.
- **AI-Powered Voice Generation for Non-Verbal Users**: Generates natural-sounding speech from text input based on AI recommendations.
- **Real-Time Audio Description of Surroundings for Visually Impaired Users**: Provides AI-powered scene recognition and voice-based guidance.
- **AI-Driven Mental Health Assistance**: Uses sentiment analysis to offer emotional support.
- **Location-Based Volunteering Network**: Connects users with nearby volunteers for real-time assistance.
- **Imagination Enhancement & Learning Resources**: Uses AI-generated images and personalized educational content for special education.

## Technology Stack

- **Frontend**: Flutter for cross-platform mobile app development
- **Backend**: Flask for API services
- **Database**: Firebase for real-time data storage and authentication
- **AI Models**:
  - Paligenma model for scene detection, assisting blind users with navigation
  - Fal.AI Model for real-time visual image generation
  - Real-time, multilingual GenAI-powered Voicebot for personalized assistance
- **AR/VR**: Google ARKit for creating engaging, interactive educational experiences

## Getting Started

### Prerequisites

- Flutter SDK (version 3.0.0 or higher)
- Dart SDK (version 3.0.0 or higher)
- Android Studio or VS Code with Flutter extensions
- Firebase account for backend services

### Installation

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/visionai.git
   ```

2. Navigate to the project directory:
   ```
   cd visionai
   ```

3. Install dependencies:
   ```
   flutter pub get
   ```

4. Run the app:
   ```
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart                  # Entry point of the application
├── theme/                     # Theme configuration
├── screens/                   # All app screens
│   ├── auth/                  # Authentication screens
│   ├── features/              # Feature-specific screens
│   ├── home/                  # Home screen
│   ├── onboarding/            # Onboarding screens
│   └── profile/               # User profile screens
├── widgets/                   # Reusable widgets
├── models/                    # Data models
├── services/                  # API and other services
└── utils/                     # Utility functions and constants
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Special thanks to all contributors and supporters of this project
- Inspired by the needs of specially-abled individuals in Mumbai and beyond
