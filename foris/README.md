# Foris iOS App

A clean, modern iOS application built with SwiftUI.

## Project Overview

Foris is an iOS application that demonstrates modern iOS development practices using SwiftUI, with a focus on clean architecture and maintainable code.

## Features

- SwiftUI-based user interface
- Network layer with proper error handling
- Comprehensive test coverage
- Clean project structure

## Requirements

- iOS 17.6+
- Xcode 16.0+
- Swift 5.9+

## Getting Started

### Building the Project

1. Clone the repository
2. Open `foris.xcodeproj` in Xcode
3. Select your target device or simulator
4. Press `Cmd+R` to build and run

### Running Tests

```bash
# Run all tests
xcodebuild -scheme foris -configuration Debug test -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# Or use the test script
./Scripts/test.sh
```

### Building for Release

```bash
# Build for release
xcodebuild -scheme foris -configuration Release build

# Or use the build script
./Scripts/build.sh
```

## Project Structure

```
foris/
├── foris/
│   ├── App/                 # App entry point and main views
│   ├── Models/              # Data models
│   ├── ViewModels/          # View models
│   ├── Views/               # SwiftUI views
│   ├── Services/            # Network and business logic
│   └── Resources/           # Assets and configuration
├── forisTests/              # Unit tests
├── Scripts/                 # Build and utility scripts
└── README.md
```

## Architecture

The app follows MVVM (Model-View-ViewModel) architecture:

- **Models**: Data structures and business logic
- **Views**: SwiftUI views for the user interface
- **ViewModels**: Presentation logic and state management
- **Services**: Network layer and external dependencies

## Dependencies

This project uses Swift Package Manager for dependency management. No external dependencies are currently required for basic functionality.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## License

This project is available under the MIT license.