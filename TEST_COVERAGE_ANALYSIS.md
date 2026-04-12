# Test Coverage Analysis & Improvement Proposals

**Date**: April 12, 2026  
**Scope**: NATURaL/Bonhomme multi-platform biofeedback chair yoga app  
**Current Status**: 29 test files covering ~109 Swift source files (~27% test file ratio)

---

## Executive Summary

The codebase has solid test coverage for core mathematical/analysis modules (entropy, drug response, binding profiles) but significant gaps in:

1. **Cross-cutting orchestration** (FeedbackEngine, SignalAnalyzer pipeline)
2. **HealthKit integration** (authorization, data collection, background delivery)
3. **Service layer** (persistence, music, connectivity, CareKit, subscriptions)
4. **PokeDrug pharmacological framework** (matchup logic, stats, evolution, habitat)
5. **UI components** (visualization views, TV display, motion coaching)
6. **Platform-specific flows** (watch connectivity, SharePlay, TV relay, live activities)

---

## Section 1: Critical Gaps (High Priority)

### 1.1 FeedbackEngine (Analysis Orchestration)
**File**: `BonhommeCore/Sources/BonhommeCore/Analysis/FeedbackEngine.swift`  
**Status**: ❌ No tests  
**Criticality**: 🔴 **Critical**

**What it does**: 
- Central orchestrator for multi-signal analysis pipeline
- Maintains signal buffers per type
- Routes signals to registered SignalAnalyzers
- Provides cross-signal context for correlation

**What's not tested**:
- Buffer lifecycle (appending, overflow, FIFO removal)
- Thread safety (NSLock behavior under concurrent ingestion)
- Analyzer registration and dispatch
- Edge cases: empty buffers, buffer limit boundaries, analyzer exceptions

**Proposed tests**:
```swift
// Test signal buffer overflow behavior
func testBufferOverflow_RemovesOldestSignals()

// Test concurrent signal ingestion
func testConcurrentIngestion_ThreadSafe()

// Test analyzer registration and dispatch
func testAnalyzerRegistration_DispatchesToCorrectType()

// Test cross-signal context propagation
func testAnalyzeAll_ProvidesCrossDomainContext()

// Test edge case: empty analysis
func testAnalyzeAll_WithNoSignals_ReturnsEmptyInsights()
```

---

### 1.2 HRVAnalyzer (Shannon Collapse Index)
**File**: `BonhommeCore/Sources/BonhommeCore/Analysis/HRVAnalyzer.swift`  
**Status**: ❌ No tests  
**Criticality**: 🔴 **Critical**

**What it does**:
- Computes Shannon Collapse Index (SCI) from HRV signals
- Window-based sliding entropy analysis
- Classifies coherence/focus state based on entropy thresholds
- Bilingual summaries (EN/FR-CA)

**What's not tested**:
- Empty signal handling
- Window sliding behavior
- Entropy threshold classification logic
- Trend calculation (improving/stable/declining)
- Localization of summaries
- Integration with EntropyCalculator

**Proposed tests**:
```swift
// Test empty HRV signal handling
func testAnalyze_NoHRVSignals_ReturnsNormalStatus()

// Test entropy threshold classification
func testAnalyze_LowEntropy_ReturnsCoherentStatus()
func testAnalyze_HighEntropy_ReturnsDistractionStatus()

// Test window-based SCI calculation
func testAnalyze_WindowSliding_ComputesCorrectSCI()

// Test trend calculation
func testAnalyze_TrendCalculation_ReturnsImproving()

// Test localization
func testAnalyze_FrenchLocale_ReturnsFrenchSummary()
```

---

### 1.3 HealthKitManager (Authorization & Background Delivery)
**File**: `Bonhomme/Services/HealthKit/HealthKitManager.swift`  
**Status**: ❌ No tests  
**Criticality**: 🔴 **Critical** (user-facing authorization flow)

**What it does**:
- Requests HealthKit authorization for 14+ data types
- Enables background delivery for HRV, HR, sleep, RR, etc.
- Validates capability availability
- Handles entitlement constraints (e.g., no clinical medication records)

