//
// --------------------------------------------------------------------------
// License+Helper.swift
// Created for Mac Mouse Fix (https://github.com/noah-nuebling/mac-mouse-fix)
// Created by Noah Nuebling in 2022
// Licensed under the MMF License (https://github.com/noah-nuebling/mac-mouse-fix/blob/master/License)
// --------------------------------------------------------------------------
//

/// [Oct 2026] The Helper-specific part of `Shared/License/License.swift` – moved here (verbatim) from a Helper-only `#if` block in there, since it calls into the Helper (`SwitchMaster`, `TrialNotificationController`).

import Cocoa

extension License {

    @objc static func checkAndReact(triggeredByUser: Bool) {

        /// This runs a check and then if necessary it:
        /// - ... shows some feedback about the licensing state to the user
        /// - ... locks down the helper
        
        /// Start an async-context
        Task.init(priority: (triggeredByUser ? .userInitiated : .background), operation: { @LicensingActor in
            assertRunLoop(licensingRunLoop())

            /// Get licensing state
            let licenseState = await GetLicenseState.get()
            
            if licenseState.isLicensed {
                
                /// Do nothing if licensed
                return
                
            } else {
                
                /// Get stuff
                let licenseConfig = await GetLicenseConfig.get()  /// This makes an internet connection, so we wanna avoid calling it unless necessary. Read more in the definition.
                let trialState = GetTrialState.get(licenseConfig)
                
                /// Not licensed -> check trial
                if trialState.trialIsActive {
                    
                    /// Trial still active -> do nothing
                    //      TODO: @UX Maybe display small reminder after half of trial is over? Or when there's one week of the trial left?
                    
                } else {
                    
                    /// Trial has expired -> show UI
                    
                    if triggeredByUser {
                        
                        /// Display more complex UI
                        ///     This is unused so far
                        ///     Opus 5.5: [Sep 2026] Was meant for the mainApp (used to `assert(runningMainApp())` here), but this function is Helper-only now.
                        assert(false)
                        
                    } else {
                        
                        /// Not triggered by user -> the users workflow is disruped -> make it as short as possible
                        
                        /// Show trialNotification
                        mfrun(CFRunLoopGetMain()) {
                            TrialNotificationController.shared.open(licenseConfig: licenseConfig, licenseState: licenseState, trialState: trialState, triggeredByUser: triggeredByUser)
                        }

                        /// Lock helper
                        SwitchMaster.shared.lockDown()
                        
                    }
                }
            }
        })
    }
}
