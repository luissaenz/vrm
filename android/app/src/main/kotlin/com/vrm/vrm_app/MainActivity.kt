package com.vrm.vrm_app

import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.nio.ByteBuffer

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.vrm.vrm_app/stitcher"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "stitchVideos") {
                val clips = call.argument<List<String>>("clips")
                val outputPath = call.argument<String>("outputPath")
                if (clips != null && outputPath != null) {
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            val success = mergeVideos(clips, outputPath)
                            withContext(Dispatchers.Main) {
                                if (success) {
                                    result.success(true)
                                } else {
                                    result.error("STITCH_FAILED", "MediaMuxer failed", null)
                                }
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.error("STITCH_FAILED", e.message, null)
                            }
                        }
                    }
                } else {
                    result.error("INVALID_ARGS", "Clips or outputPath are null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun mergeVideos(clips: List<String>, outputPath: String): Boolean {
        if (clips.isEmpty()) return false
        try {
            val muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
            var outVideoTrackIndex = -1
            var outAudioTrackIndex = -1
            
            // First pass to determine tracks and add them to Muxer
            val firstExtractor = MediaExtractor()
            firstExtractor.setDataSource(clips[0])
            for (i in 0 until firstExtractor.trackCount) {
                val format = firstExtractor.getTrackFormat(i)
                val mime = format.getString(MediaFormat.KEY_MIME) ?: ""
                if (mime.startsWith("video/")) {
                    outVideoTrackIndex = muxer.addTrack(format)
                } else if (mime.startsWith("audio/")) {
                    outAudioTrackIndex = muxer.addTrack(format)
                }
            }
            firstExtractor.release()
            muxer.start()

            val byteBuffer = ByteBuffer.allocate(1024 * 1024 * 5)
            val bufferInfo = MediaCodec.BufferInfo()
            var videoPtsOffset = 0L
            var audioPtsOffset = 0L

            for (clip in clips) {
                val extractor = MediaExtractor()
                extractor.setDataSource(clip)
                
                var currentVideoTrack = -1
                var currentAudioTrack = -1
                
                for (i in 0 until extractor.trackCount) {
                    val mime = extractor.getTrackFormat(i).getString(MediaFormat.KEY_MIME) ?: ""
                    if (mime.startsWith("video/")) currentVideoTrack = i
                    else if (mime.startsWith("audio/")) currentAudioTrack = i
                }

                var lastVideoPts = 0L
                var lastAudioPts = 0L

                // Write video
                if (currentVideoTrack != -1 && outVideoTrackIndex != -1) {
                    extractor.selectTrack(currentVideoTrack)
                    while (true) {
                        val sampleSize = extractor.readSampleData(byteBuffer, 0)
                        if (sampleSize < 0) break
                        
                        bufferInfo.offset = 0
                        bufferInfo.size = sampleSize
                        bufferInfo.flags = extractor.sampleFlags
                        bufferInfo.presentationTimeUs = extractor.sampleTime + videoPtsOffset
                        lastVideoPts = Math.max(lastVideoPts, extractor.sampleTime)
                        
                        muxer.writeSampleData(outVideoTrackIndex, byteBuffer, bufferInfo)
                        extractor.advance()
                    }
                    extractor.unselectTrack(currentVideoTrack)
                }

                // Write audio
                if (currentAudioTrack != -1 && outAudioTrackIndex != -1) {
                    extractor.selectTrack(currentAudioTrack)
                    while (true) {
                        val sampleSize = extractor.readSampleData(byteBuffer, 0)
                        if (sampleSize < 0) break
                        
                        bufferInfo.offset = 0
                        bufferInfo.size = sampleSize
                        bufferInfo.flags = extractor.sampleFlags
                        bufferInfo.presentationTimeUs = extractor.sampleTime + audioPtsOffset
                        lastAudioPts = Math.max(lastAudioPts, extractor.sampleTime)
                        
                        muxer.writeSampleData(outAudioTrackIndex, byteBuffer, bufferInfo)
                        extractor.advance()
                    }
                    extractor.unselectTrack(currentAudioTrack)
                }
                
                videoPtsOffset += lastVideoPts + 30000L
                audioPtsOffset += lastAudioPts + 30000L
                
                extractor.release()
            }
            
            muxer.stop()
            muxer.release()
            return true
        } catch (e: Exception) {
            e.printStackTrace()
            return false
        }
    }
}
