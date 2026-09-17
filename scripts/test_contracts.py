#!/usr/bin/env python3
"""Linux-runnable NATURaL product contracts.

These assert behavior that would catch regressions without Swift or Xcode:
Shannon / SCI / Crooks numbers, privacy, identity, HUD copy, icons.
They are not tautologies — each maps to a shipping invariant.
"""
from __future__ import annotations

import json
import math
import pathlib
import plistlib
import struct
import sys
import xml.etree.ElementTree as ET

ROOT = pathlib.Path(__file__).resolve().parents[1]
FAILS: list[str] = []


def fail(msg: str) -> None:
    FAILS.append(msg)


def read(rel: str) -> str:
    return (ROOT / rel).read_text(encoding="utf-8")


def png_ihdr(path: pathlib.Path) -> tuple[int, int, int, int, bool]:
    data = path.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError(f"{path} is not PNG")
    width, height, depth, color = struct.unpack(">IIBB", data[16:26])
    i = 8
    has_trns = False
    while i + 8 <= len(data):
        ln = struct.unpack(">I", data[i : i + 4])[0]
        typ = data[i + 4 : i + 8]
        if typ == b"tRNS":
            has_trns = True
        if typ == b"IEND":
            break
        i += 12 + ln
    return width, height, depth, color, has_trns


# --- Shannon / SCI / Crooks (must match BonhommeCore) ---


def shannon_adaptive(values: list[float], bin_count: int = 32) -> float:
    clean = [v for v in values if math.isfinite(v)]
    if len(clean) < 2:
        return 0.0
    lo, hi = min(clean), max(clean)
    span = hi - lo
    if span <= 0:
        return 0.0
    width = span / bin_count
    bins = [0] * bin_count
    for value in clean:
        idx = int((value - lo) / width)
        idx = max(0, min(bin_count - 1, idx))
        bins[idx] += 1
    total = float(len(clean))
    entropy = 0.0
    for count in bins:
        if count:
            p = count / total
            entropy -= p * math.log2(p)
    return entropy


def circular_shannon(
    angles: list[float], bin_count: int = 32, *, fold_cut: bool = True
) -> float:
    """Parity with EntropyCalculator.circularShannonEntropyScalar (±180 cut)."""
    clean = [a for a in angles if math.isfinite(a)]
    if len(clean) < 2:
        return 0.0
    width = 360.0 / bin_count
    bins = [0] * bin_count
    for angle in clean:
        a = math.fmod(angle, 360.0)
        if a > 180.0:
            a -= 360.0
        if a < -180.0:
            a += 360.0
        if fold_cut and a == 180.0:
            a = -180.0
        idx = int((a + 180.0) / width)
        idx = max(0, min(bin_count - 1, idx))
        bins[idx] += 1
    total = float(len(clean))
    entropy = 0.0
    for count in bins:
        if count:
            p = count / total
            entropy -= p * math.log2(p)
    return entropy


def entropy_to_score(entropy: float, bin_count: int = 32) -> float:
    max_h = math.log2(bin_count)
    if max_h <= 0:
        return 1.0
    clamped = max(0.0, min(max_h, entropy))
    return 1.0 - (clamped / max_h)


def sci_band(score: float | None, grounding: bool) -> str:
    if grounding:
        return "grounding"
    if score is None or not math.isfinite(score):
        return "unknown"
    score = min(1.0, max(0.0, score))
    if score < 0.3:
        return "collapsed"
    if score < 0.6:
        return "settling"
    if score < 0.8:
        return "focused"
    return "coherent"


def test_shannon_formula() -> None:
    if shannon_adaptive([]) != 0 or shannon_adaptive([1.0]) != 0:
        fail("empty / singleton Shannon must be 0")
    if shannon_adaptive([float("nan"), float("inf")]) != 0:
        fail("non-finite-only Shannon must be 0")
    if shannon_adaptive([4.0] * 64) != 0:
        fail("identical values must have H=0 (adaptive range collapse)")
    # 50/50 two values → one bin each if they differ → H = 1 bit when binCount≥2
    two = [0.0] * 50 + [1.0] * 50
    h = shannon_adaptive(two, 32)
    if abs(h - 1.0) > 1e-9:
        fail(f"two-point 50/50 Shannon should be 1 bit, got {h}")
    if entropy_to_score(0) != 1.0:
        fail("H=0 must score 1 (coherent)")
    if abs(entropy_to_score(5.0) - 0.0) > 1e-12:
        fail("H=log2(32) must score 0")
    if not (0 <= entropy_to_score(2.5) <= 1):
        fail("score must clamp to [0,1]")


