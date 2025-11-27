# GYMRar 🏋️

A modern iOS workout tracking application with AI-powered routine generation, built with SwiftUI and SwiftData.

## Features

### 🎯 Core Functionality

- **Workout Logging**: Track sets, reps, weight, RPE, and notes for every exercise
- **Routine Management**: Create and edit workout routines with customizable splits
- **Exercise Catalog**: Comprehensive exercise database organized by muscle groups
- **Gym Management**: Manage multiple gym locations with machine-specific calibrations
- **History Tracking**: View complete workout history with detailed performance data
- **Today View**: Quick access to today's scheduled workout from your active routine

### 🤖 AI-Powered Features (iOS 26+)

Leveraging Apple's Foundation Models framework:

- **Intelligent Routine Generation**: Create workout routines using natural language prompts
- **Routine Modification**: Ask AI to adjust existing routines based on your needs
- **Equipment Adaptation**: Automatically adapt routines to available equipment
- **Smart Exercise Selection**: AI uses your exercise catalog to build appropriate programs
- **Real-time Streaming**: Watch your routine being generated in real-time

### 📊 Advanced Training Features

- **Multiple Split Types**:
  - Upper/Lower
  - Push/Pull/Legs
  - Full Body
  - Bro Split (5-day)
  - Custom

- **Progression Tracking**:
  - Double progression
  - Linear small load progression
  - Automatic load suggestions based on rep performance

- **Machine Calibration**:
  - Gym-specific machine calibrations
  - Linear formula support: `real weight = a × marked + b`
  - Track aliases for machines at different gyms

- **Flexible Units**:
  - Support for both kg and lb
  - Gym-specific default units
  - Exercise-specific unit overrides

## Technical Stack

- **Language**: Swift
- **UI Framework**: SwiftUI
- **Data Persistence**: SwiftData (iOS 17+)
- **AI Integration**: FoundationModels (iOS 26+)
- **Minimum iOS Version**: iOS 17.0

## Project Structure

```
GYMRar/
├── AI/
│   ├── FoundationAIService.swift      # AI service with streaming support
│   └── InventoryTool.swift            # Tool for AI to access exercise catalog
├── Models/
│   ├── DomainModels.swift             # Core data models (SwiftData)
│   ├── RoutineEngine.swift            # Template generators & progression logic
│   ├── DataSeeder.swift               # Initial data seeding
│   └── UnitHelpers.swift              # Unit conversion utilities
├── Views/
│   ├── RootView.swift                 # Main tab navigation
│   ├── TodayView.swift                # Today's workout overview
│   ├── LogWorkoutView.swift           # Active workout logging
│   ├── RoutineBuilderView.swift       # Routine creation/editing
│   ├── RoutineListView.swift          # All routines overview
│   ├── GymsView.swift                 # Gym & calibration management
│   ├── HistoryView.swift              # Workout history
│   ├── SettingsView.swift             # App settings
│   ├── ExercisePickerView.swift       # Exercise selection interface
│   ├── AIPromptSheet.swift            # AI prompt interface
│   └── AIPreviewOverlay.swift         # Real-time AI generation preview
└── Resources/
```

## Data Models

### Core Entities

- **`Gym`**: Gym locations with default weight units and location notes
- **`Calibration`**: Machine-specific weight calibrations for accurate tracking
- **`Exercise`**: Exercise catalog with muscle group classification
- **`Routine`**: Workout programs with multiple training days
- **`RoutineDay`**: Individual training days within a routine
- **`RoutineItem`**: Specific exercises with set/rep schemes and progression rules
- **`Workout`**: Logged workout sessions with date and gym info
- **`WorkoutSet`**: Individual logged sets with weight, reps, and RPE

### Enumerations

- **`MuscleGroup`**: chest, back, shoulders, biceps, triceps, quads, hamstrings, glutes, calves, core, other
- **`WeightUnit`**: kg, lb
- **`SplitType`**: Upper/Lower, Push/Pull/Legs, Full Body, Bro Split, Custom
- **`ProgressionRule`**: doubleProgression, linearSmallLoad

## AI System Architecture

The AI system uses Apple's Foundation Models with guided generation to ensure structured output:

### 1. **RoutineDraft Generation**

The AI generates type-safe `RoutineDraft` structures that include:
- Routine name
- Multiple training days with labels
- Exercise items with sets, rep ranges, and units

### 2. **Context Awareness**

The AI has access to:
- Current routine (for modifications)
- Available exercises in the catalog
- User's prompt/requirements
- Gym equipment limitations (via InventoryTool)

### 3. **Streaming UI**

Real-time preview of AI-generated content as it streams:
- Live updates during generation
- Immediate feedback on exercise selection
- Transparent generation process

## Getting Started

### Prerequisites

- macOS 14.0 or later
- Xcode 15.0 or later
- iOS 17.0+ device or simulator
- For AI features: iOS 26.0+ device

### Building the Project

1. Clone the repository:
```bash
git clone https://github.com/yourusername/GYMRar.git
cd GYMRar
```

2. Open the project in Xcode:
```bash
open GYMRar.xcodeproj
```

3. Select your target device/simulator

4. Build and run (⌘R)

### First Launch

On first launch, the app will:
- Create the SwiftData store in Application Support
- Seed initial exercise catalog
- Initialize default settings

## Usage

### Creating Your First Routine

1. Navigate to the **Routines** tab
2. Tap **"+"** to create a new routine
3. Choose between:
   - **Template**: Select a pre-built split type
   - **Custom**: Build from scratch
   - **AI Assistant** (iOS 26+): Describe what you want in natural language

### Using AI to Generate Routines

Example prompts:
- "Create a 4-day upper/lower split focused on strength"
- "Build me a push/pull/legs routine with only dumbbell exercises"
- "Add more shoulder work to my current routine"
- "Adapt this for home gym with just a barbell and bench"

### Logging a Workout

1. Go to **Today** tab
2. Select your active routine
3. Tap **Start Workout**
4. Log each set with weight, reps, and optional RPE
5. Add notes for specific sets if needed
6. Complete workout to save to history

### Managing Gyms & Calibrations

1. Navigate to **Gyms** tab
2. Add your gym locations
3. For each machine that needs calibration:
   - Create a calibration entry
   - Set the linear formula coefficients (a, b)
   - Add an alias for easy identification

## Data Storage

- **Location**: `~/Library/Application Support/default.store`
- **Format**: SwiftData binary format
- **Migration**: Automatic schema migration with fallback to reset on failure

## Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is created by Alejandro Gonzalez. All rights reserved.

## Acknowledgments

- Built with Apple's latest frameworks: SwiftUI, SwiftData, and FoundationModels
- Inspired by evidence-based training principles
- Designed for serious lifters who value data-driven progress

---

**Note**: AI features require iOS 26.0 or later and are powered by Apple's Foundation Models framework. The app gracefully degrades functionality on older iOS versions while maintaining core workout tracking capabilities.

Link to the repo!
https://github.com/AlejandroSpot2/GYMRar