package com.example.HaliSahaApp.data.remote

import com.example.HaliSahaApp.data.models.PlayerPosition
import com.example.HaliSahaApp.data.models.User
import com.example.HaliSahaApp.data.models.UserType
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseAuthInvalidCredentialsException
import com.google.firebase.auth.FirebaseAuthInvalidUserException
import com.google.firebase.auth.FirebaseAuthUserCollisionException
import com.google.firebase.auth.FirebaseAuthWeakPasswordException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await
import java.util.UUID

// MARK: - Auth Service
object AuthService {

    private val auth: FirebaseAuth = FirebaseAuth.getInstance()
    private val firebaseService = FirebaseService // Singleton erişim

    // MARK: - StateFlow Properties (Swift'teki @Published karşılığı)
    private val _currentUser = MutableStateFlow<User?>(null)
    val currentUser: StateFlow<User?> = _currentUser.asStateFlow()

    private val _isAuthenticated = MutableStateFlow(false)
    val isAuthenticated: StateFlow<Boolean> = _isAuthenticated.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _authError = MutableStateFlow<AuthError?>(null)
    val authError: StateFlow<AuthError?> = _authError.asStateFlow()

    // MARK: - Init & Auth State Listener
    init {
        setupAuthStateListener()
    }

    private fun setupAuthStateListener() {
        auth.addAuthStateListener { firebaseAuth ->
            val firebaseUser = firebaseAuth.currentUser
            if (firebaseUser != null) {
                CoroutineScope(Dispatchers.IO).launch {
                    fetchUserProfile(firebaseUser.uid)
                }
            } else {
                _currentUser.value = null
                _isAuthenticated.value = false
            }
        }
    }

    // MARK: - Fetch User Profile
    private suspend fun fetchUserProfile(userId: String) {
        try {
            val user: User = firebaseService.fetchDocument(
                collection = firebaseService.usersCollection,
                documentId = userId
            )
            _currentUser.value = user
            _isAuthenticated.value = true
        } catch (e: Exception) {
            // Kullanıcı Firestore'da yoksa
            println("User profile not found: ${e.localizedMessage}")
            _isAuthenticated.value = false
        }
    }

    // MARK: - Email/Password Sign Up
    suspend fun signUp(
        email: String,
        password: String,
        firstName: String,
        lastName: String,
        username: String,
        phone: String,
        preferredPosition: PlayerPosition = PlayerPosition.UNSPECIFIED
    ) {
        _isLoading.value = true
        _authError.value = null

        try {
            // 1. Firebase Auth ile kullanıcı oluştur
            val authResult = auth.createUserWithEmailAndPassword(email, password).await()
            val userId = authResult.user?.uid ?: throw AuthError.Unknown("User ID alınamadı")

            // 2. Firestore'da kullanıcı profili oluştur
            val newUser = User(
                id = userId,
                email = email,
                firstName = firstName,
                lastName = lastName,
                username = username,
                phone = phone,
                preferredPosition = preferredPosition,
                userType = UserType.PLAYER
            )

            firebaseService.createDocument(
                collection = firebaseService.usersCollection,
                data = newUser,
                documentId = userId
            )

            _currentUser.value = newUser
            _isAuthenticated.value = true

        } catch (e: Exception) {
            _authError.value = mapAuthError(e)
            throw _authError.value!!
        } finally {
            _isLoading.value = false
        }
    }

    // MARK: - Email/Password Sign In
    suspend fun signIn(email: String, password: String) {
        _isLoading.value = true
        _authError.value = null

        try {
            val authResult = auth.signInWithEmailAndPassword(email, password).await()
            val userId = authResult.user?.uid ?: throw AuthError.Unknown("User ID alınamadı")
            fetchUserProfile(userId)
        } catch (e: Exception) {
            _authError.value = mapAuthError(e)
            throw _authError.value!!
        } finally {
            _isLoading.value = false
        }
    }

    // MARK: - Sign Out
    fun signOut() {
        try {
            auth.signOut()
            _currentUser.value = null
            _isAuthenticated.value = false
        } catch (e: Exception) {
            _authError.value = AuthError.SignOutFailed
        }
    }

    // MARK: - Password Reset
    suspend fun sendPasswordReset(email: String) {
        try {
            auth.sendPasswordResetEmail(email).await()
        } catch (e: Exception) {
            throw mapAuthError(e)
        }
    }

