import 'dart:io';
import 'package:fishes_app/design/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pytorch/flutter_pytorch.dart';
import 'package:flutter_pytorch/pigeon.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:fish_app/design/app_color.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;
  File? _image;
  List<ResultObjectDetection>? _output;
  late ModelObjectDetection _objectModel;
  List<ResultObjectDetection?> objDetect = [];
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  Future<void> loadModel() async {
    String pathObjectDetectionModel = "assets/models/trained_fish_detection_model.torchscript";
    try {
      _objectModel = await FlutterPytorch.loadObjectDetectionModel(
        pathObjectDetectionModel,
        6,  // Ensure this matches the number of classes in your model
        640,
        640,
        labelPath: "assets/models/labels.txt",
      );
      setState(() {
        _loading = false;
      });
    } catch (e) {
      print("Error loading model: $e");
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> detectImage(File image) async {
    setState(() {
      _loading = true;
    });

    // Run the model on the image
    List<ResultObjectDetection>? prediction = (await _objectModel.getImagePrediction(
      await image.readAsBytes(),
      minimumScore: 0.5,  // Adjust confidence threshold as needed
      IOUThershold: 0.3,  // Adjust IoU threshold as needed
    )).cast<ResultObjectDetection>();
    objDetect.forEach((element) {
      print({
        "score": element?.score,
        "className": element?.className,
        "class": element?.classIndex,
        "rect": {
          "left": element?.rect.left,
          "top": element?.rect.top,
          "width": element?.rect.width,
          "height": element?.rect.height,
          "right": element?.rect.right,
          "bottom": element?.rect.bottom,
        },
      });
    });

    setState(() {
      _output = prediction;
      _loading = false;
    });

    // Debugging output
    if (_output != null) {
      for (var result in _output!) {
        print('Detected: ${result.className} with confidence: ${result.score}');
      }
    } else {
      print('No detection occurred.');
    }
  }

  Future<void> pickImage() async {
    var image = await picker.getImage(source: ImageSource.camera);
    if (image == null) return;

    setState(() {
      _image = File(image.path);
    });

    await detectImage(_image!);
  }

  Future<void> pickGalleryImage() async {
    var image = await picker.getImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() {
      _image = File(image.path);
    });

    await detectImage(_image!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/image/water_background.png"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Positioned(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 50),
                  const Padding(
                    padding: EdgeInsets.all(50),
                    child: Column(
                      children: [
                        Text(
                          'Fish Detection App',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 25),
                        ),
                      ],
                    ),
                  ),
                  Center(
                    child: _loading
                        ? CircularProgressIndicator()
                        : _image != null
                            ? Column(
                                children: <Widget>[
                                  Container(
                                    height: 300,
                                    child: _objectModel.renderBoxesOnImage(_image!, objDetect),
                                  ),
                                  const SizedBox(height: 20),
                                  _output != null && _output!.isNotEmpty
                                      ? Text(
                                          'Detected: ${_output!.first.className} (Confidence: ${(_output!.first.score * 100).toStringAsFixed(2)}%)',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold),
                                        )
                                      : Text(
                                          'No objects detected.',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold),
                                        ),
                                  const SizedBox(height: 10),
                                ],
                              )
                            : Container(),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        GestureDetector(
                          onTap: () {
                            pickImage();
                          },
                          child: Container(
                            width: MediaQuery.of(context).size.width / 3,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 18),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    offset: const Offset(4, 4),
                                    blurRadius: 15,
                                    spreadRadius: 1,
                                    color: Colors.grey.shade500,
                                  ),
                                  const BoxShadow(
                                      offset: Offset(-4, -4),
                                      blurRadius: 15,
                                      spreadRadius: 1,
                                      color: Colors.white),
                                ]),
                            child: const Column(
                              children: [
                                Icon(
                                  Icons.photo_camera,
                                  size: 30,
                                  color: AppColor.primaryColor,
                                ),
                                Text(
                                  "Camera",
                                  style: TextStyle(
                                    color: AppColor.primaryColor,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        GestureDetector(
                          onTap: () {
                            pickGalleryImage();
                          },
                          child: Container(
                            width: MediaQuery.of(context).size.width / 3,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 18),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    offset: const Offset(4, 4),
                                    blurRadius: 15,
                                    spreadRadius: 1,
                                    color: Colors.grey.shade500,
                                  ),
                                  const BoxShadow(
                                      offset: Offset(-4, -4),
                                      blurRadius: 15,
                                      spreadRadius: 1,
                                      color: Colors.white),
                                ]),
                            child: const Column(
                              children: [
                                Icon(
                                  Icons.photo,
                                  size: 30,
                                  color: AppColor.primaryColor,
                                ),
                                Text(
                                  "Gallery",
                                  style: TextStyle(
                                    color: AppColor.primaryColor,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}