**What's not tested**:
- Authorization request success/failure paths
- Background delivery per-type frequency configuration
- Entitlement guard logic (avoiding permanent authorization failure)
- Platform availability checks
- Error propagation (async throws)

**Proposed tests**:
```swift
// Mock HKHealthStore and test authorization flow
func testRequestAuthorization_Succeeds()
func testRequestAuthorization_Throws_PropagatesError()

// Test background delivery setup
func testEnableBackgroundDelivery_ConfiguresAllTypes()
func testEnableBackgroundDelivery_HandlesUnavailableTypes()

// Test platform availability
func testIsAvailable_ReturnsTrueOnSupportedDevice()

// Test clinical record entitlement guard
func testRequestAuthorization_DoesNotIncludeClinicalRecords()
```

---

### 1.4 MedicationAnalyzer
**File**: `BonhommeCore/Sources/BonhommeCore/Analysis/MedicationAnalyzer.swift`  
**Status**: ❌ No tests  
**Criticality**: 🟠 **High**

**What it does**:
- Analyzes medication timing and adherence
- Correlates with HRV response windows
- Implements SignalAnalyzer protocol

**What's not tested**:
- Signal analysis logic
- Empty medication signals
- Cross-correlation with HRV context
- Adherence status classification

---

### 1.5 SignalAnalyzer Protocol Integration Tests
**File**: `BonhommeCore/Sources/BonhommeCore/Analysis/SignalAnalyzer.swift`  
**Status**: ⚠️ Partial (individual analyzers tested, protocol not)  
**Criticality**: 🟠 **High**

**What's not tested**:
- AnalysisContext propagation correctness
- Signal ordering and isolation between analyzer types
- Protocol conformance validation (all analyzers implement correctly)
- Type safety of heterogeneous signal arrays

**Proposed tests** (integration):
```swift
// Test protocol conformance
func testAllAnalyzers_ConformToSignalAnalyzer()

// Test AnalysisContext isolation
func testAnalysisContext_KeepsSignalTypesSeparate()

// Test multi-analyzer pipeline
func testMultipleAnalyzers_ReceiveCorrectContext()
```

---

## Section 2: Major Gaps (Medium-High Priority)

### 2.1 PokeDrug Framework (12 uncovered files)
**Files**: `PokeDrugMatchup.swift`, `PokeDrugStats.swift`, `PokeDrugHabitat.swift`, `PokeDrugEvolution.swift`, `PokeDrugStatComparator.swift`, `PokeDrugSuperaCluster.swift`, `PolypharmacologyAnalyzer.swift`, `DockingInsightAnalyzer.swift`  
**Status**: ❌ 8 of 12 uncovered  
**Criticality**: 🟠 **High** (complex pharmacological logic)

**What's not tested**:
- Type matchup chart effectiveness calculations
- Stat comparison and ranking logic
- Supercluster classification
- Habitat-to-target affinity mapping
- Evolution/phylogeny calculations
- Polypharmacology interactions (multi-drug)
- DockingInsightAnalyzer signal pipeline

**Proposed test suite** (40-60 tests):
```swift
// PokeDrugMatchup coverage
func testEffectiveness_ScaffoldVsTarget()
func testEffectiveness_AllScaffolds_HaveDefinedChart()
func testTypeEffectiveness_Comparable_Works()

// PokeDrugStats coverage
func testStatCalculation_FromSpecimens()
func testStatComparator_RanksCorrectly()
func testStatComparator_TiebreakLogic()

// PokeDrugHabitat coverage
func testHabitatAffinity_ComputesCorrectly()
func testHabitat_EnvironmentMapping()

// PokeDrugEvolution coverage
func testEvolution_ComputesType()
func testEvolution_TraversalOrder()

// PokeDrugSuperaCluster coverage
func testSuperaCluster_ClassifiesMultipleTypes()
func testSuperaCluster_GroupingLogic()

// PolypharmacologyAnalyzer coverage
func testPolypharmacologyAnalyzer_CombinationAnalysis()
func testPolypharmacologyAnalyzer_InteractionDetection()

// DockingInsightAnalyzer coverage
func testDockingInsightAnalyzer_SignalAnalyzerConformance()
```

