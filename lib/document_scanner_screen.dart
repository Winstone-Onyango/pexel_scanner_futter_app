import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:image_cropper/image_cropper.dart' as cropper;
import 'package:image_editor_plus/image_editor_plus.dart';
import 'dart:io';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;

class DocumentScannerScreen extends StatefulWidget {
  final String imagePath;

  const DocumentScannerScreen({super.key, required this.imagePath});

  @override
  State<DocumentScannerScreen> createState() => _DocumentScannerScreenState();
}

class _DocumentScannerScreenState extends State<DocumentScannerScreen> {
  File? _editedImage;
  bool _isEditing = false;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _editedImage = File(widget.imagePath);
    _checkPermissions();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 20),
              const SizedBox(width: 10),
              Text(
                message,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _checkPermissions() async {
    if (await Permission.storage.request().isGranted) {
      print("Storage permission granted");
    } else {
      print("Storage permission denied");
    }
  }

  Future<void> _saveImageToGallery() async {
    if (_editedImage == null || !_editedImage!.existsSync()) {
      _showErrorSnackBar("Image file not found");
      return;
    }
    try {
      final directory = await getApplicationDocumentsDirectory();
      final String fileName =
          'document_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String newPath = path.join(directory.path, fileName);

      await _editedImage!.copy(newPath);

      final bool? success = await GallerySaver.saveImage(
        newPath,
        albumName: 'Document scanner',
      );

      if (success == true) {
        _showSaveBottomSheet(fileName, newPath);

        print('Image saved to gellery successfully');
      } else {
        _showErrorSnackBar("Failed to save image to Gallery");
      }
    } catch (e) {
      print('Error saving image: $e');
      _showErrorSnackBar("Error saving image: $e");
    }
  }

  Future<void> _cropImage() async {
    if (_editedImage == null || !_editedImage!.existsSync()) {
      print("Image file does not exist: ${_editedImage?.path}");
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
                    "Image file not found",
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

    print("Attempting to crop image: ${_editedImage!.path}");

    try {
      final croppedFile = await cropper.ImageCropper().cropImage(
        sourcePath: _editedImage!.path,
        compressQuality: 90,
        compressFormat: cropper.ImageCompressFormat.jpg,
        aspectRatio: const cropper.CropAspectRatio(ratioX: 4, ratioY: 3),
        uiSettings: [
          cropper.AndroidUiSettings(
            toolbarTitle: 'Crop Document',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: cropper.CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          cropper.IOSUiSettings(
            title: 'Crop Document',
            aspectRatioLockEnabled: false,
          ),
        ],
      );

      if (croppedFile != null) {
        print("Image cropped successfully: ${croppedFile.path}");
        setState(() {
          _editedImage = File(croppedFile.path);
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
                    Icon(Icons.verified, color: Colors.green, size: 20),

                    SizedBox(width: 20),
                    Text(
                      "Image cropped successfully",
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
      } else {
        print("Cropping was cancelled");
      }
    } catch (e) {
      print('Error cropping image: $e');
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
                  Icon(Icons.verified, color: Colors.green, size: 20),

                  SizedBox(width: 20),
                  Text(
                    "Failed to crop image $e",
                    style: TextStyle(
                      color: Colors.red,
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
    }
  }

  Future<void> _scanDocument() async {
    setState(() => _isScanning = true);

    try {
      final String? scannedImagePath = await FlutterDocScanner()
          .getScanDocuments();

      if (scannedImagePath != null) {
        setState(() {
          _editedImage = File(scannedImagePath);
        });
      }
    } catch (e) {
      print('Error scanning document: $e');
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
                  Icon(Icons.verified, color: Colors.green, size: 20),

                  SizedBox(width: 20),
                  Text(
                    "Failed to scan document",
                    style: TextStyle(
                      color: Colors.red,
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
    } finally {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _editImage() async {
    try {
      final editedImage = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageEditor(image: _editedImage!),
        ),
      );

      if (editedImage != null && editedImage is File) {
        setState(() {
          _editedImage = editedImage;
        });
      }
    } catch (e) {
      print('Error editing image: $e');
    }
  }

  void _showSaveBottomSheet(String imageName, String imagePath) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            color: Colors.black.withOpacity(0.5),
            child: GestureDetector(
              onTap: () {},
              child: DraggableScrollableSheet(
                initialChildSize: 0.5,
                minChildSize: 0.3,
                maxChildSize: 0.7,
                builder: (_, controller) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey[700],
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Document Saved',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            const Icon(
                              Icons.image,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                imageName,
                                style: const TextStyle(color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.folder,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                imagePath,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.share,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  onPressed: () {
                                    // Implement share functionality
                                    _shareImage();
                                  },
                                ),
                                const Text(
                                  'Share',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.photo_library,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  onPressed: () {
                                    // Implement view in gallery functionality
                                    _viewInGallery();
                                  },
                                ),
                                const Text(
                                  'View in Gallery',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _shareImage() {
    print('Sharing image: ${_editedImage!.path}');
  }

  void _viewInGallery() {
    print('Viewing image in gallery: ${_editedImage!.path}');
  }

  Future<void> _saveImage() async {
    var Status = await Permission.storage.status;
    if (!Status.isGranted) {
      Status = await Permission.storage.request();
      if (!Status.isGranted) {
        _showErrorSnackBar("Storage permission required to save images");
        return;
      }
    }
    await _saveImageToGallery();
  }

  Future<void> _applyFilter() async {
    setState(() => _isEditing = true);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isEditing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 20),
              SizedBox(width: 10),
              Text(
                "Filters applied",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Document Scanner',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: _isEditing || _isScanning
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : PhotoView(
              imageProvider: FileImage(_editedImage!),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
            ),
      bottomNavigationBar: Container(
        height: 80,
        color: Colors.black,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.filter, color: Colors.white, size: 28),
              onPressed: _applyFilter,
              tooltip: 'Apply Filter',
            ),
            IconButton(
              icon: const Icon(Icons.crop, color: Colors.white, size: 28),
              onPressed: _cropImage,
              tooltip: 'Crop Document',
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white, size: 28),
              onPressed: _editImage,
              tooltip: 'Edit Image',
            ),
            IconButton(
              icon: const Icon(
                Icons.document_scanner,
                color: Colors.white,
                size: 28,
              ),
              onPressed: _scanDocument,
              tooltip: 'Scan Document',
            ),
            IconButton(
              icon: const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 28,
              ),
              onPressed: _saveImage,
              tooltip: 'Save Document',
            ),
          ],
        ),
      ),
    );
  }
}
