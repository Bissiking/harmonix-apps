package com.harmonix.harmonix_apps

import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache

class MainActivity : AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Share the UI FlutterEngine with Android Auto service so both sides use
        // the same MethodChannel registrations and app state/providers.
        FlutterEngineCache.getInstance().put(HarmonixAudioService.ENGINE_ID, flutterEngine)
    }
}
