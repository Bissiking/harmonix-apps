package com.harmonix.harmonix_apps

import android.content.Intent
import android.os.Bundle
import android.support.v4.media.MediaBrowserCompat
import android.support.v4.media.MediaDescriptionCompat
import android.support.v4.media.MediaMetadataCompat
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import androidx.media.MediaBrowserServiceCompat
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

/**
 * HarmonixAudioService — MediaBrowserServiceCompat for Android Auto.
 *
 * Bridges Android Auto's MediaBrowser protocol to Flutter via a MethodChannel.
 * The Flutter side ([AutoBridge]) handles the actual business logic.
 *
 * Flow:
 *   Android Auto connects → onGetRoot() grants access
 *   Auto requests browse tree → onLoadChildren() calls Flutter "getQueue"
 *   User taps track → callback.onPlayFromMediaId() calls Flutter "playFromId"
 *   Flutter updates AudioHandler → MediaSession state propagates back
 */
class HarmonixAudioService : MediaBrowserServiceCompat() {

    companion object {
        const val ENGINE_ID = "harmonix_engine"
        const val CHANNEL = "com.harmonix.apps/auto"
        const val ROOT_ID = "HARMONIX_ROOT"
    }

    private lateinit var mediaSession: MediaSessionCompat
    private lateinit var channel: MethodChannel
    private var flutterEngine: FlutterEngine? = null

    // ---------------------------------------------------------------- Lifecycle

    override fun onCreate() {
        super.onCreate()

        // Reuse a cached FlutterEngine if available (shared with MainActivity)
        flutterEngine = FlutterEngineCache.getInstance().get(ENGINE_ID)
            ?: FlutterEngine(this).also { engine ->
                engine.dartExecutor.executeDartEntrypoint(
                    DartExecutor.DartEntrypoint.createDefault()
                )
                FlutterEngineCache.getInstance().put(ENGINE_ID, engine)
            }

        channel = MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL)

        mediaSession = MediaSessionCompat(this, "HarmonixAudio").apply {
            setCallback(AutoMediaCallback(channel, this))
            isActive = true
        }

        sessionToken = mediaSession.sessionToken
    }

    override fun onDestroy() {
        mediaSession.release()
        super.onDestroy()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }

    // --------------------------------------------------------- Browse protocol

    override fun onGetRoot(
        clientPackageName: String,
        clientUid: Int,
        rootHints: Bundle?
    ): BrowserRoot {
        // Accept all clients. Restrict to Auto package in production:
        // if (clientPackageName != "com.google.android.projection.gearhead") return null
        return BrowserRoot(ROOT_ID, null)
    }

    override fun onLoadChildren(
        parentId: String,
        result: Result<MutableList<MediaBrowserCompat.MediaItem>>
    ) {
        result.detach()

        channel.invokeMethod("getQueue", null, object : MethodChannel.Result {
            override fun success(value: Any?) {
                @Suppress("UNCHECKED_CAST")
                val items = (value as? List<Map<String, Any?>>)
                    ?.map { it.toMediaItem() }
                    ?.toMutableList()
                    ?: mutableListOf()
                result.sendResult(items)
            }

            override fun error(code: String, message: String?, details: Any?) {
                result.sendResult(mutableListOf())
            }

            override fun notImplemented() {
                result.sendResult(mutableListOf())
            }
        })
    }

    // -------------------------------------------------------------- Helpers

    private fun Map<String, Any?>.toMediaItem(): MediaBrowserCompat.MediaItem {
        val id = get("id") as? String ?: ""
        val title = get("title") as? String ?: "Unknown"
        val subtitle = get("subtitle") as? String ?: ""
        val coverUrl = get("coverUrl") as? String

        val desc = MediaDescriptionCompat.Builder()
            .setMediaId(id)
            .setTitle(title)
            .setSubtitle(subtitle)
            .apply {
                if (coverUrl != null) {
                    setIconUri(android.net.Uri.parse(coverUrl))
                }
            }
            .build()

        return MediaBrowserCompat.MediaItem(
            desc,
            MediaBrowserCompat.MediaItem.FLAG_PLAYABLE
        )
    }
}
