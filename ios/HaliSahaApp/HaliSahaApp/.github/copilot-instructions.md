# HaliSaha iOS App - AI Coding Assistant Guide

## Architecture Overview

SwiftUI MVVM app for booking football pitches in Turkey. Dual-user system: **players** and **facility admins**.

**Data Flow**: `View` → `ViewModel (@MainActor)` → `Service (singleton)` → `Firebase`

**Navigation**: [ContentView.swift](Root/ContentView.swift) routes by `AuthService.shared.currentUser.userType`:
- `.admin` → `AdminTabView` (Dashboard, Bookings, Facilities, Reports, Settings)
- `.player/.guest` → `MainTabView` (Home, Map, Bookings, Chat, Profile)
- Unauthenticated → `LoginView`

## Critical Patterns

### Service Singletons
All Firebase access through singletons in [Services/](Services/). Never create new instances:
```swift
// ✅ Correct
let bookings = try await BookingService.shared.fetchUserBookings()
let facility: Facility = try await FirebaseService.shared.fetchDocument(from: collection, documentId: id)

// ❌ Wrong - never instantiate directly
let service = BookingService()
```

### Firestore Schema
```
users/{userId}
facilities/{facilityId}/pitches/{pitchId}  ← Sub-collection
bookings/{bookingId}
groups/{groupId}/messages/{messageId}      ← Sub-collection
```
Access sub-collections: `firebaseService.pitchesCollection(for: facilityId)`

### Denormalized Data Pattern
Booking stores copies of `facilityName`, `userFullName`, etc. for query performance. **When updating source data, update copies too**:
```swift
// If facility.name changes, existing bookings keep old name unless manually updated
```

### Constants (No Magic Numbers)
Use [Constants.swift](Utilities/Constants.swift):
- `AppConstants.depositPercentage` (0.20), `.freeCancellationHours` (24)
- `UIConstants.paddingMedium`, `.cornerRadiusMedium`, `.buttonHeight`
- `FirestoreCollection.bookings`, `FirestoreField.userId` for query strings

### ViewModel Pattern
```swift
@MainActor
final class SomeViewModel: ObservableObject {
    @Published var items: [Item] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false
    
    var isFormValid: Bool { /* computed validation */ }
    
    func fetchData() async {
        isLoading = true
        defer { isLoading = false }
        do {
            items = try await SomeService.shared.fetch()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
```

### Turkish Localization
- Use `Locale(identifier: "tr_TR")` for dates
- Extensions: `date.formattedTurkish`, `date.withDayName`, `string.formattedPhoneNumber`
- UI strings in Turkish (comments too: `// Kullanıcı profili`)

### Validation
Use [Validators.swift](Utilities/Validators.swift) - `FormValidator.validateEmail()`, `.validatePhone()`, `.validatePassword()`
Returns `ValidationResult` with `.isValid` and `.errorMessage`

## Business Rules

- **Deposit**: 20% of total (`AppConstants.depositPercentage`)
- **Cancellation**: Free if >24h before match (`booking.canBeCancelled` computed property)
- **Facility approval**: New facilities start `.pending`, admin approves to `.approved`
- **Phone format**: Turkish 10-digit starting with 5 (`5XX XXX XX XX`)

## File Structure Conventions

- **MARK comments**: `// MARK: - Section Name`
- **Models**: `@DocumentID var id: String?`, Codable, computed properties for derived values
- **Views**: Use components from [Views/Components/](Views/Components/) (`PrimaryButton`, `CustomTextField`, `FacilityCard`)
- **Extensions**: Add to [Extensions.swift](Utilities/Extensions.swift), not inline

## When Modifying Code

1. **Set `updatedAt = Date()`** when editing Firestore documents
2. **Unwrap IDs safely**: `guard let id = model.id else { return }`
3. **Use `@MainActor`** on async methods that update `@Published` properties
4. **Add to Constants** for new business rules or UI values
5. **Preserve denormalized data** - update copies when source changes

## Running the App

Requires `GoogleService-Info.plist` (Firebase config). Build with ⌘R in Xcode.
