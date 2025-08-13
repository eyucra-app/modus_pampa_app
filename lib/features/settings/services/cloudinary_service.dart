//import 'dart:io';
import 'package:cloudinary_url_gen/cloudinary.dart';
//import 'package:cloudinary_url_gen/transformation/transformation.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  // --- IMPORTANTE ---
  // Reemplaza estos valores con tus propias credenciales de Cloudinary.
  // Es recomendable cargarlos desde un archivo de configuración seguro.
  final String _cloudName = 'dwy89tsa0';
  final String _uploadPreset = 'pampa_app';
  
  late final Cloudinary _cloudinary;
  late final CloudinaryPublic _cloudinaryPublic;

  CloudinaryService() {
    _cloudinary = Cloudinary.fromStringUrl('cloudinary://$_cloudName');
    _cloudinaryPublic = CloudinaryPublic(_cloudName, _uploadPreset, cache: false);
  }

  /// Sube un archivo de imagen a Cloudinary y devuelve la URL segura.
  ///
  /// Lanza una excepción si la subida falla.
   Future<String> uploadImage(XFile imageFile) async {
    try {
      final response = await _cloudinaryPublic.uploadFile(
        CloudinaryFile.fromFile(imageFile.path, resourceType: CloudinaryResourceType.Image),
      );
      
      return response.secureUrl;

    } on CloudinaryException catch (e) {
      // Catch the specific exception from the library.
      print('Error al subir imagen a Cloudinary: ${e.message}');
      
      // The 'CloudinaryException' object does not have a 'response' getter.
      print(e); 
      
      rethrow; // Re-throw the exception to be handled by the calling code.
    } catch (e) {
      // Catch any other potential exceptions.
      print('Error al subir imagen a Cloudinary: $e');
      rethrow;
    }
  }
}
