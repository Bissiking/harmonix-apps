package com.harmonix.harmonix_apps

import android.os.Bundle
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

    override fun onPlay() {
        channel.invokeMethod("play", null)
    }

    override fun onPause() {
        channel.invokeMethod("pause", null)
    }

    override fun onSkipToNext() {
        channel.invokeMethod("skipToNext", null)
    }

    override fun onSkipToPrevious() {
        channel.invokeMethod("skipToPrevious", null)
    }

    override fun onPlayFromMediaId(mediaId: String?, extras: Bundle?) {
        if (mediaId != null) {
            channel.invokeMethod("playFromId", mediaId)
        }
    }

    override fun onStop() {
        channel.invokeMethod("stop", null)
        session.isActive = false
    }

    override fun onSeekTo(pos: Long) {
        channel.invokeMethod("seekTo", pos)
    }
}
