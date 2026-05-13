//
//  QRCodeImage.swift
//  HaliSahaApp
//
//  CoreImage tabanlı gerçek QR kod üretici görünüm.
//

import CoreImage.CIFilterBuiltins
import SwiftUI

// MARK: - QR Code Image
struct QRCodeImage: View {

    let data: String
    var size: CGFloat = 220
    var foregroundColor: Color = .black
    var backgroundColor: Color = .white

    private static let context = CIContext()

    var body: some View {
        SwiftUI.Group {
            if let cgImage = generate() {
                Image(decorative: cgImage, scale: 1, orientation: .up)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
            } else {
                // Fallback: veri boş veya filtre başarısız
                Image(systemName: "qrcode")
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.15)
                    .foregroundColor(foregroundColor)
            }
        }
        .frame(width: size, height: size)
        .padding(size * 0.06)
        .background(backgroundColor)
        .cornerRadius(size * 0.08)
    }

    // MARK: - Generate
    private func generate() -> CGImage? {
        guard !data.isEmpty else { return nil }

        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(data.utf8)
        filter.correctionLevel = "H"  // Yüksek hata düzeltme — kısmen kirli/yıpranmış kodlar bile okunur

        guard let baseImage = filter.outputImage else { return nil }

        // Yüksek çözünürlük için ölçekle
        let targetPixels = max(size * 3, 600)
        let scale = targetPixels / baseImage.extent.width
        let scaled = baseImage.transformed(
            by: CGAffineTransform(scaleX: scale, y: scale)
        )

        // Renkleri uygula (false-color filter)
        let coloredImage: CIImage = {
            guard
                foregroundColor != .black || backgroundColor != .white
            else {
                return scaled
            }
            let colorFilter = CIFilter.falseColor()
            colorFilter.inputImage = scaled
            colorFilter.color0 = CIColor(color: UIColor(foregroundColor))
            colorFilter.color1 = CIColor(color: UIColor(backgroundColor))
            return colorFilter.outputImage ?? scaled
        }()

        return Self.context.createCGImage(coloredImage, from: coloredImage.extent)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        QRCodeImage(
            data: """
                {"ticketNumber":"HS-2026-001234","date":"2026-05-10T19:00:00Z","facilityId":"f1"}
                """,
            size: 240
        )

        QRCodeImage(
            data: "HS-2026-001234",
            size: 120,
            foregroundColor: Color(hex: "2E7D32")
        )
    }
    .padding()
}
