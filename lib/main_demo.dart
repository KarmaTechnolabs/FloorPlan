// import 'dart:math';
// import 'dart:ui' as ui;
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
//
// void main() {
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: ImageTextDetectionScreen(),
//     );
//   }
// }
//
// class ImageTextDetectionScreen extends StatefulWidget {
//   const ImageTextDetectionScreen({Key? key}) : super(key: key);
//
//   @override
//   _ImageTextDetectionScreenState createState() =>
//       _ImageTextDetectionScreenState();
// }
//
// class _ImageTextDetectionScreenState extends State<ImageTextDetectionScreen> {
//   ui.Image? _image;
//   List<Map<String, dynamic>> _textData = [];
//   String? _selectedText;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadImageAndExtractText();
//   }
//
//   Future<void> _loadImageAndExtractText() async {
//     // Load the image from assets
//     final imageBytes = await rootBundle.load('assets/floor_plan.png');
//     final imageCodec = await ui.instantiateImageCodec(imageBytes.buffer.asUint8List());
//     final imageFrame = await imageCodec.getNextFrame();
//     setState(() {
//       _image = imageFrame.image;
//     });
//
//     // Extract text using ML Kit
//     final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
//     final InputImage inputImage = InputImage.fromBytes(
//       bytes: imageBytes.buffer.asUint8List(),
//       inputImageData: InputImageData(
//         size: Size(_image!.width.toDouble(), _image!.height.toDouble()),
//         imageRotation: InputImageRotation.rotation0deg,
//       ),
//     );
//
//     final RecognizedText recognizedText =
//     await recognizer.processImage(inputImage);
//
//     final textData = <Map<String, dynamic>>[];
//
//     for (final textBlock in recognizedText.blocks) {
//       for (final textLine in textBlock.lines) {
//         textData.add({
//           'text': textLine.text,
//           'boundingBox': textLine.boundingBox,
//         });
//       }
//     }
//
//     setState(() {
//       _textData = textData;
//     });
//
//     recognizer.close();
//   }
//
//   void _handleTap(TapUpDetails details) {
//     if (_image == null || _textData.isEmpty) return;
//
//     final tapPosition = details.localPosition;
//     String? nearestText;
//     double minDistance = double.infinity;
//
//     for (final item in _textData) {
//       final boundingBox = item['boundingBox'] as Rect;
//       final centerX = boundingBox.center.dx;
//       final centerY = boundingBox.center.dy;
//
//       final distance = sqrt(pow(centerX - tapPosition.dx, 2) +
//           pow(centerY - tapPosition.dy, 2));
//
//       if (distance < minDistance) {
//         minDistance = distance;
//         nearestText = item['text'] as String;
//       }
//     }
//
//     setState(() {
//       _selectedText = nearestText;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Tap Text Detection'),
//       ),
//       body: GestureDetector(
//         onTapUp: _handleTap,
//         child: Stack(
//           children: [
//             if (_image != null)
//               Center(
//                 child: CustomPaint(
//                   size: Size(
//                     _image!.width.toDouble(),
//                     _image!.height.toDouble(),
//                   ),
//                   painter: ImagePainter(_image!, _textData),
//                 ),
//               ),
//             if (_selectedText != null)
//               Align(
//                 alignment: Alignment.bottomCenter,
//                 child: Container(
//                   color: Colors.black54,
//                   padding: const EdgeInsets.all(8.0),
//                   child: Text(
//                     _selectedText!,
//                     style: const TextStyle(color: Colors.white),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class ImagePainter extends CustomPainter {
//   final ui.Image image;
//   final List<Map<String, dynamic>> textData;
//
//   ImagePainter(this.image, this.textData);
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint();
//     canvas.drawImage(image, Offset.zero, paint);
//
//     final boundingBoxPaint = Paint()
//       ..color = Colors.red
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 2;
//
//     for (final item in textData) {
//       final boundingBox = item['boundingBox'] as Rect;
//       canvas.drawRect(boundingBox, boundingBoxPaint);
//     }
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }
