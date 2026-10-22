//
// --------------------------------------------------------------------------
// IOThread.h
// Created for Mac Mouse Fix (https://github.com/noah-nuebling/mac-mouse-fix)
// Created by Noah Nuebling in 2026
// Licensed under Licensed under the MMF License (https://github.com/noah-nuebling/mac-mouse-fix/blob/master/License)
// --------------------------------------------------------------------------
//

/// [Oct 2026] Moved here from `Shared/Threads.h` (was under `#if IS_HELPER`). See `MMF Concurrency Model` in `Threads.h`.

#import <Foundation/Foundation.h>


@interface IOThread : NSObject

    + (void) load_Manual;
    + (void) start;
    + (CFRunLoopRef)runLoop CF_RETURNS_NOT_RETAINED;

@end

