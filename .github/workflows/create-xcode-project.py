#!/usr/bin/env python3
import os
import uuid

def gen():
    return str(uuid.uuid4()).replace('-', '').upper()[:24]

# Create directories
os.makedirs('ios/ARIA', exist_ok=True)
os.makedirs('ios/ARIA.xcodeproj', exist_ok=True)
os.makedirs('ios/ARIA/Assets.xcassets/AppIcon.appiconset', exist_ok=True)

# Create main.swift - must use AppDelegate pattern for this structure
main_swift = '''import UIKit
import SwiftUI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIHostingController(rootView: ContentView())
        self.window = window
        window.makeKeyAndVisible()
        return true
    }
}

struct ContentView: View {
    var body: some View {
        VStack {
            Text("ARIA")
                .font(.largeTitle)
            Text("Hello World")
        }
    }
}
'''
with open('ios/ARIA/main.swift', 'w') as f:
    f.write(main_swift)

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
    <string>1.0</string>
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
</dict>
</plist>'''
with open('ios/ARIA/Info.plist', 'w') as f:
    f.write(plist)

# Create Assets
assets = '{"images":[{"idiom":"universal","platform":"ios","size":"1024x1024"}],"info":{"author":"xcode","version":1}}'
with open('ios/ARIA/Assets.xcassets/AppIcon.appiconset/Contents.json', 'w') as f:
    f.write(assets)

# Generate UUIDs
u = {k: gen() for k in ['root', 'main', 'prod', 'aria', 'app', 'src', 'assets', 'plist',
                         'target', 'sources', 'resources', 'frameworks',
                         'debug', 'release', 'debug_tgt', 'release_tgt',
                         'proj_cfg', 'tgt_cfg', 'src_build', 'res_build']}

# Create project.pbxproj
project = f'''// !$*UTF8*$!
{{
\tarchiveVersion = 1;
\tclasses = {{}};
\tobjectVersion = 56;
\tobjects = {{

/* Begin PBXBuildFile section */
\t\t{u['src_build']} /* main.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {u['src']} /* main.swift */; }};
\t\t{u['res_build']} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {u['assets']} /* Assets.xcassets */; }};
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
\t\t{u['app']} /* ARIA.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = ARIA.app; sourceTree = BUILT_PRODUCTS_DIR; }};
\t\t{u['src']} /* main.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = main.swift; sourceTree = "<group>"; }};
\t\t{u['assets']} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; }};
\t\t{u['plist']} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; }};
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
\t\t{u['frameworks']} /* Frameworks */ = {{
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = ();
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
\t\t{u['main']} = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{u['aria']} /* ARIA */,
\t\t\t\t{u['prod']} /* Products */,
\t\t\t);
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{u['prod']} /* Products */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{u['app']} /* ARIA.app */,
\t\t\t);
\t\t\tname = Products;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{u['aria']} /* ARIA */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{u['src']} /* main.swift */,
\t\t\t\t{u['assets']} /* Assets.xcassets */,
\t\t\t\t{u['plist']} /* Info.plist */,
\t\t\t);
\t\t\tpath = ARIA;
\t\t\tsourceTree = "<group>";
\t\t}};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
\t\t{u['target']} /* ARIA */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {u['tgt_cfg']} /* Build configuration list for PBXNativeTarget "ARIA" */;
\t\t\tbuildPhases = (
\t\t\t\t{u['sources']} /* Sources */,
\t\t\t\t{u['frameworks']} /* Frameworks */,
\t\t\t\t{u['resources']} /* Resources */,
\t\t\t);
\t\t\tbuildRules = ();
\t\t\tdependencies = ();
\t\t\tname = ARIA;
\t\t\tproductName = ARIA;
\t\t\tproductReference = {u['app']} /* ARIA.app */;
\t\t\tproductType = "com.apple.product-type.application";
\t\t}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
\t\t{u['root']} /* Project object */ = {{
\t\t\tisa = PBXProject;
\t\t\tbuildConfigurationList = {u['proj_cfg']} /* Build configuration list for PBXProject "ARIA" */;
\t\t\tcompatibilityVersion = "Xcode 14.0";
\t\t\tdevelopmentRegion = en;
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (en, Base);
\t\t\tmainGroup = {u['main']};
\t\t\tproductRefGroup = {u['prod']} /* Products */;
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = ({u['target']} /* ARIA */);
\t\t}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
\t\t{u['resources']} /* Resources */ = {{
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t\t{u['res_build']} /* Assets.xcassets in Resources */,
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
\t\t{u['sources']} /* Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t\t{u['src_build']} /* main.swift in Sources */,
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
\t\t{u['debug']} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{u['release']} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;
\t\t\t\tVALIDATE_PRODUCT = YES;
\t\t\t}};
\t\t\tname = Release;
\t\t}};
\t\t{u['debug_tgt']} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tINFOPLIST_FILE = ARIA/Info.plist;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = ("$(inherited)", "@executable_path/Frameworks");
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.officialzpb.aria;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{u['release_tgt']} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tINFOPLIST_FILE = ARIA/Info.plist;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = ("$(inherited)", "@executable_path/Frameworks");
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.officialzpb.aria;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t}};
\t\t\tname = Release;
\t\t}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
\t\t{u['proj_cfg']} /* Build configuration list for PBXProject "ARIA" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = ({u['debug']} /* Debug */, {u['release']} /* Release */);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
\t\t{u['tgt_cfg']} /* Build configuration list for PBXNativeTarget "ARIA" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = ({u['debug_tgt']} /* Debug */, {u['release_tgt']} /* Release */);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
/* End XCConfigurationList section */
\t}};
\trootObject = {u['root']} /* Project object */;
}}
'''

with open('ios/ARIA.xcodeproj/project.pbxproj', 'w') as f:
    f.write(project)

print('iOS project created successfully')
