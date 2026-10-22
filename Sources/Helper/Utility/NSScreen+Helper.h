//
// --------------------------------------------------------------------------
// NSScreen+Helper.h
// Created for Mac Mouse Fix (https://github.com/noah-nuebling/mac-mouse-fix)
// Created by Noah Nuebling in 2021
// Licensed under the MMF License (https://github.com/noah-nuebling/mac-mouse-fix/blob/master/License)
// --------------------------------------------------------------------------
//

/// [Oct 2026] Split out of `Shared/Extensions/NSScreen+Additions` (was `#if IS_HELPER`) since it depends on `HelperUtility`.

#import <Cocoa/Cocoa.h>
#import "NSScreen+Additions.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSScreen (Helper)

+ (NSScreen * _Nullable)screenUnderMousePointerWithEvent:(CGEventRef _Nullable)event;

@end

NS_ASSUME_NONNULL_END
