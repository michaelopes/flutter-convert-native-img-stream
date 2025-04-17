package dev.ms.convert_native_img_stream

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.ImageFormat
import android.graphics.Matrix
import android.graphics.Rect
import android.graphics.YuvImage
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.ByteArrayOutputStream

/** ConvertNativeImgStreamPlugin */
class ConvertNativeImgStreamPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "convert_native_img_stream")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    if (call.method == "getPlatformVersion") {
      result.success("Android ${android.os.Build.VERSION.RELEASE}")
    } else if(call.method == "convert") {
      convert(call, result)
    } else {
      result.notImplemented()
    }
  }

 /* private fun convert(call: MethodCall, result: MethodChannel.Result) {
    val arg = (call.arguments as? Map<String, *>)
    val bytes: ByteArray? = arg?.get("bytes") as? ByteArray
    val width: Int? = arg?.get("width") as? Int
    val height: Int? = arg?.get("height") as? Int
    val quality: Int = arg?.get("quality") as? Int ?: 100

    if(bytes == null || width == null || height == null) {
      result.error("Null argument", "bytes, width, height must not be null", null)
      return
    }

    Thread {
      val out = ByteArrayOutputStream()
      val yuv = YuvImage(bytes, ImageFormat.NV21, width, height, null)
      yuv.compressToJpeg(Rect(0, 0, width, height), quality, out)
      val converted = out.toByteArray()
      Handler(Looper.getMainLooper()).post {
        result.success(converted)
      }
    }.start()
  }*/


  private fun convert(call: MethodCall, result: MethodChannel.Result) {
    val arg = call.arguments as? Map<String, *>
    val bytes = arg?.get("bytes") as? ByteArray
    val width = arg?.get("width") as? Int
    val height = arg?.get("height") as? Int
    val quality = arg?.get("quality") as? Int ?: 100
    val rotation = arg?.get("rotation") as? Float ?: 0.0

    if (bytes == null || width == null || height == null) {
      result.error("Null argument", "bytes, width, height must not be null", null)
      return
    }

    Thread {
      try {
        val yuv = YuvImage(bytes, ImageFormat.NV21, width, height, null)
        val out = ByteArrayOutputStream()
        yuv.compressToJpeg(Rect(0, 0, width, height), quality, out)
        val jpegBytes = out.toByteArray()
        if(rotation != 0) {
          val bitmap = BitmapFactory.decodeByteArray(jpegBytes, 0, jpegBytes.size)
          // 🌀 Usa bitmap do pool já com tamanho rotacionado
          val rotatedBitmap = BitmapPool.get(bitmap.height, bitmap.width, bitmap.config)
          // 🌀 Aplica rotação usando canvas + matrix
          val canvas = Canvas(rotatedBitmap)
          val matrix = Matrix().apply {
            postRotate(rotation as Float)
            postTranslate(bitmap.height.toFloat(), 0f)
          }
          canvas.drawBitmap(bitmap, matrix, null)

          val finalOut = ByteArrayOutputStream()
          rotatedBitmap.compress(Bitmap.CompressFormat.JPEG, quality, finalOut)
          val rotatedBytes = finalOut.toByteArray()

          bitmap.recycle()
          BitmapPool.put(rotatedBitmap) // devolve ao pool

          Handler(Looper.getMainLooper()).post {
            result.success(rotatedBytes)
          }

        } else {
          Handler(Looper.getMainLooper()).post {
            result.success(jpegBytes)
          }
        }
      } catch (e: Exception) {
        Handler(Looper.getMainLooper()).post {
          result.error("Processing error", e.message, null)
        }
      }
    }.start()
  }


  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
