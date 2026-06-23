import 'package:geolocator/geolocator.dart';

class PermissionService {
  Future<bool> requestLocationPermission() async {
    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    return permission ==
            LocationPermission.whileInUse ||
        permission ==
            LocationPermission.always;
  }
}