import Flutter
import UIKit

public class ConvertNativeImgStreamPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "convert_native_img_stream", binaryMessenger: registrar.messenger())
    let instance = ConvertNativeImgStreamPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
        result("iOS " + UIDevice.current.systemVersion)
        break;
    case "convert":
       guard let args = call.arguments as? [String: Any],
             let bgra = args["bytes"] as? FlutterStandardTypedData,
             let width = args["width"] as? Int,
             let height = args["height"] as? Int,
             let quality = args["quality"] as? Int
        else {
          result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing arguments", details: nil))
          return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            let jpegData = self.convertBGRA8888ToJpeg(bgra.data, width: width, height: height, quality: CGFloat(quality) / 100.0)
          DispatchQueue.main.async {
            if let jpegData = jpegData {
              result(jpegData)
            } else {
              result(FlutterError(code: "CONVERSION_FAILED", message: "JPEG conversion failed", details: nil))
            }
          }
        }
        break;
    default:
      result(FlutterMethodNotImplemented)
    }
  }
/*
  val arg = (call.arguments as? Map<String, *>)
    val bytes: ByteArray? = arg?.get("bytes") as? ByteArray
    val width: Int? = arg?.get("width") as? Int
    val height: Int? = arg?.get("height") as? Int
    val quality: Int = arg?.get("quality") as? Int ?: 100
*/
 func convertBGRA8888ToJpeg(_ bgra: Data, width: Int, height: Int, quality: CGFloat) -> FlutterStandardTypedData? {
       let bytesPerPixel = 4
       let bytesPerRow = width * bytesPerPixel
       let colorSpace = CGColorSpaceCreateDeviceRGB()

       let bitmapInfo: CGBitmapInfo = [
         .byteOrder32Little,
         CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
       ]

       guard let providerRef = CGDataProvider(data: bgra as CFData) else {
         return nil
       }

       guard let cgImage = CGImage(
         width: width,
         height: height,
         bitsPerComponent: 8,
         bitsPerPixel: 32,
         bytesPerRow: bytesPerRow,
         space: colorSpace,
         bitmapInfo: bitmapInfo,
         provider: providerRef,
         decode: nil,
         shouldInterpolate: true,
         intent: .defaultIntent
       ) else {
         return nil
       }

       let uiImage = UIImage(cgImage: cgImage)
       guard let jpegData = uiImage.jpegData(compressionQuality: quality) else {
         return nil
       }

       return FlutterStandardTypedData(bytes: jpegData)
     }
}
