package com.harmonix.harmonix_apps

import com.ryanheise.audioservice.AudioServiceActivity
import android.app.UiModeManager
import android.content.Context
import android.content.res.Configuration
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "harmonix/platform")
            .setMethodCallHandler { call, result ->
                if (call.method == "isTelevision") {
                    val manager = getSystemService(Context.UI_MODE_SERVICE) as UiModeManager
                    result.success(manager.currentModeType == Configuration.UI_MODE_TYPE_TELEVISION)
                } else result.notImplemented()
            }
    }
}
