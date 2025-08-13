# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Flutter Commands
- `flutter run` - Run the app on connected device
- `flutter run -d chrome` - Run on Chrome browser
- `flutter run -d windows` - Run on Windows desktop
- `flutter build apk` - Build Android APK
- `flutter build windows` - Build Windows executable
- `flutter analyze` - Run static analysis
- `flutter test` - Run unit tests
- `flutter clean` - Clean build artifacts
- `flutter pub get` - Install dependencies
- `flutter pub upgrade` - Upgrade dependencies

### Code Generation Commands
- `flutter packages pub run build_runner build` - Generate Riverpod providers and other generated code
- `flutter packages pub run build_runner build --delete-conflicting-outputs` - Force regenerate with conflicts resolution
- `flutter packages pub run build_runner watch` - Watch for changes and auto-generate code

## Architecture Overview

This is a Flutter application using **Clean Architecture** principles with the following structure:

### Core Architecture Components

**State Management**: Uses Riverpod 2.x with code generation for providers
- All providers use `@riverpod` annotation and code generation
- Global container (`globalContainer`) accessible from `main.dart`
- Authentication state managed through `authStateProvider`

**Navigation**: Go Router with declarative routing
- Route definitions in `lib/core/navigation/app_router.dart`
- Protected routes using authentication guards
- Guest mode support with separate routing flow

**Database**: SQLite with SQFlite
- Local-first approach with offline capabilities
- Database helper singleton pattern in `lib/core/database/database_helper.dart`
- Cross-platform support (Windows/Linux/macOS uses FFI, mobile uses standard SQLite)

**Network**: Dio HTTP client with connectivity monitoring
- Offline/online mode detection
- Automatic sync when connectivity restored
- Pending operations stored locally when offline

### Feature Structure
Each feature follows this pattern:
```
lib/features/{feature_name}/
  ├── providers/          # Riverpod providers
  ├── screens/           # UI screens
  ├── widgets/           # Feature-specific widgets
  └── services/          # Business logic services
```

### Key Features
- **Affiliates Management**: Member registration and management
- **Contributions**: Financial contributions tracking
- **Fines**: Penalty system with categories (Varios, Retraso, Falta)
- **Attendance**: Meeting attendance with QR scanning
- **Authentication**: Login/register with guest mode support
- **Reports**: PDF generation for financial reports
- **Settings**: Configuration management with Cloudinary integration

### Data Models
Located in `lib/data/models/`, all models include:
- UUID-based primary keys
- Timestamp tracking (created_at, updated_at)
- JSON serialization methods
- Database mapping functions

### Repository Pattern
- Data repositories in `lib/data/repositories/`
- Abstract interfaces with concrete SQLite implementations
- Handles both local storage and API synchronization

## Important Implementation Details

### Offline-First Design
- All operations work offline and sync when online
- Pending operations stored in `pending_operations` table
- SyncService handles bidirectional synchronization
- Connectivity provider monitors network status

### Authentication Flow
- Supports both admin users and guest mode
- Guest mode allows limited affiliate self-service
- JWT token storage in SharedPreferences
- Route guards based on authentication state

### Database Schema
Key tables:
- `users` - System users (admins)
- `affiliates` - Organization members
- `contributions` - Financial contributions
- `contribution_affiliates` - Many-to-many relationship
- `fines` - Penalty records
- `attendance_lists` - Meeting attendance tracking
- `pending_operations` - Offline operation queue

### Theme System
- Material Design 3 theming
- Light/dark mode support
- Theme state managed via Riverpod

## Code Generation Requirements

When modifying providers or data models, always run code generation:
1. Make changes to files with `@riverpod` annotations or data models
2. Run `flutter packages pub run build_runner build`
3. Commit both source files and generated files

## Testing

Currently using Flutter's built-in testing framework. Run tests with `flutter test`.

## Platform Support

- **Android**: Primary platform
- **Windows**: Desktop support with FFI SQLite
- **Web**: Chrome support available
- **iOS/macOS**: Architecture supports but requires additional setup

## Dependencies Notes

### Key Dependencies
- **flutter_riverpod**: State management with code generation
- **go_router**: Declarative navigation
- **sqflite**: Local database (with FFI variants for desktop)
- **dio**: HTTP client for API communication
- **connectivity_plus**: Network status monitoring
- **pdf/printing**: Report generation
- **cloudinary_public**: Image upload service
- **qr_code_scanner_plus**: QR code scanning for attendance

### Development Dependencies  
- **build_runner**: Code generation
- **riverpod_generator**: Provider code generation
- **flutter_lints**: Static analysis rules