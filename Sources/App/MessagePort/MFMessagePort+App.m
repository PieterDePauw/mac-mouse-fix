//
// --------------------------------------------------------------------------
// MFMessagePort+App.m
// Created for Mac Mouse Fix (https://github.com/noah-nuebling/mac-mouse-fix)
// Created by Noah Nuebling in 2021
// Licensed under the MMF License (https://github.com/noah-nuebling/mac-mouse-fix/blob/master/License)
// --------------------------------------------------------------------------
//

/// [Oct 2026] The mainApp-specific parts of `Shared/MessagePort/MFMessagePort.m` – moved here (verbatim) from mainApp-only `#if` blocks in there.

#import "MFMessagePort+App.h"
#import <Cocoa/Cocoa.h>
#import "Constants.h"
#import "Config.h"
#import "Logging.h"
#import "Mac_Mouse_Fix-Swift.h"
#import "KeyCaptureView.h"
#import "Alerts.h"

@implementation MFMessagePort (App)

+ (void)installAppHooks {
    
    /// Called from the mainApp's earliest entry point (`+[AppDelegate load]`) before anything touches MFMessagePort.
    
    [MFMessagePort installHooksWithProcessName: @"MainApp"
                                 localPortName: kMFBundleIDApp
                                remotePortName: kMFBundleIDHelper
                         crashIfLocalPortFails: NO
                                messageHandler: ^NSObject *_Nullable (NSString *message, NSObject *_Null_unspecified payload) {
        
        NSObject *response = nil;
        
        #define xxx(message_) else if ([message_ isEqual: message])
        
        if ((0)) {}
        xxx(@"getEnvAndArgs") {} /// Already handled in MFMessagePort.m – (Before [Oct 2026] this was one if-else-chain with the shared messages, so they didn't reach the `Unknown message` log below. Keep it that way.)
        xxx(@"isDarkMode")    {} /// ^
        
        
        xxx(@"addModeFeedback") {
            [MainAppState.shared.buttonTabController handleAddModeFeedbackWithPayload:(NSDictionary *)payload];
        }
        xxx(@"keyCaptureModeFeedback") {
            [KeyCaptureView handleKeyCaptureModeFeedbackWithPayload:(NSDictionary *)payload isSystemDefinedEvent:NO];
        }
        xxx(@"keyCaptureModeFeedbackWithSystemEvent") {
            [KeyCaptureView handleKeyCaptureModeFeedbackWithPayload:(NSDictionary *)payload isSystemDefinedEvent:YES];

        }
        xxx(@"helperEnabledWithNoAccessibility") {
            /// Notes:
            ///     - [Sep 2025] What is the logic for when we call checkHelperStrangenessReactWithPayload:?
            ///         When the mainApp is started while the helper is already running, it checks if the helper is enabled by sending it "getBundleVersion" -> Maybe we should call `checkHelperStrangenessReactWithPayload:` there as well?
            BOOL isStrange = [MessagePortUtility.shared checkHelperStrangenessReactWithPayload: payload];
            if (!isStrange) {
                [AuthorizeAccessibilityView add];
            }
        }
        
        xxx(@"helperEnabled") {

            BOOL isStrange = [MessagePortUtility.shared checkHelperStrangenessReactWithPayload: payload];
            if (!isStrange) { /// Helper matches mainApp instance.
                
                /// Bring mainApp for foreground
                /// Notes:
                /// - In some places like when the accessibilitySheet is dismissed, we have other methods for bringing mainApp to the foreground that might be unnecessary now that we're doing this. Edit: We stopped the accessibility enabling code from activating the app.
                /// - (September 2024) activateIgnoringOtherApps: is deprecated under macOS 15.0 Sequoia. (But it still seems to work based on my superficial testing before 3.0.3 release.) TODO: Use new cooperative activation APIs instead. (Article: https://developer.apple.com/documentation/appkit/nsapplication/passing_control_from_one_app_to_another_with_cooperative_activation?language=objc)
                
                [NSApp activateIgnoringOtherApps:YES];
                
                /// Dismiss accessibilitySheet
                ///     This is unnecessary under Ventura since `activateIgnoringOtherApps` will trigger `ResizingTabWindowController.windowDidBecomeMain()` which will also call `[AuthorizeAccessibilityView remove]`. But it's better to be safe and explicit about this.
                [AuthorizeAccessibilityView remove];
                
                /// Notify rest of the app
                [EnabledState.shared reactToDidBecomeEnabled];
            }
            
        }
        xxx(@"helperDisabled") {
            [EnabledState.shared reactToDidBecomeDisabled];
        }
        xxx(@"configFileChanged") {
            [Config loadFileAndUpdateStates];
        }
        xxx(@"showNextToastOrSheetWithSection") {
            BOOL moreToastsToGo = [ToastAndSheetTests showNextTestWithSection:(id)payload]; /// If this is true, we haven't ran out of test-toasts for this section, yet.
            response = @(moreToastsToGo);
        }
        xxx(@"didShowAllToastsAndSheets") {
            BOOL didShowAll = [ToastAndSheetTests didShowAllToastsAndSheets];
            response = @(didShowAll);
        }
        xxx(@"showCaptureToast") {
            NSSet<NSNumber *> *before = ((NSDictionary *)payload)[@"before"];
            NSSet<NSNumber *> *after  = ((NSDictionary *)payload)[@"after"];
            [ToastAndSheetTests showCaptureToastBefore: before after: after];
        }
        else {
            DDLogInfo("Unknown message received: %@", message);
        }
        
        #undef xxx
        
        return response;
    }];
}

@end
