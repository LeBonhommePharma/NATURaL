.PHONY: all build test lint lint-fix clean coverage xcode-build xcode-test \
	accel-configure accel-build accel-test accel accel-clean help

# Default target
all: lint test build

# --- BonhommeCore (Swift Package) — Path A: Swift-only (default) ---
# Does NOT build or link BonhommeAccel C++. Keep it that way.

build: ## Build BonhommeCore package
	swift build --package-path BonhommeCore

test: ## Run BonhommeCore tests (Swift-only; no Accel CMake)
	swift test --package-path BonhommeCore

coverage: ## Run tests with code coverage
	swift test --package-path BonhommeCore --enable-code-coverage
	@PROF=$$(find BonhommeCore/.build -name 'default.profdata' 2>/dev/null | head -1); \
	BIN=$$(find BonhommeCore/.build -name 'BonhommeCorePackageTests.xctest' -o -name 'BonhommeCorePackageTests' 2>/dev/null | head -1); \
	if [ -n "$$PROF" ] && [ -n "$$BIN" ]; then \
		xcrun llvm-cov report "$$BIN" -instr-profile="$$PROF"; \
	else \
		echo "Coverage data not found"; \
	fi

# --- BonhommeAccel (C++20) — Path B: CMake + ctest (opt-in) ---
# Separate from `make test`. Full docs: BonhommeAccel/TESTING.md

ACCEL_DIR := BonhommeAccel
ACCEL_BUILD := $(ACCEL_DIR)/build
ACCEL_JOBS := $(shell sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 4)

accel-configure: ## Configure BonhommeAccel (CMake, tests ON)
	cmake -B $(ACCEL_BUILD) -S $(ACCEL_DIR) -DCMAKE_BUILD_TYPE=Release -DBA_BUILD_TESTS=ON

accel-build: ## Build BonhommeAccel library + ba_tests
	cmake --build $(ACCEL_BUILD) -j $(ACCEL_JOBS)

accel-test: ## Run BonhommeAccel Catch2 suite via ctest
	ctest --test-dir $(ACCEL_BUILD) --output-on-failure

accel: accel-configure accel-build accel-test ## Configure, build, and ctest Accel

accel-clean: ## Remove BonhommeAccel build tree
	rm -rf $(ACCEL_BUILD)

# --- Xcode Project ---

xcode-build: ## Build iOS app via xcodebuild
	xcodebuild build \
		-project NATURaL.xcodeproj \
		-scheme Bonhomme \
		-destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
		-configuration Debug \
		CODE_SIGNING_ALLOWED=NO

xcode-test: ## Run iOS app tests via xcodebuild
	xcodebuild test \
		-project NATURaL.xcodeproj \
		-scheme Bonhomme \
		-destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
		-configuration Debug \
		-enableCodeCoverage YES \
		CODE_SIGNING_ALLOWED=NO

# --- Code Quality ---

lint: ## Run SwiftLint
	swiftlint lint

lint-fix: ## Run SwiftLint with auto-fix
	swiftlint lint --fix

# --- Cleanup ---

clean: ## Remove build artifacts (Swift + Accel + Xcode debris)
	rm -rf BonhommeCore/.build
	rm -rf $(ACCEL_BUILD)
	rm -rf DerivedData
	rm -rf ~/Library/Developer/Xcode/DerivedData/NATURaL-*
	rm -rf TestResults.xcresult

# --- Help ---

help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'
