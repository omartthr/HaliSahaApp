//
//  AdminDocumentUploadView.swift
//  HaliSahaApp
//
//  Saha sahibi belge yükleme ekranı (onboarding).
//  Yeni kayıt sonrası veya başvurusu reddedilen admin'in zorunlu olarak
//  geçtiği akış. 4 belge + minimum 3 saha fotoğrafı yüklenir,
//  sonra submitVerificationDocuments() ile inceleme'ye gönderilir.
//

import PhotosUI
import SwiftUI

// MARK: - Admin Document Upload View
struct AdminDocumentUploadView: View {

    // MARK: - Properties
    @StateObject private var adminService = AdminService.shared
    @StateObject private var authService = AuthService.shared

    // Tek-dosyalık belgeler için seçilen UIImage'ler (henüz yüklenmedi)
    @State private var taxCertificateImage: UIImage?
    @State private var businessLicenseImage: UIImage?
    @State private var idFrontImage: UIImage?
    @State private var idBackImage: UIImage?

    // Saha fotoğrafları (çoklu)
    @State private var facilityPhotoImages: [UIImage] = []

    // Gönderim durumu
    @State private var isSubmitting = false
    @State private var uploadProgressText: String = ""
    @State private var errorMessage: String?
    @State private var showSignOutConfirm = false

    private let primaryColor = Color(hex: "2E7D32")
    private let minFacilityPhotos = 3
    private let maxFacilityPhotos = 6

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection

                    requiredDocumentsSection

                    facilityPhotosSection

                    if let errorMessage = errorMessage {
                        errorBanner(errorMessage)
                    }

                    submitButton

