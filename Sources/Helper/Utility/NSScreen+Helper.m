//
// --------------------------------------------------------------------------
// NSScreen+Helper.m
// Created for Mac Mouse Fix (https://github.com/noah-nuebling/mac-mouse-fix)
// Created by Noah Nuebling in 2021
// Licensed under the MMF License (https://github.com/noah-nuebling/mac-mouse-fix/blob/master/License)
// --------------------------------------------------------------------------
//

#import "NSScreen+Helper.h"
#import "HelperUtility.h"

@implementation NSScreen (Helper)

+ (NSScreen * _Nullable)screenUnderMousePointerWithEvent:(CGEventRef _Nullable)event {
    
    /// TODO: Simplify / optimize this: Use [NSScreen +_screenAtPoint:]
    
    CGDirectDisplayID displayID;
    [HelperUtility displayUnderMousePointer:&displayID withEvent:event];
    
    return [NSScreen screenWithDisplayID:displayID];
}

@end
