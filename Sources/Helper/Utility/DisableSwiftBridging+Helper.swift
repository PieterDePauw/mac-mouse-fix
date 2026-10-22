//
// --------------------------------------------------------------------------
// DisableSwiftBridging+Helper.swift
// Created for Mac Mouse Fix (https://github.com/noah-nuebling/mac-mouse-fix)
// Created by Noah Nuebling in 2024
// Licensed under Licensed under the MMF License (https://github.com/noah-nuebling/mac-mouse-fix/blob/master/License)
// --------------------------------------------------------------------------
//

import Foundation

/// [Oct 2026] Split out of `Shared/DisableSwiftBridging/DisableSwiftBridging.swift` (was `#if IS_HELPER`). See explanation there.

extension Remap {
    
    static var remaps: NSDictionary {
        return __remaps() as! NSDictionary
    }
    static func modifications(withModifiers modifiers: NSDictionary) -> NSDictionary? {
        return __modifications(withModifiers: modifiers) as! NSDictionary?
    }
    static func sendAddModeFeedback(_ payload: NSDictionary) {
        __sendAddModeFeedback(payload)
    }
}

extension DeviceManager {
    
    static var attachedDevices: NSArray {
        return __attachedDevices() as! NSArray
    }
}

extension Modifiers {
    
    static func modifiers(with event: CGEvent?) -> NSMutableDictionary {
        return __modifiers(with: event) as! NSMutableDictionary
    }
    
    static func buttonModsChanged(to newMods: NSMutableArray) {
        __buttonModsChanged(to: newMods)
    }
}

extension ModifiedDrag {
    
    static func initializeDrag(withDict dict: NSDictionary) {
        __initializeDrag(withDict: dict)
    }
}

extension Actions {

    static func executeActionArray(_ array: NSArray, phase: MFActionPhase) {
        __executeActionArray(array, phase: phase)
    }
}

extension RemapsAnalyzer {
    
    static func modificationsModifyButtons(_ modifications: NSDictionary, maxButton: Int32) -> Bool {
        return __modificationsModifyButtons(modifications, maxButton: maxButton)
    }
    
    static func modificationsModifyScroll(_ modifications: NSDictionary) -> Bool {
        return __modificationsModifyScroll(modifications)
    }
    static func modificationsModifyPointing(_ modifications: NSDictionary) -> Bool {
        return __modificationsModifyPointing(modifications)
    }
    
    static func maxLevel(forButton button: NSNumber, remaps: NSDictionary, modificationsActingOnThisButton: NSDictionary) -> NSInteger {
        return __maxLevel(forButton: button, remaps: remaps, modificationsActingOnThisButton: modificationsActingOnThisButton)
    }
    
    static func effectExists(forButton button: NSNumber, remaps: NSDictionary, modificationsActingOnButton: NSDictionary) -> Bool {
        return __effectExists(forButton: button, remaps: remaps, modificationsActingOnButton: modificationsActingOnButton)
    }
    
    static func assessMappingLandscape(withButton button: NSNumber, level: NSNumber, modificationsActingOnThisButton: NSDictionary, remaps: NSDictionary, thisClickDoBe: UnsafeMutablePointer<ObjCBool>, thisDownDoBe: UnsafeMutablePointer<ObjCBool>, greaterDoBe: UnsafeMutablePointer<ObjCBool>) {
        __assessMappingLandscape(withButton: button, level: level, modificationsActingOnThisButton: modificationsActingOnThisButton, remaps: remaps, thisClickDoBe: thisClickDoBe, thisDownDoBe: thisDownDoBe, greaterDoBe: greaterDoBe)
    }
    
}