                    helpText
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Belge Yükleme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Çıkış") {
                        showSignOutConfirm = true
                    }
                    .foregroundColor(.red)
                }
            }
            .confirmationDialog(
                "Çıkış yapmak istediğinize emin misiniz? Yüklemediğiniz belgeler kaybolacak.",
                isPresented: $showSignOutConfirm,
                titleVisibility: .visible
            ) {
                Button("Çıkış Yap", role: .destructive) {
                    try? authService.signOut()
                }
                Button("Vazgeç", role: .cancel) {}
            }
            .overlay {
                if isSubmitting {
                    submittingOverlay
                }
            }
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(primaryColor.opacity(0.1))
                    .frame(width: 80, height: 80)
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 36))
                    .foregroundColor(primaryColor)
            }

            Text("İşletmenizi Doğrulayın")
                .font(.title2)
                .fontWeight(.bold)

            Text("Hesabınızın aktif olabilmesi için aşağıdaki belgeleri yüklemeniz gerekiyor. İnceleme genellikle 1-2 iş günü sürer.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
        .padding(.top, 8)
    }

    // MARK: - Required Documents Section
    private var requiredDocumentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("Zorunlu Belgeler", subtitle: "4 belge gerekli")

            VStack(spacing: 12) {
                singleDocumentPicker(
                    type: .taxCertificate,
                    image: $taxCertificateImage,
                    icon: "doc.badge.gearshape",
                    description: "Vergi numaranızı gösteren resmi belge"
                )

                singleDocumentPicker(
                    type: .businessLicense,
                    image: $businessLicenseImage,
                    icon: "building.columns",
                    description: "Belediyeden alınmış işyeri açma izni"
                )

                singleDocumentPicker(
                    type: .idFront,
                    image: $idFrontImage,
                    icon: "person.text.rectangle",
                    description: "İşletme sahibi/yetkili kimliğinin ön yüzü"
                )

                singleDocumentPicker(
                    type: .idBack,
                    image: $idBackImage,
                    icon: "person.text.rectangle.fill",
                    description: "Kimliğin arka yüzü"
                )
            }
        }
    }

    // MARK: - Facility Photos Section
    private var facilityPhotosSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle(
                "Saha Fotoğrafları",
                subtitle: "En az \(minFacilityPhotos) fotoğraf · \(facilityPhotoImages.count)/\(maxFacilityPhotos)"
            )

            VStack(alignment: .leading, spacing: 8) {
                bulletText("Dış cephe — tabela görünür şekilde")
                bulletText("Saha içi — yeşil zemin, file ve çizgiler")
                bulletText("Soyunma odası veya sosyal alan")
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.appCardBackground)
            .cornerRadius(12)

            facilityPhotoGrid
        }
    }

    private var facilityPhotoGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(Array(facilityPhotoImages.enumerated()), id: \.offset) { index, image in
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 100)
                        .clipped()
                        .cornerRadius(12)

                    Button {
                        facilityPhotoImages.remove(at: index)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.white, .black.opacity(0.6))
                    }
                    .padding(6)
                }
            }

            if facilityPhotoImages.count < maxFacilityPhotos {
                MultiPhotoPicker(maxCount: maxFacilityPhotos - facilityPhotoImages.count) { newImages in
                    facilityPhotoImages.append(contentsOf: newImages)
                    if facilityPhotoImages.count > maxFacilityPhotos {
                        facilityPhotoImages = Array(facilityPhotoImages.prefix(maxFacilityPhotos))
                    }
                }
            }
        }
    }

    // MARK: - Submit Button
    private var submitButton: some View {
        PrimaryButton(
            title: "Belgeleri Gönder",
            icon: "checkmark.shield",
            isLoading: isSubmitting,
            isDisabled: !isFormValid
        ) {
            Task { await submit() }
        }
    }

    // MARK: - Help Text
    private var helpText: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text("Belgeleriniz şifreli olarak saklanır ve sadece yetkili yöneticiler tarafından incelenir.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } icon: {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(primaryColor)
            }
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Single Document Picker Row
    private func singleDocumentPicker(
        type: AdminDocumentType,
        image: Binding<UIImage?>,
        icon: String,
        description: String
    ) -> some View {
        SinglePhotoPicker(
            title: type.displayName,
            description: description,
            icon: icon,
            primaryColor: primaryColor,
            image: image
        )
    }

    // MARK: - Section Title
    private func sectionTitle(_ title: String, subtitle: String) -> some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func bulletText(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundColor(primaryColor)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Error Banner
    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text(message)
                .font(.footnote)
                .foregroundColor(.red)
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.red.opacity(0.1))
        .cornerRadius(10)
    }

    // MARK: - Submitting Overlay
    private var submittingOverlay: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.4)
                Text(uploadProgressText.isEmpty ? "Belgeler yükleniyor..." : uploadProgressText)
                    .foregroundColor(.white)
                    .font(.subheadline)
            }
            .padding(28)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
        }
    }

    // MARK: - Validation
    private var isFormValid: Bool {
        taxCertificateImage != nil
            && businessLicenseImage != nil
            && idFrontImage != nil
            && idBackImage != nil
            && facilityPhotoImages.count >= minFacilityPhotos
    }

    // MARK: - Submit Action
    @MainActor
    private func submit() async {
        guard isFormValid,
              let userId = authService.currentUser?.id,
              let tax = taxCertificateImage,
              let license = businessLicenseImage,
              let idF = idFrontImage,
              let idB = idBackImage
        else { return }

        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        // Hangi adımda patlandığını mesaja eklemek için son adımı izliyoruz.
        var currentStep = "Hazırlık"

        do {
            currentStep = "Vergi levhası yüklenirken"
            uploadProgressText = "Vergi levhası yükleniyor..."
            let taxURL = try await StorageService.shared.uploadAdminDocument(tax, adminId: userId, type: .taxCertificate)

            currentStep = "İşyeri ruhsatı yüklenirken"
            uploadProgressText = "İşyeri ruhsatı yükleniyor..."
            let licenseURL = try await StorageService.shared.uploadAdminDocument(license, adminId: userId, type: .businessLicense)

            currentStep = "Kimlik (ön yüz) yüklenirken"
            uploadProgressText = "Kimlik (ön yüz) yükleniyor..."
            let idFrontURL = try await StorageService.shared.uploadAdminDocument(idF, adminId: userId, type: .idFront)

            currentStep = "Kimlik (arka yüz) yüklenirken"
            uploadProgressText = "Kimlik (arka yüz) yükleniyor..."
            let idBackURL = try await StorageService.shared.uploadAdminDocument(idB, adminId: userId, type: .idBack)

            currentStep = "Saha fotoğrafları yüklenirken"
            uploadProgressText = "Saha fotoğrafları yükleniyor..."
            let photoURLs = try await StorageService.shared.uploadAdminFacilityPhotos(facilityPhotoImages, adminId: userId)

            currentStep = "Başvuru gönderilirken"
            uploadProgressText = "Başvuru gönderiliyor..."
            let documents = VerificationDocuments(
                taxCertificateURL: taxURL,
                businessLicenseURL: licenseURL,
                idFrontURL: idFrontURL,
                idBackURL: idBackURL,
                facilityPhotoURLs: photoURLs
            )
            try await adminService.submitVerificationDocuments(documents)

            // submit başarılı; listener (AdminTabView içinde başlatılan)
            // myAdminProfile.documentsSubmittedAt'ı güncelleyince
            // routing otomatik olarak PendingApprovalView'a geçecek.
        } catch {
            errorMessage = "\(currentStep): \(humanReadableMessage(for: error))"
            uploadProgressText = ""
        }
    }

    // MARK: - Error Mapping
    /// Storage / Firestore hatalarını kullanıcıya anlamlı Türkçe metne çevirir.
    private func humanReadableMessage(for error: Error) -> String {
        let nsError = error as NSError

        // Network hataları (NSURLErrorDomain)
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet,
                 NSURLErrorNetworkConnectionLost,
                 NSURLErrorDataNotAllowed:
                return "İnternet bağlantınız yok veya kesildi. Bağlantınızı kontrol edip tekrar deneyin."
            case NSURLErrorTimedOut:
                return "Bağlantı zaman aşımına uğradı. Daha güçlü bir bağlantıyla tekrar deneyin."
            case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost:
                return "Sunucuya ulaşılamıyor. İnternet bağlantınızı kontrol edin."
            default:
                break
            }
        }

        // Firebase Storage hata domain'i
        if nsError.domain == "FIRStorageErrorDomain" {
            // 13 = unauthenticated, 14 = unauthorized, 15 = retry limit exceeded
            switch nsError.code {
            case 14: return "Yetki hatası: belge yüklenemedi. Lütfen tekrar giriş yapın."
            case 15: return "Bağlantı çok yavaş, yükleme tamamlanamadı. Tekrar deneyin."
            case 13: return "Oturumunuz sonlanmış. Lütfen tekrar giriş yapın."
            default: break
            }
        }

        // Genel mesaj
        return error.localizedDescription
    }
}

