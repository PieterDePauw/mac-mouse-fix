//
// --------------------------------------------------------------------------
// Config+App.m
// Created for Mac Mouse Fix (https://github.com/noah-nuebling/mac-mouse-fix)
// Created by Noah Nuebling in 2019
// Licensed under the MMF License (https://github.com/noah-nuebling/mac-mouse-fix/blob/master/License)
// --------------------------------------------------------------------------
//

#import "Config+App.h"
#import "Mac_Mouse_Fix-Swift.h"

@implementation Config (App)

+ (void)installAppHooks {
    
    /// Called from the mainApp's earliest entry point (`+[AppDelegate load]`) before anything touches Config.
    
    /// Load config file
    ///     Only the mainApp creates / upgrades / replaces the config file. (See `_loadAndRepair()` in Config.m)
    Config.repairsConfigOnLoad = YES;
    
    /// Update derived states
    ///     (Used to be the mainApp-only branch of `updateDerivedStates()` in Config.m)
    [Config registerDerivedStatesUpdater: ^{
        [ReactiveConfig.shared reactWithNewConfig:Config.shared.config];
    }];
}

@end
