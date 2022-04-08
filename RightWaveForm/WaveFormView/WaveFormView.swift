//
//  WaveFormView.swift
//  WaveFormGenerator
//
//  Created by Ilya Cherkasov on 28.09.2021.
//

import UIKit

final class WaveFormView: UIView {
    
    // MARK: - Nested types
    
    struct Constants {
        let widthRatio: CGFloat = 0.5
    }
    
    // MARK: - Private properties
    
    private let constants = Constants()
    private var colomnsRect = [CGRect]()
    private var pathBuffer = UIBezierPath()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        reflectAndFlip()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UIView lifecycle
    
    override func draw(_ rect: CGRect) {
        pathBuffer.removeAllPoints()
        colomnsRect.forEach { pathBuffer.append(UIBezierPath(rect: $0)) }
        UIColor.blue.setFill()
        pathBuffer.fill()
    }

}

// MARK: - WaveFormDisplayable

extension WaveFormView: WaveFormDisplayable {
    
    func displayFromDataset(_ dataset: Dataset) {
        colomnsRect = calculateColomnRect(from: dataset)
        setNeedsDisplay()
    }
    
}

// MARK: - Private functions

private extension WaveFormView {
    
    func reflectAndFlip() {
        transform = CGAffineTransform(scaleX: 1, y: -1)
    }
    
    func calculateColomnRect(from dataset: Dataset) -> [CGRect] {
        guard
            let max = dataset.max(),
            max > 0 else {
                return []
            }
        
        var colomnsRect = [CGRect]()
        let distanceBetweenOriginsOnX = frame.width / CGFloat(dataset.count)
        let heightRatio = frame.height / max
        
        dataset.forEach {
            let height = $0 * heightRatio
            let previousColomnOrigin = colomnsRect.last?.origin ?? .zero
            let size = CGSize(
                width: distanceBetweenOriginsOnX * constants.widthRatio,
                height: height
            )
            colomnsRect.append(
                CGRect(
                    origin: previousColomnOrigin.moveBy(x: distanceBetweenOriginsOnX),
                    size: size
                )
            )
        }
        
        return colomnsRect
    }
    
}