// MARK: - Single Photo Picker (tek belge)
private struct SinglePhotoPicker: View {
    let title: String
    let description: String
    let icon: String
    let primaryColor: Color
    @Binding var image: UIImage?

    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
            HStack(spacing: 14) {
                thumbnail
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        if image != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(primaryColor)
                        }
                    }
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: image == nil ? "plus.circle.fill" : "arrow.triangle.2.circlepath")
                    .foregroundColor(primaryColor)
                    .font(.title3)
            }
            .padding(12)
            .background(Color.appCardBackground)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(image == nil ? Color.gray.opacity(0.2) : primaryColor.opacity(0.6), lineWidth: 1)
            )
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let newItem,
                   let data = try? await newItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    image = uiImage
                }
            }
        }
    }

    private var thumbnail: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(primaryColor.opacity(0.1))
                .frame(width: 56, height: 56)
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(primaryColor)
            }
        }
    }
}

// MARK: - Multi Photo Picker (saha fotoğrafları için)
private struct MultiPhotoPicker: View {
    let maxCount: Int
    let onSelect: ([UIImage]) -> Void

    @State private var selection: [PhotosPickerItem] = []

    var body: some View {
        PhotosPicker(
            selection: $selection,
            maxSelectionCount: maxCount,
            matching: .images,
            photoLibrary: .shared()
        ) {
            VStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundColor(Color(hex: "2E7D32"))
                Text("Ekle")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(Color.appCardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                    .foregroundColor(.gray.opacity(0.4))
            )
            .cornerRadius(12)
        }
        .onChange(of: selection) { _, items in
            Task {
                var loaded: [UIImage] = []
                for item in items {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        loaded.append(uiImage)
                    }
                }
                if !loaded.isEmpty { onSelect(loaded) }
                selection = []
            }
        }
    }
}

// MARK: - Preview
#Preview {
    AdminDocumentUploadView()
}
