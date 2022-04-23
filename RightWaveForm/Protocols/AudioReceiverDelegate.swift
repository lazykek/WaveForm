//
//  AudioReceiverDelegate.swift
//  RightWaveForm
//
//  Created by Ilya Cherkasov on 06.04.2022.
//

import Foundation

protocol AudioReceiverDelegate: AnyObject {
    
    func recordURLOutput(_ url: URL)
    func noMicrophoneAccess()
    
}
