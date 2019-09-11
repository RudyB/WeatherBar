//
//  StatusBarManager.swift
//  WeatherStatus
//
//  Created by Rudy Bermudez on 9/10/19.
//  Copyright © 2019 Rudy Bermudez. All rights reserved.
//

import Cocoa


class StatusBarManager: NSObject
{
    // MARK:- Properties
    
    fileprivate let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.variableLength)
    
    var menuObserver: CFRunLoopObserver?
    
    private let weatherUpdater: WeatherUpdater
    
    // MARK:- Menu Items
    
    private lazy var currentConditionsMenuItem: NSMenuItem = {
        let item = NSMenuItem()
        item.isEnabled = false
        item.title = "Loading Weather Conditions"
        return item
    }()
    
    private lazy var updateWeatherMenuItem: NSMenuItem = {
        let item = NSMenuItem()
        item.title = "Update"
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
            button.title = "--℉"
            button.image = NSImage(named: NSImage.Name("default"))!
                .tint(color: NSColor.black)
                .resized(to: NSSize(width: 15, height: 15))
            ConfigureMenu()
            weatherUpdater.onCurrentForecastFetched = onWeatherFetched(_:)
            weatherUpdater.refreshWeatherConditions()
        }
        
    }
    
    // MARK:- Private Methods
    
    private func onWeatherFetched(_ result: APIResult<CurrentWeather>)
    {
        guard let button = statusItem.button else { return }
        
        switch result {
        case .failure(let error):
            print(error)
        case .success(let weather):
            DispatchQueue.main.async { [weak self] in
                self?.currentConditionsMenuItem.title = "\(weather.apparentTemperatureString) \(weather.summary)"
                button.image = weather.icon.image
                    .tint(color: NSColor.black)
                    .resized(to: NSSize(width: 15, height: 15))
            }
            
        }
    }
    
    private func ConfigureMenu()
    {
        let menu = NSMenu()
        
        menu.delegate = self
        menu.autoenablesItems = false
        
        menu.addItem(currentConditionsMenuItem)
        menu.addItem(updateWeatherMenuItem)
        menu.addItem(temperatureOptionMenuItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(settingsMenuItem)
        menu.addItem(quitMenuItem)
        
        statusItem.menu = menu
        
        hiddenMenuItems.append(updateWeatherMenuItem)
    }
    
    // MARK:- Menu Handling Methods
    
    @objc private func UpdateWeather()
    {
        print("Update Weather")
        weatherUpdater.refreshWeatherConditions()
    }
    
    @objc func ShowTemperature(sender: NSMenuItem)
    {
        print("Show Temperature")
        if(sender.state == NSControl.StateValue.on)
        {
            sender.state = .off
        }
        else
        {
            sender.state = .on
        }
    }
    
    @objc private func ShowSettings()
    {
        print("Show Settings")
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
