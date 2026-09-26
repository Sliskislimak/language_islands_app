import AVKit
import Flutter
import SwiftUI
import UIKit

/// Pływający pasek Picture-in-Picture (iOS 15+) z aktualnie ćwiczonym zdaniem.
///
/// Wykorzystuje `AVPictureInPictureVideoCallViewController`, dzięki czemu okno
/// PiP hostuje widok SwiftUI (`PipContentView`) i nie wymaga generowania
/// sztucznego strumienia wideo.
final class PipManager: NSObject {
  static let shared = PipManager()

  private static let channelName = "language_islands/pip"

  private let content = PipContentModel()

  private var channel: FlutterMethodChannel?
  private var pipController: AVPictureInPictureController?
  private var sourceView: UIView?

  private var barViewController: UIViewController?

  private override init() {
    super.init()
  }

  // MARK: - Flutter channel

  func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: Self.channelName,
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterMethodNotImplemented)
        return
      }
      self.handle(call, result: result)
    }
    self.channel = channel
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isPipSupported":
      result(isSupported)
    case "isPipActive":
      result(pipController?.isPictureInPictureActive ?? false)
    case "startPip":
      startPip(result: result)
    case "stopPip":
      stopPip()
      result(nil)
    case "updateContent":
      let arguments = call.arguments as? [String: Any]
      applyContent(arguments)
      applyStyle(arguments)
      result(nil)
    case "setPipStyle":
      applyStyle(call.arguments as? [String: Any])
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private var isSupported: Bool {
    guard #available(iOS 15.0, *) else { return false }
    return AVPictureInPictureController.isPictureInPictureSupported()
  }

  private func applyContent(_ arguments: [String: Any]?) {
    let primary = arguments?["primaryText"] as? String
    let phonetic = arguments?["phoneticText"] as? String
    let translation = arguments?["translationText"] as? String
    DispatchQueue.main.async {
      self.content.update(
        primaryText: primary,
        phoneticText: phonetic,
        translationText: translation
      )
    }
  }

  private func applyStyle(_ arguments: [String: Any]?) {
    guard let arguments else { return }

    var parsedFontDelta: CGFloat? = nil
    if let num = arguments["fontDelta"] as? NSNumber {
      parsedFontDelta = CGFloat(truncating: num)
    }

    var parsedTranslationDelta: CGFloat? = nil
    if let num = arguments["translationSizeDelta"] as? NSNumber {
      parsedTranslationDelta = CGFloat(truncating: num)
    }

    let alignRight = arguments["translationAlignRight"] as? Bool

    var parsedWidth: CGFloat? = nil
    if let num = arguments["windowWidth"] as? NSNumber {
      parsedWidth = CGFloat(truncating: num)
    }

    var parsedHeight: CGFloat? = nil
    if let num = arguments["windowHeight"] as? NSNumber {
      parsedHeight = CGFloat(truncating: num)
    }

    guard parsedFontDelta != nil || parsedTranslationDelta != nil || alignRight != nil || parsedWidth != nil else {
      return
    }

    DispatchQueue.main.async {
      self.content.updateStyle(
        fontDelta: parsedFontDelta,
        translationSizeDelta: parsedTranslationDelta,
        translationAlignRight: alignRight
      )
      self.syncPreferredContentSize(width: parsedWidth, height: parsedHeight)
    }
  }

  private func syncPreferredContentSize(width: CGFloat? = nil, height: CGFloat? = nil) {
    guard #available(iOS 15.0, *),
          let bar = barViewController as? PipBarViewController
    else { return }
    bar.applyDimensions(
      width: width,
      height: height,
      fontDelta: content.fontDelta,
      translationSizeDelta: content.translationSizeDelta
    )
  }

  // MARK: - PiP lifecycle

  private func startPip(result: @escaping FlutterResult) {
    guard #available(iOS 15.0, *), isSupported else {
      result(false)
      return
    }

    guard let controller = ensureController() else {
      result(false)
      return
    }

    if controller.isPictureInPictureActive {
      result(true)
      return
    }

    controller.startPictureInPicture()
    result(true)
  }

  private func stopPip() {
    guard #available(iOS 15.0, *) else { return }
    let controller = pipController
    DispatchQueue.main.async {
      if controller?.isPictureInPictureActive == true {
        controller?.stopPictureInPicture()
      }
      self.content.clear()
    }
  }

  @available(iOS 15.0, *)
  private func ensureController() -> AVPictureInPictureController? {
    if let existing = pipController { return existing }

    guard let host = hostWindow() else { return nil }

    let anchor = UIView(frame: CGRect(x: 0, y: 0, width: 2, height: 2))
    anchor.backgroundColor = .clear
    anchor.isUserInteractionEnabled = false
    anchor.alpha = 0.02
    host.addSubview(anchor)
    sourceView = anchor

    let contentViewController = PipBarViewController(model: content)
    barViewController = contentViewController

    let source = AVPictureInPictureController.ContentSource(
      activeVideoCallSourceView: anchor,
      contentViewController: contentViewController
    )

    let controller = AVPictureInPictureController(contentSource: source)
    controller.delegate = self
    controller.canStartPictureInPictureAutomaticallyFromInline = true
    pipController = controller
    return controller
  }

  private func hostWindow() -> UIWindow? {
    let scenes = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
    let windows = scenes.flatMap(\.windows)
    return windows.first(where: \.isKeyWindow) ?? windows.first
  }

  private func teardownSourceView() {
    sourceView?.removeFromSuperview()
    sourceView = nil
  }
}

