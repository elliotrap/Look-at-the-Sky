//
//  CrossAppVariables.swift
//  GuideMe
//
//  Created by Elliot Rapp on 9/17/24.
//

import Foundation
import AVFoundation

class CrossAppVariables: NSObject, ObservableObject, AVAudioPlayerDelegate, AVAudioRecorderDelegate {
    static let shared = CrossAppVariables()

    // Audio Recorder and Player
    var audioRecorder: AVAudioRecorder?
    var audioPlayer: AVAudioPlayer?
    
    // Published Variables
    @Published var currentPlayingURL: URL?
    @Published var currentRecordingURL: URL?
    @Published var meditationSegments: [MeditationSegment] = []
    @Published var isPickerOpen: Bool = false
    @Published var isPlaying: Bool = false
    @Published var isRecording: Bool = false
}
