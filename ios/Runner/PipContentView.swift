import CoreGraphics
import SwiftUI

/// Teksty i styl prezentowane w pływającym pasku PiP. Aktualizowane z Fluttera
/// przez `updateContent` / `setPipStyle` bez przebudowywania okna PiP.
final class PipContentModel: ObservableObject {
  @Published var primaryText: String = ""
  @Published var phoneticText: String = ""
  @Published var translationText: String = ""

  /// Wspólny przyrost rozmiaru tekstu docelowego i fonetyki (0, 2 lub 4 pt).
  @Published var fontDelta: CGFloat = 0

  /// Dodatkowy przyrost rozmiaru samego tłumaczenia (0, 2 lub 4 pt).
  @Published var translationSizeDelta: CGFloat = 0

  /// Gdy `true`, tłumaczenie trafia do prawej kolumny pod zapisem fonetycznym.
  @Published var translationAlignRight: Bool = true

  func update(primaryText: String?, phoneticText: String?, translationText: String?) {
    self.primaryText = primaryText ?? ""
    self.phoneticText = phoneticText ?? ""
    self.translationText = translationText ?? ""
  }

  func updateStyle(
    fontDelta: CGFloat?,
    translationSizeDelta: CGFloat?,
    translationAlignRight: Bool?
  ) {
    self.fontDelta = Self.clampDelta(fontDelta ?? self.fontDelta)
    self.translationSizeDelta = Self.clampDelta(
      translationSizeDelta ?? self.translationSizeDelta
    )
    self.translationAlignRight = translationAlignRight ?? self.translationAlignRight
  }

  func clear() {
    primaryText = ""
    phoneticText = ""
    translationText = ""
  }

  private static func clampDelta(_ value: CGFloat) -> CGFloat {
    min(max(value, 0), 4)
  }
}

struct PipContentView: View {
  @ObservedObject var model: PipContentModel

  private static let baseTargetSize: CGFloat = 20
  private static let basePhoneticSize: CGFloat = 13
  private static let baseTranslationSize: CGFloat = 11

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
        .font(.system(size: Self.baseTargetSize + model.fontDelta, weight: .bold))
        .foregroundColor(.white)
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        .frame(maxWidth: .infinity, alignment: .leading)

      if model.translationAlignRight {
        rightColumn
      } else {
        leftColumn
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .padding(.horizontal, 12)
    .padding(.vertical, 6)
    .background(Color.black.opacity(0.85))
    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
  }

  /// Fonetyka i tłumaczenie w prawej kolumnie — łatwiejsze dla początkujących.
  private var rightColumn: some View {
    HStack(alignment: .top, spacing: 8) {
      Spacer(minLength: 0)
      VStack(alignment: .trailing, spacing: 1) {
        if !model.phoneticText.isEmpty {
          phoneticLine
        }
        if !model.translationText.isEmpty {
          translationLine
        }
      }
    }
  }

  /// Fonetyka i tłumaczenie pod kanji, wyrównane do lewej.
  private var leftColumn: some View {
    VStack(alignment: .leading, spacing: 1) {
      if !model.phoneticText.isEmpty {
        phoneticLine
      }
      if !model.translationText.isEmpty {
        translationLine
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var phoneticLine: some View {
    Text(model.phoneticText)
      .font(.system(size: Self.basePhoneticSize + model.fontDelta, weight: .semibold))
      .foregroundColor(Self.phoneticColor)
      .lineLimit(1)
      .minimumScaleFactor(0.6)
      .multilineTextAlignment(model.translationAlignRight ? .trailing : .leading)
  }

  private var translationLine: some View {
    Text(model.translationText)
      .font(.system(size: translationFontSize, weight: .regular))
      .foregroundColor(Self.translationColor)
      .lineLimit(1)
      .minimumScaleFactor(0.6)
      .multilineTextAlignment(model.translationAlignRight ? .trailing : .leading)
  }

  private var translationFontSize: CGFloat {
    Self.baseTranslationSize + model.fontDelta + model.translationSizeDelta
  }
}
