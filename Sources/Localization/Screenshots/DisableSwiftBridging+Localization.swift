//
// --------------------------------------------------------------------------
// DisableSwiftBridging+Localization.swift
// Created for Mac Mouse Fix (https://github.com/noah-nuebling/mac-mouse-fix)
// Created by Noah Nuebling in 2024
// Licensed under Licensed under the MMF License (https://github.com/noah-nuebling/mac-mouse-fix/blob/master/License)
// --------------------------------------------------------------------------
//

import Foundation

/// [Oct 2026] Split out of `Shared/DisableSwiftBridging/DisableSwiftBridging.swift` (was `#if IS_MAIN_APP || IS_XC_TEST`). See explanation there.

/// Only compiled into the mainApp and the LocalizationScreenshotTaker (not the Helper)

extension NSAttributedString {
    
    /// NSString+Steganography.h
    
    func attributedStringByAppendingString(asSecretMessage message: NSString) -> NSAttributedString {
        return __attributedStringByAppendingString(asSecretMessage: message) as! NSAttributedString
    }
    func _secretMessages() -> NSArray {
        return ___secretMessages() as! NSArray
    }
    //func withoutSecretMessages() -> NSAttributedString {
    //    return __withoutSecretMessages() as! NSAttributedString
    //}
}

extension NSString {
    
    /// NSString+Steganography.h
    
    func stringByAppendingString(asSecretMessage message: NSString) -> NSString {
        return __stringByAppendingString(asSecretMessage: message) as! NSString
    }
    func encodedAsSecretMessage() -> NSString {
        return __encodedAsSecretMessage() as! NSString
    }
    func _secretMessages() -> NSArray {
        return ___secretMessages() as! NSArray
    }
    func withoutSecretMessages() -> NSString {
        return __withoutSecretMessages() as! NSString
    }
    
}

extension NSString {

    /// LocalizedStringAnnotation.h

    func withoutAnnotations() -> NSString {
        return __withoutAnnotations() as! NSString
    }
}

