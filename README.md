# Vision AI - Assistive Technology Platform

A comprehensive assistive technology platform that leverages AI to provide inclusive experiences for individuals with disabilities, featuring both a mobile app and a volunteer matching web service.

## 🌟 Overview

Vision AI is an innovative solution designed to improve accessibility and independence for specially-abled individuals through:

1. A **Flutter-based mobile application** with AI-powered assistive features
2. A **Flask-based volunteer matching web platform** that connects users with helpers

This platform aims to create an inclusive ecosystem where technology and human support come together to enhance quality of life for people with various disabilities.

## 📱 Mobile Application Features

### Speech to Image Generation
Convert spoken descriptions into visual representations in real-time.

**How it works:**
1. Navigate to "Speech to Image" from the home screen
2. Tap the microphone and describe what you'd like to visualize
3. The app processes your speech and generates a corresponding image
4. Review the generated image alongside your spoken text

**Technical details:**
- Uses Flutter's `speech_to_text` package for voice recognition
- Supports multiple languages including English and Hindi
- Connects to a generative AI API (pranavai.onrender.com/generate)

### Real-Time Captioning
Convert speech to text instantly for better communication in various environments.

### Voice Generation
Generate natural-sounding speech from text for enhanced communication capabilities.

### Scene Description
Audio description of surroundings through camera input to assist with navigation and spatial awareness.

### Mental Health Support
AI-driven emotional support and resources to help maintain psychological well-being.

### Volunteer Network
Connect with nearby helpers for real-world assistance when needed.

### Learning Resources
Educational content optimized for accessibility with AR/VR experiences.

## 🤝 Volunteer Platform Features

### For Those Seeking Assistance
- Create detailed help requests specifying exact needs
- Choose from various disability and assistance types
- Set preferences for volunteer characteristics
- Schedule assistance for specific dates and durations
- Manage and track request status

### For Volunteers
- Create profiles with skills, availability, and preferences
- Browse and respond to help requests
- Receive real-time notifications about nearby assistance needs
- Track volunteering history and impact
- Receive ratings and feedback to build reputation

### Matching System
- Smart matching algorithm considering location, skills, and preferences
- Real-time availability tracking
- Secure communication channels
- Rating and review system

## 🔧 Technology Stack

### Mobile Application
- **Frontend**: Flutter for cross-platform mobile development
- **Languages**: Dart
- **Authentication**: Firebase Authentication
- **Database**: Firebase Realtime Database
- **AI Features**:
  - Paligenma model for scene detection and navigation assistance
  - Fal.AI Model for real-time image generation
  - Multilingual GenAI-powered Voicebot

### Volunteer Platform
- **Backend**: Flask (Python)
- **Database**: Firebase Realtime Database
- **Authentication**: Firebase Authentication
- **Frontend**: HTML, CSS, JavaScript
- **Maps Integration**: For location-based volunteer matching
- **Notification System**: For real-time alerts

## 🗂 Project Structure

### Mobile App Structure
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

### Volunteer Platform Structure
```
volunteer-platform/
├── app.py                     # Main Flask application
├── templates/                 # HTML templates
├── static/                    # Static assets (CSS, JS, images)
├── instance/                  # Instance-specific configurations
└── requirements.txt           # Python dependencies
```

## 🚀 Installation and Setup

### Mobile Application
```bash
# Clone the repository
git clone https://github.com/yourusername/vision-ai.git

# Navigate to the mobile app directory
cd vision-ai/knowwiz-algoforge

# Install dependencies
flutter pub get

# Run the application
flutter run
```

### Volunteer Platform
```bash
# Navigate to the volunteer platform directory
cd vision-ai/Volunteer

# Create and activate a virtual environment (optional but recommended)
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run the application
python app.py
```

## 🗉 Requirements

### Mobile Application
- Flutter 3.0+
- Dart 2.17+
- Android 6.0+ or iOS 11.0+
- Firebase account with proper configuration

### Volunteer Platform
- Python 3.7+
- Flask
- Firebase Admin SDK
- Modern web browser

## 🔍 Troubleshooting

### Mobile Application
If you encounter Firebase-related errors:
1. Update Firebase dependencies to the latest versions
2. Ensure you have the correct Firebase configuration in your project
3. Try running on a specific platform (e.g., `flutter run -d android` or `flutter run -d ios`)

### Volunteer Platform
If you encounter issues with the volunteer platform:
1. Verify Firebase credentials are correctly set up
2. Check that all required Python packages are installed
3. Ensure proper network connectivity for API communications

## 👥 Contributing

Contributions are welcome! Please feel free to submit a Pull Request or open an Issue with your ideas and suggestions.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Special thanks to all contributors and supporters of this project
- Inspired by the needs of specially-abled individuals in Mumbai and beyond
- Grateful to the open-source community for providing tools and libraries that make this project possible

---

For more information, contact us at support@visionai.org

