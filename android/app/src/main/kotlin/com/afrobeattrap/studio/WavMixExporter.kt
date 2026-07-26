package com.afrobeattrap.studio

import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import java.io.File
import java.io.FileOutputStream
import java.io.RandomAccessFile
import java.net.HttpURLConnection
import java.net.URL
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.min
import kotlin.math.roundToInt

object WavMixExporter {

    fun export(
        voicePath: String,
        beatUrl: String,
        outputPath: String,
        voiceVolume: Float,
        beatVolume: Float,
    ): Boolean {
        val voice = readWavPcm(voicePath) ?: return false
        val beatFile = downloadToCache(beatUrl) ?: return false
        return try {
            val beatPcm = decodeMp3ToMono16(beatFile, voice.sampleRate) ?: return false
            val beatLooped = loopToLength(beatPcm, voice.samples.size)
            val mixed = mixSamples(voice.samples, beatLooped, voiceVolume, beatVolume)
            writeWavPcm16(outputPath, mixed, voice.sampleRate, 1)
            true
        } finally {
            beatFile.delete()
        }
    }

    private data class PcmData(val samples: ShortArray, val sampleRate: Int)

    private fun readWavPcm(path: String): PcmData? {
        val file = File(path)
        if (!file.exists() || file.length() <= 44) return null

        RandomAccessFile(file, "r").use { raf ->
            val header = ByteArray(44)
            raf.readFully(header)
            val sampleRate =
                ByteBuffer.wrap(header, 24, 4).order(ByteOrder.LITTLE_ENDIAN).int
            val channels =
                ByteBuffer.wrap(header, 22, 2).order(ByteOrder.LITTLE_ENDIAN).short.toInt()
            val bitsPerSample =
                ByteBuffer.wrap(header, 34, 2).order(ByteOrder.LITTLE_ENDIAN).short.toInt()
            if (bitsPerSample != 16 || sampleRate <= 0) return null

            val pcmBytes = (file.length() - 44).toInt()
            if (pcmBytes <= 0 || pcmBytes % 2 != 0) return null
            val raw = ByteArray(pcmBytes)
            raf.readFully(raw)

            val sampleCount = pcmBytes / 2 / channels
            val mono = ShortArray(sampleCount)
            val buffer = ByteBuffer.wrap(raw).order(ByteOrder.LITTLE_ENDIAN).asShortBuffer()
            if (channels == 1) {
                buffer.get(mono)
            } else {
                val stereo = ShortArray(pcmBytes / 2)
                buffer.get(stereo)
                for (i in mono.indices) {
                    val left = stereo[i * 2].toInt()
                    val right = stereo[i * 2 + 1].toInt()
                    mono[i] = ((left + right) / 2).toShort()
                }
            }
            return PcmData(mono, sampleRate)
        }
    }

    private fun writeWavPcm16(path: String, samples: ShortArray, sampleRate: Int, channels: Int) {
        val dataSize = samples.size * 2
        val out = FileOutputStream(path)
        out.use { stream ->
            val header = ByteBuffer.allocate(44).order(ByteOrder.LITTLE_ENDIAN)
            header.put("RIFF".toByteArray())
            header.putInt(36 + dataSize)
            header.put("WAVE".toByteArray())
            header.put("fmt ".toByteArray())
            header.putInt(16)
            header.putShort(1)
            header.putShort(channels.toShort())
            header.putInt(sampleRate)
            header.putInt(sampleRate * channels * 2)
            header.putShort((channels * 2).toShort())
            header.putShort(16)
            header.put("data".toByteArray())
            header.putInt(dataSize)
            stream.write(header.array())

            val pcm = ByteBuffer.allocate(dataSize).order(ByteOrder.LITTLE_ENDIAN)
            for (sample in samples) pcm.putShort(sample)
            stream.write(pcm.array())
        }
    }

    private fun downloadToCache(url: String): File? {
        return try {
            val connection = URL(url).openConnection() as HttpURLConnection
            connection.connectTimeout = 20000
            connection.readTimeout = 30000
            connection.instanceFollowRedirects = true
            connection.connect()
            if (connection.responseCode !in 200..299) return null
            val file = File.createTempFile("beat_mix_", ".mp3")
            connection.inputStream.use { input ->
                file.outputStream().use { output -> input.copyTo(output) }
            }
            file
        } catch (_: Exception) {
            null
        }
    }

