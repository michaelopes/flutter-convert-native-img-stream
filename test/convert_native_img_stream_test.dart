import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:convert_native_img_stream/convert_native_img_stream.dart';
import 'package:convert_native_img_stream/convert_native_img_stream_platform_interface.dart';
import 'package:convert_native_img_stream/convert_native_img_stream_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockConvertNativeImgStreamPlatform
    with MockPlatformInterfaceMixin
    implements ConvertNativeImgStreamPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<Uint8List?> convert(
    Uint8List imgBytes,
    int width,
    int height,
    int quality,
    int rotationFix,
  ) {
    return Future.value(Uint8List(0));
  }
}

void main() {
  final ConvertNativeImgStreamPlatform initialPlatform =
      ConvertNativeImgStreamPlatform.instance;

  test('$MethodChannelConvertNativeImgStream is the default instance', () {
    expect(
        initialPlatform, isInstanceOf<MethodChannelConvertNativeImgStream>());
  });

  test('getPlatformVersion', () async {
    ConvertNativeImgStream convertNativeImgStreamPlugin =
        ConvertNativeImgStream();
    MockConvertNativeImgStreamPlatform fakePlatform =
        MockConvertNativeImgStreamPlatform();
    ConvertNativeImgStreamPlatform.instance = fakePlatform;

    expect(await convertNativeImgStreamPlugin.getPlatformVersion(), '42');
  });

  test('convert', () async {
    ConvertNativeImgStream convertNativeImgStreamPlugin =
        ConvertNativeImgStream();
    MockConvertNativeImgStreamPlatform fakePlatform =
        MockConvertNativeImgStreamPlatform();
    ConvertNativeImgStreamPlatform.instance = fakePlatform;

    expect(
        await convertNativeImgStreamPlugin.convertImgToBytes(
            Uint8List(0), 0, 0),
        throwsA(isA<Exception>));

    expect(
        await convertNativeImgStreamPlugin.convertImgToBytes(
            Uint8List(1), 0, 0),
        Uint8List(1));
  });
}
