import SwiftUI

/// Teksty prezentowane w pływającym pasku PiP. Aktualizowane z Fluttera
/// przez `updateContent` bez przebudowywania okna PiP.
final class PipContentModel: ObservableObject {
  @Published var primaryText: String = ""
  @Published var phoneticText: String = ""
  @Published var translationText: String = ""

  func update(primaryText: String?, phoneticText: String?, translationText: String?) {
    self.primaryText = primaryText ?? ""
    self.phoneticText = phoneticText ?? ""
    self.translationText = translationText ?? ""
  }

  func clear() {
    primaryText = ""
    phoneticText = ""
    translationText = ""
  }
}

struct PipContentView: View {
  @ObservedObject var model: PipContentModel

  private static let phoneticColor = Color(
    .sRGB,
    red: 253.0 / 255.0,
    green: 224.0 / 255.0,
    blue: 71.0 / 255.0,
    opacity: 1
  )

  private static let translationColor = Color(
    .sRGB,
    red: 148.0 / 255.0,
    green: 163.0 / 255.0,
    blue: 184.0 / 255.0,
    opacity: 1
  )

  var body: some View {
    VStack(alignment: .leading, spacing: 1) {
      Text(model.primaryText)
        .font(.system(size: 20, weight: .bold))
        .foregroundColor(.white)
        .lineLimit(1)
        .minimumScaleFactor(0.5)

      if !model.phoneticText.isEmpty {
        Text(model.phoneticText)
          .font(.system(size: 13, weight: .semibold))
          .foregroundColor(Self.phoneticColor)
          .lineLimit(1)
          .minimumScaleFactor(0.6)
      }

      if !model.translationText.isEmpty {
        Text(model.translationText)
          .font(.system(size: 11, weight: .regular))
          .foregroundColor(Self.translationColor)
          .lineLimit(1)
          .minimumScaleFactor(0.6)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .padding(.horizontal, 12)
    .padding(.vertical, 6)
    .background(Color.black.opacity(0.85))
    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
  }
}
