//
//  RawAudioDataReceiverDelegate.swift
//  RightWaveForm
//
//  Created by Ilya Cherkasov on 06.04.2022.
//

import Foundation

protocol RawAudioDataReceiverDelegate: AnyObject {
    
    func rawAudioDataOutput(_ raw: [Int16])
    
}
