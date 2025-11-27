# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

GYMRar is an iOS fitness tracking app built with SwiftUI and SwiftData. It helps users manage gym routines, log workouts, track exercises with machine calibrations, and generate routines using Apple's Foundation Models (iOS 26+).

**Tech Stack**: Swift 6, SwiftUI, SwiftData, FoundationModels (iOS 26+)
**Minimum Target**: iOS 18+ (iOS 26+ required for AI features)
**No external dependencies** - pure Apple frameworks

## Build Commands

```bash
# Build the project
xcodebuild -scheme GYMRar -configuration Release

# Build for simulator
xcodebuild -scheme GYMRar -destination 'platform=iOS Simulator,name=iPhone 16'
```

No tests or linting configured currently.

## Architecture

### Data Layer (SwiftData)
- **Gym** → has Routines, Calibrations, Workouts
- **Routine** → **RoutineDay** → **RoutineItem** (exercise references with sets/reps/progression)
- **Workout** → **WorkoutSet** (logged entries with weight/reps/rpe)
- **Exercise** → catalog with muscle groups
- **Calibration** → machine weight mapping: `real = a × marked + b`

### Key Files
- `GYMRarApp.swift` - Entry point, ModelContainer setup with auto-migration recovery
- `Models/DomainModels.swift` - All SwiftData @Model classes
- `Models/RoutineEngine.swift` - `LocalRulesEngine` for routine generation & progression logic
- `Models/UnitHelpers.swift` - `CalibrationMath` and `UnitConv` for weight calculations
- `Views/LogWorkoutView.swift` - Draft pattern for workout logging with calibration lookup
- `Views/RoutineBuilderView.swift` - Routine CRUD with AI generation integration
- `AI/FoundationAIService.swift` - Apple Foundation Models integration (iOS 26+)

### Patterns Used
- **Draft Pattern**: LogWorkoutView and RoutineBuilderView use draft structs before committing to SwiftData
- **@Query**: Reactive data binding from SwiftData
- **AIHolder**: Lazy initialization pattern for FoundationModels (avoids loading on older iOS)
- **Progression Logic**: Double progression at ±2.5% weight boundaries

### Tab Structure
1. Today - Start workout from routine
2. Routines - CRUD routines (with AI generation)
3. Gyms - Manage gyms & machine calibrations
4. History - Browse logged workouts
5. Settings - Default weight unit

## Key Implementation Details

### Machine Calibration Formula
```
real = a × marked + b
```
Where `a` is multiplier, `b` is offset. Used in LogWorkoutView for real weight display.

### Unit Conversion
```swift
1 kg = 2.20462 lb  // conversion factor: 0.45359237
```

### AI Features (iOS 26+)
Wrap in `#available(iOS 26, *)` guards. Uses guided generation with `@Generable` macros on `RoutineDraft` struct.

### SwiftData Migration
On migration failure, the app removes the corrupted store and reinitializes. Schema defined in `GYMRarApp.makeContainer()`.

## Conventions

- Spanish comments/prompts in AI-related code (coach-themed)
- Silent error handling with `try?` in many places
- Haptic feedback via `.sensoryFeedback()` modifier
- `@Bindable` for SwiftData model binding in forms
