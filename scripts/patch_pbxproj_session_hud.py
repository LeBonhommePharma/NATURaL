#!/usr/bin/env python3
"""Idempotent pbxproj patcher for NATURaL session HUD / Mac / Apple-kit files.

Adds explicit PBX file refs for new Bonhomme/*.swift sources (SPM auto-includes
BonhommeCore). Clones the BonhommeTV target pattern for BonhommeMac
(SDK macosx, bundle com.natural.Bonhomme.mac, MACOSX_DEPLOYMENT_TARGET 14.0).
"""
from __future__ import annotations

import hashlib
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
PBX = ROOT / "NATURaL.xcodeproj" / "project.pbxproj"

# Stable 24-hex IDs derived from a seed (must not collide with existing objects).
def hid(seed: str) -> str:
    digest = hashlib.sha1(f"f705:{seed}".encode()).hexdigest().upper()
    return digest[:24]


IDS = {
    "mac_product": hid("mac.product"),
    "mac_app_ref": hid("mac.BonhommeMacApp.swift"),
    "mac_root_ref": hid("mac.MacRootView.swift"),
    "mac_plist_ref": hid("mac.Info.plist"),
    "mac_ent_ref": hid("mac.entitlements"),
    "mac_app_build": hid("mac.build.BonhommeMacApp"),
    "mac_root_build": hid("mac.build.MacRootView"),
    "mac_core_fw": hid("mac.build.BonhommeCore.fw"),
    "mac_group": hid("mac.group.BonhommeMac"),
    "mac_app_group": hid("mac.group.App"),
    "mac_target": hid("mac.target"),
    "mac_sources": hid("mac.sources"),
    "mac_frameworks": hid("mac.frameworks"),
    "mac_debug": hid("mac.debug"),
    "mac_release": hid("mac.release"),
    "mac_cfglist": hid("mac.cfglist"),
    "mac_pkg": hid("mac.pkg.BonhommeCore"),
}

IOS_FILES = [
    ("Bonhomme/Features/Workout/ARPoseCoachView.swift", "703B6E2D72B9A3F1184DD037"),  # Workout group
    ("Bonhomme/Features/Workout/PoseCoachStage.swift", "703B6E2D72B9A3F1184DD037"),
    ("Bonhomme/Services/Music/HeadphoneMotionActuator.swift", "869CEDD7ABE929A5415359CE"),
    ("Bonhomme/Services/Siri/SessionTips.swift", "B98FCC200A649E73AA5510D2"),
]

WIDGET_FILES = [
    ("NATURaLWidgets/BrandTokens.swift", "130AD70FD95A4806574C6E3A"),
    ("NATURaLWidgets/StartChairYogaControl.swift", "130AD70FD95A4806574C6E3A"),
]

IOS_SOURCES_PHASE = "75D36BED9165EA876343B76C"
WIDGET_SOURCES_PHASE = "0E2C3DDD8F819138FFB68E0F"


def already_has(text: str, token: str) -> bool:
    return token in text


def insert_after(text: str, marker: str, insertion: str) -> str:
    idx = text.find(marker)
    if idx < 0:
        raise SystemExit(f"marker not found: {marker[:80]!r}")
    end = idx + len(marker)
    return text[:end] + insertion + text[end:]


def add_file_to_group_and_sources(
    text: str,
    rel_path: str,
    group_id: str,
    sources_phase_id: str,
    comment_name: str,
) -> str:
    filename = pathlib.Path(rel_path).name
    file_ref = hid(f"ref:{rel_path}")
    build_ref = hid(f"build:{rel_path}")
    if file_ref in text:
        return text

    file_ref_line = (
        f"\t\t{file_ref} /* {filename} */ = "
        f"{{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; "
        f"path = {filename}; sourceTree = \"<group>\"; }};\n"
    )
    build_line = (
        f"\t\t{build_ref} /* {filename} in Sources */ = "
        f"{{isa = PBXBuildFile; fileRef = {file_ref} /* {filename} */; }};\n"
    )
    text = insert_after(text, "/* Begin PBXBuildFile section */\n", build_line)
    text = insert_after(text, "/* Begin PBXFileReference section */\n", file_ref_line)

    child_line = f"\t\t\t\t{file_ref} /* {filename} */,\n"
    group_anchor = f"\t\t{group_id} /* "
    gidx = text.find(group_anchor)
    if gidx < 0:
        raise SystemExit(f"group {group_id} not found for {rel_path}")
    children_open = text.find("children = (", gidx)
    children_close = text.find("\t\t\t);", children_open)
    if file_ref not in text[children_open:children_close]:
        text = text[:children_close] + child_line + text[children_close:]

    # Normalize compact "in Sources */,);" closings so inserts stay in-phase.
    compact = re.compile(
        rf"(\t\t{sources_phase_id} /\* Sources \*/ = \{{[\s\S]*?)(in Sources \*/,)\);"
    )
    text, n = compact.subn(r"\1\2\n\t\t\t);", text, count=1)
    _ = n

    source_line = f"\t\t\t\t{build_ref} /* {filename} in Sources */,\n"
    pidx = text.find(f"\t\t{sources_phase_id} /* Sources */ = {{")
    if pidx < 0:
        raise SystemExit(f"sources phase {sources_phase_id} not found for {rel_path}")
    files_open = text.find("files = (", pidx)
    files_close = text.find("\t\t\t);", files_open)
    phase_end = text.find("\t\t};", files_open)
    if files_close < 0 or (phase_end >= 0 and files_close > phase_end):
        raise SystemExit(f"could not find files closing for phase {sources_phase_id}")
    if build_ref not in text[files_open:files_close]:
        text = text[:files_close] + source_line + text[files_close:]
    return text


