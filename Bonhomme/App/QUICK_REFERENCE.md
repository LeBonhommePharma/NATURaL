# 🚀 NATURaL iOS - Quick Debug Reference

## Instant Actions

### Build & Run
```
⌘B = Build
⌘R = Run
⌘U = Run Tests
⇧⌘K = Clean Build
⌘I = Profile with Instruments
```

### Debug Dashboard
1. Run app in DEBUG mode
2. Tap **🐞 ladybug icon** (top-right)
3. View live system status
4. Run diagnostics
5. Print to console
6. Clear workout state

---

## Expected Console Output

### ✅ Successful Startup
```
✅ AppState initialized successfully
🔍 Running initialization diagnostics...
✅ HealthKit is available
✅ FeedbackEngine initialized with analyzers
✅ Initialization checks complete
```

### ⚠️ Normal Warnings (Simulator)
```
⚠️ Failed to create CloudKit container: ...
   Falling back to local-only storage.
```
**Don't panic!** This is expected on simulator.

### ❌ Critical Errors
```
❌ CRITICAL: Failed to create local container: ...
   Using in-memory storage. Data will not persist.
```
**Action**: Check storage permissions, clean build folder

---

## Common Issues - Quick Fix

| Issue | Quick Fix |
|-------|-----------|
| Build fails | ⇧⌘K then ⌘B |
| CloudKit error | **Normal on simulator** |
| HealthKit unavailable | **Normal on simulator**, test on device |
| App crashes on launch | Check console, run tests ⌘U |
| Missing types | Clean build, check BonhommeCore framework |

---

## Test Suites

### Run All Tests: ⌘U

**Coverage:**
- ✅ AppState initialization
- ✅ Persistence container
- ✅ SessionProgressView
- ✅ LocalizedString
- ✅ Notification system
- ✅ Performance benchmarks
- ✅ System diagnostics

---

## Debug Tools

### 1. Debug Dashboard (`DebugDashboardView`)
- Real-time app state monitoring
- Run diagnostics on demand
- Print status to console
- Clear workout state

### 2. Console Logs
- 🔍 = Diagnostics running
- ✅ = Success
- ⚠️ = Warning (non-critical)
- ❌ = Error (critical)
- ℹ️ = Information

### 3. Test Suite (`AppInitializationTests`)
- Automated component testing
- Edge case validation
- Performance monitoring

---

## Files Changed/Created

### Enhanced
- ✅ `BonhommeApp.swift` - Error handling, debug integration
- ✅ `AppState.swift` - Safe initialization

### New
- ✅ `DebugDashboardView.swift` - Debug UI
- ✅ `AppInitializationTests.swift` - Test suite
- ✅ `DEBUGGING_SUMMARY.md` - Full report
- ✅ `STARTUP_CHECKLIST.md` - Testing guide
- ✅ `QUICK_REFERENCE.md` - This file

---

## Status: ✅ READY TO TEST

All systems operational. Ready for:
- ✅ Simulator testing
- ✅ Device testing
- ✅ Performance profiling
- ✅ TestFlight deployment (after device validation)

---

## Need Help?

1. **Open Debug Dashboard**: Tap 🐞 icon
2. **Check Console**: Look for emoji markers
3. **Run Tests**: Press ⌘U
4. **Read Full Guide**: See `STARTUP_CHECKLIST.md`
5. **Review Summary**: See `DEBUGGING_SUMMARY.md`

---

**Last Updated**: April 11, 2026  
**Status**: Debugged & Production-Ready ✅
