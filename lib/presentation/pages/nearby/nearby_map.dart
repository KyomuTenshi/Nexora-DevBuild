import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nexora/domain/entities/geo_point.dart';
import 'package:nexora/domain/entities/place.dart';

/// Всё, что нужно карте. Вынесено в отдельный класс, чтобы в тестах
/// подставлять простой виджет вместо настоящей карты Google.
class NearbyMapArgs {
  const NearbyMapArgs({
    required this.center,
    required this.places,
    required this.selected,
    required this.showMyLocation,
    required this.onSelect,
  });

  final GeoPoint center;
  final List<Place> places;
  final Place? selected;

  /// Показывать ли «синюю точку» пользователя (только если есть разрешение).
  final bool showMyLocation;
  final ValueChanged<Place> onSelect;
}

typedef NearbyMapBuilder = Widget Function(
    BuildContext context,
    NearbyMapArgs args,
    );

/// Карта Google с маркерами мест.
class NearbyMap extends StatefulWidget {
  const NearbyMap({super.key, required this.args});

  final NearbyMapArgs args;

  @override
  State<NearbyMap> createState() => _NearbyMapState();
}

class _NearbyMapState extends State<NearbyMap> {
  GoogleMapController? _controller;

  static LatLng _latLng(GeoPoint p) => LatLng(p.latitude, p.longitude);

  static double _hue(PlaceCategory category) => switch (category) {
    PlaceCategory.cinema => BitmapDescriptor.hueRed,
    PlaceCategory.books => BitmapDescriptor.hueAzure,
    PlaceCategory.games => BitmapDescriptor.hueGreen,
  };

  @override
  void didUpdateWidget(NearbyMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final now = widget.args;
    final before = oldWidget.args;

    if (now.selected != null && now.selected?.id != before.selected?.id) {
      _move(now.selected!.position, 16);
    } else if (now.center != before.center) {
      _move(now.center, 13);
    }
  }

  void _move(GeoPoint point, double zoom) {
    _controller?.animateCamera(CameraUpdate.newLatLngZoom(_latLng(point), zoom));
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _latLng(args.center),
        zoom: 13,
      ),
      markers: {
        for (final place in args.places)
          Marker(
            markerId: MarkerId(place.id),
            position: _latLng(place.position),
            icon: BitmapDescriptor.defaultMarkerWithHue(_hue(place.category)),
            infoWindow: InfoWindow(title: place.name, snippet: place.address),
            onTap: () => args.onSelect(place),
          ),
      },
      myLocationEnabled: args.showMyLocation,
      myLocationButtonEnabled: args.showMyLocation,
      zoomControlsEnabled: false,
      onMapCreated: (controller) => _controller = controller,
    );
  }
}