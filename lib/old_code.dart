// ignore_for_file: prefer_const_constructors, unnecessary_null_comparison, avoid_print, unused_element, sized_box_for_whitespace

import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;

class FloorPlanScreenOldCode extends StatefulWidget {
  const FloorPlanScreenOldCode({Key? key}) : super(key: key);

  @override
  State<FloorPlanScreenOldCode> createState() => _FloorPlanScreenOldCodeState();
}

class _FloorPlanScreenOldCodeState extends State<FloorPlanScreenOldCode> {
  late ui.Image floorImage;
  List<Map<String, dynamic>> textData = [];
  bool isImageLoaded = false;

  final List<String> imageList = [
    'assets/image_1.jpeg',
    'assets/image_2.jpeg',
    'assets/image_3.jpeg',
    'assets/image_4.jpeg',
    'assets/floor_1.png',
    'assets/floor_2.png',
    'assets/floor_3.png',
    'assets/floor_4.png',
    'assets/floor_5.png',
  ];

  @override
  void initState() {
    super.initState();
    loadAndProcessImage('assets/image_1.jpeg');
  }

  Future<void> loadAndProcessImage(String imagePath) async {
    final byteData = await rootBundle.load(imagePath);
    final imageBytes = byteData.buffer.asUint8List();

    final grayscaleBytes = await convertToGrayscale(imageBytes);

    final codec =
    await ui.instantiateImageCodec(Uint8List.fromList(grayscaleBytes));
    final frame = await codec.getNextFrame();
    floorImage = frame.image;

    final extractedTextData = await extractTextFromImage(grayscaleBytes);
    setState(() {
      textData = extractedTextData;
      isImageLoaded = true;
    });
  }

  Future<Uint8List> convertToGrayscale(Uint8List bytes) async {
    final image = img.decodeImage(bytes)!;
    final grayscaleImage = img.grayscale(image);
    return Uint8List.fromList(img.encodePng(grayscaleImage));
  }

  Future<File> saveGrayscaleImage(List<int> imageBytes) async {
    try {
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/temp_image.png';
      final file = File(path);
      await file.writeAsBytes(imageBytes);
      return file;
    } catch (e) {
      print('Error saving image: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> extractTextFromImage(
      List<int> imageBytes) async {
    final textRecognizer = GoogleMlKit.vision.textRecognizer();
    final file = await saveGrayscaleImage(imageBytes);
    final inputImage = InputImage.fromFilePath(file.path);

    final recognizedText = await textRecognizer.processImage(inputImage);
    final extractedData = <Map<String, dynamic>>[];
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final text = line.text;
        final boundingBox = line.boundingBox;

        if (boundingBox != null && !separateTextBasedOnCharacterCount(text)) {
          extractedData.add({'text': text, 'rect': boundingBox});
        }
      }
    }
    textRecognizer.close();
    return extractedData;
  }

  bool separateTextBasedOnCharacterCount(String input) {
    final regex = RegExp(r'([\d-]+"?X[\d-]+)');
    final match = regex.firstMatch(input);

    if (match != null) {
      final matchedText = match.group(1)!;
      final alphabetCount =
          matchedText.replaceAll(RegExp(r'[^a-zA-Z]'), '').length;
      return alphabetCount <= 2;
    }
    return false;
  }

  String? findNearestText(
      double x, double y, List<Map<String, dynamic>> textData) {
    String? nearestText;
    double minDistance = double.infinity;

    for (final data in textData) {
      final rect = data['rect'] as Rect;
      double distance = calculateDistanceToRect(x, y, rect);
      print('Checking rect: $rect with distance: $distance');
      if (distance < minDistance) {
        minDistance = distance;
        nearestText = data['text'];
      }
    }
    print('Nearest text: $nearestText with distance: $minDistance');
    return nearestText;
  }

  double calculateDistanceToRect(double x, double y, Rect rect) {
    if (rect.contains(Offset(x, y))) {
      return 0.0;
    }

    double dx = max(rect.left - x, x - rect.right);
    double dy = max(rect.top - y, y - rect.bottom);

    return sqrt(dx * dx + dy * dy);
  }


  Future<Uint8List> _convertToBytes(ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Floor Activity'),
      ),
      body: Column(
        children: [
          Expanded(
            child: isImageLoaded
                ? Stack(
              children: [
                // Positioned.fill(
                //   child: InteractiveViewer(
                //       minScale: 0.2,
                //       maxScale: 4.0,
                //       child: CustomPaint(
                //         painter: ImagePainter(floorImage, textData),
                //       )),
                // ),
                //
                // GestureDetector(
                //   onTapDown: (details) {
                //     final position = details.localPosition;
                //     final clickedText = findNearestText(
                //         position.dx, position.dy, textData);
                //     if (clickedText != null) {
                //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                //           content: Text('Clicked text: $clickedText')));
                //     } else {
                //       ScaffoldMessenger.of(context).showSnackBar(
                //           SnackBar(content: Text('No text nearby')));
                //     }
                //   },
                // ),

                ///Zoom In-Out
                FutureBuilder<Uint8List>(
                  future: _convertToBytes(floorImage),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (snapshot.hasData) {
                      return GestureDetector(
                        onTapDown: (details) {
                          final position = details.localPosition;
                          final clickedText =
                          findNearestText(position.dx, position.dy, textData);
                          if (clickedText != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Clicked text: $clickedText')));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('No text nearby')));
                          }
                        },
                        child: Center(
                          child: InteractiveViewer(
                            minScale: 0.5,
                            maxScale: 4.0,
                            child: Image.memory(
                              snapshot.data!,
                            ),
                          ),
                        ),
                      );
                    } else {
                      return Center(child: Text('No data available.'));
                    }
                  },
                )
              ],
            )
                : Center(child: CircularProgressIndicator()),
          ),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: imageList.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => loadAndProcessImage(imageList[index]),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset(
                      imageList[index],
                      width: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ImagePainter extends CustomPainter {
  final ui.Image image;
  final List<Map<String, dynamic>> textData;

  ImagePainter(this.image, this.textData);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImage(image, Offset.zero, Paint());

    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final data in textData) {
      final rect = data['rect'] as Rect;
      canvas.drawRect(
        Rect.fromLTWH(
          rect.left,
          rect.top,
          rect.width,
          rect.height,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}