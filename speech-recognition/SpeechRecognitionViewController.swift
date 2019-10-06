//  Copyright © 2019 Carla Chipana. All rights reserved.

import UIKit

class SpeechRecognitionViewController: UIViewController {

    @IBOutlet var mainView: UIView!
    @IBOutlet var contentView: UIView!
    @IBOutlet var microphoneContainerView: UIView!
    @IBOutlet var speechResultsView: UIView!
    @IBOutlet var speechResultsLabel: UILabel!
    @IBOutlet var microphoneImageView: UIImageView!
    @IBOutlet var stopSpeechRecognitionImageView: UIImageView!

    var microphone: UIImage {
        return #imageLiteral(resourceName: "microphone")
    }

    lazy var speechRecognitionManager = SpeechRecognitionManager.shared
    private var permissions = SpeechRecognitionPermissions()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupAppearance()
        speechRecognitionManager.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        reset()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        speechRecognitionManager.stop()
    }

    // MARK: - Setup

    private func setupAppearance() {
        speechResultsLabel.numberOfLines = 0
        speechResultsLabel.lineBreakMode = .byWordWrapping
        speechResultsLabel.textAlignment = .center
        speechResultsLabel.contentMode = .center
        speechResultsLabel.backgroundColor = .clear

        // Setup microphone button
        microphoneImageView.layer.masksToBounds = true
        microphoneImageView.layer.cornerRadius = 10

        microphoneImageView.image = UIImage(named: "microphone")
        microphoneImageView.contentMode = .scaleAspectFit
        microphoneImageView.isUserInteractionEnabled = true

        microphoneImageView.isAccessibilityElement = true
        microphoneImageView.accessibilityTraits = .button
        microphoneImageView.accessibilityLabel = "Microphone Button"

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tappedMicrophoneButton))
        microphoneImageView.addGestureRecognizer(tapGesture)

        // Setup Stop button
        stopSpeechRecognitionImageView.layer.masksToBounds = true
        stopSpeechRecognitionImageView.layer.cornerRadius = 10

        stopSpeechRecognitionImageView.image = UIImage(named: "stopSpeech")
        stopSpeechRecognitionImageView.contentMode = .scaleAspectFit
        stopSpeechRecognitionImageView.isUserInteractionEnabled = true

        stopSpeechRecognitionImageView.isAccessibilityElement = true
        stopSpeechRecognitionImageView.accessibilityTraits = .button
        stopSpeechRecognitionImageView.accessibilityLabel = "Stop Speech Button"

        let tapStopGesture = UITapGestureRecognizer(target: self, action: #selector(tappedStopSpeechButton))
        stopSpeechRecognitionImageView .addGestureRecognizer(tapStopGesture)
    }

    func reset() {
        speechResultsLabel.text = "Initial State"
        speechResultsView.backgroundColor = .white
    }

    // MARK: - Events

    @objc func tappedMicrophoneButton() {
        speechRecognitionManager.stop()
        reset()

        self.permissions.getCurrentMicrophonePermission { (microphoneIsAllowed) in

            guard microphoneIsAllowed else {
                print("Microphone access not granted")
                return
            }

            self.permissions.getCurrentSpeechPermission { (speechIsallowed) in
                guard speechIsallowed else {
                    print("No speech authorization")
                    return
                }
                self.startSpeechRecognition()
            }
        }
    }

    @objc func tappedStopSpeechButton() {
        speechRecognitionManager.stop()
        reset()
    }

    func startSpeechRecognition() {
        speechRecognitionManager.start()

        DispatchQueue.main.async {
            self.speechResultsLabel.text = "Listening..."
        }
    }

    func performActionChangeBackground(for detectedText: String) {
        let keyPrefix = "change color to"

        if detectedText.contains(keyPrefix) {
            if detectedText.contains("\(keyPrefix) red") {
                speechResultsView.backgroundColor = .red
            } else if detectedText.contains("\(keyPrefix) blue") {
                speechResultsView.backgroundColor = .blue
            } else if detectedText.contains("\(keyPrefix) green") {
                speechResultsView.backgroundColor = .green
            } else if detectedText.contains("\(keyPrefix) yellow") {
                speechResultsView.backgroundColor = .yellow
            }
        }
    }
}

// MARK: - SpeechManagerDelegate
extension SpeechRecognitionViewController: SpeechManagerDelegate {
    func didChange(text: String?) {
        speechResultsLabel.text = text

        guard let text = text else {
            return
        }
        performActionChangeBackground(for: text.lowercased())

        // nice to apture: capture last word with a countdown timer
        // https://learnappmaking.com/timer-swift-how-to/#executing-code-with-a-delay
    }

    func didEnd(text: String?) {
        guard let text = text else {
            reset()
            return
        }

        speechResultsLabel.text = text
    }

    func didChangeAvailability(with available: Bool) {
        if available {
            microphoneImageView.isUserInteractionEnabled = true
        } else {
            microphoneImageView.isUserInteractionEnabled = false
        }
    }

    func didGetError(with errorMessage: String) {
        speechRecognitionManager.stop()

        speechResultsLabel.text = "\(String(describing: speechResultsLabel.text))\nError=\(errorMessage)"
    }

}
