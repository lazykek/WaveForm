//
//  CGPoint.swift
//  RightWaveForm
//
//  Created by Ilya Cherkasov on 05.04.2022.
//

import UIKit

extension CGPoint {
    
    func moveBy(x: CGFloat, y: CGFloat = 0) -> CGPoint {
        var point = self
        point.x += x
        point.y += y
        return point
    }
    
}
