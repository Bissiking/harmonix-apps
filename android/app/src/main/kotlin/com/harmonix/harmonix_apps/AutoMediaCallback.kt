package com.harmonix.harmonix_apps

import android.os.Bundle
import android.util.Log
import android.support.v4.media.session.MediaSessionCompat
import io.flutter.plugin.common.MethodChannel

/**
 * Handles media control commands from Android Auto and forwards them
 * to Flutter via the MethodChannel.
 */
class AutoMediaCallback(
    private val channel: MethodChannel,
    private val session: MediaSessionCompat,
) : MediaSessionCompat.Callback() {
    companion object {
        private const val TAG = "HarmonixAutoCallback"
    }

    override fun onPlay() {
        session.isActive = true
        Log.d(TAG, "onPlay")
        channel.invokeMethod("play", null)
    }

    override fun onPause() {
        Log.d(TAG, "onPause")
        channel.invokeMethod("pause", null)
    }

    override fun onSkipToNext() {
        Log.d(TAG, "onSkipToNext")
        channel.invokeMethod("skipToNext", null)
    }

    override fun onSkipToPrevious() {
        Log.d(TAG, "onSkipToPrevious")
        channel.invokeMethod("skipToPrevious", null)
    }

    override fun onPlayFromMediaId(mediaId: String?, extras: Bundle?) {
        if (mediaId != null) {
            session.isActive = true
            Log.d(TAG, "onPlayFromMediaId mediaId=$mediaId")
            channel.invokeMethod("playFromId", mediaId)
        }
    }

    override fun onStop() {
        Log.d(TAG, "onStop")
        channel.invokeMethod("stop", null)
        session.isActive = false
    }

    override fun onSeekTo(pos: Long) {
        Log.d(TAG, "onSeekTo pos=$pos")
        channel.invokeMethod("seekTo", pos)
    }
}