---

### 2.2 HealthKit Integration Tests (5 uncovered services)
**Files**: `HeartRateMonitor.swift`, `WorkoutRecorder.swift`, `MedicationTracker.swift`, `FitnessPlusReader.swift`, `ActivityRingService.swift`  
**Status**: ❌ All uncovered  
**Criticality**: 🟠 **High** (data acquisition)

**Impact**: These services feed raw signals into FeedbackEngine. Without tests, signal corruption/loss risks.

**Proposed tests** (10-15 per service):
```swift
// HeartRateMonitor
func testHeartRateMonitor_StartsQuery()
func testHeartRateMonitor_HandlesNewData()
func testHeartRateMonitor_HandlesSamplingErrors()

// WorkoutRecorder
func testWorkoutRecorder_BeginsSession()
func testWorkoutRecorder_RecordsHeartRate()
func testWorkoutRecorder_EndsSessionCorrectly()

// MedicationTracker
func testMedicationTracker_FetchesRecords()
func testMedicationTracker_ParsesTimestamps()

// FitnessPlusReader
func testFitnessPlusReader_FetchesSessions()
func testFitnessPlusReader_ConvertsToWorkouts()

// ActivityRingService
func testActivityRingService_FetchesTodaysSummary()
func testActivityRingService_ComputesProgress()
```

---

### 2.3 Persistence & State Management (3 uncovered)
**Files**: `WorkoutStateStore.swift`, `PersistentModels.swift`  
**Status**: ❌ Uncovered  
**Criticality**: 🟠 **High**

**Impact**: SwiftData crash recovery, CloudKit sync, state consistency

**Proposed tests**:
```swift
// WorkoutStateStore
func testWorkoutStateStore_SavesAndReloads()
func testWorkoutStateStore_CrashRecovery()
func testWorkoutStateStore_CloudKitSync_Conflict()

// PersistentModels
func testPersistentModels_Initialization()
func testPersistentModels_CloudKitCoding()
```

---

### 2.4 UI Component Tests (5 uncovered views)
**Files**: `TVDisplayView.swift`, `HeartRateGaugeView.swift`, `PoseCountdownView.swift`, `SCIVisualizationView.swift`, `SessionProgressView.swift`, `MotionCoachView.swift`  
**Status**: ❌ All uncovered  
**Criticality**: 🟡 **Medium** (no snapshot tests, UI testing framework issues)

**Current XCUITest coverage**: `WorkoutFlowUITests.swift`, `AirPlayFallbackUITests.swift` are integration-level, not unit-level.

**Proposed approach** (UI snapshot testing):
```swift
// Use SwiftUI preview snapshots + XCTest
// NOTE: Full pixel-perfect snapshot testing requires Xcode 15.3+ with ViewInspector

// HeartRateGaugeView
func testHeartRateGaugeView_DisplaysValue()
func testHeartRateGaugeView_AnimatesTransition()

// PoseCountdownView
func testPoseCountdownView_ShowsCountdown()
func testPoseCountdownView_CompletionCallback()

// SCIVisualizationView
func testSCIVisualizationView_PlotsDynamically()
```

---

## Section 3: Moderate Gaps (Medium Priority)

### 3.1 Services Without Tests (12 files)
- `CareKitBridge.swift` — CareKit prescription management
- `YogaTaskBuilder.swift` — Task generation
- `MusicService.swift` — Playlist adaptation
- `PhoneConnectivityBridge.swift` — Watch ↔ Phone messaging
- `ChairYogaActivity.swift` — SharePlay session
- `SessionCoordinator.swift` — Collaborative state
- `ResearchKitBridge.swift` — Survey collection
- `SubscriptionManager.swift` — IAP handling
- `WorkoutIntents.swift` — Siri intents

