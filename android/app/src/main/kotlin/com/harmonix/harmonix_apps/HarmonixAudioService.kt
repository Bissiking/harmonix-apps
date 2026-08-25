package com.harmonix.harmonix_apps

import android.content.Intent
import android.graphics.BitmapFactory
import android.util.Log
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import androidx.core.content.FileProvider
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
import io.flutter.plugins.GeneratedPluginRegistrant
import java.io.File
import java.io.FileOutputStream
import java.net.HttpURLConnection
import java.net.URL
import java.security.MessageDigest
import java.util.concurrent.Executors

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
        private const val TAG = "HarmonixAutoService"
    }

    private lateinit var mediaSession: MediaSessionCompat
    private lateinit var channel: MethodChannel
    private var flutterEngine: FlutterEngine? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private val ioExecutor = Executors.newSingleThreadExecutor()
    private val pendingDownloads = mutableSetOf<String>()

    // ---------------------------------------------------------------- Lifecycle

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "onCreate()")

        // Create a dedicated FlutterEngine for this service.
        // This engine is separate from MainActivity's engine (managed by
        // AudioServicePlugin) so each side has its own Dart isolate.
        flutterEngine = FlutterEngineCache.getInstance().get(ENGINE_ID)
            ?: FlutterEngine(this).also { engine ->
                GeneratedPluginRegistrant.registerWith(engine)
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
        Log.d(TAG, "MediaSession ready")
    }

    override fun onDestroy() {
        Log.d(TAG, "onDestroy()")
        ioExecutor.shutdownNow()
        mediaSession.release()
        super.onDestroy()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "onStartCommand() flags=$flags startId=$startId")
        return START_STICKY
    }

    // --------------------------------------------------------- Browse protocol

    override fun onGetRoot(
        clientPackageName: String,
        clientUid: Int,
        rootHints: Bundle?
    ): BrowserRoot {
        Log.d(TAG, "onGetRoot() client=$clientPackageName uid=$clientUid")
        // Accept all clients. Restrict to Auto package in production:
        // if (clientPackageName != "com.google.android.projection.gearhead") return null
        return BrowserRoot(ROOT_ID, null)
    }

    override fun onLoadChildren(
        parentId: String,
        result: Result<MutableList<MediaBrowserCompat.MediaItem>>
    ) {
        result.detach()
        Log.d(TAG, "onLoadChildren() parentId=$parentId")

        channel.invokeMethod("getQueue", null, object : MethodChannel.Result {
            override fun success(value: Any?) {
                @Suppress("UNCHECKED_CAST")
                val items = (value as? List<Map<String, Any?>>)
                    ?.map { it.toMediaItem() }
                    ?.toMutableList()
                    ?: mutableListOf()
                result.sendResult(items)
                Log.d(TAG, "onLoadChildren() sent ${items.size} items")
                if (items.isEmpty()) {
                    // Flutter side may still be booting when AA asks the queue.
                    // Trigger a refresh shortly after to avoid getting stuck on empty state.
                    mainHandler.postDelayed({ notifyChildrenChanged(ROOT_ID) }, 900)
                }
            }

            override fun error(code: String, message: String?, details: Any?) {
                Log.w(TAG, "getQueue error code=$code message=$message")
                result.sendResult(mutableListOf())
                mainHandler.postDelayed({ notifyChildrenChanged(ROOT_ID) }, 900)
            }

            override fun notImplemented() {
                Log.w(TAG, "getQueue not implemented")
                result.sendResult(mutableListOf())
                mainHandler.postDelayed({ notifyChildrenChanged(ROOT_ID) }, 900)
            }
        })
    }

    // -------------------------------------------------------------- Helpers

    private fun onFlutterMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            // Flutter notifies the service when queue changes.
            // This prompts Android Auto to refresh the browse tree.
            "queueChanged" -> {
                Log.d(TAG, "queueChanged")
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
                val artBytes = payload?.get("artBytes") as? ByteArray
                val durationMs = (payload?.get("durationMs") as? Number)?.toLong()
                var localArtUri: android.net.Uri? = null
                if (artBytes != null) {
                    localArtUri = cacheArtworkBytes(id.ifEmpty { title }, artBytes)?.let {
                        FileProvider.getUriForFile(this, "$packageName.fileprovider", it).also { uri ->
                            grantArtworkReadPermission(uri)
                        }
                    }
                }
                if (localArtUri == null && artUri != null) {
                    localArtUri = resolveOrScheduleArtworkUri(artUri)
                }
                val artBitmap = if (artBytes != null && artBytes.isNotEmpty()) {
                    BitmapFactory.decodeByteArray(artBytes, 0, artBytes.size)
                } else null
                Log.d(
                    TAG,
                    "nowPlayingChanged artBytes=${artBytes?.size ?: 0} decoded=${artBitmap != null} artUri=$artUri localArtUri=${localArtUri?.toString()}"
                )

                val metadata = MediaMetadataCompat.Builder()
                    .putString(MediaMetadataCompat.METADATA_KEY_MEDIA_ID, id)
                    .putString(MediaMetadataCompat.METADATA_KEY_TITLE, title)
                    .putString(MediaMetadataCompat.METADATA_KEY_ARTIST, subtitle)
                    .putString(MediaMetadataCompat.METADATA_KEY_ALBUM, album)
                    .apply {
                        if (artBitmap != null) {
                            putBitmap(MediaMetadataCompat.METADATA_KEY_ALBUM_ART, artBitmap)
                            putBitmap(MediaMetadataCompat.METADATA_KEY_DISPLAY_ICON, artBitmap)
                        }
                        if (localArtUri != null) {
                            putString(MediaMetadataCompat.METADATA_KEY_ALBUM_ART_URI, localArtUri.toString())
                            putString(MediaMetadataCompat.METADATA_KEY_DISPLAY_ICON_URI, localArtUri.toString())
                        } else if (artUri != null) {
                            putString(MediaMetadataCompat.METADATA_KEY_ALBUM_ART_URI, artUri)
                            putString(MediaMetadataCompat.METADATA_KEY_DISPLAY_ICON_URI, artUri)
                        }
                        if (durationMs != null) {
                            putLong(MediaMetadataCompat.METADATA_KEY_DURATION, durationMs)
                        }
                    }
                    .build()

                mediaSession.setMetadata(metadata)
                Log.d(TAG, "nowPlayingChanged id=$id title=$title")
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
                Log.d(TAG, "playbackStateChanged playing=$playing state=$processingState pos=$positionMs")
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
                    // Covers are now public; let Android Auto fetch directly in list rows.
                    setIconUri(android.net.Uri.parse(coverUrl))
                } else {
                    setIconUri(fallbackArtworkUri())
                }
                setIconBitmap(BitmapFactory.decodeResource(resources, R.mipmap.ic_launcher))
            }
            .build()

        return MediaBrowserCompat.MediaItem(
            desc,
            MediaBrowserCompat.MediaItem.FLAG_PLAYABLE
        )
    }

    private fun fallbackArtworkUri(): android.net.Uri {
        return android.net.Uri.parse("android.resource://$packageName/${R.mipmap.ic_launcher}")
    }

    private fun resolveOrScheduleArtworkUri(remoteUrl: String): android.net.Uri {
        val existing = cachedArtworkFile(remoteUrl)
        if (existing.exists()) {
            val uri = FileProvider.getUriForFile(
                this,
                "$packageName.fileprovider",
                existing
            )
            grantArtworkReadPermission(uri)
            return uri
        }

        scheduleArtworkDownload(remoteUrl)
        return fallbackArtworkUri()
    }

    private fun scheduleArtworkDownload(remoteUrl: String) {
        synchronized(pendingDownloads) {
            if (!pendingDownloads.add(remoteUrl)) return
        }
        ioExecutor.execute {
            try {
                downloadArtwork(remoteUrl)
                mainHandler.post { notifyChildrenChanged(ROOT_ID) }
            } catch (e: Exception) {
                Log.w(TAG, "Artwork download failed: $remoteUrl", e)
            } finally {
                synchronized(pendingDownloads) { pendingDownloads.remove(remoteUrl) }
            }
        }
    }

    private fun downloadArtwork(remoteUrl: String): File {
        val outFile = cachedArtworkFile(remoteUrl)
        outFile.parentFile?.mkdirs()
        if (outFile.exists() && outFile.length() > 0L) return outFile

        val conn = (URL(remoteUrl).openConnection() as HttpURLConnection).apply {
            connectTimeout = 6000
            readTimeout = 10000
            requestMethod = "GET"
        }
        conn.connect()
        if (conn.responseCode !in 200..299) {
            throw IllegalStateException("HTTP ${conn.responseCode}")
        }
        conn.inputStream.use { input ->
            FileOutputStream(outFile).use { output -> input.copyTo(output) }
        }
        return outFile
    }

    private fun cacheArtworkBytes(key: String, bytes: ByteArray): File? {
        return try {
            val safe = sha1(key)
            val outFile = File(File(cacheDir, "auto_covers"), "$safe.png")
            outFile.parentFile?.mkdirs()
            FileOutputStream(outFile).use { it.write(bytes) }
            outFile
        } catch (e: Exception) {
            Log.w(TAG, "cacheArtworkBytes failed for key=$key", e)
            null
        }
    }

    private fun cachedArtworkFile(remoteUrl: String): File {
        val ext = when {
            remoteUrl.endsWith(".png", ignoreCase = true) -> "png"
            remoteUrl.endsWith(".webp", ignoreCase = true) -> "webp"
            else -> "jpg"
        }
        val safe = sha1(remoteUrl)
        return File(File(cacheDir, "auto_covers"), "$safe.$ext")
    }

    private fun sha1(input: String): String {
        val bytes = MessageDigest.getInstance("SHA-1").digest(input.toByteArray())
        return bytes.joinToString("") { b -> "%02x".format(b) }
    }

    private fun grantArtworkReadPermission(uri: android.net.Uri) {
        val flags = Intent.FLAG_GRANT_READ_URI_PERMISSION
        val targets = listOf(
            "com.google.android.projection.gearhead", // Android Auto phone host
            "com.google.android.apps.automotive.templates.host", // emulator/hosts variants
            "com.android.car.media",
            "com.google.android.gms"
        )
        for (pkg in targets) {
            try {
                grantUriPermission(pkg, uri, flags)
            } catch (_: Exception) {
                // Ignore package not present on current host.
            }
        }
    }
}
