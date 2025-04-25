import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pamigay/utils/constants.dart';
import 'dart:io';

class ImagePickerWidget extends StatelessWidget {
  final File? imageFile;
  final Function(File) onImageSelected;
  final double height;
  final String placeholder;
  final bool isCircular;
  final double borderRadius;
  final Color backgroundColor;
  final Color iconColor;
  final double? width;
  final File? currentImage;

  const ImagePickerWidget({
    Key? key,
    required this.imageFile,
    required this.onImageSelected,
    this.height = 180,
    this.placeholder = 'Upload Image',
    this.isCircular = false,
    this.borderRadius = 12,
    this.backgroundColor = Colors.blue,
    this.iconColor = PamigayColors.primary,
    this.width,
    this.currentImage,
  }) : super(key: key);

  Future<void> _showImageSourceOptions(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        onImageSelected(File(pickedFile.path));
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final File? displayImage = imageFile ?? currentImage;
    
    if (isCircular) {
      return GestureDetector(
        onTap: () => _showImageSourceOptions(context),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: height / 2,
                backgroundColor: Colors.grey[200],
                backgroundImage: displayImage != null 
                    ? FileImage(displayImage) 
                    : null,
                child: (displayImage == null)
                    ? Icon(Icons.person, size: height / 1.5, color: Colors.grey)
                    : null,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.camera_alt,
                  color: iconColor,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return GestureDetector(
        onTap: () => _showImageSourceOptions(context),
        child: Container(
          height: height,
          width: width ?? double.infinity,
          decoration: BoxDecoration(
            color: backgroundColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: backgroundColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: displayImage != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(borderRadius),
                  child: Image.file(
                    displayImage,
                    fit: BoxFit.cover,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.file_upload_outlined,
                      size: 50,
                      color: iconColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      placeholder,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        color: iconColor,
                      ),
                    ),
                  ],
                ),
        ),
      );
    }
  }
}
