//
// --------------------------------------------------------------------------
// MFMessagePort.m
// Created for Mac Mouse Fix (https://github.com/noah-nuebling/mac-mouse-fix)
// Created by Noah Nuebling in 2021
// Licensed under the MMF License (https://github.com/noah-nuebling/mac-mouse-fix/blob/master/License)
// --------------------------------------------------------------------------
//

/// This class is used to communicate between the MainApp and the Helper.
///     More or less works like a function call across processes.
/// Notes:
/// - Can't be named MessagePort because there's already a class in Foundation with that name
/// - This is a wrapper around CFMessagePort, which itself is a wrapper around mach ports. This was one of the first things we wrote for Mac Mouse Fix. Don't remember why we didn't use the higher level NSMachPort or directly use the low level mach_port C APIs. 
///
/// TODO:
///     Make this secure.
///     Ideas: ([Since Dec 2024]])
///         1. Switch from CFMessagePort to NSMachPort
///             - then get the **audit token** from the mach message, then use `SecTaskCreateWithAuditToken()` and `SecTaskCopySigningIdentifier()` to get the 'signingID' of the message sender.
///                 (I speculate that) the 'signingID' is NULL if the app isn't signed, and otherwise is the bundleID. BundleID's are unique among signed apps I think. If these assumptions are true this should let us confidently identify the message sender as "not a hacker".
///             - Given the sender's **PID** we could also check that the relative path between us and the helper matches our expectations. This might not add additional protection against hackers, but it would also solve the "Strange Helper" issues (Although IIRC I don't see those anymore since macOS 15 Sequoia)
///         2. Use NSSecureCoding to unarchive our objects.
///             - Might be a bit annoying / verbose to deal with on the receiving end.
///             - Not sure how much this would help (NSSecureCoding only enforces that you specify which classes may be decoded from the archive – but theres probably lots of other things about the message we should validate to actually make things secure. Discussed this more in MFDataClass implementation.)
///     Also see:
///         - Dennis Babkin blog about mach messaging in macOS, with "Security Considerations" section:
///             https://dennisbabkin.com/blog/?t=interprocess-communication-using-mach-messages-for-macos

#import "MFMessagePort.h"
#import <Cocoa/Cocoa.h>
#import "Constants.h"
#import "SharedUtility.h"
#import "Locator.h"
#import "HelperServices.h"
#import "Locator.h"
#import "Logging.h"
#import "Threads.h"

/// [Oct 2026] This file used to import App/Helper headers and the target's `-Swift.h` header, and had mainApp-only / Helper-only `#if` blocks.
///     Now, the target-specific parts live in `App/MessagePort/MFMessagePort+App.m` and `Helper/MessagePort/MFMessagePort+Helper.m` and are plugged in through the `Per-target hooks` (See MFMessagePort.h)

/// This class is used to communicate between the MainApp and the Helper.
///     More or less works like a function call across processes.
/// Notes:
/// - Can't be named MessagePort because there's already a class in Foundation with that name
/// - This is a wrapper around CFMessagePort, which itself is a wrapper around mach ports. This was one of the first things we wrote for Mac Mouse Fix. Don't remember why we didn't use the higher level NSMachPort or directly use the low level mach_port C APIs.
///
/// Discussion / confusion:
///     We used to do use `load` instead of `initialize` but that lead to issues when restarting the app if it's translocated:
///     If the app detects that it is translocated, it will restart itself at the untranslocated location,  after removing the quarantine flags from itself. It starts a copy of itself while it's still running, and only then does it terminate itself. If the message port is already 'claimed' by the translocated instances when it starts the     untranslocated copy, then the untranslocated copy can't 'claim' the message port for itself, which leads to things like the accessiblity screen not working.
///     I hope that moving using `initialize` instead of `load` in the mainApp should fix this and work just fine for everything else. I don't know why we used load to begin with.
///     Edit: I don't remember why we moved to `load_Manual` now, but it works fine
///
/// Event older Notes:
///     Notes from mainApp:
///         On Catalina, creating the local Port returns NULL and throws a permission denied error. Trying to schedule it with the runloop yields a crash.
///         But even if you just skip the runloop scheduling it still works somehow!

///     Notes from Helper:
///         CFMessagePortCreateRunLoopSource() used to crash when another instance of MMF Helper was already running.
///         It would log this: `*** CFMessagePort: bootstrap_register(): failed 1100 (0x44c) 'Permission denied', port = 0x1b03, name = 'com.nuebling.mac-mouse-fix.helper'`
///         I think the reason for this message is that the existing instance would already 'occupy' the kMFBundleIDHelper name.
///         Checking if `localPort != nil` should detect this case

