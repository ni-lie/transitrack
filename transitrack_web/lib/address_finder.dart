import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'config/keys.dart';

Stream<String> getAddressFromLatLngStream(double latitude, double longitude) async* {
  final apiKey = Keys.GoogleMapsAPI; // Replace with your Google Maps API key
  final url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$apiKey';
  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['status'] == 'OK') {
      List<dynamic> results = data['results'];
      if (results.isNotEmpty) {
        String formattedAddress = results[0]['formatted_address'];
        List<String> addressComponents = formattedAddress.split(',');
        if (addressComponents.length >= 2) {
          yield addressComponents.sublist(0, 2).join(', ');
        }
      }
    } else {
      throw Exception('Geocoding failed: ${data['status']}');
    }
  } else {
    yield 'Failed to fetch address'; // Yield an empty string if no address is found
  }
}