//
//  SimpleDefaults.swift
//
//  Created by Brian Kracoff on 9/11/14.
//  Copyright (c) 2014 Brian Kracoff. All rights reserved.
//
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import UIKit

private let _DebugMode = false

private let _SingletonInstance = SimpleDefaults()

private let _BaseKey = "SimpleDefaults"
private let _DeviceKey = "\(_BaseKey).Device"
private let _UserKey = "\(_BaseKey).User"

public class SimpleDefaults: NSObject {
    
    public class var sharedInstance: SimpleDefaults {
        return _SingletonInstance
    }
    
    // How often to synchronize the Defaults (in seconds)
    public var synchronizeInterval: Double = 5.0 {
        didSet {
            _resetSynchronizeTimer()
        }
    }
    
    private var _deviceDefaults: [String: AnyObject] = Dictionary()
    private var _deviceDefaultsNew = false
    
    private var _userDefaults: [String: AnyObject] = Dictionary()
    private var _userDefaultsNew = false
    
    private var _synchronizeTimer = NSTimer()
    
    override private init() {
        super.init()
        
        _log("Initializing...")
        
        _loadDefaults()
        _resetSynchronizeTimer()
    }
    
    deinit {
        _synchronizeTimer.invalidate()
    }
    
    // MARK: - Loading Defaults
    
    private func _loadDefaults() {
        _loadDeviceDefaults()
        _loadUserDefaults()
    }
    
    // MARK: - Synchronizing
    
    private func _resetSynchronizeTimer() {
        if _synchronizeTimer.valid {
            _synchronizeTimer.invalidate()
        }
        
        _synchronizeTimer = NSTimer.scheduledTimerWithTimeInterval(synchronizeInterval, target: self, selector: Selector("_handleSynchronizeTimerFired"), userInfo: nil, repeats: true)
    }
   
    @objc private func _handleSynchronizeTimerFired() {
        _log("Synchronize timer fired")
        _synchronizeDefaults(synchronize: false)
    }
    
    private func _synchronizeDefaults(synchronize: Bool = false) {
        _saveDeviceDefaults()
        _saveUserDefaults()
        
        if synchronize {
            _synchronize()
        }
    }
    
    private func _synchronize() {
        if UIDevice.currentDevice().systemVersion.compare("8.0",
            options: NSStringCompareOptions.NumericSearch) == NSComparisonResult.OrderedAscending {
                // Only need to do this for iOS 7 or less.
                // In iOS 8, it's synchronized much more often
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    // MARK: - User Defaults
    
    public func getUserDefault<T>(#key: NSString, fallbackValue: T) -> T {
        _log("Searching for user default for key \"\(key)\"")
        
        objc_sync_enter(_userDefaults)
        if let userDefault = _userDefaults[key] as? T {
            objc_sync_exit(_userDefaults)
            _log("Found user default \"\(userDefault)\"")
            return userDefault
        }
        else {
            objc_sync_exit(_userDefaults)
            _log("No user default found, returning fallbackValue")
            return fallbackValue
        }
    }
    
    public func setUserDefault(#key: NSString, value: AnyObject?) {
        _log("Setting user default \"\(value)\" for key \"\(key)\"")
        objc_sync_enter(_userDefaults)
        _userDefaults[key] = value
        _userDefaultsNew = true
        objc_sync_exit(_userDefaults)
    }
    
    public func synchronizeUserDefaults() {
        _saveUserDefaults(synchronize: true)
    }
    
    public func resetUserDefaults() {
        _log("Reseting user defaults")
        objc_sync_enter(_userDefaults)
        _userDefaults.removeAll(keepCapacity: false)
        _userDefaultsNew = true
        objc_sync_exit(_userDefaults)
    }
    
    private func _saveUserDefaults(synchronize: Bool = false) {
        if !_userDefaultsNew {
            return
        }
        
        _log("Saving user defaults")
        
        _userDefaultsNew = false
        NSUserDefaults.standardUserDefaults().setObject(_userDefaults, forKey:_UserKey)
        
        if synchronize {
            _synchronize()
        }
    }
    
    private func _loadUserDefaults() {
        _log("Loading user defaults from disk")
        if let userDefaults = NSUserDefaults.standardUserDefaults().objectForKey(_UserKey) as? [String: AnyObject] {
            _log("User defaults found with \(userDefaults.count) keys")
            objc_sync_enter(_userDefaults)
            _userDefaults = userDefaults
            objc_sync_exit(_userDefaults)
        }
        else {
            _log("No cached user defaults")
        }
    }
    
    // MARK: - Device Defaults
    
    public func getDeviceDefault<T>(#key: NSString, fallbackValue: T) -> T {
        _log("Searching for device default for key \"\(key)\"")
        
        objc_sync_enter(_deviceDefaults)
        if let deviceDefault = _deviceDefaults[key] as? T {
            objc_sync_exit(_deviceDefaults)
            _log("Found device default \"\(deviceDefault)\"")
            return deviceDefault
        }
        else {
            objc_sync_exit(_deviceDefaults)
            _log("No device default found, returning fallbackValue")
            return fallbackValue
        }
        
    }
    
    public func setDeviceDefault(#key: NSString, value: AnyObject?) {
        _log("Setting device default \"\(value)\" for key \"\(key)\"")
        objc_sync_enter(_deviceDefaults)
        _deviceDefaults[key] = value
        _deviceDefaultsNew = true
        objc_sync_exit(_deviceDefaults)
    }
    
    public func synchronizeDeviceDefaults() {
        _saveDeviceDefaults(synchronize: true)
    }
    
    private func _saveDeviceDefaults(synchronize: Bool = false) {
        if !_deviceDefaultsNew {
            return
        }
        
        _log("Saving device defaults")
        
        _deviceDefaultsNew = false
        NSUserDefaults.standardUserDefaults().setObject(_deviceDefaults, forKey:_DeviceKey)
        
        if synchronize {
            _synchronize()
        }
    }
    
    private func _loadDeviceDefaults() {
        _log("Loading device defaults from disk")
        if let deviceDefaults = NSUserDefaults.standardUserDefaults().objectForKey(_DeviceKey) as? [String: AnyObject] {
            _log("Device defaults found with \(deviceDefaults.count) keys")
            objc_sync_enter(_deviceDefaults)
            _deviceDefaults = deviceDefaults
            objc_sync_exit(_deviceDefaults)
        }
        else {
            _log("No cached device defaults")
        }
    }
    
    // MARK: - logging
    
    private func _log(str: String) {
        if _DebugMode {
            println("[INFO] SimpleDefaults: \(str)")
        }
    }
    
}
