//
//  SpeechRecognitionPermissions.swift
//  speech-recognition
//
//  Created by Carla Chipana on 10/2/19.
//  Copyright © 2019 Carla Chipana. All rights reserved.
//

import Foundation
import Speech
import AVFoundation

class SpeechRecognitionPermissions {

    // MARK: - Microphone Permissions

    func getCurrentMicrophonePermission(_ currentMicrophoneStatus: @escaping (Bool) -> Void) {
        let microphoneStatus = AVAudioSession().recordPermission

        switch microphoneStatus {
        case .granted:
            currentMicrophoneStatus(true)

        case .undetermined:
            requestMicrophonePermission(currentMicrophoneStatus)

        case .denied:
            print("Display settings shortcut message")
            currentMicrophoneStatus(false)
        }
    }

    func requestMicrophonePermission(_ microphoneCompletionStatus: @escaping (Bool) -> Void) {

        AVAudioSession().requestRecordPermission { (authorizationStatus) in
            microphoneCompletionStatus(authorizationStatus)
        }
    }

    // MARK: - Speech Recognition Permissions

    func getCurrentSpeechPermission(_ currentSpeechStatus: @escaping (Bool) -> Void) {
        let speechStatus = SFSpeechRecognizer.authorizationStatus()

        switch speechStatus {
        case .authorized:
            currentSpeechStatus(true)

        case .notDetermined:
            requestSpeechPermission(currentSpeechStatus)

        case .denied, .restricted:
            print("Display settings shortcut message")
            currentSpeechStatus(false)
        }
    }

    func requestSpeechPermission(_ speechCompletionStatus: @escaping (Bool) -> Void) {

        SFSpeechRecognizer.requestAuthorization { (authorizationStatus) in

            speechCompletionStatus(authorizationStatus == SFSpeechRecognizerAuthorizationStatus.authorized)
        }
    }

}
