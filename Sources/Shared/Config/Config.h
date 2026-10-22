//
// --------------------------------------------------------------------------
// Config.h
// Created for Mac Mouse Fix (https://github.com/noah-nuebling/mac-mouse-fix)
// Created by Noah Nuebling in 2019
// Licensed under the MMF License (https://github.com/noah-nuebling/mac-mouse-fix/blob/master/License)
// --------------------------------------------------------------------------
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

#import "Threads.h"

/// RunLoop
static inline CFRunLoopRef configRunLoop(void) CF_RETURNS_NOT_RETAINED {
    return threads_stateRunLoop(); /// mainApp: mainThread, Helper: IOThread [Oct 2026]
}

@interface Config : NSObject


/// Singleton
+ (Config *)shared;

/// Main storage
@property (strong, nonatomic) NSMutableDictionary *config; /// [Aug 2025] This could just be an ivar instead of a property  (Except if we wanna support KVO)

/// Load
+ (void)load_Manual;

/// Load from file
- (void)loadConfigFromFile;

/// Read and write
NSObject * _Nullable config(NSString *keyPath);
void setConfig(NSString *keyPath, NSObject *value);
void removeFromConfig(NSString *keyPath);
void commitConfig(void);

/// React
+ (void)loadFileAndUpdateStates;

/// Repair
//- (void) repairIncompleteAppOverrideForBundleID: (NSString *)bundleID
//                               relevantKeyPaths: (NSArray <NSString *> *)keyPathsToDefaultValues;
- (void) cleanConfig; /// [Oct 2026] Only used by the mainApp (Used to be a mainApp-only `#if`)

/// Overrides
///     -> `loadOverridesForAppUnderMousePointerWithEvent:` and `configWithAppOverridesApplied` moved to `Helper/Core/Config/Config+Helper.h` [Oct 2026]

/// Per-target hooks [Oct 2026]
///     Config is shared between the mainApp and the Helper, but some of its behavior differs between them. Each target sets this up once at launch, before anything touches Config. (mainApp: `App/Utility/Config+App.m`, Helper: `Helper/Core/Config/Config+Helper.m`)
///     (Used to be mainApp-only / Helper-only `#if` blocks inside Config.m)
@property (class, nonatomic) BOOL repairsConfigOnLoad;                  /// mainApp: YES – `loadConfigFromFile` creates/upgrades/replaces the config file if necessary (`_loadAndRepair()`). Helper: NO – it just reads the file and crashes if that fails.
+ (void)registerDerivedStatesUpdater:(void (^)(void))updater;           /// `updater`s are called in registration order from `updateDerivedStates()` – whenever the config has been loaded from file or committed.

@end
