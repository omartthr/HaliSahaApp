package com.example.HaliSahaApp

import android.app.Application
import com.google.firebase.FirebaseApp

class HaliSahaApp : Application() {
    override fun onCreate() {
        super.onCreate()
        // Firebase Başlatma
        FirebaseApp.initializeApp(this)
    }
}