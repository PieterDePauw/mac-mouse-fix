//
// --------------------------------------------------------------------------
// MFMessagePort.h
// Created for Mac Mouse Fix (https://github.com/noah-nuebling/mac-mouse-fix)
// Created by Noah Nuebling in 2021
// Licensed under the MMF License (https://github.com/noah-nuebling/mac-mouse-fix/blob/master/License)
// --------------------------------------------------------------------------
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Per-target hooks [Oct 2026]
///     MFMessagePort is shared between the mainApp and the Helper (and the LocalizationScreenshotTaker, which only uses `sendMessage:withPayload:toRemotePort:waitForReply:` and doesn't install hooks).
///     What differs between the targets is installed once at launch, before anything touches MFMessagePort. (mainApp: `App/MessagePort/MFMessagePort+App.m`, Helper: `Helper/MessagePort/MFMessagePort+Helper.m`)
///     (Used to be mainApp-only / Helper-only `#if` blocks inside MFMessagePort.m)
///
///     messageHandler: Called for *every* received message, after MFMessagePort.m has handled the messages shared by all targets (`getEnvAndArgs`, `isDarkMode`). Return a non-nil response to reply. Should log unknown messages.
typedef NSObject *_Nullable (^MFMessagePortHandler)(NSString *message, NSObject *_Null_unspecified payload);

@interface MFMessagePort : NSObject

+ (void)installHooksWithProcessName:(NSString *)processName                  /// For logging. mainApp: @"MainApp", Helper: @"Helper"
                      localPortName:(NSString *)localPortName                /// mainApp: `kMFBundleIDApp`, Helper: `kMFBundleIDHelper`
                     remotePortName:(NSString *)remotePortName               /// Used by `sendMessage:withPayload:waitForReply:`. mainApp: `kMFBundleIDHelper`, Helper: `kMFBundleIDApp`
              crashIfLocalPortFails:(BOOL)crashIfLocalPortFails              /// mainApp: NO (It will probably work anyway), Helper: YES (Probably another instance of the Helper is running)
                     messageHandler:(MFMessagePortHandler)messageHandler;

+ (void)load_Manual;

+ (NSObject *_Nullable)sendMessage:(NSString * _Nonnull)message withPayload:(NSObject <NSCoding> * _Nullable)payload waitForReply:(BOOL)replyExpected;
+ (NSObject *_Nullable)sendMessage:(NSString * _Nonnull)message withPayload:(NSObject<NSCoding> * _Nullable)payload toRemotePort:(NSString *)remotePortName waitForReply:(BOOL)waitForReply;

@end

NS_ASSUME_NONNULL_END