**Severity**: 🟡 **Medium** (mostly integration/glue logic)

**Proposed quick wins**:
```swift
// CareKitBridge (5 tests)
func testCareKitBridge_FetchesPrescriptions()
func testCareKitBridge_UpdatesAdheerence()

// MusicService (5 tests)
func testMusicService_SwitchesPlaylist()
func testMusicService_RespectsCrossfadeDelay()

// PhoneConnectivityBridge (5 tests)
func testPhoneConnectivityBridge_SendsAndReceives()
func testPhoneConnectivityBridge_RecoversFromDisconnect()

// SubscriptionManager (3 tests)
func testSubscriptionManager_FetchesEntitlements()
func testSubscriptionManager_HandlesPurchase()
```

---

### 3.2 Analysis Modules With Partial Coverage
- `AnalysisConfiguration.swift` — Configuration object (no tests)
- `MolecularScaffold.swift` — Scaffold enum (no tests)
- `PharmacokineticProfile.swift` — PK data (no tests)
- `WorkoutMetadata.swift` — Workout metadata (no tests)

**Severity**: 🟡 **Medium** (data-centric, lower risk)

---

## Section 4: Existing Tests (Well-Covered Areas)

✅ **Excellent coverage**:
- `EntropyCalculator` (15+ tests, including SIMD validation)
- `PokeDrugType` & `PokeDrugSpecies` (comprehensive classification)
- `CrossDomainValidator` (molecular ↔ physiological correlation)
- `DrugResponseAnalyzer` (entropy collapse detection)
- `FlexAIDdSAnalyzer` (docking pose analysis)
- `PartitionFunctionCalculator` (Boltzmann ensemble)
- `ThermodynamicBindingProfile` (ΔG/ΔH/-TΔS decomposition)
- `LigandEfficiencyCalculator` (LE/BEI metrics)
- `PopulationPKAnalyzer` (population pharmacokinetics)
- `PoseCatalog` & `Pose` (26 bilingual poses, modifications)
- `LocalizedString` (9-language localization)
- `ProfileConsistencyValidator` (data integrity)
- `SelectivityEntropyAnalyzer` (drug selectivity)
- `EnthalpyEntropyCompensation` (ΔH/ΔS trade-off)
- `EvolutionThermodynamics` (phylogenetic entropy)

✅ **Good integration coverage**:
- `WorkoutFlowViewModelTests` (end-to-end workout flow)
- `TVDisplayCoordinatorTests` (AirPlay + Bonjour relay)
- `WorkoutFlowUITests` (full user journey)
- `AirPlayFallbackUITests` (fallback scenarios)

---

## Section 5: Test Infrastructure & Tooling

### 5.1 Current Setup
- **Framework**: XCTest (no custom runners)
- **Swift version**: 5.9+ (full async/await support)
- **Concurrency**: Tests use `async/await`, `@MainActor`
- **Mocking**: Ad-hoc mocks (no Mockingbird/SwiftMock framework)
- **CI/CD**: None configured

### 5.2 Recommended Additions

#### A. Mock/Spy Framework
```swift
// Current: Manual mocks
final class MockHealthKitManager: HealthKitManager {
    var authorizationWasCalled = false
    func requestAuthorization() async throws {
        authorizationWasCalled = true
    }
}

// Recommendation: Adopt swift-mock or write code-gen mocks
// Example: @GenerateMocks decorator (Xcode 16+)
```

#### B. Parameterized Testing
```swift
// Current: Separate test methods
func testEntropyWithBinCount32()
func testEntropyWithBinCount64()

// Recommendation: Use parameterized tests
@ParameterizedTest(binCounts: [8, 16, 32, 64, 128])
func testEntropy_VariousBinCounts(binCount: Int)
```

#### C. Snapshot Testing
```swift
// Recommendation: Adopt SwiftUI previews + SnapshotTesting
// For UI views: PoseCountdownView, HeartRateGaugeView, etc.
import SnapshotTesting

func testPoseCountdownView_Snapshot() {
    assertSnapshot(of: PoseCountdownView(...), as: .image)
}
```

