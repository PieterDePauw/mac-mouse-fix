//
// --------------------------------------------------------------------------
// Config+App.h
// Created for Mac Mouse Fix (https://github.com/noah-nuebling/mac-mouse-fix)
// Created by Noah Nuebling in 2019
// Licensed under the MMF License (https://github.com/noah-nuebling/mac-mouse-fix/blob/master/License)
// --------------------------------------------------------------------------
//

/// [Oct 2026] The mainApp-specific parts of `Shared/Config/Config.m` (Used to be mainApp-only `#if` blocks in there)

#import "Config.h"

@interface Config (App)

/// Per-target hooks
+ (void)installAppHooks; /// Call this once at launch, before anything touches Config. See `Per-target hooks` in Config.h

@end
