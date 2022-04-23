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
            } //Выбираем максимальное значение среди данных для масштабирования
        
        var colomnsRect = [CGRect]() //сюда будем записывать результаты вычисления размеров и origin наших столбцов
        let distanceBetweenOriginsOnX = frame.width / CGFloat(dataset.count) //Вычисляем расстояние между origin двух соседних столбцов
        let heightRatio = frame.height / max
        
        dataset.forEach {
            // Высоту получаем путём умножения соответствующего значения из dataset на коэффициент масштабирования
            let height = $0 * heightRatio
            let previousColomnOrigin = colomnsRect.last?.origin ?? .zero
            let size = CGSize(
                //Ширину столбца получаем как расстояние между origin двух соседних столбцов, умноженное на коэффициент, который меньше единицы.
                //Чем больше коэффициент, тем жирнее будут столбцы.
                width: distanceBetweenOriginsOnX * constants.widthRatio,
                height: height
            )
            colomnsRect.append(
                CGRect(
                    //Origin текущего столба получаем сдвигом origin предыдущего на его ширину
                    origin: previousColomnOrigin.moveBy(x: distanceBetweenOriginsOnX),
                    size: size
                )
            )
        }
        
        return colomnsRect
    }
    
}
