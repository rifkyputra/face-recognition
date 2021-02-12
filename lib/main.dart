import 'dart:io';
import 'dart:ui';

import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:camera/camera.dart';
import 'package:image_feature_detector/image_feature_detector.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Material App',
      home: Scaffold(
        body: PageView(
          children: [
            Scaffold(
              body: Center(
                child: Text('Swipe'),
              ),
            ),
            Scaffold(
              body: CameraView(),
            )
          ],
        ),
      ),
    );
  }
}

class CameraView extends StatefulWidget {
  @override
  _CameraViewState createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  CameraController _cameraController;
  List<CameraDescription> cameras;
  var _imageData;
  var _img;
  bool isFaceDetected;
  List<Rect> rect = <Rect>[];
  String photoLabels = '';

  @override
  void initState() {
    availableCameras().then((cam) {
      _cameraController = CameraController(cam[1], ResolutionPreset.low)
        ..initialize().then((_) {
          if (!mounted) {
            return;
          }
          // _cameraController.startImageStream((img) async {
          //   final file = File.fromRawPath(img.planes[0].bytes).path;

          //   // imageData =
          //   //     await ImageFeatureDetector.detectAndTransformRectangle(file);
          // });
          setState(() {});
        });
    });
    super.initState();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    if (rect != null) {
      rect.clear();
    }
    try {
      final fil = await _cameraController.takePicture();
      _img = fil.path;
      final l = await ImageFeatureDetector.detectRectangles(_img);
      _imageData = await decodeImageFromList(await fil.readAsBytes());

      final FirebaseVisionImage visionImage =
          FirebaseVisionImage.fromFile(File(_img));

      final FaceDetector faceDetector = FirebaseVision.instance.faceDetector();
      final ImageLabeler labeler = FirebaseVision.instance.imageLabeler();

      final List<Face> faces = await faceDetector.processImage(visionImage);

      photoLabels = '';
      await labeler.processImage(visionImage)
        ..forEach((label) {
          photoLabels += label.text + ' ';
          print('label : ');
          print(label.text);
        });

      for (Face face in faces) {
        rect.add(face.boundingBox);
        final double rotY =
            face.headEulerAngleY; // Head is rotated to the right rotY degrees
        final double rotZ =
            face.headEulerAngleZ; // Head is tilted sideways rotZ degre
      }
      setState(() {
        isFaceDetected = true;
      });

      faceDetector.close();
      labeler.close();

      // imageData =
      //     await ImageFeatureDetector.detectAndTransformRectangle(
      //         _img);

    } catch (e) {
      print(e);
    }
    // print(xfile.name);

    // _img = File.fromRawPath(await xfile.);

    setState(() {});
    // print('${_cameraController.takePicture}');
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController?.value?.isInitialized ?? false) {
      return Stack(
        // alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 0,
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 0.7,
              child: GestureDetector(
                onTap: () {
                  // _cameraController.setFocusMode(FocusMode.auto);
                  // _cameraController.setFocusPoint();
                  print('some');
                },
                child: AspectRatio(
                  aspectRatio: _cameraController.value.aspectRatio,
                  child: CameraPreview(_cameraController),
                ),
              ),
            ),
          ),
          if (_img != null)
            Positioned(
              right: 0,
              top: 0,
              child: Image.file(
                File(_img),
                width: 222,
                height: MediaQuery.of(context).size.height * 0.3,
              ),
            ),
          if (_imageData != null)
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: 222,
                height: MediaQuery.of(context).size.height * 0.3,
                child: FittedBox(
                  child: SizedBox(
                    width: _imageData.width.toDouble(),
                    height: _imageData.height.toDouble(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        CustomPaint(
                          painter: FacePainter(
                            rect: rect,
                            imageFile: _imageData,
                            captionText: photoLabels,
                          ),
                        ),
                        Text(
                          'photoLabels.toString()',
                          style: TextStyle(color: Colors.blue, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  // Text(
                  //   photoLabels.toString(),
                  //   style: TextStyle(color: Colors.blue, fontSize: 33),
                  // ),
                ),
              ),
            ),
          Align(
            // bottom: 80,
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () => _capture(),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.camera),
              ),
            ),
          ),
        ],
      );
    }
    return Container();
  }
}

class FacePainter extends CustomPainter {
  List<Rect> rect;
  var imageFile;
  final String captionText;

  FacePainter(
      {@required this.rect, @required this.imageFile, this.captionText});

  @override
  void paint(Canvas canvas, Size size) {
    if (imageFile != null) {
      canvas.drawImage(imageFile, Offset.zero, Paint());
    }

    for (Rect rectangle in rect) {
      canvas.drawRect(
        rectangle,
        Paint()
          ..color = Colors.teal
          ..strokeWidth = 6.0
          ..style = PaintingStyle.stroke,
      );
    }

    if (captionText != null && captionText != '' && rect.isNotEmpty) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: '$captionText',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(
        minWidth: 0,
        maxWidth: 200,
      );
      // final offset = Offset(rect[0].bottomLeft, rect[0].size.height);
      textPainter.paint(canvas, rect[0].bottomLeft);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class NewPageView extends StatefulWidget {
  @override
  _NewPageViewState createState() => _NewPageViewState();
}

class _NewPageViewState extends State<NewPageView> {
  // PageController _pageController =
  double fraction = 1;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      body: Stack(
        alignment: Alignment.topLeft,
        children: [
          PageView(
            onPageChanged: (index) {
              if (index != 1) {
                print(index);
                setState(() {
                  fraction = 0.8;
                });
              } else {
                setState(() {
                  fraction = 1;
                });
              }
            },
            controller: PageController(
              initialPage: 1,
              keepPage: true,
              viewportFraction: fraction,
            ),
            children: [
              Transform.translate(
                offset: fraction != 0 ? Offset(-40, 0) : Offset.zero,
                child: Scaffold(
                  appBar: AppBar(
                    title: Text('Material App Bar'),
                  ),
                  body: Center(
                    child: Container(
                      child: Text('Hello World'),
                    ),
                  ),
                ),
              ),
              Transform.scale(
                scale: fraction,
                child: Scaffold(
                  appBar: AppBar(
                    title: Text('Material App Bar'),
                  ),
                  body: Center(
                    child: Container(
                      child: Text('Hello World'),
                    ),
                  ),
                ),
              ),
              Scaffold(
                appBar: AppBar(
                  title: Text('Material App Bar'),
                ),
                body: Center(
                  child: Container(
                    child: Text('Hello World'),
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
