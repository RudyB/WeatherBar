//
//  StatusMenuButtonView.swift
//  WeatherStatus
//
//  Created by Rudy Bermudez on 9/13/19.
//  Copyright © 2019 Rudy Bermudez. All rights reserved.
//

import Cocoa

class StatusMenuButtonView: NSView {

    @IBOutlet var contentView: NSView!
    @IBOutlet weak var icon: NSImageView!
    @IBOutlet weak var temperature: NSTextField!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit()
    {
        Bundle.main.loadNibNamed("StatusMenuButtonView", owner: self, topLevelObjects: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.width, .height]
    }
    
}