    // MARK: - Continue as Guest
    fun continueAsGuest() {
        val guestUser = User(
            id = "guest_${UUID.randomUUID()}",
            email = "",
            firstName = "Misafir",
            lastName = "",
            username = "guest",
            phone = "",
            userType = UserType.GUEST
        )
        _currentUser.value = guestUser
        _isAuthenticated.value = false
    }



    // MARK: - Admin Registration
    suspend fun registerAsAdmin(
        email: String,
        password: String,
        firstName: String,
        lastName: String,
        phone: String,
        businessName: String, // Şimdilik User modelinde yok, Facility modelinde olacak
        taxNumber: String     // Şimdilik User modelinde yok, Facility modelinde olacak
    ) {
        _isLoading.value = true
        _authError.value = null

        try {
            val authResult = auth.createUserWithEmailAndPassword(email, password).await()
            val userId = authResult.user?.uid ?: throw AuthError.Unknown("User ID alınamadı")

            val adminUser = User(
                id = userId,
                email = email,
                firstName = firstName,
                lastName = lastName,
                username = generateUsername(email),
                phone = phone,
                userType = UserType.ADMIN
            )

            firebaseService.createDocument(
                collection = firebaseService.usersCollection,
                data = adminUser,
                documentId = userId
            )

            _currentUser.value = adminUser
            _isAuthenticated.value = true

        } catch (e: Exception) {
            _authError.value = mapAuthError(e)
            throw _authError.value!!
        } finally {
            _isLoading.value = false
        }
    }

    // MARK: - Update FCM Token
    suspend fun updateFCMToken(token: String) {
        val userId = auth.currentUser?.uid ?: return
        try {
            firebaseService.updateDocument(
                collection = firebaseService.usersCollection,
                documentId = userId,
                fields = mapOf(FirestoreField.FCM_TOKEN to token)
            )
        } catch (e: Exception) {
            println("FCM Token update failed: ${e.message}")
        }
    }

    // MARK: - Delete Account
    suspend fun deleteAccount() {
        val user = auth.currentUser ?: throw AuthError.NotAuthenticated
        val userId = user.uid

        try {
            // 1. Firestore'dan sil
            firebaseService.deleteDocument(firebaseService.usersCollection, userId)

            // 2. Auth'dan sil
            user.delete().await()

            _currentUser.value = null
            _isAuthenticated.value = false
        } catch (e: Exception) {
            throw AuthError.Unknown("Hesap silinemedi: ${e.message}")
        }
    }

    // MARK: - Helpers
    private fun generateUsername(email: String): String {
        val base = email.split("@").firstOrNull() ?: "user"
        val random = (1000..9999).random()
        return "${base}_${random}"
    }

    private fun mapAuthError(e: Exception): AuthError {
        return when (e) {
            is FirebaseAuthInvalidUserException -> AuthError.UserNotFound
            is FirebaseAuthInvalidCredentialsException -> AuthError.InvalidCredential
            is FirebaseAuthUserCollisionException -> AuthError.EmailAlreadyInUse
            is FirebaseAuthWeakPasswordException -> AuthError.WeakPassword
            else -> AuthError.Unknown(e.localizedMessage ?: "Bilinmeyen hata")
        }
    }
}

// MARK: - Auth Error Sealed Class
sealed class AuthError(message: String) : Exception(message) {
    object InvalidEmail : AuthError("Geçersiz e-posta adresi.")
    object EmailAlreadyInUse : AuthError("Bu e-posta adresi zaten kullanımda.")
    object WeakPassword : AuthError("Şifre en az 6 karakter olmalıdır.")
    object InvalidCredential : AuthError("E-posta veya şifre hatalı.")
    object UserNotFound : AuthError("Kullanıcı bulunamadı.")
    object NetworkError : AuthError("İnternet bağlantınızı kontrol edin.")
    object TooManyRequests : AuthError("Çok fazla deneme. Lütfen bekleyin.")
    object NotAuthenticated : AuthError("Oturum açmanız gerekiyor.")
    object SignOutFailed : AuthError("Çıkış yapılamadı.")
    object NotImplemented : AuthError("Bu özellik henüz aktif değil.")
    class Unknown(message: String) : AuthError(message)
}