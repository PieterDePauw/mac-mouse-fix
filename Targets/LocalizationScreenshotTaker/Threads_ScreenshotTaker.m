//
// --------------------------------------------------------------------------
// Threads_ScreenshotTaker.m
// Created for Mac Mouse Fix (https://github.com/noah-nuebling/mac-mouse-fix)
// Created by Noah Nuebling in 2026
// Licensed under Licensed under the MMF License (https://github.com/noah-nuebling/mac-mouse-fix/blob/master/License)
// --------------------------------------------------------------------------
//

/// [Oct 2026] The LocalizationScreenshotTaker compiles `Shared/MessagePort/MFMessagePort.m`, which references the `threads_stateRunLoop()` per-target hook (See `Threads.h`).
///     We only ever use `+[MFMessagePort sendMessage:withPayload:toRemotePort:waitForReply:]` here (never `+load_Manual`) so this is never called – it just needs to exist for the linker.
///     (Before [Oct 2026], MFMessagePort.m excluded `+load_Manual` for this target with an `IS_THIRD` macro. Main runLoop is what that branch would've used.)

#import "Threads.h"

CFRunLoopRef threads_stateRunLoop(void) {
    return CFRunLoopGetMain();
}
