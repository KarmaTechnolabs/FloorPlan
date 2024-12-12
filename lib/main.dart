// ignore_for_file: prefer_const_constructors, unnecessary_null_comparison, avoid_print, unused_element, sized_box_for_whitespace, unused_import

import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;

import 'old_code.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FloorPlanScreen(),
      // home: FloorPlanScreenOldCode(),
    );
  }
}

class FloorPlanScreen extends StatefulWidget {
  const FloorPlanScreen({Key? key}) : super(key: key);

  @override
  State<FloorPlanScreen> createState() => _FloorPlanScreenState();
}

class _FloorPlanScreenState extends State<FloorPlanScreen> {
  ui.Image? floorImage;
  List<Map<String, dynamic>> textData = [];
  Rect? selectedRect;
  bool isImageLoaded = false;
  double? imageWidth;
  double? imageHeight;

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

    imageWidth = floorImage?.width.toDouble();
    imageHeight = floorImage?.height.toDouble();

    final extractedTextData = await extractTextFromImage(grayscaleBytes);
    setState(() {
      textData = extractedTextData;
      isImageLoaded = true;
      selectedRect = null;
    });
  }

  Future<Uint8List> convertToGrayscale(Uint8List bytes) async {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }
      final grayscaleImage = img.grayscale(image);
      return Uint8List.fromList(img.encodePng(grayscaleImage));
    } catch (e) {
      print('Error in convertToGrayscale: $e');
      rethrow;
    }
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
    try {
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
    } catch (e) {
      print('Error extracting text: $e');
      return [];
    }
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
    Rect? nearestRect;

    for (final data in textData) {
      final rect = data['rect'] as Rect;
      double distance = calculateDistanceToRect(x, y, rect);
      if (distance < minDistance) {
        minDistance = distance;
        nearestText = data['text'];
        nearestRect = rect;
      }
    }

    if (nearestRect != null) {
      setState(() {
        selectedRect = nearestRect;
      });
    }
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
          Expanded(child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  panEnabled: true,
                  scaleEnabled: true,
                  child: CustomPaint(
                    painter: floorImage != null
                        ? ImagePainter(floorImage!, textData, selectedRect)
                        : null,
                  ),
                ),
              ),
              GestureDetector(
                onTapDown: (details) {
                  final position = details.localPosition;
                  final clickedText =
                  findNearestText(position.dx, position.dy, textData);
                  if (clickedText != null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Clicked text: $clickedText')));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('No text nearby')));
                  }
                },
              ),
            ],
          )),
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

class TextHighlightPainter extends CustomPainter {
  final List<Map<String, dynamic>> textData;
  final Rect? selectedRect;

  TextHighlightPainter(this.textData, this.selectedRect);

  @override
  void paint(Canvas canvas, Size size) {
    final defaultPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final selectedPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (final data in textData) {
      final rect = data['rect'] as Rect;
      final paint = rect == selectedRect ? selectedPaint : defaultPaint;
      canvas.drawRect(
        Rect.fromLTRB(
          rect.left,
          rect.top,
          rect.right,
          rect.bottom,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ImagePainter extends CustomPainter {
  final ui.Image? image;
  final List<Map<String, dynamic>> textData;
  final Rect? selectedRect;

  ImagePainter(this.image, this.textData, this.selectedRect);

  @override
  void paint(Canvas canvas, Size size) {
    if (image != null) {
      // Calculate scale factor to fit image within screen width
      final scaleX = size.width / (image?.width.toDouble()??0.0);
      final scaleY = size.height / (image?.height.toDouble()??0.0);
      final scaleFactor = min(scaleX, scaleY); // Use min to preserve aspect ratio

      final paint = Paint();
      final rect = Rect.fromLTWH(0, 0, (image?.width.toDouble()??0.0) * scaleFactor, (image?.height.toDouble()??0.0) * scaleFactor);

      // Draw image at the calculated scale
      canvas.drawImageRect(image!, Rect.fromLTWH(0, 0, (image?.width.toDouble()??0.0), (image?.height.toDouble()??0.0)), rect, paint);
    }

    final defaultPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final selectedPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (final data in textData) {
      final rect = data['rect'] as Rect;
      final paint = (rect == selectedRect) ? selectedPaint : defaultPaint;
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}