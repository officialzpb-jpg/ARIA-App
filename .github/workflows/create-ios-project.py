#!/usr/bin/env python3
import os
import uuid

def gen_uuid():
    return str(uuid.uuid4()).replace('-', '').upper()[:24]

# Create directories
os.makedirs('ios/ARIA/Assets.xcassets/AppIcon.appiconset', exist_ok=True)
os.makedirs('ios/ARIA.xcodeproj', exist_ok=True)

# Create AppIcon
appicon = '{"images":[{"idiom":"universal","platform":"ios","size":"1024x1024"}],"info":{"author":"xcode","version":1}}'
with open('ios/ARIA/Assets.xcassets/AppIcon.appiconset/Contents.json', 'w') as f:
    f.write(appicon)

# Create Info.plist
plist = '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>ARIA</string>
    <key>CFBundleIdentifier</key>
    <string>com.officialzpb.aria</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>ARIA</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>UIApplicationSceneManifest</key>
    <dict>
        <key>UIApplicationSupportsMultipleScenes</key>
        <true/>
    </dict>
    <key>UIApplicationSupportsIndirectInputEvents</key>
    <true/>
    <key>UILaunchScreen</key>
    <dict/>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
    </array>
    <key>NSMicrophoneUsageDescription</key>
    <string>ARIA needs microphone access for voice commands</string>
    <key>NSSpeechRecognitionUsageDescription</key>
    <string>ARIA needs speech recognition to process your voice</string>
</dict>
</plist>'''
with open('ios/ARIA/Info.plist', 'w') as f:
    f.write(plist)

# Check for existing Swift files or create minimal one
swift_files = []
if os.path.exists('ios/ARIA'):
    for f in os.listdir('ios/ARIA'):
        if f.endswith('.swift'):
            swift_files.append(f)

if not swift_files:
    # Create minimal App.swift
    app_swift = '''import SwiftUI

