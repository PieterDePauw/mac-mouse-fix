//
// --------------------------------------------------------------------------
// main.m
// Created for Mac Mouse Fix (https://github.com/noah-nuebling/mac-mouse-fix)
// Created by Noah Nuebling in 2021
// Licensed under the MMF License (https://github.com/noah-nuebling/mac-mouse-fix/blob/master/License)
// --------------------------------------------------------------------------
//

#import <Cocoa/Cocoa.h>
#import "Threads.h"

#pragma mark - Per-target hooks (See `Threads.h`)

int _enableRunLoopAsserts = 1;

CFRunLoopRef threads_stateRunLoop(void) {
    return CFRunLoopGetMain();
}

int main(int argc, const char * argv[]) {
    @autoreleasepool { // Setup code that might create autoreleased objects goes here.
        
    }
    return NSApplicationMain(argc, argv);
}
