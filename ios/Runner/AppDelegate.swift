import AuthenticationServices
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // El boton de Sign in with Apple del sistema, para `AppleAuthButton`.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "AppleIDButton") {
      registrar.register(
        AppleIDButtonFactory(messenger: registrar.messenger()),
        withId: "camrun/apple_id_button"
      )
    }
  }
}

/// Crea el `ASAuthorizationAppleIDButton` **del sistema** que pinta Flutter.
///
/// La guia de Apple prefiere este boton a uno dibujado: apariencia aprobada,
/// titulo traducido al idioma del dispositivo y etiqueta de VoiceOver. La
/// autorizacion en si la hace el plugin `sign_in_with_apple`; el boton solo
/// avisa a Flutter de que se pulso.
final class AppleIDButtonFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    AppleIDButtonView(
      viewId: viewId,
      arguments: args as? [String: Any] ?? [:],
      messenger: messenger
    )
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }
}

final class AppleIDButtonView: NSObject, FlutterPlatformView {
  private let button: ASAuthorizationAppleIDButton
  private let channel: FlutterMethodChannel

  init(viewId: Int64, arguments: [String: Any], messenger: FlutterBinaryMessenger) {
    // Los tres titulos y los tres estilos que define Apple; nada mas.
    let type: ASAuthorizationAppleIDButton.ButtonType
    switch arguments["type"] as? String {
    case "signIn": type = .signIn
    case "signUp": type = .signUp
    default: type = .continue
    }

    let style: ASAuthorizationAppleIDButton.Style
    switch arguments["style"] as? String {
    case "white": style = .white
    case "whiteOutline": style = .whiteOutline
    default: style = .black
    }

    button = ASAuthorizationAppleIDButton(
      authorizationButtonType: type,
      authorizationButtonStyle: style
    )
    // La guia deja ajustar las esquinas para que coincidan con los demas
    // botones de la app.
    if let radius = arguments["cornerRadius"] as? Double {
      button.cornerRadius = CGFloat(radius)
    }

    channel = FlutterMethodChannel(
      name: "camrun/apple_id_button/\(viewId)",
      binaryMessenger: messenger
    )
    super.init()
    button.addTarget(self, action: #selector(pressed), for: .touchUpInside)
  }

  func view() -> UIView { button }

  @objc private func pressed() {
    channel.invokeMethod("pressed", arguments: nil)
  }
}
