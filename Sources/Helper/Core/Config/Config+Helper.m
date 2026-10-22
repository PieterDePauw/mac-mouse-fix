//
// --------------------------------------------------------------------------
// Config+Helper.m
// Created for Mac Mouse Fix (https://github.com/noah-nuebling/mac-mouse-fix)
// Created by Noah Nuebling in 2019
// Licensed under the MMF License (https://github.com/noah-nuebling/mac-mouse-fix/blob/master/License)
// --------------------------------------------------------------------------
//

/// [Oct 2026] The Helper-specific parts of `Shared/Config/Config.m` – moved here (verbatim, except for the ivar -> static var changes) from Helper-only `#if` blocks in there.

#import "Config+Helper.h"
#import <CoreServices/CoreServices.h>
#import "Remap.h"
#import "HelperUtility.h"
#import "SharedUtility.h"
#import "Constants.h"
#import "Threads.h"
#import "Logging.h"
#import "Mac_Mouse_Fix_Helper-Swift.h"

@implementation Config (Helper)

#pragma mark - Per-target hooks

+ (void)installHelperHooks {
    
    /// Called from the Helper's entry point (`+[AccessibilityCheck load]`) before anything touches Config.
    
    /// Load config file
    ///     The Helper doesn't repair the config, it just reads it. (See `loadConfigFromFile`)
    Config.repairsConfigOnLoad = NO;
    
    /// Update derived states
    ///     (Used to be the Helper-only branch of `updateDerivedStates()` in Config.m)
    [Config registerDerivedStatesUpdater: ^{
        
        /// Force update of internal state, (even the active app hastn't changed)
        ///     (Not sure if we need to always do this or only after loading from file)
        loadOverridesForApp(@"");

        /// Notify other modules
        [Remap reload];
        [ScrollConfig reload];
        //[Scroll decide];
        [PointerConfig reload];
        [GeneralConfig reload];
        [MenuBarItem reload];
    }];
}

#pragma mark - Overrides

/// Vars
///     [Oct 2026] These used to be ivars of Config. (Config is a singleton so static vars work the same.)
static NSString *_bundleIDOfAppWhichCausesAppOverride;
static NSMutableDictionary *_configWithAppOverridesApplied;

- (NSMutableDictionary *)configWithAppOverridesApplied {
    return _configWithAppOverridesApplied;
}

/// Applies AppOverrides from app with `bundleIdentifier` to `self->_config` and writes the result into `_configWithAppOverridesApplied`.
static void loadOverridesForApp(NSString *bundleID) {

    /// Store app
    _bundleIDOfAppWhichCausesAppOverride = bundleID;

    /// Get overrides for app
    NSDictionary *overrides = [Config.shared.config objectForKey:kMFConfigKeyAppOverrides];
    NSDictionary *overridesForThisApp;
    for (NSString *b in overrides.allKeys) {
        if ([bundleID isEqualToString:b]) {
                overridesForThisApp = [[overrides objectForKey: b] objectForKey:@"Root"];
        }
    }
    if (overridesForThisApp) {
        _configWithAppOverridesApplied = [[SharedUtility dictionaryWithOverridesAppliedFrom:overridesForThisApp to: Config.shared.config] mutableCopy];
    } else {
        _configWithAppOverridesApplied = Config.shared.config;
    }
}

- (BOOL)loadOverridesForAppUnderMousePointerWithEvent:(CGEventRef)event {
    
    /// Unused in MMF 3
    ///     Reactivate when we reimplement app-specific settings.
    return NO;
    
    /// Returns yes when it's made a change
    /// TODO: Add compatibility for command line executables
    /// TODO: Look into using kCGMouseEventWindowUnderMousePointer to get the window under the mouse pointer
    
    /// Validate
    assertRunLoop(configRunLoop());

    /// Get bundleID
    NSRunningApplication *app = [HelperUtility appUnderMousePointerWithEvent:event];
    NSString *bundleID = app.bundleIdentifier;

    /// Debug
    DDLogDebug("Loading overrides for app %@", bundleID);

    /// Set internal state
    if (![_bundleIDOfAppWhichCausesAppOverride isEqual:bundleID]) {
        loadOverridesForApp(bundleID);
        return YES;
    }
    
    return NO;
}

#pragma mark - Listen to filesystem changes
/// This stuff is unused in MainApp (and can be removed entirely. Was just for testing.)

