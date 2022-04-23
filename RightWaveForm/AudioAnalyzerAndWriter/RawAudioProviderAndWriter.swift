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
    private let captureSession = AVCaptureSession() ///Управляет захватом данных с микрофона
    private let audioOutput = AVCaptureAudioDataOutput() ///Осуществляет вывод данных и доступ к буферам
    private var writer: AVAssetWriter? ///Пишет данные в нужный нам формат
    private var writerInput: AVAssetWriterInput? ///Добавляет новые данные аудио данные к уже существующим
    private var fileURL: URL?
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
        //startToConfigureCaptureSession()
        configureCaptureSession()
        configureAudioOutput()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Functions
    
    func startRunning() {
        sessionQueue.async {
            if AVCaptureDevice.authorizationStatus(for: .audio) == .authorized {
                self.captureSession.startRunning()
            }
        }
    }
    
    func stopRunning() {
        sessionQueue.async { [weak self] in
            if AVCaptureDevice.authorizationStatus(for: .audio) == .authorized {
                self?.captureSession.stopRunning()
                self?.writer?.finishWriting {
                    guard let url = self?.fileURL else {
                        return
                    }
                    self?.audioReceiverDelegate?.recordURLOutput(url)
                }
            }
        }
    }
    
}

// MARK: - AVCaptureAudioDataOutputSampleBufferDelegate

extension RawAudioProviderAndWriter: AVCaptureAudioDataOutputSampleBufferDelegate {
 
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        
        writerInput?.append(sampleBuffer)

        var audioBufferList = AudioBufferList()
        var blockBuffer: CMBlockBuffer?
        
        CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
            sampleBuffer, ///sampleBuffer - буффер, о котором и говорилось в докладе
            bufferListSizeNeededOut: nil, ///можем положить указатель на целое число, которое задает размер AudioBufferList
            bufferListOut: &audioBufferList, ///кладём указатель на AudioBufferList, куда и будут записываться данные
            bufferListSize: MemoryLayout.stride(ofValue: audioBufferList),
            blockBufferAllocator: nil,
            blockBufferMemoryAllocator: nil,
            flags: kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
            blockBufferOut: &blockBuffer ///необходим, чтобы функция отрабатывала
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
        checkMicrophoneAccessPermission { [weak self] isAllowed in
            self?.configureCaptureSession()
            self?.sessionQueue.resume()
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
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                completion(granted)
            }
        default:
            completion(false)
        }
    }
    
    func configureCaptureSession() {
        captureSession.beginConfiguration()
        
        if captureSession.canAddOutput(audioOutput) {
            captureSession.addOutput(audioOutput)
        } else {
            print("Can't add `audioOutput`.")
            return
        }
        
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
        captureSession.commitConfiguration()
    }
    
    func configureWriter() {
        fileURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent(UUID().uuidString)

        let outputSettings: [String : Any] = [
            AVFormatIDKey: UInt(kAudioFormatLinearPCM),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsNonInterleaved: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]
        
        writerInput = AVAssetWriterInput(
            mediaType: AVMediaType.audio,
            outputSettings: outputSettings
        )
        
        do {
            writer = try AVAssetWriter(outputURL: fileURL!, fileType: .wav)
            writer?.add(writerInput!)
            self.writer?.startWriting()
            self.writer?.startSession(atSourceTime: .zero)
        } catch let error {
            print(error)
        }
    }
    
}