#### D. Property-Based Testing
```swift
// Recommendation: Adopt swift-check for entropy, correlation tests
import CheckSwift

func testShannon_Entropy_SumsToZeroOrNegative(
    @PropertyTesting probabilities: [Double]
) {
    let entropy = shannonEntropy(probabilities)
    XCTAssertLessThanOrEqual(entropy, 0)  // or some bound
}
```

#### E. CI/CD Integration
```yaml
# Recommended: Add GitHub Actions workflow
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - name: Swift tests
        run: |
          cd BonhommeCore && swift test
      - name: C++ tests
        run: |
          cd BonhommeAccel/build && ctest --output-on-failure
      - name: Xcode tests
        run: xcodebuild test -scheme Bonhomme -destination 'generic/platform=iOS'
```

---

## Section 6: C++ BonhommeAccel Test Coverage

**Status**: ✅ Well-covered (4 Catch2 test files)
- `test_entropy.cpp` — Linear & circular entropy
- `test_correlation.cpp` — Pearson correlation
- `test_pairwise.cpp` — Pairwise distance
- `test_incomplete_beta.cpp` — Statistical function

**Minor gaps**:
- No SIMD backend validation (AVX2/NEON branch coverage)
- No OpenMP parallelism stress tests
- No CUDA/ROCm integration tests (optional backends)

**Proposed additions**:
```cpp
// Backend-specific tests
#ifdef BA_SIMD_AVX2
TEST_CASE("AVX2 backend produces identical results to scalar")
#endif

// Stress testing
TEST_CASE("OpenMP parallelism under high load")
```

---

## Section 7: Test Data & Fixtures

### 7.1 Current Gaps
- No comprehensive fixture library for common scenarios
- Limited edge case coverage (NaN, infinity, empty arrays)
- No performance benchmarking baseline

### 7.2 Recommended Fixtures
```swift
// Create shared test fixtures
struct TestData {
    // Realistic HRV window
    static let normalHRVWindow: [HRVSignal] = [...]
    
    // Drug response envelope
    static let doseResponseWindow: [MedicationSignal] = [...]
    
    // Entropy edge cases
    static let singletonDistribution: [Double] = [1.0]
    static let uniformDistribution: [Double] = Array(repeating: 0.5, count: 2)
    static let nanArray: [Double] = [0, Double.nan, 1]
}

// Use in tests
func testHRVAnalyzer_NormalWindow() {
    let analyzer = HRVAnalyzer()
    let insight = analyzer.analyze(signals: TestData.normalHRVWindow, context: .init())
    XCTAssertEqual(insight.status, .normal)
}
```

---

## Section 8: Prioritized Roadmap

### **Phase 1: Critical (2–3 weeks)**
1. **FeedbackEngine** (8-10 tests) — Buffer, concurrency, dispatch
2. **HRVAnalyzer** (10-12 tests) — Core SCI logic
3. **HealthKitManager** (8-10 tests) — Authorization, background delivery

**Effort**: ~40 test cases, ~1.5–2 weeks  
**Impact**: Unlocks multi-signal pipeline validation

---

### **Phase 2: High Priority (3–4 weeks)**
4. **PokeDrug framework** (40-60 tests) — Type matchup, stats, evolution
5. **HealthKit services** (MedicationTracker, HeartRateMonitor, WorkoutRecorder) (15-20 tests)
6. **MedicationAnalyzer** (8-10 tests)

**Effort**: ~70-90 test cases, ~3–4 weeks  
**Impact**: Validates pharmacological framework, data acquisition

---

### **Phase 3: Medium Priority (2–3 weeks)**
7. **Service layer** (CareKit, Music, Persistence, Connectivity) (20-30 tests)
8. **Partial UI tests** (snapshots for key views) (10-15 tests)

**Effort**: ~40-50 test cases, ~2–3 weeks  
**Impact**: Better service integration, visual regression detection

---

