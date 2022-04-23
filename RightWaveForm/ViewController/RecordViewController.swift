/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view controller.
*/

import AVFoundation
import UIKit

final class RecordViewController: UIViewController {
    
    // MARK: - Nested types
    
    private struct Constants {
        
        let defaultSideInset: CGFloat = 10.0
        let defaultCornerRadius: CGFloat = 10.0
        let defaultSpacing: CGFloat = 10.0
        let defaultControllButtonHeght: CGFloat = 50.0
        let defaultWaveFormHeight: CGFloat = 200.0
        let noMicrophoneAccessTitle = "Микрофон недоступен"
        let noMicrophoneAccessMessage = "Разрешите доступ к микрофону в настройках и перезапустите приложение"
        let recordButtonTitle = "Record"
        let stopButtonTitle = "Stop"
        let playButtonTitle = "Play"
        
    }
    
    // MARK: - Private properties
    
    private var controlButtonsStackHeight: CGFloat {
        contolButtons.arrangedSubviews.reduce(into: 0.0) { partialResult, _ in
            partialResult +=
            constants.defaultControllButtonHeght +
            constants.defaultSpacing
        }
    }
    
    private let constants = Constants()

    private let audioSpectrogram = RawAudioProviderAndWriter()
    private let datasetProvider = DatasetProvider()
    private var audioPlayer: AVAudioPlayer?
    private var recordingUrl: URL?
    
    private lazy var waveForm: WaveFormDisplayable = getWaveForm()
    private lazy var contolButtons = getControlButtonsStack()
    
    private lazy var recordButton = makeButton(
        withTitle: constants.recordButtonTitle,
        color: .blue,
        action: #selector(record)
    )
    
    private lazy var stopButton = makeButton(
        withTitle: constants.stopButtonTitle,
        color: .red,
        action: #selector(stop)
    )
    
    private lazy var playButton = makeButton(
        withTitle: constants.playButtonTitle,
        color: .systemGreen,
        action: #selector(play)
    )
    
    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        view.addSubview(waveForm)
        view.addSubview(contolButtons)
        setupConstraints()
        
        audioSpectrogram.audioReceiverDelegate = self
        audioSpectrogram.rawAudioDataReceiverDelegate = self
        
        stopButton.turnOff()
        playButton.turnOff()
    }
    
}

// MARK: - AudioReceiverDelegate

extension RecordViewController: AudioReceiverDelegate {
        
    func recordURLOutput(_ url: URL) {
        recordingUrl = url
    }
    
    func noMicrophoneAccess() {
        let alert = UIAlertController(
            title: constants.noMicrophoneAccessTitle,
            message: constants.noMicrophoneAccessMessage,
            preferredStyle: .alert
        )
        present(alert, animated: true)
    }

}

extension RecordViewController: RawAudioDataReceiverDelegate {
    
    // MARK: - RawAudioDataReceiverDelegate
    
    func rawAudioDataOutput(_ raw: [Int16]) {
        DispatchQueue.main.async { [weak self] in
            self?.datasetProvider.append(raw)
            self?.waveForm.displayFromDataset(self?.datasetProvider.provide() ?? [])
        }
    }
    
}

// MARK: - Private functions

private extension RecordViewController {
        
    func getWaveForm() -> WaveFormDisplayable {
        let waveForm = WaveFormView()
        waveForm.backgroundColor = .lightGray
        waveForm.clipsToBounds = true
        waveForm.layer.cornerRadius = constants.defaultCornerRadius
        waveForm.layer.borderWidth = 1.0
        waveForm.layer.borderColor = UIColor.black.cgColor
        waveForm.translatesAutoresizingMaskIntoConstraints = false
        return waveForm
    }
    
    func makeButton(withTitle title: String, color: UIColor, action: Selector) -> UIButton {
        let button = UIButton()
        button.setTitle(title, for: .normal)
        button.backgroundColor = color
        button.layer.cornerRadius = constants.defaultCornerRadius
        button.addTarget(self, action: action, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }
    
    func getControlButtonsStack() -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: [
            recordButton, stopButton, playButton
        ])
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 10
        return stackView
    }
    
    func playAudio(url: URL?) {
        guard let url = url else {
            return
        }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Cant load file")
        }
    }
    
    func setupConstraints() {
        NSLayoutConstraint.activate([
            waveForm.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                constant: constants.defaultSideInset
            ),
            waveForm.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                constant: -constants.defaultSideInset
            ),
            waveForm.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: constants.defaultSideInset
            ),
            waveForm.heightAnchor.constraint(equalToConstant: constants.defaultWaveFormHeight),
            
            contolButtons.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                constant: constants.defaultSideInset
            ),
            contolButtons.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                constant: -constants.defaultSideInset
            ),
            contolButtons.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            contolButtons.heightAnchor.constraint(equalToConstant: controlButtonsStackHeight)
        ])
    }
    
    // MARK: - Actions
    
    @objc func record() {
        audioSpectrogram.startRunning()
        recordButton.turnOff()
        stopButton.turnOn()
    }
    
    @objc func stop() {
        audioSpectrogram.stopRunning()
        stopButton.turnOff()
        playButton.turnOn()
    }
    
    @objc func play() {
        playAudio(url: recordingUrl)
    }
    
}

