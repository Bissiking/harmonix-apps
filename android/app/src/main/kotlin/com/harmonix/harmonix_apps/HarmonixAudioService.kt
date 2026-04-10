package com.harmonix.harmonix_apps

import android.content.Intent
import android.os.Bundle
import android.support.v4.media.MediaBrowserCompat
import android.support.v4.media.MediaDescriptionCompat
import android.support.v4.media.MediaMetadataCompat
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import androidx.media.MediaBrowserServiceCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodCall
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
        channel.setMethodCallHandler(::onFlutterMethodCall)

        mediaSession = MediaSessionCompat(this, "HarmonixAudio").apply {
            setCallback(AutoMediaCallback(channel, this))
            isActive = true
            setPlaybackState(
                PlaybackStateCompat.Builder()
                    .setActions(defaultActions())
                    .setState(PlaybackStateCompat.STATE_PAUSED, 0L, 1f)
                    .build()
            )
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

    private fun onFlutterMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            // Flutter notifies the service when queue changes.
            // This prompts Android Auto to refresh the browse tree.
            "queueChanged" -> {
                notifyChildrenChanged(ROOT_ID)
                result.success(null)
            }
            "nowPlayingChanged" -> {
                val payload = call.arguments as? Map<*, *>
                val id = payload?.get("id") as? String ?: ""
                val title = payload?.get("title") as? String ?: "Unknown"
                val subtitle = payload?.get("subtitle") as? String ?: ""
                val album = payload?.get("album") as? String ?: ""
                val artUri = payload?.get("artUri") as? String
                val durationMs = (payload?.get("durationMs") as? Number)?.toLong()

                val metadata = MediaMetadataCompat.Builder()
                    .putString(MediaMetadataCompat.METADATA_KEY_MEDIA_ID, id)
                    .putString(MediaMetadataCompat.METADATA_KEY_TITLE, title)
                    .putString(MediaMetadataCompat.METADATA_KEY_ARTIST, subtitle)
                    .putString(MediaMetadataCompat.METADATA_KEY_ALBUM, album)
                    .apply {
                        if (artUri != null) {
                            putString(MediaMetadataCompat.METADATA_KEY_ALBUM_ART_URI, artUri)
                            putString(MediaMetadataCompat.METADATA_KEY_DISPLAY_ICON_URI, artUri)
                        }
                        if (durationMs != null) {
                            putLong(MediaMetadataCompat.METADATA_KEY_DURATION, durationMs)
                        }
                    }
                    .build()

                mediaSession.setMetadata(metadata)
                result.success(null)
            }
            "playbackStateChanged" -> {
                val payload = call.arguments as? Map<*, *>
                val playing = payload?.get("playing") as? Boolean ?: false
                val processingState = (payload?.get("processingState") as? Number)?.toInt() ?: 0
                val positionMs = (payload?.get("positionMs") as? Number)?.toLong() ?: 0L
                val speed = (payload?.get("speed") as? Number)?.toFloat() ?: 1f

                val compatState = when (processingState) {
                    1, 2 -> PlaybackStateCompat.STATE_BUFFERING
                    3 -> if (playing) PlaybackStateCompat.STATE_PLAYING else PlaybackStateCompat.STATE_PAUSED
                    4 -> PlaybackStateCompat.STATE_STOPPED
                    5 -> PlaybackStateCompat.STATE_ERROR
                    else -> PlaybackStateCompat.STATE_NONE
                }

                val state = PlaybackStateCompat.Builder()
                    .setActions(defaultActions())
                    .setState(compatState, positionMs, if (playing) speed else 0f)
                    .build()

                mediaSession.setPlaybackState(state)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun defaultActions(): Long {
        return PlaybackStateCompat.ACTION_PLAY or
            PlaybackStateCompat.ACTION_PAUSE or
            PlaybackStateCompat.ACTION_PLAY_FROM_MEDIA_ID or
            PlaybackStateCompat.ACTION_SKIP_TO_NEXT or
            PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS or
            PlaybackStateCompat.ACTION_SEEK_TO or
            PlaybackStateCompat.ACTION_STOP
    }

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
