import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'document_scanner_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isFlashOn = false;
  bool _isCameraFront = false;
  List<CameraDescription>? _cameras;
  bool _isLoading = true;
  int _selectedIndex = 0;
  String? _capturedImagePath;
  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        int cameraIndex = _isCameraFront && _cameras!.length > 1 ? 1 : 0;

        _controller = CameraController(
          _cameras![cameraIndex],
          ResolutionPreset.medium,
        );

        _initializeControllerFuture = _controller!.initialize();
        await _initializeControllerFuture;

        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Padding(
            padding: EdgeInsets.all(10),
            child: Container(
              height: 40,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Error initializing camera$e",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 20),
                  Icon(Icons.error, color: Colors.red, size: 20),
                ],
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          duration: Duration(seconds: 1),
        ),
      );
      print('Error initializing camera: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleFlash() {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      _isFlashOn = !_isFlashOn;
    });

    if (_isFlashOn) {
      _controller!.setFlashMode(FlashMode.torch);
    } else {
      _controller!.setFlashMode(FlashMode.off);
    }
  }

  void _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    setState(() {
      _isLoading = true;
      _isCameraFront = !_isCameraFront;
    });

    if (_controller != null) {
      await _controller!.dispose();
    }

    int cameraIndex = _isCameraFront ? 1 : 0;

    _controller = CameraController(
      _cameras![cameraIndex],
      ResolutionPreset.medium,
    );

    try {
      _initializeControllerFuture = _controller!.initialize();
      await _initializeControllerFuture;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Padding(
            padding: EdgeInsets.all(10),
            child: Container(
              height: 40,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Error switching camera $e",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 20),
                  Icon(Icons.verified, color: Colors.black, size: 20),
                ],
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          duration: Duration(seconds: 1),
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Padding(
            padding: EdgeInsets.all(10),
            child: Container(
              height: 40,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Camera not initialized",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 20),
                  Icon(Icons.error, color: Colors.red, size: 20),
                ],
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    try {
      final XFile picture = await _controller!.takePicture();
      print('Image captured: ${picture.path}');

      setState(() {
        _capturedImagePath = picture.path;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Padding(
            padding: EdgeInsets.all(10),
            child: Container(
              height: 40,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  SizedBox(width: 10),
                  Text(
                    "Image Captured",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      print('Error taking picture: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 15, 15, 15),
      appBar: AppBar(
        toolbarHeight: 90,
        backgroundColor: const Color.fromARGB(255, 15, 15, 15),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Container(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(
                  _isFlashOn ? Icons.flash_on : Icons.flash_off,
                  color: Colors.white,
                  size: 21,
                ),
                onPressed: _toggleFlash,
              ),
              IconButton(
                icon: const Icon(Icons.grid_on, color: Colors.white, size: 20),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(
                  _isCameraFront
                      ? Icons.camera_alt_outlined
                      : Icons.camera_alt_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: _switchCamera,
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white, size: 21),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : (_controller != null && _controller!.value.isInitialized
                ? CameraPreview(_controller!)
                : const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          'Camera not available',
                          style: TextStyle(color: Colors.white),
                        ),
                        Icon(Icons.error, color: Colors.red),
                      ],
                    ),
                  )),
      bottomNavigationBar: Container(
        height: 120,
        color: const Color.fromARGB(255, 15, 15, 15),
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextButton("Photo", 0),
                  _buildTextButton("Id Card", 1),
                  _buildTextButton("Document", 2),
                  _buildTextButton("QR Scanner", 3),
                  _buildTextButton("O Detector", 4),
                  _buildTextButton("Assistant", 5),
                  _buildTextButton("Online", 6),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color.fromARGB(255, 36, 35, 35),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.gpp_good_outlined,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: _takePicture,
                      child: Center(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Icon(
                              Icons.camera_alt,
                              size: 33,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

                    _buildImagePreview(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextButton(String text, int index) {
    final isSelected = _selectedIndex == index;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isSelected ? Colors.blue : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: TextButton(
        onPressed: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        style: TextButton.styleFrom(
          foregroundColor: isSelected
              ? Colors.blue
              : const Color.fromARGB(255, 248, 248, 248),
          textStyle: const TextStyle(fontSize: 13),
        ),
        child: Text(text),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_capturedImagePath != null) {
      return GestureDetector(
        onTap: () {
          print('View captured image: $_capturedImagePath');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  DocumentScannerScreen(imagePath: _capturedImagePath!),
            ),
          );
        },
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(8),
            color: Colors.transparent,
            image: DecorationImage(
              image: FileImage(File(_capturedImagePath!)),
              fit: BoxFit.cover,
            ),
            border: Border.all(color: Colors.white, width: 1),
          ),
        ),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color.fromARGB(255, 36, 35, 35),
        ),
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(Icons.image, color: Colors.white),
        ),
      );
    }
  }
}
