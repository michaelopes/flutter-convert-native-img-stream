import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'convert_native_img_stream_platform_interface.dart';

class ConvertNativeImgStream {
  Future<String?> getPlatformVersion() {
    return ConvertNativeImgStreamPlatform.instance.getPlatformVersion();
  }

  Future<File?> convertImg(
      Uint8List imgBytes, int width, int height, String pathToSave,
      {int rotationFix = 90, int quality = 100}) async {
    final converted = convertImgToBytes(
      imgBytes,
      width,
      height,
      rotationFix: rotationFix,
      quality: quality,
    );
    return compute((List<dynamic> params) async {
      final bytes = params[0];
      final path = params[1];
      return await _saveImageToFile(bytes, path);
    }, [converted, pathToSave]);
  }

  Future<Uint8List?> convertImgToBytes(
    Uint8List imgBytes,
    int width,
    int height, {
    int rotationFix = 90,
    int quality = 100,
    bool enablePostProcessing = true,
  }) async {
    if (imgBytes.isEmpty) {
      throw Exception("imgBytes are empty");
    }
    if (width == 0 || height == 0) {
      throw Exception("width or height cant be zero");
    }
    Uint8List? jpegData = imgBytes;
    if (Platform.isAndroid) {
      jpegData = await ConvertNativeImgStreamPlatform.instance
          .convert(imgBytes, width, height, quality, rotationFix);
      if (!enablePostProcessing) {
        return jpegData;
      }
    }
    return compute((List<dynamic> params) async {
      final int w = params[0];
      final int h = params[1];
      final Uint8List bytes = params[2];

      if (Platform.isAndroid) {
        if (quality != 100) {
          img.Image? image = img.decodeJpg(bytes);
          return img.encodeJpg(image!, quality: quality);
        }
        return bytes;
      } else {
        img.Image im = img.Image.fromBytes(
            height: h.toInt(),
            width: w.toInt(),
            bytes: bytes.buffer,
            format: img.Format.uint8,
            order: img.ChannelOrder.bgra);
        final imgData = img.encodeJpg(im, quality: quality);
        return imgData;
      }
    }, [width, height, jpegData]);
  }

  Future<File?> _saveImageToFile(Uint8List? jpegData, String appDir) async {
    if (jpegData == null) {
      return null;
    }
    try {
      // Get the temporary directory path
      final String fileName = '${DateTime.now().toIso8601String()}.jpg';
      final String newPath = '$appDir/$fileName';

      // Save the image to the specified path
      final File imageFile = File(newPath);
      await imageFile.writeAsBytes(jpegData);
      return imageFile;
    } catch (e) {
      return null;
    }
  }
}
