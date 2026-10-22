//
// --------------------------------------------------------------------------
// MenuBarItem.swift
// Created for Mac Mouse Fix (https://github.com/noah-nuebling/mac-mouse-fix)
// Created by Noah Nuebling in 2022
// Licensed under the MMF License (https://github.com/noah-nuebling/mac-mouse-fix/blob/master/License)
// --------------------------------------------------------------------------
//

/// This uses non-reactive state management. It's so complicated even for this simple example!

/**
 Also see:
 https://github.com/noah-nuebling/mac-mouse-fix/issues/190
 
 */

import Foundation

@objc class MenuBarItem: NSObject {
    
    // MARK: Vars and outlets
    
    var topLevelObjects: NSArray? = []
    static var instance: MenuBarItem? = nil
    
    var statusItem: NSStatusItem? = nil
    @IBOutlet var menu: NSMenu!
    
    @IBOutlet weak var scrollEnabledItem: NSMenuItem!
    @IBOutlet weak var buttonsEnabledItem: NSMenuItem!
    
    @IBOutlet weak var appCompatItem: NSMenuItem!
    @IBOutlet var appCompatView: NSView!
    
    @IBOutlet weak var appCompatHintItem: NSMenuItem!
    @IBOutlet var appCompatHintView: NSView!

    /// Master on/off switch. Built in code (instead of IB) because it's a custom view item like the ones in the system's Wi-Fi/Bluetooth menus.
    ///     Its state is derived from the two killSwitches – it's on unless both buttons and scrolling are killed – so there's no extra config key.
    var masterItem: NSMenuItem? = nil
    var masterSwitch: NSSwitch? = nil

    // MARK: Init
    
    @objc static func load_Manual() {
        assertRunLoop(CFRunLoopGetMain())
        instance = MenuBarItem()
        Bundle.main.loadNibNamed(NSNib.Name("MenuBarItem"), owner: instance, topLevelObjects: &(instance!.topLevelObjects))
        instance?.load_Manual()
    }
    
    func load_Manual() {
        
        /// Setup statusbar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.autosaveName = "MMFMenuBarItem" /// Probably unnecessary
        statusItem?.button?.title = ""
        let image = NSImage(named: "CoolMenuBarIcon")
        statusItem?.button?.image = image
        statusItem?.menu = menu
        //statusItem?.isVisible = false /// This makes the item forget its position when restarting the computer

        /// Turn off menuItem autoenabling
        ///     So we can control enabling through SwitchMaster
        statusItem?.menu?.autoenablesItems = false
        
        /// Setup group menu item
        /// `.indentationLevel` doesn't work. Do indentation in IB autolayout instead
        appCompatItem.view = appCompatView
        
        /// Turn off group item
        //menu.removeItem(appCompatItem)

        /// Setup hint menu item
        appCompatHintItem.view = appCompatHintView
        
        /// Turn off hint
        menu.removeItem(appCompatHintItem)

        /// Setup master switch item
        setupMasterItem()

        /// Load state
        MenuBarItem.reload()
    }

