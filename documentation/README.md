# Choice Agent App

A Flutter application for collection agents with Provider state management and offline-first architecture.

## 📚 Documentation

ഈ project-ന് മൂന്നു documentation files ഉണ്ട്:

### For Developers
- **[FLUTTER_PROJECT_ARCHITECTURE.md](FLUTTER_PROJECT_ARCHITECTURE.md)** - സമ്പൂർണ്ണമായ architecture guide
- **[ARCHITECTURE_QUICK_REFERENCE.md](ARCHITECTURE_QUICK_REFERENCE.md)** - Daily development quick reference

### For AI Agents
- **[.agent-instructions.md](.agent-instructions.md)** - AI agents-ന് വേണ്ടിയുള്ള instructions

---

## 🚀 Getting Started

### Prerequisites
```bash
Flutter SDK: >=3.0.0
Dart SDK: >=3.0.0
```

### Installation

1. **Clone the repository**
```bash
git clone <repository-url>
cd choice_agent_app
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Generate code (for Drift database)**
```bash
flutter pub run build_runner build
```

4. **Run the app**
```bash
flutter run
```

---

## 🏗️ Project Architecture

**State Management:** Provider  
**Architecture:** MVVM-like pattern  
**Local Database:** Drift (SQLite)  
**HTTP Client:** http package

### Folder Structure
```
lib/
├── core/theme/          # Colors, text styles, theming
├── constants/           # API endpoints, assets, strings
├── data/models/         # Data models
├── database/            # Drift database tables
├── presentation/
│   ├── providers/       # State management
│   ├── screens/         # UI screens
│   └── widgets/         # Reusable widgets
├── services/            # API services
└── utils/               # Utility functions
```

📖 **For detailed architecture:** Read [FLUTTER_PROJECT_ARCHITECTURE.md](FLUTTER_PROJECT_ARCHITECTURE.md)

---

## 📝 Development Guidelines

### Creating a New Feature

1. Create model in `lib/data/models/`
2. Create provider in `lib/presentation/providers/`
3. Create screen in `lib/presentation/screens/[feature]/`
4. Register provider in `main.dart`
5. Follow the patterns in `.agent-instructions.md`

### Code Standards

✅ **Always:**
- Use Provider for state management
- Handle loading, error, and empty states
- Use theme constants (never hardcode colors/styles)
- Follow null safety guidelines
- Break complex widgets into smaller methods
- Add meaningful comments

❌ **Never:**
- Hardcode colors or text styles
- Use `StatefulWidget` when Provider can handle it
- Forget error handling
- Skip null checks

📋 **Daily Reference:** [ARCHITECTURE_QUICK_REFERENCE.md](ARCHITECTURE_QUICK_REFERENCE.md)

---

## 🛠️ Build & Deploy

### Debug Build
```bash
flutter run
```

### Release Build (Android)
```bash
flutter build apk --release
```

### Release Build (iOS)
```bash
flutter build ios --release
```

### Run Tests
```bash
flutter test
```

---

## 📦 Key Dependencies

```yaml
provider: ^6.0.0           # State management
http: ^1.1.0               # HTTP client
drift: ^2.13.0             # Local database
shared_preferences: ^2.2.0 # Key-value storage
intl: ^0.18.0              # Internationalization
flutter_svg: ^2.0.0        # SVG support
```

---

## 🤖 AI-Assisted Development

ഈ project AI agents (GitHub Copilot, ChatGPT) use ചെയ്ത് develop ചെയ്യാൻ optimized ആണ്.

### Usage:
```
"Create a new feature called 'Orders' following .agent-instructions.md"
"Add a payment history screen following the architecture in FLUTTER_PROJECT_ARCHITECTURE.md"
```

---

## 📱 Features

- ✅ Collection History
- ✅ EMI Collection (Bank/Cash/UPI)
- ✅ Customer Details
- ✅ Route Management
- ✅ Offline Support
- ✅ Agent Reminders
- ✅ Document Upload
- ✅ Payment Tracking

---

## 🔧 Troubleshooting

### Common Issues

**Build Runner Errors:**
```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

**Provider Not Found:**
- Make sure provider is registered in `main.dart`
- Check if you're using correct `context`

**Database Issues:**
- Delete app and reinstall
- Clear app data
- Regenerate database code

---

## 👥 Team Guidelines

### For New Team Members:
1. Read [FLUTTER_PROJECT_ARCHITECTURE.md](FLUTTER_PROJECT_ARCHITECTURE.md) (45 mins)
2. Explore existing features
3. Create a simple feature following the templates
4. Get code reviewed

### For Code Reviews:
- Check against [ARCHITECTURE_QUICK_REFERENCE.md](ARCHITECTURE_QUICK_REFERENCE.md)
- Verify folder structure
- Ensure error handling
- Check for hardcoded values

---

## 📄 License

[Add your license here]

---

## 📞 Support

For questions or issues:
- Check documentation files
- Ask team lead
- Update docs if you find gaps

---

**Documentation Last Updated:** June 2026  
**Project Version:** 1.0.0

---

## Quick Links

- 📘 [Full Architecture Guide](FLUTTER_PROJECT_ARCHITECTURE.md)
- 📋 [Quick Reference](ARCHITECTURE_QUICK_REFERENCE.md)
- 🤖 [AI Agent Instructions](.agent-instructions.md)
- 📝 [User Stories](user_stories.md)