### **Phase 4: Nice-to-Have (1–2 weeks)**
9. **Infrastructure** (CI/CD, parameterized tests, property-based testing)
10. **Remaining minor modules** (scaffolds, configs, metadata)

---

## Section 9: Risk Assessment

### High-Risk Uncovered Areas
| Area | Risk | Coverage |
|------|------|----------|
| FeedbackEngine concurrency | Data race, deadlock | 0% |
| HRVAnalyzer threshold logic | Misclassification, patient safety | 0% |
| HealthKit authorization | App renders unusable if it fails | 0% |
| PokeDrug matchup chart | Incorrect drug recommendations | ~25% |
| Persistence/CloudKit | Data loss on crash or sync conflict | 0% |

### Mitigation Strategy
- **Focus Phase 1–2** on critical/high-risk areas first
- **Add crash recovery tests** for persistence before launch
- **Add integration tests** for FeedbackEngine signal flow
- **Validate PokeDrug matchup** against published binding data

---

## Section 10: Success Metrics

| Metric | Current | Target | Timeline |
|--------|---------|--------|----------|
| Test file count | 29 | 50–60 | 8–10 weeks |
| Test case count | ~150–180 | 400–500 | 8–10 weeks |
| % Coverage (by file) | 27% | 60%+ | 8–10 weeks |
| % Coverage (critical modules) | 75% | 95%+ | 4–6 weeks |
| C++ test count | 50 | 70+ | 2–3 weeks |
| CI/CD passing | ❌ None | ✅ GitHub Actions | 1–2 weeks |

---

## Appendix A: Coverage Visualization

```
BonhommeCore/Analysis/ (34 files)
├── ✅ EntropyCalculator (15+ tests)
├── ✅ DrugResponseAnalyzer (10+ tests)
├── ✅ FlexAIDdSAnalyzer (12+ tests)
├── ✅ CrossDomainValidator (8+ tests)
├── ✅ ThermodynamicBindingProfile (10+ tests)
├── ✅ PartitionFunctionCalculator (8+ tests)
├── ✅ LigandEfficiencyCalculator (6+ tests)
├── ✅ PopulationPKAnalyzer (8+ tests)
├── ✅ ProfileConsistencyValidator (6+ tests)
├── ✅ SelectivityEntropyAnalyzer (6+ tests)
├── ✅ EvolutionThermodynamics (5+ tests)
├── ✅ EnthalpyEntropyCompensation (8+ tests)
├── ✅ HealthSignal (5+ tests)
├── ✅ PokeDrugType (10+ tests)
├── ✅ PokeDrugSpecies (8+ tests)
├── ❌ FeedbackEngine (0 tests)
├── ❌ HRVAnalyzer (0 tests)
├── ❌ MedicationAnalyzer (0 tests)
├── ❌ MolecularScaffold (0 tests)
├── ❌ PharmacokineticProfile (0 tests)
├── ❌ AnalysisConfiguration (0 tests)
├── ❌ DockingInsightAnalyzer (0 tests)
├── ❌ SignalAnalyzer (protocol, partial)
├── ❌ PokeDrugMatchup (0 tests)
├── ❌ PokeDrugStats (0 tests)
├── ❌ PokeDrugStatComparator (0 tests)
├── ❌ PokeDrugHabitat (0 tests)
├── ❌ PokeDrugEvolution (0 tests)
├── ❌ PokeDrugSuperaCluster (0 tests)
├── ❌ PolypharmacologyAnalyzer (0 tests)
└── ❌ BindingEntropyProfile (0 tests)

Bonhomme/Services/HealthKit/ (8 files)
├── ❌ HealthKitManager (0 tests)
├── ❌ HeartRateMonitor (0 tests)
├── ❌ WorkoutRecorder (0 tests)
├── ❌ MedicationTracker (0 tests)
├── ❌ FitnessPlusReader (0 tests)
├── ❌ ActivityRingService (0 tests)
├── ❌ ResearchKitBridge (0 tests)
└── ✅ YogaStyle+HealthKit (minimal, extension)

Bonhomme/Services/Persistence/ (2 files)
├── ❌ WorkoutStateStore (0 tests)
└── ❌ PersistentModels (0 tests)

Bonhomme/Services/ (10 other)
├── ❌ CareKitBridge (0 tests)
├── ❌ YogaTaskBuilder (0 tests)
├── ❌ MusicService (0 tests)
├── ❌ PhoneConnectivityBridge (0 tests)
├── ❌ ChairYogaActivity (0 tests)
├── ❌ SessionCoordinator (0 tests)
├── ❌ SubscriptionManager (0 tests)
├── ❌ Entitlement (0 tests)
└── ❌ WorkoutIntents (0 tests)

BonhommeCore/UI/ (1 file)
└── ❌ MotionCoachView (0 tests)

BonhommeCore/TVDisplay/ (6 files)
├── ✅ TVDisplayPayload (2 tests)
├── ❌ TVDisplayView (0 tests)
├── ❌ HeartRateGaugeView (0 tests)
├── ❌ PoseCountdownView (0 tests)
├── ❌ SCIVisualizationView (0 tests)
└── ❌ SessionProgressView (0 tests)

BonhommeCore/Models/ (4 files)
├── ✅ PoseCatalog (12+ tests)
├── ✅ Pose (10+ tests)
├── ✅ LocalizedString (8+ tests)
└── ❌ WorkoutMetadata (0 tests)

Tests/BonhommeTests/ (2 files)
├── ✅ WorkoutFlowViewModelTests (8+ tests)
└── ✅ TVDisplayCoordinatorTests (6+ tests)

Tests/BonhommeUITests/ (2 files)
├── ✅ WorkoutFlowUITests (integration)
└── ✅ AirPlayFallbackUITests (integration)

BonhommeAccel/tests/ (4 files)
├── ✅ test_entropy.cpp (20+ cases)
├── ✅ test_correlation.cpp (15+ cases)
├── ✅ test_pairwise.cpp (10+ cases)
└── ✅ test_incomplete_beta.cpp (8+ cases)
```

