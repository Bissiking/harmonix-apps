package com.harmonix.harmonix_apps

import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : AudioServiceActivity() {
    /**
     * Do NOT cache this engine in [FlutterEngineCache] under
     * [HarmonixAudioService.ENGINE_ID].
     *
     * Previously [configureFlutterEngine] stored the activity's engine under
     * the same key the Android Auto service uses.  When Android Auto started
     * *before* the user opened the app the service created an engine, executed
     * Dart's `main()`, and cached it.  When the activity later started it
     * received the *same* engine in a partially-initialised state (bootstrap
     * stuck, providers not ready) → infinite loading screen on the phone and
     * broken library in Android Auto.
     *
     * By NOT caching the activity engine under the service's key, each side
     * gets its own engine and Dart isolate.  The service's MethodChannel
     * bridge still works because AutoBridge only registers its handler when
     * called from the activity's [HarmonixApp] (app.dart).
     */
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Do NOT put this engine into FlutterEngineCache – the Android Auto
        // service (HarmonixAudioService) maintains its own separate engine
        // under ENGINE_ID = "harmonix_engine".
    }
}
