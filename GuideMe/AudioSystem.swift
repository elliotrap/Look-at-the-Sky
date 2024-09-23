//
//  AudioSystem.swift
//  GuideMe
//
//  Created by Elliot Rapp on 9/17/24.
//

import SwiftUI
import AVFoundation
import AVFAudio

class AudioRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    static var shared = AudioRecorder()
    @ObservedObject var variables = CrossAppVariables.shared

    
    var audioRecorder: AVAudioRecorder?
    var audioPlayer: AVAudioPlayer?

    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var currentPlayingURL: URL?
    @Published var permissionGranted = false 

    override init() {
        super.init()
        setupRecorder()
        fetchRecordings()
    }

    // MARK: - Setup Recorder and Permissions

    func setupRecorder() {
        #if targetEnvironment(simulator)
        // If running in the simulator, automatically set permissionGranted to true
        permissionGranted = true
        fetchRecordings()
        print("Running in simulator: Permission granted automatically.")
        #else
        // Check the iOS version and request permission for real devices
        if #available(iOS 17.0, *) {
            // Use AVAudioApplication's new class method for iOS 17 and above
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    self?.permissionGranted = granted
                    if granted {
                        print("Permission granted")
                        self?.fetchRecordings()
                    } else {
                        print("Permission denied")
                    }
                }
            }
        } else {
            // Fallback on earlier versions using AVAudioSession
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    self?.permissionGranted = granted
                    if granted {
                        print("Permission granted")
                        self?.fetchRecordings()
                    } else {
                        print("Permission denied")
                    }
                }
            }
        }
        #endif
    }

    // MARK: - Recording Functions
    
    func startRecording() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent(generateUniqueFileName())

        // Define the recording settings
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            // Setup the audio session
            let session = AVAudioSession.sharedInstance()
            
            // Set category with options to default to speaker and allow Bluetooth
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            
            // Activate the session
            try session.setActive(true)
            
            // Select the built-in microphone
            if let builtInMic = session.availableInputs?.first(where: { $0.portType == .builtInMic }) {
                try session.setPreferredInput(builtInMic)
                print("Selected Built-In Microphone: \(builtInMic.portName)")
            } else {
                print("Built-In Microphone not found. Using default input.")
            }
            
            // Initialize and prepare the recorder
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            isRecording = true
            print("Recording started with URL: \(audioFilename)")
        } catch {
            print("Could not start recording: \(error.localizedDescription)")
        }
    }
    

    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false

        // Save the recording URL
        if let url = audioRecorder?.url {
            variables.currentRecordingURL = url
            variables.meditationSegments.append(MeditationSegment(type: .recording(url)))
            print("Recording saved at URL: \(url)")
        }

        // Deactivate the audio session
        let session = AVAudioSession.sharedInstance()
        try? session.setActive(false)

        // Open the silence duration picker
        variables.isPickerOpen = true

        // Debug print the current state of meditationSegments
        printMeditationSegments()
    }
    
    func printMeditationSegments() {
        print("Current meditationSegments:")
        for (index, segment) in variables.meditationSegments.enumerated() {
            switch segment.type {
            case .recording(let url):
                print("Segment \(index + 1): Recording - \(url.lastPathComponent)")
            case .silence(let duration):
                print("Segment \(index + 1): Silence for \(duration) seconds")
            }
        }
    }
    // MARK: - Playback Functions

    func playRecording(url: URL) {
        do {
            // Initialize the audio player with the selected recording file
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()

            isPlaying = true
            currentPlayingURL = url
        } catch {
            print("Could not play recording: \(error.localizedDescription)")
        }
    }

    func stopPlayback() {
        audioPlayer?.stop()
        isPlaying = false
        currentPlayingURL = nil
    }

    // MARK: - Helper Functions

    func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    func generateUniqueFileName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"
        let timestamp = formatter.string(from: Date())
        return "Recording_\(timestamp).m4a"
    }

    func fetchRecordings() {
        let directory = getDocumentsDirectory()
        do {
            let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            let m4aFiles = files.filter { $0.pathExtension == "m4a" }
            DispatchQueue.main.async {
        
                
                // Append fetched recordings to meditationSegments
                for url in m4aFiles.sorted(by: { $0.lastPathComponent > $1.lastPathComponent }) {
                    self.variables.meditationSegments.append(MeditationSegment(type: .recording(url)))
                }
            }
        } catch {
            print("Could not fetch recordings: \(error.localizedDescription)")
        }
    }

    // Delete a recording
    func deleteRecording(url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            print("Could not delete recording: \(error.localizedDescription)")
        }
    }
    
    func appendNewRecording() {
        guard let url = variables.audioRecorder?.url else {
            print("No recording URL found.")
            return
        }
        
        DispatchQueue.main.async {
            self.variables.meditationSegments.append(MeditationSegment(type: .recording(url)))
        }
    }

}

// MARK: - AVAudioRecorderDelegate & AVAudioPlayerDelegate

extension AudioRecorder {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        currentPlayingURL = nil
    }

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            print("Recording finished successfully.")
            appendNewRecording()
        } else {
            print("Recording failed.")
        }
    }
    

}