def add_mac_target(text: str) -> str:
    if IDS["mac_target"] in text or "BonhommeMac.app" in text:
        return text

    build_files = f"""
		{IDS["mac_app_build"]} /* BonhommeMacApp.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {IDS["mac_app_ref"]} /* BonhommeMacApp.swift */; }};
		{IDS["mac_root_build"]} /* MacRootView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {IDS["mac_root_ref"]} /* MacRootView.swift */; }};
		{IDS["mac_core_fw"]} /* BonhommeCore in Frameworks */ = {{isa = PBXBuildFile; productRef = {IDS["mac_pkg"]} /* BonhommeCore */; }};
"""
    text = insert_after(text, "/* Begin PBXBuildFile section */\n", build_files)

    file_refs = f"""
		{IDS["mac_product"]} /* BonhommeMac.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = BonhommeMac.app; sourceTree = BUILT_PRODUCTS_DIR; }};
		{IDS["mac_app_ref"]} /* BonhommeMacApp.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = BonhommeMacApp.swift; sourceTree = "<group>"; }};
		{IDS["mac_root_ref"]} /* MacRootView.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = MacRootView.swift; sourceTree = "<group>"; }};
		{IDS["mac_plist_ref"]} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; }};
		{IDS["mac_ent_ref"]} /* BonhommeMac.entitlements */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = BonhommeMac.entitlements; sourceTree = "<group>"; }};
"""
    text = insert_after(text, "/* Begin PBXFileReference section */\n", file_refs)

    products_pat = re.compile(
        r"(0A2C978E52A76F0AA9F68BB5 /\* Products \*/ = \{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = \(\n)([\s\S]*?)(\t\t\t\);)",
    )
    pm = products_pat.search(text)
    if not pm:
        raise SystemExit("Products group not found")
    children = pm.group(2) + f"\t\t\t\t{IDS['mac_product']} /* BonhommeMac.app */,\n"
    text = text[: pm.start()] + pm.group(1) + children + pm.group(3) + text[pm.end() :]

    root_pat = re.compile(
        r"(2B731CEFC6751AAE0EC69B98 = \{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = \(\n)([\s\S]*?)(\t\t\t\);)",
    )
    rm = root_pat.search(text)
    if not rm:
        raise SystemExit("root group not found")
    root_children = rm.group(2) + f"\t\t\t\t{IDS['mac_group']} /* BonhommeMac */,\n"
    text = text[: rm.start()] + rm.group(1) + root_children + rm.group(3) + text[rm.end() :]

    mac_groups = f"""
		{IDS["mac_group"]} /* BonhommeMac */ = {{
			isa = PBXGroup;
			children = (
				{IDS["mac_app_group"]} /* App */,
				{IDS["mac_plist_ref"]} /* Info.plist */,
				{IDS["mac_ent_ref"]} /* BonhommeMac.entitlements */,
			);
			path = BonhommeMac;
			sourceTree = "<group>";
		}};
		{IDS["mac_app_group"]} /* App */ = {{
			isa = PBXGroup;
			children = (
				{IDS["mac_app_ref"]} /* BonhommeMacApp.swift */,
				{IDS["mac_root_ref"]} /* MacRootView.swift */,
			);
			path = App;
			sourceTree = "<group>";
		}};
"""
    text = insert_after(text, "/* Begin PBXGroup section */\n", mac_groups)

    mac_target = f"""
		{IDS["mac_target"]} /* BonhommeMac */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {IDS["mac_cfglist"]} /* Build configuration list for PBXNativeTarget "BonhommeMac" */;
			buildPhases = (
				{IDS["mac_sources"]} /* Sources */,
				{IDS["mac_frameworks"]} /* Frameworks */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = BonhommeMac;
			packageProductDependencies = (
				{IDS["mac_pkg"]} /* BonhommeCore */,
			);
			productName = BonhommeMac;
			productReference = {IDS["mac_product"]} /* BonhommeMac.app */;
			productType = "com.apple.product-type.application";
		}};
"""
    # Insert before End PBXNativeTarget
    text = text.replace("/* End PBXNativeTarget section */", mac_target + "/* End PBXNativeTarget section */")

    text = text.replace(
        "\t\t\t\tF87083C4BE51F1CCA10B40AC /* BonhommeTV */,\n",
        "\t\t\t\tF87083C4BE51F1CCA10B40AC /* BonhommeTV */,\n"
        f"\t\t\t\t{IDS['mac_target']} /* BonhommeMac */,\n",
    )

    frameworks = f"""
		{IDS["mac_frameworks"]} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			files = (
				{IDS["mac_core_fw"]} /* BonhommeCore in Frameworks */,
			);
		}};
"""
    text = text.replace("/* End PBXFrameworksBuildPhase section */", frameworks + "/* End PBXFrameworksBuildPhase section */")

    sources = f"""
		{IDS["mac_sources"]} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			files = (
				{IDS["mac_app_build"]} /* BonhommeMacApp.swift in Sources */,
				{IDS["mac_root_build"]} /* MacRootView.swift in Sources */,
			);
		}};
"""
    text = text.replace("/* End PBXSourcesBuildPhase section */", sources + "/* End PBXSourcesBuildPhase section */")

    configs = f"""
		{IDS["mac_debug"]} /* Debug configuration for PBXNativeTarget "BonhommeMac" */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				CODE_SIGN_ENTITLEMENTS = BonhommeMac/BonhommeMac.entitlements;
				COMBINE_HIDPI_IMAGES = YES;
				CURRENT_PROJECT_VERSION = 1;
				DEBUG_INFORMATION_FORMAT = dwarf;
				DEVELOPMENT_TEAM = ZJLX84G8QV;
				ENABLE_HARDENED_RUNTIME = YES;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = BonhommeMac/Info.plist;
				LD_RUNPATH_SEARCH_PATHS = "$(inherited) @executable_path/../Frameworks";
				MACOSX_DEPLOYMENT_TARGET = 14.0;
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.natural.Bonhomme.mac;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SDKROOT = macosx;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
				SWIFT_VERSION = 5.0;
			}};
			name = Debug;
		}};
		{IDS["mac_release"]} /* Release configuration for PBXNativeTarget "BonhommeMac" */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				CODE_SIGN_ENTITLEMENTS = BonhommeMac/BonhommeMac.entitlements;
				COMBINE_HIDPI_IMAGES = YES;
				COPY_PHASE_STRIP = YES;
				CURRENT_PROJECT_VERSION = 1;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				DEVELOPMENT_TEAM = ZJLX84G8QV;
				ENABLE_HARDENED_RUNTIME = YES;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = BonhommeMac/Info.plist;
				LD_RUNPATH_SEARCH_PATHS = "$(inherited) @executable_path/../Frameworks";
				MACOSX_DEPLOYMENT_TARGET = 14.0;
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.natural.Bonhomme.mac;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SDKROOT = macosx;
				SWIFT_OPTIMIZATION_LEVEL = "-O";
				SWIFT_VERSION = 5.0;
			}};
			name = Release;
		}};
"""
    text = text.replace("/* End XCBuildConfiguration section */", configs + "/* End XCBuildConfiguration section */")

    cfglist = f"""
		{IDS["mac_cfglist"]} /* Build configuration list for PBXNativeTarget "BonhommeMac" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{IDS["mac_debug"]} /* Debug configuration for PBXNativeTarget "BonhommeMac" */,
				{IDS["mac_release"]} /* Release configuration for PBXNativeTarget "BonhommeMac" */,
			);
			defaultConfigurationName = Release;
		}};
"""
    text = text.replace("/* End XCConfigurationList section */", cfglist + "/* End XCConfigurationList section */")

    pkg = f"""
		{IDS["mac_pkg"]} /* BonhommeCore */ = {{
			isa = XCSwiftPackageProductDependency;
			package = 6B1B48011FD2DF61F369AFC4 /* XCLocalSwiftPackageReference "BonhommeCore" */;
			productName = BonhommeCore;
		}};
"""
    text = text.replace(
        "/* End XCSwiftPackageProductDependency section */",
        pkg + "/* End XCSwiftPackageProductDependency section */",
    )
    return text


def add_existing_new_files(text: str) -> str:
    for rel, group in IOS_FILES:
        path = ROOT / rel
        if path.exists():
            text = add_file_to_group_and_sources(text, rel, group, IOS_SOURCES_PHASE, path.name)
    for rel, group in WIDGET_FILES:
        path = ROOT / rel
        if path.exists():
            text = add_file_to_group_and_sources(text, rel, group, WIDGET_SOURCES_PHASE, path.name)
    return text


def main() -> int:
    text = PBX.read_text()
    original = text
    text = add_mac_target(text)
    text = add_existing_new_files(text)
    if text == original:
        print("pbxproj already up to date")
        return 0
    PBX.write_text(text)
    print("patched", PBX)
    return 0


if __name__ == "__main__":
    sys.exit(main())