// MARK: - AVPictureInPictureControllerDelegate

extension PipManager: AVPictureInPictureControllerDelegate {
  func pictureInPictureControllerDidStartPictureInPicture(
    _ pictureInPictureController: AVPictureInPictureController
  ) {
    channel?.invokeMethod("onPipStarted", arguments: nil)
  }

  func pictureInPictureControllerDidStopPictureInPicture(
    _ pictureInPictureController: AVPictureInPictureController
  ) {
    content.clear()
    channel?.invokeMethod("onPipStopped", arguments: nil)
  }

  func pictureInPictureController(
    _ pictureInPictureController: AVPictureInPictureController,
    failedToStartPictureInPictureWithError error: Error
  ) {
    pipController = nil
    barViewController = nil
    teardownSourceView()
    channel?.invokeMethod("onPipStopped", arguments: nil)
  }
}

// MARK: - Kontroler zawartości okna PiP

@available(iOS 15.0, *)
final class PipBarViewController: AVPictureInPictureVideoCallViewController {
  private let hostingController: UIHostingController<PipContentView>

  private static let defaultWidth: CGFloat = 360.0
  private static let defaultHeight: CGFloat = 90.0

  init(model: PipContentModel) {
    hostingController = UIHostingController(rootView: PipContentView(model: model))
    super.init(nibName: nil, bundle: nil)
    preferredContentSize = CGSize(width: Self.defaultWidth, height: Self.defaultHeight)
  }

  func applyDimensions(
    width: CGFloat?,
    height: CGFloat?,
    fontDelta: CGFloat,
    translationSizeDelta: CGFloat
  ) {
    let finalWidth = width ?? Self.defaultWidth
    let finalHeight: CGFloat
    if let explicitHeight = height {
      finalHeight = explicitHeight
    } else {
      let raw = Self.defaultHeight + (fontDelta * 3.0) + (translationSizeDelta * 2.0)
      finalHeight = max(76.0, min(116.0, raw))
    }

    let size = CGSize(width: finalWidth, height: finalHeight)
    guard preferredContentSize != size else { return }
    preferredContentSize = size
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("PipBarViewController does not support initialization from a nib.")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .black
    hostingController.view.backgroundColor = .clear

    addChild(hostingController)
    view.addSubview(hostingController.view)
    hostingController.view.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
      hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    hostingController.didMove(toParent: self)
  }
}