def test_circular_wrap_is_not_linear() -> None:
    clustered = [179.0] * 100 + [-179.0] * 100
    circ = circular_shannon(clustered)
    if circ >= 2.0:
        fail(f"±179° circular entropy should be low, got {circ}")
    pair = [180.0] * 80 + [-180.0] * 80
    folded = circular_shannon(pair, fold_cut=True)
    unfolded = circular_shannon(pair, fold_cut=False)
    if folded != 0:
        fail(f"+180 and -180 must share a bin (H=0), got {folded}")
    if unfolded <= 0:
        fail("without the +180 ≡ -180 fold, +180 must occupy a different bin")
    src = read("BonhommeCore/Sources/BonhommeCore/Analysis/EntropyCalculator.swift")
    if "if a == 180.0 { a = -180.0 }" not in src:
        fail("Swift circular cut must fold +180 onto -180")
    uniform = [-180.0 + 360.0 * i / 512.0 for i in range(512)]
    if circular_shannon(uniform) < math.log2(32) * 0.95:
        fail("uniform circular angles must approach max entropy")


def test_sci_and_grounding_policy() -> None:
    chrome = read("BonhommeCore/Sources/BonhommeCore/UI/SessionHUDMetrics.swift")
    for needle in (
        "case ..<0.3: return .collapsed",
        "case 0.3..<0.6: return .settling",
        "case 0.6..<0.8: return .focused",
        "if isGrounding { return .grounding }",
    ):
        if needle not in chrome:
            fail(f"SCI band contract missing: {needle}")
    if sci_band(0.95, True) != "grounding":
        fail("grounding must win over high SCI")
    if sci_band(float("nan"), False) != "unknown":
        fail("NaN SCI is unknown, not collapsed")
    if sci_band(1.4, False) != "coherent":
        fail("SCI>1 must clamp into coherent")
    if sci_band(0.1, False) != "collapsed":
        fail("SCI 0.1 is collapsed")
    crooks = read("BonhommeCore/Sources/BonhommeCore/Control/ThermodynamicPhase.swift")
    if "groundingThreshold: Double = 0.12" not in crooks:
        fail("Crooks grounding threshold must stay 0.12")
    if "reversibilityThreshold: Double = 0.03" not in crooks:
        fail("Crooks reversibility threshold must stay 0.03")
    if "groundingBPM: Double = 92.0" not in crooks:
        fail("grounding beat must stay 92 BPM")
    if "nominalBPM: Double = 85.0" not in crooks:
        fail("nominal seated BPM must stay 85")


def test_hud_honesty() -> None:
    metrics = read("BonhommeCore/Sources/BonhommeCore/UI/SessionHUDMetrics.swift")
    if 'return "—"' not in metrics:
        fail("HUD must render em-dash for missing SCI/HR")
    if "sciPercentText" not in metrics.split("accessibilitySummary")[1]:
        fail("a11y summary must use clamped sciPercentText, not raw score*100")
    if "display = min(poseCount, max(1, poseIndex + 1))" not in metrics:
        fail("pose progress must be 1-based n/N, never 0/N")
    vision = read("BonhommeVision/App/SpatialBiofeedbackView.swift")
    if "Color.cyan" in vision or "CompactSCIMeter" not in vision:
        fail("visionOS ornament must use CompactSCIMeter, not cyan SCI")
    if "hudMetrics" not in read("BonhommeVision/App/SpatialPoseView.swift"):
        fail("visionOS session must expose SessionHUDMetrics")
    vision_space = read("BonhommeVision/App/ImmersivePoseSpace.swift")
    if ".cyan" in vision_space:
        fail("immersive figure/SCI ring must not use system cyan")
    if "BrandPalette.violet" not in vision_space:
        fail("immersive SCI ring must use BrandPalette.violet, not pose-category hue")
    compact = read("BonhommeCore/Sources/BonhommeCore/UI/SessionHUDViews.swift")
    if "SessionHUDMetrics(sciScore: score).sciPercentText" not in compact:
        fail("CompactSCIMeter must use HUD percent formatter (NaN → —, overflow → 100)")
    if 'percentText == "—" ? "unavailable"' not in compact:
        fail("CompactSCIMeter VoiceOver must use clamped percentText")
    tv_ring = read("BonhommeCore/Sources/BonhommeCore/TVDisplay/SCIVisualizationView.swift")
    if "SessionHUDMetrics(sciScore: score).sciPercentText" not in tv_ring:
        fail("TV SCI ring must use HUD percent formatter")
    widgets = read("NATURaLWidgets/BrandTokens.swift")
    if "min(1, max(0, score))" not in widgets:
        fail("widget BrandTokens.sciPercent must clamp SCI to [0, 1]")
    live = read("NATURaLLiveActivity/WorkoutLiveActivity.swift")
    if "min(1, max(0, score))" not in live:
        fail("Live Activity SCI percent must clamp")
    if "SessionHUDMetrics(sciScore: score).sciPercentText" not in read(
        "Bonhomme/Services/Siri/IntentBridge.swift"
    ):
        fail("Siri SCI percent must use SessionHUDMetrics")
    tv = read("BonhommeCore/Sources/BonhommeCore/TVDisplay/TVDisplayView.swift")
    if "spaciousChips: true" not in tv:
        fail("tvOS inspector chips must be spacious (10-foot)")
    if "timelinePaused" not in tv:
        fail("TV idle breath loop must honor Reduce Motion")
    root = read("BonhommeTV/Views/TVRootView.swift")
    if "Color.green" in root:
        fail("TV connection status must use BrandColor, not Color.green")
    home = read("Bonhomme/Features/Workout/HomeView.swift")
    if "NavigationSplitView" not in home:
        fail("iPad home must keep NavigationSplitView")
    watch = read("BonhommeWatch/App/WatchHomeView.swift")
    if any(ch in watch for ch in ("🎨", "🔥", "✨", "⚙️")):
        fail("Watch home uses emoji chrome")


