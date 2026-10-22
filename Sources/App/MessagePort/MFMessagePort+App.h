//
// --------------------------------------------------------------------------
// MFMessagePort+App.h
// Created for Mac Mouse Fix (https://github.com/noah-nuebling/mac-mouse-fix)
// Created by Noah Nuebling in 2021
// Licensed under the MMF License (https://github.com/noah-nuebling/mac-mouse-fix/blob/master/License)
// --------------------------------------------------------------------------
//

/// [Oct 2026] The mainApp-specific parts of `Shared/MessagePort/MFMessagePort.m` (Used to be mainApp-only `#if` blocks in there)

#import "MFMessagePort.h"

@interface MFMessagePort (App)

+ (void)installAppHooks; /// Call this once at launch, before anything touches MFMessagePort. See `Per-target hooks` in MFMessagePort.h

@end
