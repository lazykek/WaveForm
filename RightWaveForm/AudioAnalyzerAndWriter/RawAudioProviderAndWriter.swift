/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Class that generates a spectrogram from an audio signal.
*/
import AVFoundation

final class RawAudioProviderAndWriter: NSObject {
    
    // MARK: - Nested types
    
    struct Constants {
        let captureQueueLabel = "captureQueue"
        let sessionQueueLabel = "sessionQueue"
    }
    
    // MARK: - Public properties
    
    weak var audioReceiverDelegate: AudioReceiverDelegate?
    weak var rawAudioDataReceiverDelegate: RawAudioDataReceiverDelegate?
    
    // MARK: - Private properties
    
    private let constants = Constants()
    private let captureSession = AVCaptureSession()
    private let audioOutput = AVCaptureAudioDataOutput()
    
    let outputSettings: [String : Any] = [
        AVFormatIDKey: UInt(kAudioFormatLinearPCM),
        AVSampleRateKey: 44100,
        AVNumberOfChannelsKey: 2,
        AVLinearPCMBitDepthKey: 16,
        AVLinearPCMIsNonInterleaved: false,
        AVLinearPCMIsFloatKey: false,
        AVLinearPCMIsBigEndianKey: false
    ]
    private var writer: AVAssetWriter?
    private lazy var writerInput = AVAssetWriterInput(
        mediaType: AVMediaType.audio,
        outputSettings: outputSettings
    )

    private lazy var fileURL = FileManager.default.urls(
        for: .documentDirectory,
        in: .userDomainMask
    )[0].appendingPathComponent(UUID().uuidString)
    
    private var averageValuesBuffer = [Float]()
    
    private lazy var captureQueue = DispatchQueue(
        label: constants.captureQueueLabel,
        qos: .userInitiated,
        attributes: [],
        autoreleaseFrequency: .workItem
    )
    
    private lazy var sessionQueue = DispatchQueue(
        label: constants.sessionQueueLabel,
        attributes: [],
        autoreleaseFrequency: .workItem
    )

    // MARK: - Initialization
    
    override init() {
        super.init()
        configureWriter()
        startToConfigureCaptureSession()
        configureAudioOutput()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Functions
    
    func startRunning() {
        checkMicrophoneAccessPermission { [weak self] isAllowed in
            if !isAllowed {
                self?.audioReceiverDelegate?.noMicrophoneAccess()
                return
            }
            self?.sessionQueue.async {
                self?.captureSession.startRunning()
            }
        }
    }
    
    func stopRunning() {
        sessionQueue.async { [weak self] in
            self?.captureSession.stopRunning()
            self?.writerInput.markAsFinished()
            self?.writer?.finishWriting {
                guard let url = self?.fileURL else {
                    return
                }
                self?.audioReceiverDelegate?.recordURLOutput(url)
            }
        }
    }
    
}

// MARK: - AVCaptureAudioDataOutputSampleBufferDelegate

extension RawAudioProviderAndWriter: AVCaptureAudioDataOutputSampleBufferDelegate {
 
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        
        writerInput.append(sampleBuffer)

        var audioBufferList = AudioBufferList()
        var blockBuffer: CMBlockBuffer?
        
        CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
            sampleBuffer,
            bufferListSizeNeededOut: nil,
            bufferListOut: &audioBufferList,
            bufferListSize: MemoryLayout.stride(ofValue: audioBufferList),
            blockBufferAllocator: nil,
            blockBufferMemoryAllocator: nil,
            flags: kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
            blockBufferOut: &blockBuffer
        )
                
        guard let data = audioBufferList.mBuffers.mData else {
            return
        }
        
        let actualSampleCount = CMSampleBufferGetNumSamples(sampleBuffer)
        
        let ptr = data.bindMemory(to: Int16.self, capacity: actualSampleCount)
        let buf = UnsafeBufferPointer(start: ptr, count: actualSampleCount)
        
        rawAudioDataReceiverDelegate?.rawAudioDataOutput(Array(buf))
    }
    
}

// MARK: - Private functions

private extension RawAudioProviderAndWriter {
    
    func startToConfigureCaptureSession() {
        sessionQueue.suspend()
        checkMicrophoneAccessPermission { [weak self] isAllowed in
            if isAllowed {
                self?.configureCaptureSession()
                self?.sessionQueue.resume()
            }
        }
    }
    
    func configureAudioOutput() {
        audioOutput.setSampleBufferDelegate(
            self,
            queue: captureQueue
        )
    }
    
    func checkMicrophoneAccessPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                completion(granted)
            }
        default:
            completion(false)
        }
    }
    
    func configureCaptureSession() {
        captureSession.beginConfiguration()
        
        guard
            let microphone = AVCaptureDevice.default(
                .builtInMicrophone,
                for: .audio,
                position: .unspecified
            ),
            let microphoneInput = try? AVCaptureDeviceInput(device: microphone) else {
                return
            }
                
        if captureSession.canAddInput(microphoneInput) {
            captureSession.addInput(microphoneInput)
        }
        
        if captureSession.canAddOutput(audioOutput) {
            captureSession.addOutput(audioOutput)
        } else {
            print("Can't add `audioOutput`.")
            return
        }
        
        captureSession.commitConfiguration()
    }
    
    func configureWriter() {
        writerInput = AVAssetWriterInput(
            mediaType: AVMediaType.audio,
            outputSettings: outputSettings
        )
        
        do {
            writer = try AVAssetWriter(outputURL: fileURL, fileType: .wav)
            writer?.add(writerInput)
            self.writer?.startWriting()
            self.writer?.startSession(atSourceTime: .zero)
        } catch let error {
            print(error)
        }
    }
    
}