#define messagePortRunLoop() threads_stateRunLoop() /// mainApp: mainThread, Helper: IOThread [Oct 2026]


@implementation MFMessagePort

#pragma mark - Per-target hooks

static NSString *_processName = nil;
static NSString *_localPortName = nil;
static NSString *_remotePortName = nil;
static BOOL _crashIfLocalPortFails = NO;
static MFMessagePortHandler _messageHandler = nil;

+ (void)installHooksWithProcessName:(NSString *)processName localPortName:(NSString *)localPortName remotePortName:(NSString *)remotePortName crashIfLocalPortFails:(BOOL)crashIfLocalPortFails messageHandler:(MFMessagePortHandler)messageHandler {
    _processName = processName;
    _localPortName = localPortName;
    _remotePortName = remotePortName;
    _crashIfLocalPortFails = crashIfLocalPortFails;
    _messageHandler = [messageHandler copy];
}

+ (void)load_Manual {
    
    #pragma mark - Init
    
    /// Set up a local port for listening for incoming messages

    /// Log
    DDLogInfo("Initializing MessagePort...");
    
    /// Create port
    CFStringRef messagePortName = (__bridge void *)_localPortName; /// mainApp: `kMFBundleIDApp`, Helper: `kMFBundleIDHelper` [Oct 2026]
    CFMessagePortRef localPort = CFMessagePortCreateLocal(kCFAllocatorDefault, messagePortName, didReceiveMessage, NULL, NULL);

    /// Log
    DDLogInfo("Created localPort: %@", localPort);
    
    /// Validate
    if (localPort == NULL) {
        
        if (!_crashIfLocalPortFails) { /// mainApp [Oct 2026]
            DDLogInfo("Failed to create a local message port. It will probably work anyway for some reason");
        } else { /// Helper
            DDLogError("Failed to create a local message port. This might be because there is another instance of %@ already running. Crashing the app.", kMFHelperName);
            @throw [NSException exceptionWithName:@"NoMessagePortException" reason:@"Couldn't create a local CFMessagePort. Can't function properly without local CFMessagePort" userInfo:nil];
        }

        return;
    }
        
    /// Add message port to main runLoop
    CFRunLoopSourceRef runLoopSource = CFMessagePortCreateRunLoopSource(kCFAllocatorDefault, localPort, 0);
    CFRunLoopAddSource(messagePortRunLoop(), runLoopSource, kCFRunLoopCommonModes);
    CFRelease(runLoopSource);
}

NSString *CFMessagePortSendRequest_ErrorCode_ToString(SInt32 errorCode) {
    
    auto map = @{
        @(kCFMessagePortSuccess)             : @"Success",
        @(kCFMessagePortSendTimeout)         : @"SendTimeout",
        @(kCFMessagePortReceiveTimeout)      : @"ReceiveTimeout",
        @(kCFMessagePortIsInvalid)           : @"IsInvalid",
        @(kCFMessagePortTransportError)      : @"TransportError",
        @(kCFMessagePortBecameInvalidError)  : @"BecameInvalidError",
    };
    
    return map[@(errorCode)] ?: stringf(@"(%d)", errorCode);
}

static CFDataRef _Nullable didReceiveMessage(CFMessagePortRef port, SInt32 messageID, CFDataRef data, void *info) {
    
    #pragma mark Receive messages
    
    /// Decode message
    NSDictionary *messageDict = [NSKeyedUnarchiver unarchiveObjectWithData:(__bridge NSData *)data];
    NSString *message = messageDict[kMFMessageKeyMessage];
    NSObject *payload = messageDict[kMFMessageKeyPayload];
    
    /// Log
    DDLogInfo("Received Message: %@ with payload: %@", message, payload);
    
    /// Process message
    NSObject *response = nil;
    
    /// Handle commands
    ///     Note: [Jul 2025] We're using NSString to identify the commands. I think this is what `SInt32 messageID` is for, but it's nice to be able to debug-print the strings. To replicate that with `SInt32 messageID`, we might wanna use a `FOR_EACH` macro or `X-MACRO` ... or just keep using strings, it works fine.
    
    #define xxx(message_) else if ([message_ isEqual: message])
    
    if ((0)) {}
    xxx(@"getEnvAndArgs") {
        response = @{
            @"env":  NSProcessInfo.processInfo.environment,
            @"args": NSProcessInfo.processInfo.arguments,
        };
    }
    xxx(@"isDarkMode") {
        response = @([[NSAppearance.currentAppearance bestMatchFromAppearancesWithNames: @[NSAppearanceNameAqua, NSAppearanceNameDarkAqua]] isEqual: NSAppearanceNameDarkAqua]);
    }
    
    
    /// Handle target-specific commands
    ///     [Oct 2026] Those used to be mainApp-only / Helper-only `#if` blocks right here. Now they're in `MFMessagePort+App.m` / `MFMessagePort+Helper.m`.
    ///         Note: The handler is called for *every* message (even the ones handled above) – that's how the Helper's `#if` block used to work. (The mainApp's handler skips the ones handled above, which is how the mainApp's `#if` block used to work.)
    if (_messageHandler) {
        NSObject *targetResponse = _messageHandler(message, payload);
        if (targetResponse != nil) response = targetResponse;
    }
    
    #undef xxx
    
    /// Return response
    if (response != nil) {
         return (__bridge_retained CFDataRef)[NSKeyedArchiver archivedDataWithRootObject: response];
    } else {
        return NULL;
    }
}

