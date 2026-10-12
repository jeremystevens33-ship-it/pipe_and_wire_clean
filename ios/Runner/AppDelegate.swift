import Flutter
import UIKit
import AVFoundation
import Speech

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var jobSpeech: JobSpeechBridge?
  private var shareChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    let launched = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    if let controller = window?.rootViewController as? FlutterViewController {
      jobSpeech = JobSpeechBridge(messenger: controller.binaryMessenger)
      let channel = FlutterMethodChannel(name: "pipe_and_wire/share", binaryMessenger: controller.binaryMessenger)
      shareChannel = channel
      channel.setMethodCallHandler { [weak controller] call, reply in
        guard call.method == "shareText" else {
          reply(FlutterMethodNotImplemented)
          return
        }
        guard let arguments = call.arguments as? [String: Any],
              let text = arguments["text"] as? String, !text.isEmpty else {
          reply(FlutterError(code: "empty", message: "There is no list to share.", details: nil))
          return
        }
        guard let controller = controller, controller.view.window != nil,
              controller.presentedViewController == nil else {
          reply(FlutterError(code: "busy", message: "Close the current menu and try sharing again.", details: nil))
          return
        }
        let sheet = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let popover = sheet.popoverPresentationController {
          popover.sourceView = controller.view
          popover.sourceRect = CGRect(x: controller.view.bounds.midX,
              y: controller.view.bounds.maxY - controller.view.safeAreaInsets.bottom - 8,
              width: 1, height: 1)
          popover.permittedArrowDirections = []
        }
        sheet.completionWithItemsHandler = { _, _, _, error in
          if error != nil {
            reply(FlutterError(code: "share", message: "Sharing could not finish. Please try again.", details: nil))
          } else {
            reply(nil)
          }
        }
        controller.present(sheet, animated: true)
      }
    }
    return launched
  }
}

/// The same field-level speech channel used by Android and the Flutter keypad.
private final class JobSpeechBridge {
  private let channel: FlutterMethodChannel
  private let engine = AVAudioEngine()
  private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
  private var request: SFSpeechAudioBufferRecognitionRequest?
  private var task: SFSpeechRecognitionTask?
  private var pending: FlutterResult?
  private var session: UUID?
  private var lastText = ""
  private var tapInstalled = false
  private var audioSessionActive = false
  private var stopping = false
  private var pauseSeconds = 2.0
  private var silenceTimer: Timer?
  private var timeoutTimer: Timer?
  private var finalTimer: Timer?
  private var observers: [NSObjectProtocol] = []

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "pipe_and_wire/offline_speech", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      switch call.method {
      case "available":
        result(self.recognizer != nil)
      case "status":
        result([
          "available": self.recognizer != nil,
          "mode": self.recognizer?.supportsOnDeviceRecognition == true ? "on_device" : "phone_service"
        ])
      case "listen":
        self.listen(arguments: call.arguments, result: result)
      case "stop":
        self.stop()
        result(nil)
      case "cancel":
        self.finish(error: "Listening cancelled.")
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    observers.append(NotificationCenter.default.addObserver(
      forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main
    ) { [weak self] _ in
      self?.finish(error: "Listening stopped when the app left the screen.")
    })
    observers.append(NotificationCenter.default.addObserver(
      forName: AVAudioSession.interruptionNotification, object: nil, queue: .main
    ) { [weak self] notification in
      let type = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
      if type == AVAudioSession.InterruptionType.began.rawValue {
        self?.finish(error: "Recording was interrupted. Tap the microphone to try again.")
      }
    })
  }