@main
struct ARIAApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "mic.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            Text("ARIA")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("AI Routing & Integration Assistant")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}
'''
    with open('ios/ARIA/App.swift', 'w') as f:
        f.write(app_swift)
    swift_files = ['App.swift']

# Generate UUIDs
uuids = {name: gen_uuid() for name in [
    'root', 'main_group', 'products_group', 'aria_group', 'app_ref',
    'assets_ref', 'plist_ref', 'target', 'sources_phase', 'resources_phase',
    'frameworks_phase', 'project_config', 'target_config', 'debug_proj',
    'release_proj', 'debug_target', 'release_target', 'assets_build'
]}

# Build file references
file_refs = []
build_files = []
children = []
sources = []

for fname in swift_files:
    fref = gen_uuid()
    bref = gen_uuid()
    file_refs.append(f'\t\t{fref} /* {fname} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {fname}; sourceTree = "<group>"; }};')
    build_files.append(f'\t\t\t\t{bref} /* {fname} in Sources */ = {{isa = PBXBuildFile; fileRef = {fref} /* {fname} */; }};')
    children.append(f'\t\t\t\t{fref} /* {fname} */,')
    sources.append(f'\t\t\t\t{bref},')

file_refs_str = '\n'.join(file_refs)
build_files_str = '\n'.join(build_files)
children_str = '\n'.join(children)
sources_str = '\n'.join(sources)

# Create project.pbxproj
project = f'''// !$*UTF8*$!
{{
\tarchiveVersion = 1;
\tclasses = {{}};
\tobjectVersion = 56;
\tobjects = {{

/* Begin PBXBuildFile section */
{build_files_str}
\t\t{uuids['assets_build']} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {uuids['assets_ref']} /* Assets.xcassets */; }};
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
\t\t{uuids['app_ref']} /* ARIA.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = ARIA.app; sourceTree = BUILT_PRODUCTS_DIR; }};
{file_refs_str}
\t\t{uuids['assets_ref']} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; }};
\t\t{uuids['plist_ref']} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; }};
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
\t\t{uuids['frameworks_phase']} /* Frameworks */ = {{
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = ();
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
\t\t{uuids['main_group']} = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{uuids['aria_group']} /* ARIA */,
\t\t\t\t{uuids['products_group']} /* Products */,
\t\t\t);
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{uuids['products_group']} /* Products */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{uuids['app_ref']} /* ARIA.app */,
\t\t\t);
\t\t\tname = Products;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{uuids['aria_group']} /* ARIA */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{children_str}
\t\t\t\t{uuids['assets_ref']} /* Assets.xcassets */,
\t\t\t\t{uuids['plist_ref']} /* Info.plist */,
\t\t\t);
\t\t\tpath = ARIA;
\t\t\tsourceTree = "<group>";
\t\t}};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
\t\t{uuids['target']} /* ARIA */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {uuids['target_config']} /* Build configuration list for PBXNativeTarget "ARIA" */;
\t\t\tbuildPhases = (
\t\t\t\t{uuids['sources_phase']} /* Sources */,
\t\t\t\t{uuids['frameworks_phase']} /* Frameworks */,
\t\t\t\t{uuids['resources_phase']} /* Resources */,
\t\t\t);
\t\t\tbuildRules = ();
\t\t\tdependencies = ();
\t\t\tname = ARIA;
\t\t\tproductName = ARIA;
\t\t\tproductReference = {uuids['app_ref']} /* ARIA.app */;
\t\t\tproductType = "com.apple.product-type.application";
\t\t}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
\t\t{uuids['root']} /* Project object */ = {{
\t\t\tisa = PBXProject;
\t\t\tbuildConfigurationList = {uuids['project_config']} /* Build configuration list for PBXProject "ARIA" */;
\t\t\tcompatibilityVersion = "Xcode 14.0";
\t\t\tdevelopmentRegion = en;
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (en, Base);
\t\t\tmainGroup = {uuids['main_group']};
\t\t\tproductRefGroup = {uuids['products_group']} /* Products */;
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = ({uuids['target']} /* ARIA */);
\t\t}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
\t\t{uuids['resources_phase']} /* Resources */ = {{
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t\t{uuids['assets_build']} /* Assets.xcassets in Resources */,
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
\t\t{uuids['sources_phase']} /* Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
{sources_str}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
\t\t{uuids['debug_proj']} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;
\t\t\t\tENABLE_TESTABILITY = YES;
\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;
\t\t\t\tONLY_ACTIVE_ARCH = YES;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{uuids['release_proj']} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;
\t\t\t\tVALIDATE_PRODUCT = YES;
\t\t\t}};
\t\t\tname = Release;
\t\t}};
\t\t{uuids['debug_target']} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tINFOPLIST_FILE = ARIA/Info.plist;
\t\t\t\tINFOPLIST_KEY_NSMicrophoneUsageDescription = "ARIA needs microphone access";
\t\t\t\tINFOPLIST_KEY_NSSpeechRecognitionUsageDescription = "ARIA needs speech recognition";
\t\t\t\tINFOPLIST_KEY_UILaunchScreen_Generation = YES;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = ("$(inherited)", "@executable_path/Frameworks");
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.officialzpb.aria;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{uuids['release_target']} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tINFOPLIST_FILE = ARIA/Info.plist;
\t\t\t\tINFOPLIST_KEY_NSMicrophoneUsageDescription = "ARIA needs microphone access";
\t\t\t\tINFOPLIST_KEY_NSSpeechRecognitionUsageDescription = "ARIA needs speech recognition";
\t\t\t\tINFOPLIST_KEY_UILaunchScreen_Generation = YES;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = ("$(inherited)", "@executable_path/Frameworks");
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.officialzpb.aria;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t}};
\t\t\tname = Release;
\t\t}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
\t\t{uuids['project_config']} /* Build configuration list for PBXProject "ARIA" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = ({uuids['debug_proj']} /* Debug */, {uuids['release_proj']} /* Release */);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
\t\t{uuids['target_config']} /* Build configuration list for PBXNativeTarget "ARIA" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = ({uuids['debug_target']} /* Debug */, {uuids['release_target']} /* Release */);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
/* End XCConfigurationList section */
\t}};
\trootObject = {uuids['root']} /* Project object */;
}}
'''

with open('ios/ARIA.xcodeproj/project.pbxproj', 'w') as f:
    f.write(project)

print('iOS project created successfully')
