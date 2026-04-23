# NATURaL iOS App - Debug & Startup Checklist

## ✅ Quick Start Testing Guide

### 1. Build & Run
```bash
# Build the project
⌘B (Command + B) in Xcode

# Run on simulator
⌘R (Command + R)

# Run on device
Select your device, then ⌘R
```

### 2. Check Console Output
When the app starts, you should see these messages in the Xcode console:

```
✅ AppState initialized successfully
🔍 Running initialization diagnostics...
✅ HealthKit is available
✅ FeedbackEngine initialized with analyzers
✅ Initialization checks complete
```

### 3. Expected Warning Messages (Normal on Simulator)
```
⚠️ Failed to create CloudKit container: ...
   Falling back to local-only storage.
```
This is **normal** and expected when running on:
- iOS Simulator (CloudKit sync limited)
- Devices without iCloud sign-in
- Development builds without proper CloudKit entitlements

---

## 🐛 Debug Dashboard

In DEBUG builds, tap the **ladybug icon** (🐞) in the top-right corner to open the Debug Dashboard.

### Features:
- **System Information**: Platform, HealthKit status, locale
- **AppState Status**: Workout state, premium status, authorization
- **Managers Status**: All initialized managers
- **CareKit Status**: Prescribed workouts
- **Debug Actions**:
  - Run Full Diagnostics
  - Print Status to Console
  - Clear Workout State

---

## 🧪 Running Tests

### Swift Testing Framework
```bash
# Run all tests
⌘U (Command + U) in Xcode

# Run specific test suite
Click the diamond icon next to @Suite

# View test results
⌘9 (Command + 9) to open Test Navigator
```

### Available Test Suites:
1. **App Initialization Tests**
   - AppState initialization
   - Resumable workout check
   - Persistence container
   - SessionProgressView rendering
   - LocalizedString resolution

2. **Performance Tests**
   - AppState initialization speed
   - SessionProgressView update performance

3. **Diagnostic Tests**
   - System diagnostics
   - Platform information

---

## 🔍 Common Issues & Solutions

### Issue: App crashes on launch
**Check:**
- Console for error messages
- Missing BonhommeCore framework
- SwiftData model schema issues

**Solution:**
1. Clean build folder: ⇧⌘K (Shift + Command + K)
2. Rebuild: ⌘B
3. Check console output for specific errors

### Issue: "Failed to create CloudKit container"
**This is normal on simulator!**
- App automatically falls back to local storage
- All features work except cross-device sync
- On real device with iCloud: check entitlements

### Issue: HealthKit not available
**Check:**
- Running on real device (not simulator)
- Info.plist has HealthKit usage descriptions
- Entitlements include HealthKit capability

### Issue: Missing types/imports
**Check:**
- BonhommeCore framework is properly linked
- All dependencies are resolved
- Build target includes all necessary frameworks

---

## 📊 Initialization Flow

```
1. BonhommeApp.init
   └── Creates @State AppState

2. AppState.init
   ├── HealthKitManager
   ├── SubscriptionManager
   ├── TVDisplayCoordinator
   ├── CareKitBridge
   ├── PhoneConnectivityBridge
   ├── WorkoutStateStore
   ├── FeedbackEngine
   │   ├── HRVAnalyzer
   │   ├── MedicationAnalyzer
   │   └── DockingInsightAnalyzer
   └── MedicationTracker

3. BonhommeApp.body
   └── Creates ModelContainer
       ├── Try CloudKit container
       ├── Fallback to local container
       └── Last resort: in-memory container

4. ContentView.onAppear
   └── checkForResumableWorkout()

5. ContentView.task
   └── performInitializationChecks()
```

---

## 🚀 Performance Benchmarks

Expected initialization times:
- **AppState**: < 1 second
- **ModelContainer**: < 2 seconds (first launch)
- **Total app launch**: < 3 seconds

If initialization takes longer:
1. Check for network delays (CloudKit)
2. Review console for warnings
3. Run performance tests
4. Check device storage/memory

---

## 📝 Debug Console Commands

### Print current state:
Tap "Print Status to Console" in Debug Dashboard

### Clear workout state:
Tap "Clear Workout State" in Debug Dashboard
Or run:
```swift
appState.dismissRestoredWorkout()
```

### Run diagnostics:
Tap "Run Full Diagnostics" in Debug Dashboard

---

## 🔧 Development Tips

### 1. Testing on Simulator
- HealthKit features are limited
- CloudKit sync won't work properly
- Use in-memory storage for quick testing

### 2. Testing on Device
- Full HealthKit integration
- CloudKit sync requires iCloud account
- Better performance metrics

### 3. Debug Builds vs Release
- Debug Dashboard only appears in DEBUG builds
- Release builds have optimizations enabled
- Test both configurations before shipping

### 4. Monitoring Memory
- Use Instruments (⌘I) for memory profiling
- Check for retain cycles in ObservableObject
- Monitor SwiftData container size

---

## ✨ Key Files Modified/Created

### Modified:
- `BonhommeApp.swift`: Enhanced error handling, debug dashboard integration
- `AppState.swift`: Improved initialization with error handling

### Created:
- `AppInitializationTests.swift`: Comprehensive test suite
- `DebugDashboardView.swift`: Real-time debugging UI
- `STARTUP_CHECKLIST.md`: This file

---

## 📞 Need Help?

If you encounter issues:

1. **Check Console Output**: Look for 🔍, ✅, ⚠️, or ❌ emoji markers
2. **Open Debug Dashboard**: Tap the ladybug icon in DEBUG builds
3. **Run Tests**: Press ⌘U to run all tests
4. **Print Diagnostics**: Use the debug dashboard to print full status
5. **Check This Guide**: Review common issues section above

---

## 🎯 Next Steps

After confirming the app initializes correctly:

1. Test core workflows (start workout, view poses)
2. Verify HealthKit integration (on device)
3. Test CareKit prescriptions
4. Validate TV display connection
5. Test background/foreground transitions
6. Verify data persistence across app launches
7. Test on different device sizes (iPhone, iPad)
8. Performance profiling with Instruments

---

**Last Updated**: April 11, 2026  
**Platform**: iOS  
**Framework**: SwiftUI + SwiftData  
**Testing**: Swift Testing Framework