def test_privacy_and_no_cloud() -> None:
    for rel in (
        "Bonhomme/PrivacyInfo.xcprivacy",
        "BonhommeWatch/PrivacyInfo.xcprivacy",
        "BonhommeTV/PrivacyInfo.xcprivacy",
        "BonhommeVision/PrivacyInfo.xcprivacy",
        "NATURaLWidgets/PrivacyInfo.xcprivacy",
        "NATURaLLiveActivity/PrivacyInfo.xcprivacy",
        "BonhommeCore/Sources/BonhommeCore/Resources/PrivacyInfo.xcprivacy",
    ):
        text = read(rel)
        if "<key>NSPrivacyTracking</key>" not in text or "<false/>" not in text:
            fail(f"{rel} must set NSPrivacyTracking false")
        tree = ET.parse(ROOT / rel)
        keys = [el.text for el in tree.getroot().iter("key")]
        if "NSPrivacyCollectedDataTypes" not in keys:
            fail(f"{rel} missing collected data types key")
    persistence = read("Bonhomme/Services/Persistence/PersistentModels.swift")
    if "cloudKitDatabase: .none" not in persistence:
        fail("health store must disable CloudKit")
    if "cloudKitDatabase: .automatic" in persistence:
        fail("automatic CloudKit must not ship")
    entitlements = read("Bonhomme/Bonhomme.entitlements")
    for bad in ("icloud-services", "icloud-container-identifiers", "ubiquity-kvstore-identifier"):
        if bad in entitlements:
            fail(f"entitlements still contain {bad}")
    for path in (ROOT / "Bonhomme").rglob("*.swift"):
        text = path.read_text(encoding="utf-8")
        if "PaywallView" in text or "SubscriptionStoreView" in text:
            fail(f"purchase barrier in {path}")
        if "import CloudKit" in text:
            fail(f"CloudKit import in {path}")


def test_identity() -> None:
    pbx = read("NATURaL.xcodeproj/project.pbxproj")
    for ident in (
        "PRODUCT_BUNDLE_IDENTIFIER = com.natural.Bonhomme;",
        "PRODUCT_BUNDLE_IDENTIFIER = com.natural.Bonhomme.watchkitapp;",
        "PRODUCT_BUNDLE_IDENTIFIER = com.natural.BonhommeTV;",
        "PRODUCT_BUNDLE_IDENTIFIER = com.natural.BonhommeVision;",
        "DEVELOPMENT_TEAM = ZJLX84G8QV;",
    ):
        if ident not in pbx:
            fail(f"pbxproj missing {ident}")
    watch = read("BonhommeWatch/Info.plist")
    if "<true/>" not in watch or "WKApplication" not in watch:
        fail("WKApplication must stay Boolean true")
    if "WKCompanionAppBundleIdentifier" not in watch or "com.natural.Bonhomme" not in watch:
        fail("Watch companion bundle id missing")
    if "authorizationStatus()" not in read(
        "Bonhomme/Services/Music/HeadphoneMotionActuator.swift"
    ):
        fail("CMHeadphoneMotionManager.authorizationStatus must be called with ()")
    for needle in (
        "A170917E3F61000000000011 /* Assets.xcassets in Resources */",
        "A170917E3F61000000000012 /* PrivacyInfo.xcprivacy in Resources */",
        "A170917E3F61000000000111 /* Assets.xcassets in Resources */",
        "A170917E3F61000000000112 /* PrivacyInfo.xcprivacy in Resources */",
    ):
        if needle not in pbx:
            fail(f"pbxproj missing bundled resource: {needle}")

    for rel in (
        "Bonhomme/Info.plist",
        "BonhommeWatch/Info.plist",
        "BonhommeTV/Info.plist",
        "BonhommeVision/Info.plist",
    ):
        info = plistlib.loads((ROOT / rel).read_bytes())
        if info.get("ITSAppUsesNonExemptEncryption") is not False:
            fail(f"{rel} must declare ITSAppUsesNonExemptEncryption false")
        if info.get("CFBundleDisplayName") != "NATURaL":
            fail(f"{rel} display name must stay NATURaL")