  private func listen(arguments: Any?, result: @escaping FlutterResult) {
    guard pending == nil else {
      result(FlutterError(code: "busy", message: "Microphone is already listening.", details: nil))
      return
    }
    guard recognizer != nil else {
      result(FlutterError(code: "unavailable", message: "Speech is unavailable. You can type instead.", details: nil))
      return
    }
    let settings = arguments as? [String: Any]
    let pauseMillis = (settings?["pauseMillis"] as? NSNumber)?.doubleValue ?? 2000
    pauseSeconds = min(5, max(1, pauseMillis / 1000))
    let token = UUID()
    session = token
    pending = result
    lastText = ""
    stopping = false
    SFSpeechRecognizer.requestAuthorization { [weak self] authorization in
      DispatchQueue.main.async {
        guard let self = self, self.session == token else { return }
        guard authorization == .authorized else {
          self.finish(error: "Allow Speech Recognition in iPhone Settings to use voice, or type instead.")
          return
        }
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] allowed in
          DispatchQueue.main.async {
            guard let self = self, self.session == token else { return }
            guard allowed else {
              self.finish(error: "Allow Microphone access in iPhone Settings to use voice, or type instead.")
              return
            }
            self.start(token: token)
          }
        }
      }
    }
  }

  private func start(token: UUID) {
    guard session == token, let recognizer = recognizer else { return }
    guard recognizer.supportsOnDeviceRecognition || recognizer.isAvailable else {
      finish(error: "The iPhone speech service is unavailable right now. Retry or type instead.")
      return
    }
    do {
      let audio = AVAudioSession.sharedInstance()
      try audio.setCategory(.record, mode: .measurement, options: .duckOthers)
      try audio.setActive(true, options: .notifyOthersOnDeactivation)
      audioSessionActive = true
      let draft = SFSpeechAudioBufferRecognitionRequest()
      draft.shouldReportPartialResults = true
      draft.requiresOnDeviceRecognition = recognizer.supportsOnDeviceRecognition
      request = draft
      let input = engine.inputNode
      let format = input.outputFormat(forBus: 0)
      guard format.sampleRate > 0, format.channelCount > 0 else {
        finish(error: "The microphone is unavailable. Retry or type instead.")
        return
      }
      var lastActivityUpdate = 0.0
      input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
        draft.append(buffer)
        // Keep recording while audio is active, even if text previews are delayed.
        if let samples = buffer.floatChannelData?[0] {
          var peak: Float = 0
          for index in stride(from: 0, to: Int(buffer.frameLength), by: 16) {
            peak = max(peak, abs(samples[index]))
          }
          let now = ProcessInfo.processInfo.systemUptime
          if peak > 0.008 && now - lastActivityUpdate >= 0.25 {
            lastActivityUpdate = now
            DispatchQueue.main.async {
              guard let self = self, self.session == token, !self.stopping else { return }
              self.scheduleSilenceStop(token: token)
            }
          }
        }
      }
      tapInstalled = true
      task = recognizer.recognitionTask(with: draft) { [weak self] recognized, error in
        DispatchQueue.main.async {
          guard let self = self, self.session == token else { return }
          if let recognized = recognized {
            let text = recognized.bestTranscription.formattedString
            if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
              let changed = text != self.lastText
              self.lastText = text
              if !recognized.isFinal {
                self.channel.invokeMethod("partial", arguments: text)
                if changed && !self.stopping { self.scheduleSilenceStop(token: token) }
              }
            }
            if recognized.isFinal {
              self.finish(text: self.lastText)
              return
            }
          }
          if error != nil {
            // Stopping can end a recognition task without a separate final event.
            if self.stopping && !self.lastText.isEmpty {
              self.finish(text: self.lastText)
            } else {
              self.finish(error: "Speech could not finish. Try again or type instead.")
            }
          }
        }
      }
      engine.prepare()
      try engine.start()
      timeoutTimer = Timer.scheduledTimer(withTimeInterval: 45, repeats: false) { [weak self] _ in
        guard let self = self, self.session == token else { return }
        self.stop()
      }
    } catch {
      finish(error: "The microphone could not start. Try again or type instead.")
    }
  }

  private func scheduleSilenceStop(token: UUID) {
    silenceTimer?.invalidate()
    silenceTimer = Timer.scheduledTimer(withTimeInterval: pauseSeconds, repeats: false) { [weak self] _ in
      guard let self = self, self.session == token else { return }
      self.stop()
    }
  }

  private func stop() {
    guard pending != nil, !stopping else { return }
    guard request != nil else {
      finish(error: "Recording stopped before it began.")
      return
    }
    stopping = true
    silenceTimer?.invalidate()
    timeoutTimer?.invalidate()
    stopAudio()
    request?.endAudio()
    let token = session
    finalTimer = Timer.scheduledTimer(withTimeInterval: 6, repeats: false) { [weak self] _ in
      guard let self = self, self.session == token else { return }
      self.finish(text: self.lastText)
    }
  }

  private func stopAudio() {
    if engine.isRunning { engine.stop() }
    if tapInstalled {
      engine.inputNode.removeTap(onBus: 0)
      tapInstalled = false
    }
  }

  private func finish(text: String? = nil, error: String? = nil) {
    let reply = pending
    pending = nil
    session = nil
    silenceTimer?.invalidate()
    timeoutTimer?.invalidate()
    finalTimer?.invalidate()
    silenceTimer = nil
    timeoutTimer = nil
    finalTimer = nil
    stopAudio()
    request?.endAudio()
    task?.cancel()
    task = nil
    request = nil
    if audioSessionActive {
      try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
      audioSessionActive = false
    }
    stopping = false
    if let text = text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      reply?(text)
    } else {
      reply?(FlutterError(code: "speech", message: error ?? "No words recognized. Try again or type instead.", details: nil))
    }
  }

  deinit {
    observers.forEach { NotificationCenter.default.removeObserver($0) }
    finish(error: "Listening cancelled.")
    channel.setMethodCallHandler(nil)
  }
}
