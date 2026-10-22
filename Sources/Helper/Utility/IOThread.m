//
// --------------------------------------------------------------------------
// IOThread.m
// Created for Mac Mouse Fix (https://github.com/noah-nuebling/mac-mouse-fix)
// Created by Noah Nuebling in 2026
// Licensed under Licensed under the MMF License (https://github.com/noah-nuebling/mac-mouse-fix/blob/master/License)
// --------------------------------------------------------------------------
//

/// [Oct 2026] Moved here from `Shared/Threads.m` (was under `#if IS_HELPER`) so Shared doesn't need to know about the Helper's threads. See `MMF Concurrency Model` in `Threads.h`.

#import "IOThread.h"
#import "Threads.h"
#import "SharedUtility.h"
#import "MFGate.h"
#import "Logging.h"

#pragma mark - Per-target hooks (See `Threads.h`)

int _enableRunLoopAsserts = 0; /// See where this enabled in the Helper's entry point.

CFRunLoopRef threads_stateRunLoop(void) {
    return IOThread.runLoop;
}

#pragma mark - IOThread

@implementation IOThread

    /// Vars

    static CFRunLoopRef _runLoop;

    static NSThread *_thread;

    static MFGate *_runLoopGate;
    static MFGate *_startGate;

    /// Init

    + (void)load_Manual {

        /// [Sep 2026] `+load_Manual`and `+start` are only called from the Helper's entry point/start sequence in `AccessibilityCheck.m`
        ///     see there to convince yourself that this is thread safe and stuff.

        /// Setup gates
        _runLoopGate = [MFGate new];
        _startGate = [MFGate new];

        /// Setup thread
        _thread = [[NSThread alloc] initWithTarget:self selector:@selector(threadWorkload) object:nil];
        _thread.name = @"com.nuebling.mac-mouse-fix.global-event-tap";
        _thread.qualityOfService = NSQualityOfServiceUserInteractive;
        _thread.threadPriority = 1.0;
        [_thread start];

        /// Wait unil runLoop is available
        [_runLoopGate waitForWork];
    }

    + (void)start {
        [_startGate signalWorkCompleted];
    }

    /// Thread workload
    + (void)threadWorkload {

        /// Store runLoop of new thread
        _runLoop = CFRunLoopGetCurrent();
        [_runLoopGate signalWorkCompleted];

        /// Wait for +start
        [_startGate waitForWork];

        /// Increase thread priority
        set_thread_priority(63, /*round_robin*/true);

        /// Add empty source so the runLoop doesn't exit immediately
        CFRunLoopSourceRef emptySource = CFRunLoopSourceCreate(kCFAllocatorDefault, 0, &(CFRunLoopSourceContext){0});
        CFRunLoopAddSource(_runLoop, emptySource, kCFRunLoopCommonModes);

        /// Disable the native per-callout autoreleasePools
        ///     This isn't necessary, I guess it creates consistency between macOS versions for everything to go through our @autoreleasePool (below) [Oct 2026]. (Update: Claude says this actually doesn't affect timers, see CFRunLoopRunInMode comment [Oct 2026])
        if (@available(macOS 11.0, *)) {
            extern Boolean _CFRunLoopSetPerCalloutAutoreleasepoolEnabled(Boolean enabled) API_AVAILABLE(macos(10.16), ios(14.0), watchos(7.0), tvos(14.0)); /// Src: [Oct 2026] https://github.com/swiftlang/swift-corelibs-foundation/blob/main/Sources/CoreFoundation/include/CFPriv.h
            _CFRunLoopSetPerCalloutAutoreleasepoolEnabled(false);
        }

        /// Run the runLoop
        ///     This thread is blocked by the runLoop now
        while (true) {
            /// Wrap in autoreleasePool
            ///     Necessary on older macOS versions. Probably before 11.0. See `_CFRunLoopSetPerCalloutAutoreleasepoolEnabled` (above) [Oct 2026]
            @autoreleasepool {
                (void)CFRunLoopRunInMode(kCFRunLoopDefaultMode, /*seconds*/DBL_MAX, /*returnAfterSourceHandled*/true); /// Claude says this doesn't return (which drains the pool) after handling CFRunLoopTimerRef/NSTimer or blocks (mfrun). Probably fine. Could alternatively use `CFRunLoopObserverRef` [Oct 2026] Claude also says `_CFRunLoopSetPerCalloutAutoreleasepoolEnabled` doesn't affect timers and timers always drain some internal pool in macOS 10.15 or later. [Oct 2026]
            }
        }
    }

    /// Getter / main interface
    + (CFRunLoopRef)runLoop {
        mfassert(_runLoop);
        return _runLoop;
    }

@end
