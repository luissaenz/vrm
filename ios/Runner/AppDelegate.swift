import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let stitchChannel = FlutterMethodChannel(name: "com.vrm.vrm_app/stitcher",
                                              binaryMessenger: controller.binaryMessenger)
    
    stitchChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "stitchVideos" {
          guard let args = call.arguments as? [String: Any],
                let clips = args["clips"] as? [String],
                let outputPath = args["outputPath"] as? String else {
              result(FlutterError(code: "INVALID_ARGS", message: "Clips or outputPath missing", details: nil))
              return
          }
          
          self.mergeVideos(clips: clips, outputPath: outputPath, result: result)
      } else {
          result(FlutterMethodNotImplemented)
      }
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func mergeVideos(clips: [String], outputPath: String, result: @escaping FlutterResult) {
      if clips.isEmpty {
          result(false)
          return
      }
      
      let mixComposition = AVMutableComposition()
      var insertTime = CMTime.zero
      
      let videoTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
      let audioTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
      
      for clip in clips {
          let asset = AVURLAsset(url: URL(fileURLWithPath: clip))
          do {
              let timeRange = CMTimeRange(start: .zero, duration: asset.duration)
              if let vTrack = asset.tracks(withMediaType: .video).first {
                  try videoTrack?.insertTimeRange(timeRange, of: vTrack, at: insertTime)
              }
              if let aTrack = asset.tracks(withMediaType: .audio).first {
                  try audioTrack?.insertTimeRange(timeRange, of: aTrack, at: insertTime)
              }
              insertTime = CMTimeAdd(insertTime, asset.duration)
          } catch {
              print("Error inserting track: \(error)")
          }
      }
      
      guard let exporter = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality) else {
          result(false)
          return
      }
      
      exporter.outputURL = URL(fileURLWithPath: outputPath)
      exporter.outputFileType = .mp4
      exporter.shouldOptimizeForNetworkUse = true
      
      exporter.exportAsynchronously {
          DispatchQueue.main.async {
              if exporter.status == .completed {
                  result(true)
              } else {
                  result(FlutterError(code: "STITCH_FAILED", message: exporter.error?.localizedDescription, details: nil))
              }
          }
      }
  }
}
