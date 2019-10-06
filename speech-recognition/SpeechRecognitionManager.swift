//
//  SpeechRecognitionManager.swift
//  speech-recognition
//
//  Created by Carla Chipana on 9/28/19.
//  Copyright © 2019 Carla Chipana. All rights reserved.
//

import Foundation
import Speech

protocol SpeechManagerDelegate: class {
    func didChange(text: String?)
    func didEnd(text: String?)
    func didChangeAvailability(with available: Bool)
    func didGetError(with errorMessage: String)
}

class SpeechRecognitionManager {
    static let shared = SpeechRecognitionManager()

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    weak var delegate: SpeechManagerDelegate?

    func start() {
        startRecording()
    }

    func stop() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask?.finish()
        recognitionTask = nil
    }

    func startRecording() {
        if audioEngine.isRunning || recognitionTask != nil || recognitionRequest != nil {
            stop()
        }

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.record)
            try audioSession.setMode(AVAudioSession.Mode.measurement)
            try audioSession.setActive(true, options: AVAudioSession.SetActiveOptions.notifyOthersOnDeactivation)
        } catch {
            delegate?.didGetError(with: "Error setting up audioSession")
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            delegate?.didGetError(with: "Error setting up SFSpeechRecognitionRequest")
            return
        }
        recognitionRequest.shouldReportPartialResults = true
//        recognitionRequest.taskHint = .search

        let recordingFormat = audioEngine.inputNode.outputFormat(forBus: 0)
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, _) in
            self.recognitionRequest?.append(buffer)

            // nice to have: capture decibel
            // https://stackoverflow.com/a/50237644
/*          if let maxVolume = self.getPeakDecibel(from: buffer) {
                self.decibels = maxVolume
            } else {
                self.decibels = 0
            }
 */
        }
        audioEngine.prepare()

        do {
            try audioEngine.start()
        } catch {
            delegate?.didGetError(with: "Error starting audioEngine")
            return
        }

        /// Executes the speech recognition request and delivers the results to the specified handler block


        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in

            let text = result?.bestTranscription.formattedString
            var isFinal = false

            if result != nil {
                self.delegate?.didChange(text: text)
                isFinal = result?.isFinal ?? false
            }

            print("\nRecognition task=\(String(describing: self.recognitionTask?.state.rawValue))")
            print("Detected text=\(String(describing: text))")
            print("Result IsFinal=\(String(describing: result?.isFinal))")

            if let recognitionTask = self.recognitionTask,
                recognitionTask.state != SFSpeechRecognitionTaskState.starting,
                error != nil || isFinal {

                if let error = error {
                    print("Error=\(String(describing: error.localizedDescription))")
                }

                switch recognitionTask.state {
                case SFSpeechRecognitionTaskState.completed: // or isFinal
                    self.stop()
                    self.delegate?.didEnd(text: text)
                default:
                    if let error = error {
                        self.delegate?.didGetError(with: error.localizedDescription)
                        return
                    }
                }
            }
        })
    }

    // MARK: - SFSpeechRecognizerDelegate
    ///  handles changes to the availability of speech recognition services.
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        self.delegate?.didChangeAvailability(with: available)
    }
}
