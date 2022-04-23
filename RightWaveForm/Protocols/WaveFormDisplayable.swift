//
//  WaveFormDisplayable.swift
//  RightWaveForm
//
//  Created by Ilya Cherkasov on 05.04.2022.
//

import UIKit

protocol WaveFormDisplayable: UIView {
    
    typealias Dataset = [CGFloat]
    
    func displayFromDataset(_ dataset: Dataset)
    
}
