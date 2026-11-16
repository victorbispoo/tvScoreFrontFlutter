import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

class TestGallery extends ImagePickerPlatform {
  @override
  Future<LostDataResponse> getLostData() async => LostDataResponse.empty();
}