def test_brand_tokens_and_design_system() -> None:
    master = ROOT / "design-system/natural/MASTER.md"
    if not master.is_file():
        fail("design-system/natural/MASTER.md missing")
    master_text = master.read_text(encoding="utf-8")
    for token in ("#45E0A8", "#8B5CF6", "#08091A", "#E4E3F5", "NATURaL"):
        if token not in master_text:
            fail(f"MASTER.md missing brand token {token}")
    if "#0891B2" in master_text and "Brand override" not in master_text:
        fail("MASTER.md still uses generic spa teal as source of truth")
    brand = read("BonhommeCore/Sources/BonhommeCore/UI/BrandColor.swift")
    for needle in (
        "0x45E0A8",
        "0x8B5CF6",
        "0x08091A",
        "0xC4A359",
        "Color(brandHex: BrandPalette.mint)",
        "Color(brandHex: BrandPalette.violet)",
    ):
        if needle not in brand:
            fail(f"BrandColor/BrandPalette missing {needle}")
    for page in ("ios.md", "ipad.md", "watchos.md", "tvos.md", "visionos.md"):
        if not (ROOT / "design-system/natural/pages" / page).is_file():
            fail(f"design-system page {page} missing")


def test_icons() -> None:
    specs = [
        (ROOT / "Bonhomme/Assets.xcassets/AppIcon.appiconset/AppIcon.png", 1024, 1024),
        (ROOT / "BonhommeWatch/Assets.xcassets/AppIcon.appiconset/AppIcon.png", 1024, 1024),
        (ROOT / "BonhommeVision/Assets.xcassets/AppIcon.appiconset/AppIcon.png", 1024, 1024),
        (ROOT / "BonhommeTV/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png", 1024, 1024),
        (ROOT / "BonhommeTV/Assets.xcassets/AppIcon.appiconset/AppIcon.png", 1280, 768),
        (ROOT / "BonhommeTV/Assets.xcassets/AppIcon.appiconset/AppIcon-400.png", 400, 240),
        (ROOT / "BonhommeTV/Assets.xcassets/AppIcon.appiconset/AppIcon-800.png", 800, 480),
    ]
    for path, w, h in specs:
        if not path.is_file():
            fail(f"missing icon {path.relative_to(ROOT)}")
            continue
        width, height, depth, color, trns = png_ihdr(path)
        if (width, height) != (w, h):
            fail(f"{path.name} is {width}x{height}, need {w}x{h}")
        if depth != 8 or color != 2:
            fail(f"{path.name} must be 8-bit RGB (color type 2)")
        if trns:
            fail(f"{path.name} has tRNS — App Store icons must be opaque")
    workorder = ROOT / "Docs/AppStore/claude-design-icon-workorder.md"
    if not workorder.is_file():
        fail("TV/Vision layered icon workorder missing")
    tv_catalog = json.loads(
        (ROOT / "BonhommeTV/Assets.xcassets/AppIcon.appiconset/Contents.json").read_text()
    )
    sizes = {entry.get("size") for entry in tv_catalog["images"]}
    if "1280x768" not in sizes or "400x240" not in sizes:
        fail("tvOS AppIcon catalog must list 400x240 runtime + 1280x768 App Store slots")


def main() -> int:
    test_shannon_formula()
    test_circular_wrap_is_not_linear()
    test_sci_and_grounding_policy()
    test_hud_honesty()
    test_privacy_and_no_cloud()
    test_identity()
    test_brand_tokens_and_design_system()
    test_icons()
    if FAILS:
        print("FAIL")
        for item in FAILS:
            print(" -", item)
        return 1
    print("OK 8 NATURaL contracts")
    return 0


if __name__ == "__main__":
    sys.exit(main())
