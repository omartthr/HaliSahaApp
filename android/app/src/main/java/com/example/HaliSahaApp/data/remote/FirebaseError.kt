package com.example.HaliSahaApp.data.remote

sealed class FirebaseError(override val message: String) : Exception(message) {
    object NotAuthenticated : FirebaseError("Oturum açmanız gerekiyor.")
    object DocumentNotFound : FirebaseError("İstenen veri bulunamadı.")
    object PermissionDenied : FirebaseError("Bu işlem için yetkiniz yok.")
    object NetworkError : FirebaseError("İnternet bağlantınızı kontrol edin.")
    object EncodingError : FirebaseError("Veri kodlama hatası.")
    object DecodingError : FirebaseError("Veri çözümleme hatası.")
    class Unknown(message: String) : FirebaseError(message)
}