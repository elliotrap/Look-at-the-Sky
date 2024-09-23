//
//  SilentSystem.swift
//  GuideMe
//
//  Created by Elliot Rapp on 9/17/24.
//

import Foundation
import SwiftUI
import AVFoundation
import AVFAudio

// MARK: - Data Models

enum MeditationSegmentType {
    case recording(URL)
    case silence(TimeInterval) // Duration in seconds
}

struct MeditationSegment: Identifiable {
    let id = UUID()
    let type: MeditationSegmentType
}
class SilentRecorder: NSObject, ObservableObject, AVAudioPlayerDelegate {
    static let shared = SilentRecorder()
    @ObservedObject var variables = CrossAppVariables.shared

    private var audioPlayer: AVAudioPlayer?
    private var currentSegmentIndex: Int = 0

    func startPlayback() {
        let segments = variables.meditationSegments
        guard !segments.isEmpty else { return }
        currentSegmentIndex = 0
        variables.isPlaying = true
        playNextSegment(segments: segments)
    }

    private func playNextSegment(segments: [MeditationSegment]) {
        guard currentSegmentIndex < segments.count else {
            // Playback finished
            variables.isPlaying = false
            return
        }

        let segment = segments[currentSegmentIndex]
        switch segment.type {
        case .recording(let url):
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.delegate = self
                audioPlayer?.play()
                variables.currentPlayingURL = url
            } catch {
                print("Failed to play recording: \(error.localizedDescription)")
                // Skip to next segment
                currentSegmentIndex += 1
                playNextSegment(segments: segments)
            }
        case .silence(let duration):
            // Wait for the duration
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                self.currentSegmentIndex += 1
                self.playNextSegment(segments: segments)
            }
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        currentSegmentIndex += 1
        playNextSegment(segments: variables.meditationSegments)
    }

    func stopPlayback() {
        audioPlayer?.stop()
        variables.isPlaying = false
    }
}
