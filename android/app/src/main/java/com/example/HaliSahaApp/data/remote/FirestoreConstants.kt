package com.example.HaliSahaApp.data.remote

object FirestoreCollection {
    const val USERS = "users"
    const val FACILITIES = "facilities"
    const val PITCHES = "pitches"
    const val BOOKINGS = "bookings"
    const val GROUPS = "groups"
    const val MESSAGES = "messages"
    const val MATCH_POSTS = "match_posts"
    const val REVIEWS = "reviews"
    const val NOTIFICATIONS = "notifications"
    const val USER_RELIABILITY_REVIEWS = "user_reliability_reviews"
}

// Alan (Field) İsimleri - Sorgularda kullanmak için
object FirestoreField {
    const val ID = "id"
    const val CREATED_AT = "createdAt"
    const val UPDATED_AT = "updatedAt"
    const val IS_ACTIVE = "isActive"

    // User
    const val EMAIL = "email"
    const val USERNAME = "username"
    const val USER_TYPE = "userType"
    const val FCM_TOKEN = "fcmToken"

    // Facility
    const val OWNER_ID = "ownerId"
    const val STATUS = "status"
    const val LATITUDE = "latitude"
    const val LONGITUDE = "longitude"

    // Booking
    const val USER_ID = "userId"
    const val FACILITY_ID = "facilityId"
    const val PITCH_ID = "pitchId"
    const val DATE = "date"
    const val START_HOUR = "startHour"

    // Group
    const val MEMBER_IDS = "memberIds"
    const val CREATOR_ID = "creatorId"

    // Match Post
    const val MATCH_DATE = "matchDate"
    const val EXPIRES_AT = "expiresAt"

    // Notification
    const val IS_READ = "isRead"
}