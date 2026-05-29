import '../../network/dio_client.dart';
import '../../network/api_exception.dart';
import '../../constants/api_constants.dart';

/// Strategy for isolated media handling.
/// Frontend MUST NOT couple image uploads to Menu Item CRUD lifecycle.
/// Images are uploaded via this pipeline first, returning an object URL/ID.
/// That URL is then safely attached to the MenuItemDto update.
abstract class MediaRepository {
  /// Uploads raw image bytes/file to the backend media pipeline.
  /// Returns the persistent media URL on success.
  Future<Result<String>> uploadImage(List<int> bytes, String filename);
}

class ApiMediaRepository implements MediaRepository {
  final DioClient _dioClient;

  ApiMediaRepository(this._dioClient);

  @override
  Future<Result<String>> uploadImage(List<int> bytes, String filename) async {
    // In a real implementation, this would use FormData
    try {
      // Mocked endpoint behavior based on typical media APIs
      final response = await _dioClient.post(
        '${ApiConstants.apiVersion}/media/upload',
        data: {
          // This would be a FormData object with a MultipartFile in reality
          'filename': filename,
          'mock_bytes_length': bytes.length,
        },
      );

      if (response.data['success'] == true) {
        return Success(response.data['data']['url'] as String);
      } else {
        final errorMessage =
            response.data['error']?['message'] ?? 'Failed to upload image';
        return Failure(ApiFailure(errorMessage, ApiErrorCode.serverError));
      }
    } on ApiException catch (e) {
      return Failure(ApiFailure(e.message, e.code));
    } catch (e) {
      return Failure(ApiFailure(e.toString()));
    }
  }
}
