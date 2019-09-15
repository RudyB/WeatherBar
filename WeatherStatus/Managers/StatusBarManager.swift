//
//  StatusBarManager.swift
//  WeatherStatus
//
//  Created by Rudy Bermudez on 9/10/19.
//  Copyright © 2019 Rudy Bermudez. All rights reserved.
//

import Cocoa
import Houston

class StatusBarManager: NSObject
{
    // MARK:- Properties
    
    fileprivate let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.variableLength)
    
    var menuObserver: CFRunLoopObserver?
    
    private let weatherUpdater: WeatherUpdater
    
    private lazy var menuButton: StatusMenuButtonView = {
        let view = StatusMenuButtonView()
        return view
    }()
    
    // MARK:- Menu Items
    
    private lazy var lastUpdateMenuItem: NSMenuItem = {
        let item = NSMenuItem()
        item.isEnabled = false
        item.isHidden = true
        item.title = "Weather Not Yet Fetched"
        return item
    }()
    
    private lazy var statusMenuItem: NSMenuItem = {
        let item = NSMenuItem()
        item.isEnabled = false
        item.title = "Starting..."
        return item
    }()
    
    private lazy var updateWeatherMenuItem: NSMenuItem = {
        let item = NSMenuItem()
        item.title = "Refresh"
        item.target = self
        item.isHidden = true
        item.action = #selector(StatusBarManager.UpdateWeather)
        return item
    }()
    
    private lazy var temperatureOptionMenuItem: NSMenuItem = {
        let item = NSMenuItem()
        item.title = "Show Temperature"
        item.state = .off
        item.target = self
        item.action = #selector(StatusBarManager.ShowTemperature)
        return item
    }()
    
    private lazy var settingsMenuItem: NSMenuItem = {
        let item = NSMenuItem()
        item.title = "Settings"
        item.target = self
        item.action = #selector(StatusBarManager.ShowSettings)
        item.keyEquivalent = ","
        return item
    }()
    
    private lazy var quitMenuItem: NSMenuItem = {
        let item = NSMenuItem()
        item.title = "Quit"
        item.action = #selector(NSApplication.terminate(_:))
        item.keyEquivalent = "q"
        return item
    }()
    
    var hiddenMenuItems: [NSMenuItem] = []
    
    // MARK:- Public Methods
    override init() {
        
        let apiKey = ProcessInfo.processInfo.environment["API_KEY"]
        weatherUpdater = WeatherUpdater(APIKey: apiKey ?? "")
        super.init()
        if let button = statusItem.button {
            button.addSubview(menuButton)
            menuButton.frame = button.bounds
            menuButton.autoresizingMask = [.width, .height]
            
            ConfigureMenu()
            weatherUpdater.onStateChange = onStateChange
            weatherUpdater.refreshWeatherConditions()
        }
        
    }
    
    // MARK:- Private Methods
    
    private func onStateChange(_ result: APIResult<WeatherUpdater.State>)
    {
        switch result {
        case .failure(let error):
            Logger.error(error)
            self.statusMenuItem.title = "Failed to Update Weather"
        case .success(let state):
            DispatchQueue.main.async { [weak self] in
                self?.statusMenuItem.title = state.description
                if case WeatherUpdater.State.done(_, let weather) = state {
                    self?.menuButton.icon.image = weather.icon.image
                    self?.menuButton.temperature.stringValue = weather.apparentTemperatureString
                    let dateFormatter = DateFormatter()
                    dateFormatter.timeStyle = .short
                    dateFormatter.dateStyle = .short
                    self?.lastUpdateMenuItem.title = "Last Update: \(dateFormatter.string(from: Date()))"
                    self?.lastUpdateMenuItem.isHidden = false
                }
                else {
                    self?.lastUpdateMenuItem.isHidden = true
                }
            }
            
        }
    }
    
    private func ConfigureMenu()
    {
        let menu = NSMenu()
        
        menu.delegate = self
        menu.autoenablesItems = false
        
        menu.addItem(statusMenuItem)
        menu.addItem(lastUpdateMenuItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(temperatureOptionMenuItem)
        menu.addItem(updateWeatherMenuItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(settingsMenuItem)
        menu.addItem(quitMenuItem)
        
        statusItem.menu = menu

        hiddenMenuItems.append(updateWeatherMenuItem)
        
    }
    
    // MARK:- Menu Handling Methods
    
    @objc private func UpdateWeather()
    {
        Logger.verbose("Update Weather")
        weatherUpdater.refreshWeatherConditions()
    }
    
    @objc func ShowTemperature(sender: NSMenuItem)
    {
        if(sender.state == NSControl.StateValue.on)
        {
            Logger.verbose("Hide Temperature")
            sender.state = .off
            menuButton.temperature.isHidden = true
            statusItem.length = 30
        }
        else
        {
            Logger.verbose("Show Temperature")
            sender.state = .on
            menuButton.temperature.isHidden = false
            statusItem.length = 60
        }
    }
    
    @objc private func ShowSettings()
    {
        Logger.verbose("Show Settings")
    }
    
}

// MARK:- NSMenuDelegate
extension StatusBarManager : NSMenuDelegate {
    
    @objc func updateMenuItemVisibility()
    {
        let setHidden = (NSEvent.modifierFlags.rawValue & NSEvent.ModifierFlags.option.rawValue) != NSEvent.ModifierFlags.option.rawValue
        
        for item in hiddenMenuItems
        {
            item.isHidden = setHidden
        }
    }
    
    func menuWillOpen(_ menu: NSMenu) {
        
        if(menuObserver == nil)
        {
            menuObserver =  CFRunLoopObserverCreateWithHandler(nil, CFRunLoopActivity.beforeWaiting.rawValue, true, 0) { [weak self] (_, _) in
                self?.updateMenuItemVisibility()
            }
            
            CFRunLoopAddObserver(CFRunLoopGetCurrent(), menuObserver, CFRunLoopMode.commonModes);
        }
    }
    
    func menuDidClose(_ menu: NSMenu) {
        if let menuObserver = menuObserver {
            CFRunLoopObserverInvalidate(menuObserver)
            self.menuObserver = nil
        }
    }
}
