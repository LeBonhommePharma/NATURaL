.PHONY: all build test lint lint-fix clean coverage xcode-build xcode-test help

# Default target
all: lint test build

# --- BonhommeCore (Swift Package) ---

build: ## Build BonhommeCore package
	swift build --package-path BonhommeCore

test: ## Run BonhommeCore tests
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

clean: ## Remove build artifacts
	rm -rf BonhommeCore/.build
	rm -rf DerivedData
	rm -rf ~/Library/Developer/Xcode/DerivedData/NATURaL-*
	rm -rf TestResults.xcresult

# --- Help ---

help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'