    private fun decodeMp3ToMono16(file: File, targetRate: Int): ShortArray? {
        val extractor = MediaExtractor()
        extractor.setDataSource(file.absolutePath)
        var trackIndex = -1
        for (i in 0 until extractor.trackCount) {
            val format = extractor.getTrackFormat(i)
            val mime = format.getString(MediaFormat.KEY_MIME) ?: continue
            if (mime.startsWith("audio/")) {
                trackIndex = i
                break
            }
        }
        if (trackIndex < 0) {
            extractor.release()
            return null
        }

        extractor.selectTrack(trackIndex)
        val format = extractor.getTrackFormat(trackIndex)
        val mime = format.getString(MediaFormat.KEY_MIME) ?: run {
            extractor.release()
            return null
        }

        val codec = MediaCodec.createDecoderByType(mime)
        codec.configure(format, null, null, 0)
        codec.start()

        val output = ArrayList<Short>()
        val bufferInfo = MediaCodec.BufferInfo()
        var inputDone = false

        try {
            while (true) {
                if (!inputDone) {
                    val inputIndex = codec.dequeueInputBuffer(10000)
                    if (inputIndex >= 0) {
                        val inputBuffer = codec.getInputBuffer(inputIndex) ?: break
                        val sampleSize = extractor.readSampleData(inputBuffer, 0)
                        if (sampleSize < 0) {
                            codec.queueInputBuffer(
                                inputIndex,
                                0,
                                0,
                                0,
                                MediaCodec.BUFFER_FLAG_END_OF_STREAM,
                            )
                            inputDone = true
                        } else {
                            codec.queueInputBuffer(
                                inputIndex,
                                0,
                                sampleSize,
                                extractor.sampleTime,
                                0,
                            )
                            extractor.advance()
                        }
                    }
                }

                val outputIndex = codec.dequeueOutputBuffer(bufferInfo, 10000)
                when {
                    outputIndex == MediaCodec.INFO_TRY_AGAIN_LATER -> {
                        if (inputDone) break
                    }
                    outputIndex >= 0 -> {
                        val outBuffer = codec.getOutputBuffer(outputIndex) ?: continue
                        appendPcm16(outBuffer, bufferInfo, format, output)
                        codec.releaseOutputBuffer(outputIndex, false)
                        if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                            break
                        }
                    }
                }
            }
        } finally {
            codec.stop()
            codec.release()
            extractor.release()
        }

        if (output.isEmpty()) return null
        val mono = output.toShortArray()
        val sourceRate = format.getInteger(MediaFormat.KEY_SAMPLE_RATE)
        return if (sourceRate == targetRate) mono else resample(mono, sourceRate, targetRate)
    }

    private fun appendPcm16(
        buffer: ByteBuffer,
        info: MediaCodec.BufferInfo,
        format: MediaFormat,
        out: ArrayList<Short>,
    ) {
        buffer.position(info.offset)
        buffer.limit(info.offset + info.size)
        val channelCount = format.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
        val shortCount = info.size / 2
        val shorts = ShortArray(shortCount)
        buffer.order(ByteOrder.LITTLE_ENDIAN).asShortBuffer().get(shorts)
        if (channelCount <= 1) {
            for (s in shorts) out.add(s)
        } else {
            var i = 0
            while (i + 1 < shorts.size) {
                val mixed = ((shorts[i].toInt() + shorts[i + 1].toInt()) / 2).toShort()
                out.add(mixed)
                i += channelCount
            }
        }
    }

    private fun resample(input: ShortArray, fromRate: Int, toRate: Int): ShortArray {
        if (fromRate == toRate) return input
        val outputLength = (input.size.toDouble() * toRate / fromRate).roundToInt()
        val output = ShortArray(outputLength)
        for (i in output.indices) {
            val srcPos = i.toDouble() * fromRate / toRate
            val index = srcPos.toInt().coerceIn(0, input.size - 1)
            output[i] = input[index]
        }
        return output
    }

    private fun loopToLength(samples: ShortArray, length: Int): ShortArray {
        if (samples.isEmpty()) return ShortArray(length)
        val out = ShortArray(length)
        for (i in 0 until length) out[i] = samples[i % samples.size]
        return out
    }

    private fun mixSamples(
        voice: ShortArray,
        beat: ShortArray,
        voiceVolume: Float,
        beatVolume: Float,
    ): ShortArray {
        val vGain = voiceVolume.coerceIn(0f, 1f)
        val bGain = beatVolume.coerceIn(0f, 1f)
        val length = min(voice.size, beat.size)
        val mixed = ShortArray(length)
        for (i in 0 until length) {
            val sum = (voice[i] * vGain).toInt() + (beat[i] * bGain).toInt()
            mixed[i] = sum.coerceIn(Short.MIN_VALUE.toInt(), Short.MAX_VALUE.toInt()).toShort()
        }
        return mixed
    }
}
