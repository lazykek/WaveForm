//
//  DatasetProvider.swift
//  RightWaveForm
//
//  Created by Ilya Cherkasov on 08.04.2022.
//

import UIKit

final class DatasetProvider {
    
    // MARK: - Private properties
    
    private var raw = [Int16]()
    private var dataset = [CGFloat]()
    private var lock = NSLock()
    
    // MARK: - Functions
    
    func append(_ raw: [Int16]) {
        lock.lock()
        self.raw += raw
        // Решение на вычисление среднего значения плохое, в теории этот кусок может упасть
        // Лучше использовать Accelerate
        var average: CGFloat = 0.0
        for number in raw {
            average += CGFloat(abs(number)) / CGFloat(raw.count)
        }
        dataset.append(average)
        //------------
        lock.unlock()
    }
    
    func provide() -> [CGFloat] {
        dataset
    }
    
}
