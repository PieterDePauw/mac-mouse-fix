//
// --------------------------------------------------------------------------
// Config+Helper.h
// Created for Mac Mouse Fix (https://github.com/noah-nuebling/mac-mouse-fix)
// Created by Noah Nuebling in 2019
// Licensed under the MMF License (https://github.com/noah-nuebling/mac-mouse-fix/blob/master/License)
// --------------------------------------------------------------------------
//

/// [Oct 2026] The Helper-specific parts of `Shared/Config/Config.m` (Used to be Helper-only `#if` blocks in there)

#import "Config.h"


@interface Config (Helper)

/// Per-target hooks
+ (void)installHelperHooks; /// Call this once at launch, before anything touches Config. See `Per-target hooks` in Config.h

/// Filesystem changes
- (void)setupFSEventStreamCallback; /// Call this right after `[Config load_Manual]`

/// Overrides
- (BOOL)loadOverridesForAppUnderMousePointerWithEvent:(CGEventRef)event;
@property (strong, nonatomic, readonly) NSMutableDictionary *configWithAppOverridesApplied; /// [Aug 2025] This could just be an ivar

@end