---

## Appendix B: Quick Reference — Where to Add Tests

**If you have 1 day**: Add FeedbackEngine + HRVAnalyzer tests (2 critical classes)

**If you have 1 week**: Add Phase 1 (FeedbackEngine, HRVAnalyzer, HealthKitManager)

**If you have 1 month**: Add Phase 1 + 2 (+ PokeDrug framework + HealthKit services)

**If you have 2 months**: Add Phase 1–3 (includes service layer + basic UI tests)

---

## Appendix C: Test Template

```swift
import XCTest
@testable import BonhommeCore

final class FeedbackEngineTests: XCTestCase {
    var engine: FeedbackEngine!
    
    override func setUp() {
        super.setUp()
        engine = FeedbackEngine(bufferLimit: 100)
    }
    
    override func tearDown() {
        engine = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func testIngest_AppendsSignalToBuffer() throws {
        let signal = MockHRVSignal()
        engine.ingest(signal)
        // Assert signal was buffered
    }
    
    func testIngest_BufferOverflow_RemovesOldest() throws {
        for i in 0..<101 {
            engine.ingest(MockHRVSignal(timestamp: Date().addingTimeInterval(TimeInterval(i))))
        }
        // Assert only last 100 remain
    }
    
    func testIngest_Concurrent_ThreadSafe() async throws {
        let signal = MockHRVSignal()
        await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    engine.ingest(signal)
                }
            }
            try await group.waitForAll()
        }
        // Assert no crashes, all ingested
    }
}

// MARK: - Mocks

struct MockHRVSignal: HealthSignal {
    static var signalType: SignalType = .heartRateVariability
    let timestamp: Date
    let value: Double = 50
    
    init(timestamp: Date = Date()) {
        self.timestamp = timestamp
    }
}
```

---

**Document prepared**: April 12, 2026  
**Recommendation**: Start with Phase 1 (FeedbackEngine, HRVAnalyzer, HealthKitManager) for immediate impact on system stability.
