//
//  LoadingView.swift
//  JudoKit
//
//  Created by Hamon Riazy on 07/09/2015.
//  Copyright © 2015 Judo Payments. All rights reserved.
//

import UIKit

class LoadingView: UIView {

    init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor(red: 210/255, green: 210/255, blue: 210/255, alpha: 1.0)
    }
    
    init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.backgroundColor = UIColor(red: 210/255, green: 210/255, blue: 210/255, alpha: 1.0)
    }
    
}
