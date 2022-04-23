//
//  UIButton.swift
//  RightWaveForm
//
//  Created by Ilya Cherkasov on 30.04.2022.
//

import UIKit

extension UIButton {
    
    func turnOn() {
        isEnabled = true
        alpha = 1
    }
    
    func turnOff() {
        isEnabled = false
        alpha = 0.3
    }
    
}