    private func setupMasterItem() {

        /// Label
        let label = NSTextField(labelWithString: MFLocalizedString("menu-bar-item.master-toggle", comment: "Title next to the on/off switch at the top of the menu bar item's menu. Turning the switch off disables both buttons and scrolling features."))
        label.font = NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false

        /// Switch
        let toggle = NSSwitch()
        toggle.controlSize = .mini
        toggle.target = self
        toggle.action = #selector(toggleMaster(_:))
        toggle.translatesAutoresizingMaskIntoConstraints = false
        toggle.setAccessibilityLabel(label.stringValue)

        /// Container
        ///     Uses autoresizing (not constraints) for the container itself so NSMenu can stretch it to the menu's width
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 220, height: 30))
        container.autoresizingMask = [.width]
        container.addSubview(label)
        container.addSubview(toggle)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            toggle.leadingAnchor.constraint(greaterThanOrEqualTo: label.trailingAnchor, constant: 12),
            toggle.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            toggle.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])

        /// Clicking the label toggles, too – like in the system menus
        container.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(clickMasterRow(_:))))

        /// Insert at the top, followed by a separator
        let item = NSMenuItem()
        item.view = container
        menu.insertItem(item, at: 0)
        menu.insertItem(NSMenuItem.separator(), at: 1)

        masterItem = item
        masterSwitch = toggle
    }

    /// Reflect killSwitch state in the UI. Call on main.
    private func applyState(buttonsKilled: Bool, scrollKilled: Bool) {
        assertRunLoop(CFRunLoopGetMain())
        let isOn = !(buttonsKilled && scrollKilled)
        buttonsEnabledItem.state = !buttonsKilled ? .on : .off
        scrollEnabledItem.state = !scrollKilled ? .on : .off
        masterSwitch?.state = isOn ? .on : .off
        statusItem?.button?.appearsDisabled = !isOn /// Dim the menu bar icon while everything is off, so the state is visible without opening the menu
    }

    private func writeKillSwitches(buttonsKilled: Bool, scrollKilled: Bool) {
        assertRunLoop(CFRunLoopGetMain())
        applyState(buttonsKilled: buttonsKilled, scrollKilled: scrollKilled)
        mfrun(IOThread.runLoop()) {
            setConfig("General.buttonKillSwitch", buttonsKilled as NSObject)
            setConfig("General.scrollKillSwitch", scrollKilled as NSObject)
            commitConfig()
        }
    }
    
    // MARK: SwitchMaster interface
    
    static func enableButtonsItem(_ enable: Bool) { /// Note: [Mar 2025] 'enabled' doesn't mean the item is checked. It means that it's clickable and not grayed-out.
        assertRunLoop(CFRunLoopGetMain())
        instance?.buttonsEnabledItem.isEnabled = enable

    }
    static func enableScrollItem(_ enable: Bool) {
        assertRunLoop(CFRunLoopGetMain())
        instance?.scrollEnabledItem.isEnabled = enable
    }
    
    static func buttonsItemIsEnabled() -> Bool { /// This is for introspection for debugging SwitchMaster
        assertRunLoop(CFRunLoopGetMain())
        return instance?.buttonsEnabledItem.isEnabled ?? false
    }
    static func scrollItemIsEnabled() -> Bool {
        assertRunLoop(CFRunLoopGetMain())
        return instance?.scrollEnabledItem.isEnabled ?? false
    }
    
    // MARK: Reload
    
    @objc static func reload() {

        assertRunLoop(IOThread.runLoop())

        let shouldShow = config("General.showMenuBarItem") as? Bool ?? false
        mfrun(CFRunLoopGetMain()) {
            instance?.statusItem?.isVisible = shouldShow
        }

        let buttonsKilled = config("General.buttonKillSwitch") as? Bool ?? false
        let scrollKilled = config("General.scrollKillSwitch") as? Bool ?? false
        
        if shouldShow {

            mfrun(CFRunLoopGetMain()) {
                instance?.applyState(buttonsKilled: buttonsKilled, scrollKilled: scrollKilled)
            }
            
        }
        else {

            /// Disable all settings from the menuItem, if the menuItem is disabled
            /// Need to do the killed check to prevent infinite loops. (Not sure if true anymore). This would be easier if we just used the reactive ConfigValue instead.
            
            if (buttonsKilled || scrollKilled) {
                setConfig("General.scrollKillSwitch", false as NSObject)
                setConfig("General.buttonKillSwitch", false as NSObject)
                commitConfig()
            }
        }
    }
    
    // MARK: IBActions
    
    @IBAction func openMMF(_ sender: Any) {
        assertRunLoop(CFRunLoopGetMain())
        HelperUtility.openMainApp()
    }
    
    @IBAction func disableScroll(_ sender: NSMenuItem) {
        assertRunLoop(CFRunLoopGetMain())
        // TODO: Fix bug where scrolling freezes after turning smooth scroll back on

        /// Toggle & set to config
        ///     Also writes the buttons killSwitch (unchanged), so the master switch stays in sync
        let scrollKilled = sender.state == .on
        writeKillSwitches(buttonsKilled: buttonsEnabledItem.state != .on, scrollKilled: scrollKilled)
    }

    @IBAction func disableButtons(_ sender: NSMenuItem) {
        assertRunLoop(CFRunLoopGetMain())
        /// Toggle & set to config
        let buttonsKilled = sender.state == .on
        writeKillSwitches(buttonsKilled: buttonsKilled, scrollKilled: scrollEnabledItem.state != .on)
    }

    @objc func toggleMaster(_ sender: NSSwitch) {
        assertRunLoop(CFRunLoopGetMain())
        /// Off kills both features, on revives both
        let killed = sender.state != .on
        writeKillSwitches(buttonsKilled: killed, scrollKilled: killed)
    }

    @objc func clickMasterRow(_ sender: NSClickGestureRecognizer) {
        guard let toggle = masterSwitch, let row = sender.view else { return }
        if toggle.frame.contains(sender.location(in: row)) { return } /// The switch handles its own clicks – don't toggle twice
        toggle.state = toggle.state == .on ? .off : .on
        toggleMaster(toggle)
    }
    
    @IBAction func checkUpdates(_ sender: Any) {
        
        /// Implement?
    }
    
}
