import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

class ImageUploaderService {
  Future<bool> _checkImageSize(File imageFile) async {
    int sizeInBytes = imageFile.lengthSync();
    double sizeInMb = sizeInBytes / (1024 * 1024);

    if (sizeInMb > 5) {
      return true;
    } else {
      return false;
    }
  }

  Future<String?> uploadPicture(image) async {
    try {
      File imageFile = File(image.path);
      String fileExtension = imageFile.path.split('.').last.toLowerCase();

      final bytes = await imageFile.readAsBytes();

      if (fileExtension == 'jpg' ||
          fileExtension == 'jpeg' ||
          fileExtension == 'png' ||
          fileExtension == 'gif' ||
          fileExtension == 'bmp' ||
          fileExtension == 'tiff' ||
          fileExtension == 'tif' ||
          fileExtension == 'webp' ||
          fileExtension == 'svg' ||
          fileExtension == 'heif' ||
          fileExtension == 'heic' ||
          fileExtension == 'ico') {
        bool isLarge = await _checkImageSize(imageFile);

        img.Image? originalImage = img.decodeImage(Uint8List.fromList(bytes));
        if (originalImage != null) {
          img.Image compressedImage = img.copyResize(
            originalImage,
            width: 800,
            height: 800,
          );

          List<int> compressedBytes = isLarge
              ? img.encodeJpg(compressedImage, quality: 50)
              : img.encodeJpg(originalImage, quality: 70);

          final base64Image =
              'data:image/jpeg;base64, ${base64Encode(compressedBytes)}';

          var request = http.MultipartRequest(
            'POST',
            // Uri.parse('https://bucket.transfa.org/files/single_image.php'),
            Uri.parse('https://bucket.ndai.africa/single_image.php'),
          );
          request.fields['image'] = base64Image;

          var response = await request.send();

          if (response.statusCode == 200) {
            var responseBody = await response.stream.bytesToString();
            var decodedResponse = jsonDecode(responseBody);
            return decodedResponse['url'];
          } else {
            print("Image upload failed");
          }
        } else {
          print('Error: Invalid image format');
        }
      } else if (fileExtension == 'pdf') {
        final base64PDF = 'data:application/pdf;base64,${base64Encode(bytes)}';

        var request = http.MultipartRequest(
          'POST',
          Uri.parse('https://bucket.transfa.org/files/single_image.php'),
        );
        request.fields['image'] = base64PDF;

        var response = await request.send();

        if (response.statusCode == 200) {
          var responseBody = await response.stream.bytesToString();
          var decodedResponse = jsonDecode(responseBody);
          return decodedResponse['url'];
        } else {
          print("PDF upload failed");
        }
      } else {
        print("Unsupported file type");
      }
    } catch (e) {
      print("An error occurred: $e");
    }

    return null;
  }

  String getInitials(String name) {
    if (name.trim().isEmpty) return '';
    List<String> parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0];
    return parts[0][0] + parts[1][0];
  }
}
