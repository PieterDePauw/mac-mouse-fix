//
// --------------------------------------------------------------------------
// MFMessagePort+Helper.m
// Created for Mac Mouse Fix (https://github.com/noah-nuebling/mac-mouse-fix)
// Created by Noah Nuebling in 2021
// Licensed under the MMF License (https://github.com/noah-nuebling/mac-mouse-fix/blob/master/License)
// --------------------------------------------------------------------------
//

/// [Oct 2026] The Helper-specific parts of `Shared/MessagePort/MFMessagePort.m` – moved here (verbatim) from Helper-only `#if` blocks in there.

#import "MFMessagePort+Helper.h"
#import <Cocoa/Cocoa.h>
#import "Constants.h"
#import "Config.h"
#import "Locator.h"
#import "Logging.h"
#import "Threads.h"
#import "Mac_Mouse_Fix_Helper-Swift.h"
#import "AccessibilityCheck.h"
#import "KeyCaptureMode.h"

@implementation MFMessagePort (Helper)

+ (void)installHelperHooks {
    
    /// Called from the Helper's entry point (`+[AccessibilityCheck load]`) before anything touches MFMessagePort.
    
    [MFMessagePort installHooksWithProcessName: @"Helper"
                                 localPortName: kMFBundleIDHelper
                                remotePortName: kMFBundleIDApp
                         crashIfLocalPortFails: YES
                                messageHandler: ^NSObject *_Nullable (NSString *message, NSObject *_Null_unspecified payload) {
        
        NSObject *response = nil;
        
        #define xxx(message_) else if ([message_ isEqual: message])
        
        if ((0)) ;
        xxx(@"configFileChanged") {
            [Config loadFileAndUpdateStates];
        }
        xxx(@"terminate") {
            mfrun(CFRunLoopGetMain(), ^{
                [NSApp terminate: NULL];
                //[NSApp.delegate applicationWillTerminate:[[NSNotification alloc] init]]; /// This creates an infinite loop or something? The statement below is never executed.
            });

        }
        xxx(@"checkAccessibility") {
            BOOL isTrusted = [AccessibilityCheck checkAccessibilityAndUpdateSystemSettings];
            response = @(isTrusted);
        }
        xxx(@"enableAddMode") {
            BOOL success = [Remap enableAddMode];
            response = @(success);
        }
        xxx(@"disableAddMode") {
            BOOL success = [Remap disableAddMode];
            response = @(success);
        }
        xxx(@"enableKeyCaptureMode") {
            [KeyCaptureMode enable];
        }
        xxx(@"disableKeyCaptureMode") {
            [KeyCaptureMode disable];
        }
        xxx(@"getActiveDeviceInfo") {
            
            Device *dev = HelperState.shared.activeDevice;
            if (dev != NULL) {
                
                response = @{
                    @"name": dev.name == nil ? @"" : dev.name,
                    @"manufacturer": dev.manufacturer == nil ? @"" : dev.manufacturer,
                    @"nOfButtons": @(dev.nOfButtons),
                };
            }
        }
        xxx(@"updateActiveDeviceWithEventSenderID") {
            /// We can't just pass over the CGEvent from the mainApp because the senderID isn't stored when serializing CGEvents
            uint64_t senderID = [(NSNumber *)payload unsignedIntegerValue];
            [HelperState.shared updateActiveDeviceWithEventSenderID:senderID];
        }
        xxx(@"getBundleVersion") {
            response = @(Locator.bundleVersion);
        }
        else {
            DDLogInfo("Unknown message received: %@", message);
        }
        
        #undef xxx
        
        return response;
    }];
}

@end