static void invalidationCallback(CFMessagePortRef ms, void *info) { /// Helper for `sendMessage:` [Oct 2026]
    /// Log state
    NSString *name = _processName ?: @"MainApp"; /// [Oct 2026] mainApp: @"MainApp", Helper: @"Helper". (The LocalizationScreenshotTaker doesn't install hooks – it used to fall into the `#else` (MainApp) branch here, too.)
    DDLogInfo("Remote MessagePort invalidated in %@", name);
}

+ (NSObject *_Nullable)sendMessage:(NSString * _Nonnull)message withPayload:(NSObject<NSCoding> * _Nullable)payload toRemotePort:(NSString *)remotePortName waitForReply:(BOOL)waitForReply {
    
    #pragma mark Send messages
    
    /// Get remote port
    /// Note: We can't just create the port once and cache it, trying to send with that port will yield ``kCFMessagePortIsInvalid``
    CFMessagePortRef remotePort = CFMessagePortCreateRemote(kCFAllocatorDefault, (__bridge CFStringRef)remotePortName);

    /// Validate
    if (remotePort == NULL) {
        DDLogInfo("Can't send message \'%@\', because there is no CFMessagePort", message);
        return nil;
    }
    
    /// Setup callback when port is invalidated
    ///     Not sure why we're doing this.
    CFMessagePortSetInvalidationCallBack(remotePort, invalidationCallback);

    /// Create message dict
    NSDictionary *messageDict;
    if (payload) {
        messageDict = @{
            kMFMessageKeyMessage: message,
            kMFMessageKeyPayload: (id _Nonnull)payload,
        };
    } else {
        messageDict = @{
            kMFMessageKeyMessage: message,
        };
    }
    
    /// Log
    DDLogInfo("Sending message: %@ with payload: %@ from bundle: %@ via message port", message, payload, NSBundle.mainBundle.bundleIdentifier);
    
    /// Send message
    SInt32 messageID = 0x420666; /// Arbitrary
    CFDataRef messageData = (__bridge CFDataRef)[NSKeyedArchiver archivedDataWithRootObject:messageDict];
    CFTimeInterval sendTimeout = 0.0;
    CFTimeInterval recieveTimeout = 0.0;
    CFStringRef replyMode = NULL;
    CFDataRef responseData = NULL;
    if (waitForReply) {
        sendTimeout = 0.0;
        recieveTimeout = 1.0;
        replyMode = kCFRunLoopDefaultMode;
    }
    SInt32 status = CFMessagePortSendRequest(remotePort, messageID, messageData, sendTimeout, recieveTimeout, replyMode, &responseData);
    
    /// Release port
    CFRelease(remotePort);
    
    /// Handle errors
    ///     Should we retry on timeout? [Oct 2025]
    if (status != 0) {
        DDLogError("Non-zero CFMessagePortSendRequest return: %@", CFMessagePortSendRequest_ErrorCode_ToString(status));
        return nil;
    }
    
    /// Decode response
    NSObject *response = nil;
    if (responseData != NULL && waitForReply) {
        response = [NSKeyedUnarchiver unarchiveObjectWithData:(__bridge NSData *)responseData];
    }
    
    /// Return response
    return response;
}

///
/// Helper stuff
///
+ (NSObject *_Nullable)sendMessage:(NSString *)message withPayload:(NSObject<NSCoding> *)payload waitForReply:(BOOL)replyExpected {
        
    /// Convenience wrapper
    ///     Automatically sends the message to the helper if the mainApp is the sender, and sends to the mainApp if the helper is the sender.
    
    /// Get remote port name
    NSString *remotePortName = _remotePortName; /// mainApp: `kMFBundleIDHelper`, Helper: `kMFBundleIDApp` [Oct 2026]

    /// Call core
    NSObject *response = [self sendMessage:message withPayload:payload toRemotePort:remotePortName waitForReply:replyExpected];
    
    /// Return
    return response;
}

@end