- (void)setupFSEventStreamCallback {
    
    /**
     We're setting up a File System Monitor so that manual edits to the main configuration file have an effect.
     This allows you to easily test configurations.
     
     Secret trick to find the main configuration file: Open the Mac Mouse Fix app, and click on "More...". Then, hold Command and Shift while clicking the Mac Mouse Fix Icon in the top left.
     
     Why are we disabling this now?
     In MMF 3 this causes a bug with the addField. And turning this off is the only feasible way I can find to fix that bug.
     
     Explanation of the bug that this caused:
     - When the mainApp writes the config to file it calls `[Config handleConfigFileChange]` . Then the eventStreamCallback calls `[Config handleConfigFileChange]` again - but with a significant delay. Sometimes seems like more than a second. The second, delayed call to `[Config handleConfigFileChange]` leads addMode to be disabled. When the user intends to use addMode that's annoying.
     - To fix this we would either have to ignore FSEvents originating from the mainApp - I haven't found a way to do that. Or we would have to disable the delay with which the FSEvent callback is called. There is a `latency` parameter but even if you set it low there are still usually long delays.
     
     Edit: I have an idea for a fix! Simply disable the eventStream while the mainApp is open / while the messageport is connected! Maybe implement this as part of SwitchMaster
     */

    assertRunLoop(configRunLoop());
    #if 0 /// Disable for now
        /// [Oct 2026] Note: `_configFilePath` is a private ivar of Config.m – if you re-enable this, you need to expose it (or use `Locator.configURL`)

        CFRunLoopRef runLoop = configRunLoop();

        CFArrayRef pathsToWatch;
        void *callbackInfo = NULL; /// Could put stream-specific data here.
        if (@available(macOS 13.0, *)) { /// The old code causes a crash on Ventura (specifically trying to log the cfPath using DDLogInfo)
            NSArray *pathsToWatchNS = @[_configFilePath];
            pathsToWatch = (__bridge_retained CFArrayRef)pathsToWatchNS; /// `__bridge_retained` -> we need to release this manually
        } else {
            CFStringRef cfPath = (__bridge CFStringRef)_configFilePath.copy; /// Why are we copying this?
            CFStringRef cfArray[1] = {cfPath};
            pathsToWatch = CFArrayCreate(NULL, (const void **)cfArray, 1, NULL);
        }


        DDLogInfo("pathsToWatch : %@", (__bridge NSArray *)pathsToWatch);

        /// Create eventStream
        /// Notes:
        /// - Not sure if fileEvents flag is a good idea
        /// - Flags ignoreSelf and markSelf seem redundant but this post (https://stackoverflow.com/a/37014613/10601702) says it's necessary. Still kind of unnecessary since Helper never writes to file I think.
        /// - Latency is for optimization I think. Probably totally unnecessary here, but with noDefer it shouldn't make a difference.
        /// - The flag kFSEventStreamCreateFlagUseExtendedData apparently makes a file "inode" available which is something like a low level id. Don't think that's useful for us though.

        CFAbsoluteTime latency = 300.0/1000.0;
        FSEventStreamCreateFlags flags = kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagNoDefer | kFSEventStreamCreateFlagIgnoreSelf | kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagMarkSelf;
        FSEventStreamRef remapsFileEventStream = FSEventStreamCreate(kCFAllocatorDefault, &Handle_FSEventStreamCallback, callbackInfo, pathsToWatch, kFSEventStreamEventIdSinceNow, latency, flags);

        /// Start eventStream
        FSEventStreamScheduleWithRunLoop(remapsFileEventStream, runLoop, kCFRunLoopDefaultMode);
        BOOL EventStreamStarted = FSEventStreamStart(remapsFileEventStream);
        DDLogInfo("EventStreamStarted: %d", EventStreamStarted);

        /// Release stuff
        ///     We might be leaking a bunch of things here in this class but it doesn't matter since it's only run once when the app starts up
        CFRelease(pathsToWatch);

    #endif
}

void Handle_FSEventStreamCallback(ConstFSEventStreamRef streamRef, void *clientCallBackInfo, size_t numEvents, void *eventPaths, const FSEventStreamEventFlags *eventFlags, const FSEventStreamEventId *eventIds) {
    
    /// Disable for now (see setupFSEventStreamCallback for explanation)
    assert(false);

    assertRunLoop(configRunLoop());

    /// Gather info
    
    NSArray<NSString *> *paths = (__bridge NSArray *)((CFArrayRef)eventPaths);
    BOOL noInfo = *eventFlags == kFSEventStreamEventFlagNone;
    BOOL isFromSelf = *eventFlags & kFSEventStreamEventFlagOwnEvent;
    BOOL isModified = *eventFlags & kFSEventStreamEventFlagItemModified;
    BOOL isRemoved = *eventFlags & kFSEventStreamEventFlagItemRemoved;
    BOOL isRenamed = *eventFlags & kFSEventStreamEventFlagItemRenamed;
    BOOL isCreated = *eventFlags & kFSEventStreamEventFlagItemCreated;
    BOOL isFile = *eventFlags & kFSEventStreamEventFlagItemIsFile;
    
    /// Log
    
    DDLogInfo("FSEvent for config.plist - paths: %@, noInfo: %d, isFromSelf: %d, isModified: %d, isRemoved: %d, isRenamed: %d, isCreated: %d, isFile: %d", paths, noInfo, isFromSelf, isModified, isRemoved, isRenamed, isCreated, isFile);
    
    if (!isFromSelf && isFile) {
        [Config loadFileAndUpdateStates];
    }
}

@end
