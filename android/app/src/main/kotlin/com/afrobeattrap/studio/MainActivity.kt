package com.afrobeattrap.studio

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val executor = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "exportMix" -> {
                        val voicePath = call.argument<String>("voicePath")
                        val beatUrl = call.argument<String>("beatUrl")
                        val outputPath = call.argument<String>("outputPath")
                        val voiceVolume = call.argument<Double>("voiceVolume")?.toFloat()
                        val beatVolume = call.argument<Double>("beatVolume")?.toFloat()
                        if (
                            voicePath.isNullOrBlank() ||
                            beatUrl.isNullOrBlank() ||
                            outputPath.isNullOrBlank() ||
                            voiceVolume == null ||
                            beatVolume == null
                        ) {
                            result.error("INVALID_ARGS", "Missing mix export arguments", null)
                            return@setMethodCallHandler
                        }
                        executor.execute {
                            try {
                                val ok = WavMixExporter.export(
                                    voicePath = voicePath,
                                    beatUrl = beatUrl,
                                    outputPath = outputPath,
                                    voiceVolume = voiceVolume,
                                    beatVolume = beatVolume,
                                )
                                runOnUiThread {
                                    if (ok) result.success(outputPath)
                                    else result.error("MIX_FAILED", "Could not export mix", null)
                                }
                            } catch (e: Exception) {
                                runOnUiThread {
                                    result.error("MIX_ERROR", e.message, null)
                                }
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    companion object {
        private const val CHANNEL = "com.afrobeattrap.studio/wav_mix"
    }
}
