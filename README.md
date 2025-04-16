# convert_native_img_stream

Converter utility for converting ImageFormatGroup.nv21 or ImageFormatGroup.bgra8888 to jpeg file (coming from camera stream)

## Intro
This plugin is mainly developed for situation when you are using the ml kit or other library that are processing the
frames in single plane native format (nv12 or bgra) and you want to save the exactly processed frame from CameraImage 
object of frame. It will help you to convert the frame into jpeg format (into memory or file)

## Sample usage
```dart
  CameraImage frame; //init your frame from stream
  Uint8List? imageBytes;
  File? imageFile;
  
  final convertNative = ConvertNativeImgStream();
  
  covertFrame() async {
    final jpegByte = await convertNative.convertImgToBytes(frame.planes.first.bytes, frame.width, frame.height);
    final jpegFile = await convertNative.convertImg(frame.planes.first.bytes, frame.width, frame.height, "/path/to/save");
  }

    @override
    Widget build(BuildContext context) {
      return MaterialApp(
        home: Scaffold(
            appBar: AppBar(
              title: const Text('Test'),
            ),
            body: Column(
              children: [
                if(imageBytes != null)
                  Image.memory(imageBytes!, fit: BoxFit.cover)
                if(imageFile != null)
                  Image.file(
                    imageFile,
                    fit: BoxFit.cover
                  )
              ]
            )
        ),
      );
    }
```