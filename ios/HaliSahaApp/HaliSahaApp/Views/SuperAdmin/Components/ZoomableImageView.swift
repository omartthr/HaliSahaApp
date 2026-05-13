//
//  DocumentViewerSheet.swift
//  HaliSahaApp
//
//  Süper admin'in belge incelemesinde kullandığı tam ekran görüntüleyici.
//  Mevcut ZoomableImageView (Components/FullScreenImageViewer.swift) componentini
//  başlık + kapatma butonuyla saran ince bir wrapper.
//

import SwiftUI

// MARK: - Document Viewer Sheet
struct DocumentViewerSheet: View {

    let imageURL: String
    let title: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ZoomableImageView(imageURL: imageURL)
                .ignoresSafeArea()

            VStack {
                HStack {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3.weight(.medium))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding()
                .padding(.top, 44)

                Spacer()
            }
        }
        .statusBarHidden(true)
    }
}

// MARK: - Preview
#Preview {
    DocumentViewerSheet(
        imageURL: "https://picsum.photos/800/600",
        title: "Vergi Levhası"
    )
}
