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

  /// Przechowywany jako `UIViewController`, bo `PipBarViewController` jest
  /// dostępny wyłącznie od iOS 15.
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

    let fontDelta = (arguments["fontDelta"] as? NSNumber)?.doubleValue
    let translationDelta = (arguments["translationSizeDelta"] as? NSNumber)?.doubleValue
    let alignRight = arguments["translationAlignRight"] as? Bool

    // `updateContent` dzieli obsługę z `setPipStyle`, więc ignorujemy wywołania
    // bez żadnego z kluczy stylu.
    guard fontDelta != nil || translationDelta != nil || alignRight != nil else {
      return
    }

    DispatchQueue.main.async {
      self.content.updateStyle(
        fontDelta: fontDelta.map(CGFloat.init),
        translationSizeDelta: translationDelta.map(CGFloat.init),
        translationAlignRight: alignRight
      )
      self.syncPreferredContentSize()
    }
  }

  /// Wyższe litery i większe tłumaczenie wymagają wyższego okna PiP, inaczej
  /// dolna linia zostaje ucięta.
  private func syncPreferredContentSize() {
    guard #available(iOS 15.0, *),
          let bar = barViewController as? PipBarViewController
    else { return }
    bar.applyPreferredContentSize(
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

    // Źródło PiP musi należeć do hierarchii widoków w oknie, ale samo pozostaje
    // praktycznie niewidoczne — właściwa treść żyje w kontrolerze PiP.
    let anchor = UIView(frame: CGRect(x: 0, y: 0, width: 2, height: 2))
    anchor.backgroundColor = .clear
    anchor.isUserInteractionEnabled = false
    anchor.alpha = 0.02
    host.addSubview(anchor)
    sourceView = anchor

    let contentViewController = PipBarViewController(model: content)
    contentViewController.applyPreferredContentSize(
      fontDelta: content.fontDelta,
      translationSizeDelta: content.translationSizeDelta
    )
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

/// Wąski poziomy pasek hostujący `PipContentView` przez `UIHostingController`.
@available(iOS 15.0, *)
final class PipBarViewController: AVPictureInPictureVideoCallViewController {
  private let hostingController: UIHostingController<PipContentView>

  private static let barWidth: CGFloat = 360
  private static let baseBarHeight: CGFloat = 86
  private static let maxBarHeight: CGFloat = 108

  init(model: PipContentModel) {
    hostingController = UIHostingController(rootView: PipContentView(model: model))
    super.init(nibName: nil, bundle: nil)
    preferredContentSize = CGSize(width: Self.barWidth, height: Self.baseBarHeight)
  }

  /// 86 pt dla ustawień standardowych, 96–108 pt gdy któraś czcionka rośnie.
  func applyPreferredContentSize(fontDelta: CGFloat, translationSizeDelta: CGFloat) {
    let grown = fontDelta > 0 || translationSizeDelta > 0
    let raw = Self.baseBarHeight + fontDelta * 3 + translationSizeDelta * 2
    let height = grown
      ? min(Self.maxBarHeight, max(96, raw))
      : Self.baseBarHeight
    let size = CGSize(width: Self.barWidth, height: height)
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
