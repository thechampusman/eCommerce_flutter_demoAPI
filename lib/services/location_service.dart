import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  
  Future<bool> requestLocationPermission() async {
    try {
      PermissionStatus permission = await Permission.location.request();
      return permission == PermissionStatus.granted;
    } catch (e) {
      print('Location permission error: $e');
      return false;
    }
  }

  
  Future<bool> isLocationPermissionGranted() async {
    try {
      PermissionStatus permission = await Permission.location.status;
      return permission == PermissionStatus.granted;
    } catch (e) {
      print('Location permission check error: $e');
      return false;
    }
  }

  
  Future<Position?> getCurrentPosition() async {
    try {
      bool hasPermission = await isLocationPermissionGranted();
      if (!hasPermission) {
        hasPermission = await requestLocationPermission();
        if (!hasPermission) return null;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      return position;
    } catch (e) {
      print('Get current position error: $e');
      return null;
    }
  }

  
  Future<String> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = '';

        if (place.street?.isNotEmpty ?? false) {
          address += place.street!;
        }
        if (place.subLocality?.isNotEmpty ?? false) {
          if (address.isNotEmpty) address += ', ';
          address += place.subLocality!;
        }
        if (place.locality?.isNotEmpty ?? false) {
          if (address.isNotEmpty) address += ', ';
          address += place.locality!;
        }
        if (place.administrativeArea?.isNotEmpty ?? false) {
          if (address.isNotEmpty) address += ', ';
          address += place.administrativeArea!;
        }
        if (place.postalCode?.isNotEmpty ?? false) {
          if (address.isNotEmpty) address += ' ';
          address += place.postalCode!;
        }

        return address.isNotEmpty ? address : 'Unknown Location';
      }

      return 'Unknown Location';
    } catch (e) {
      print('Get address error: $e');
      return 'Unknown Location';
    }
  }

  
  Future<Position?> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        Location location = locations[0];
        return Position(
          latitude: location.latitude,
          longitude: location.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }
      return null;
    } catch (e) {
      print('Get coordinates from address error: $e');
      return null;
    }
  }

  
  Future<String> getCurrentLocationAddress() async {
    try {
      Position? position = await getCurrentPosition();
      if (position != null) {
        return await getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
      }
      return 'Location not available';
    } catch (e) {
      print('Get current location address error: $e');
      return 'Location not available';
    }
  }
}
