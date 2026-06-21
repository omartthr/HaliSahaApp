package com.example.HaliSahaApp.data.remote

import com.example.HaliSahaApp.data.models.Group
import com.example.HaliSahaApp.data.models.Message
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.Query
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.tasks.await

object ChatService {

    private val firebaseService = FirebaseService

    // MARK: - Get User Groups (Real-time)
    fun getUserGroupsFlow(userId: String): Flow<List<Group>> = callbackFlow {
        val query = firebaseService.groupsCollection
            .whereArrayContains("memberIds", userId)
            .orderBy("updatedAt", Query.Direction.DESCENDING)

        val listenerRegistration = query.addSnapshotListener { snapshot, error ->
            if (error != null) {
                close(error)
                return@addSnapshotListener
            }

            if (snapshot != null) {
                val groups = snapshot.documents.mapNotNull { it.toObject(Group::class.java) }
                trySend(groups)
            }
        }

        awaitClose {
            listenerRegistration.remove()
        }
    }

    // MARK: - Get Messages (Real-time)
    fun getMessagesFlow(groupId: String): Flow<List<Message>> = callbackFlow {
        val query = firebaseService.messagesCollection(groupId)
            .orderBy("createdAt", Query.Direction.ASCENDING)

        val listenerRegistration = query.addSnapshotListener { snapshot, error ->
            if (error != null) {
                close(error)
                return@addSnapshotListener
            }

            if (snapshot != null) {
                val messages = snapshot.documents.mapNotNull { it.toObject(Message::class.java) }
                trySend(messages)
            }
        }

        awaitClose {
            listenerRegistration.remove()
        }
    }

    // MARK: - Send Message
    suspend fun sendMessage(groupId: String, message: Message) {
        val messageRef = firebaseService.messagesCollection(groupId).document()
        val messageWithId = message.copy(id = messageRef.id)

        // Firebase rules require content to be <= 2000 chars, senderId to be auth.uid, etc.
        // The rule: onlyChanged(['lastMessage', 'updatedAt']) for member updating group.
        
        firebaseService.db.runBatch { batch ->
            // 1. Add message
            batch.set(messageRef, messageWithId)

            // 2. Update Group's lastMessage and updatedAt
            val groupRef = firebaseService.groupsCollection.document(groupId)
            val updates = mapOf(
                "lastMessage" to mapOf(
                    "senderId" to message.senderId,
                    "senderName" to message.senderName,
                    "content" to message.content,
                    "timestamp" to FieldValue.serverTimestamp(),
                    "messageType" to message.messageType.rawValue
                ),
                "updatedAt" to FieldValue.serverTimestamp()
            )
            batch.update(groupRef, updates)
        }.await()
    }

    // MARK: - Mark Messages As Read
    suspend fun markMessagesAsRead(groupId: String, messageIds: List<String>, userId: String) {
        if (messageIds.isEmpty()) return
        
        firebaseService.db.runBatch { batch ->
            messageIds.forEach { msgId ->
                val msgRef = firebaseService.messagesCollection(groupId).document(msgId)
                batch.update(
                    msgRef,
                    "readBy", FieldValue.arrayUnion(userId),
                    "updatedAt", FieldValue.serverTimestamp()
                )
            }
        }.await()
    }
}
