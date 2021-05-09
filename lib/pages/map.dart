import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:psinsx/models/insx_model2.dart';
import 'package:psinsx/pages/insx_edit.dart';
import 'package:psinsx/utility/my_style.dart';
import 'package:psinsx/utility/normal_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyMap extends StatefulWidget {
  @override
  _MyMapState createState() => _MyMapState();
}

class _MyMapState extends State<MyMap> {
  double lat, lng;
  LatLng startMapLatLng;
  List<InsxModel2> insxModel2s = [];

  @override
  void initState() {
    super.initState();
    findLatLng();
  }

  double calculageHues(String notidate) {
    List<double> hues = [80.0, 60.0, 200.0, 20.0];
    List<String> strings = notidate.split(" ");
    List<String> dateTimeInts = strings[0].split('-');
    DateTime notiDateTime = DateTime(
      int.parse(dateTimeInts[0]),
      int.parse(dateTimeInts[1]),
      int.parse(dateTimeInts[2]),
    );

    DateTime currentDateTime = DateTime.now();
    int diferDate = currentDateTime.difference(notiDateTime).inDays;
    double result = hues[0];

    if (diferDate >= 7) {
      result = hues[3];
    } else if (diferDate >= 4) {
      result = hues[2];
    } else if (diferDate >= 2) {
      result = hues[1];
    }
    return result;
  }

  Set<Marker> myAllMarker() {
    List<Marker> markers = [];
    List<double> hues = [80.0, 60.0, 150.0, 20.0];

    Marker userMarker = Marker(
      markerId: MarkerId('idUser'),
      position: LatLng(lat, lng),
      infoWindow: InfoWindow(title: 'คุณอยู่ที่นี่'),
      icon: BitmapDescriptor.defaultMarkerWithHue(280),
    );

    markers.add(userMarker);

    for (var item in insxModel2s) {
      Marker marker = Marker(
        icon: BitmapDescriptor.defaultMarkerWithHue(
            calculageHues(item.noti_date)),
        markerId: MarkerId('id${item.id}'),
        position: LatLng(double.parse(item.lat), double.parse(item.lng)),
        infoWindow: InfoWindow(
          title: item.cus_name,
          snippet: 'pea: ${item.pea_no}',
          onTap: () {
            MaterialPageRoute route = MaterialPageRoute(
              builder: (context) => InsxEdit(
                insxModel2: item,
                fromMap: true,
              ),
            );
            Navigator.push(context, route).then(
              (value) {
                //print('Back Form insx');
                myReadAPI();
              },
            );
          },
        ),
      );
      markers.add(marker);
    }
    return markers.toSet();
  }

  Future<Null> myReadAPI() async {
    print('myReadAPI work ===:>>>');
    insxModel2s.clear();

    SharedPreferences preferences = await SharedPreferences.getInstance();
    String workername = preferences.getString('staffname');

    String url =
        'https://pea23.com/apipsinsx/getInsxWhereUser.php?isAdd=true&worker_name=$workername';

    await Dio().get(url).then((value) {
      print('### value ==>>> $value');
      if (value.toString() != 'null') {
        for (var item in json.decode(value.data)) {
          InsxModel2 model2 = InsxModel2.fromMap(item);
          insxModel2s.add(model2);
        }
        setState(() {
          myAllMarker();
        });
      }else {
        setState(() {
          
        });
      }
    });
  }

  Future<Null> findLatLng() async {
    bool enableServiceLocation = await Geolocator.isLocationServiceEnabled();

    if (enableServiceLocation) {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          lat = 16.753188;
          lng = 101.203616;
          startMapLatLng = LatLng(16.753188, 101.203616);
          myReadAPI();
        });
      } else if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission().then((value) async {
          if (value == LocationPermission.deniedForever) {
            setState(() {
              lat = 16.753188;
              lng = 101.203616;
              startMapLatLng = LatLng(16.753188, 101.203616);
              myReadAPI();
            });
          } else {
            // find Lat, lng
            var position = await findPosition();
            setState(() {
              lat = position.latitude;
              lng = position.longitude;
              startMapLatLng = LatLng(lat, lng);
              myReadAPI();
            });
          }
        });
      } else {
        // find lat, lng
        var position = await findPosition();
        setState(() {
          lat = position.latitude;
          lng = position.longitude;
          startMapLatLng = LatLng(lat, lng);
          myReadAPI();
        });
      }
    } else {
      normalDialog(
          context, 'โปรดเปิด Service Location ไม่เช่นนั้นเราต้อง fix พิกัด');
      setState(() {
        lat = 16.753188;
        lng = 101.203616;
        startMapLatLng = LatLng(16.753188, 101.203616);
        myReadAPI();
      });
    }
  }

  Future<Position> findPosition() async {
    Position position;
    try {
      position = await Geolocator.getCurrentPosition();
      return position;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: lat == null ? MyStyle().showProgress() : buildGoogleMap(),
    );
  }

  Widget buildGoogleMap() {
    return Stack(
      children: [
        insxModel2s.length == 0 ? buildSecondMap() : buildMainMap(),
        Positioned(
          bottom: 4,
          child: Container(
            width: MediaQuery.of(context).size.width,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  child: Text('Test'),
                  onPressed: () {
                    myReadAPI();
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  GoogleMap buildMainMap() {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: startMapLatLng,
        zoom: 16,
      ),
      onMapCreated: (controller) {},
      markers: myAllMarker(),
      myLocationButtonEnabled: true,
      myLocationEnabled: true,
    );
  }

  GoogleMap buildSecondMap() {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: startMapLatLng,
        zoom: 16,
      ),
      onMapCreated: (controller) {},
      // markers: myAllMarker(),
      myLocationButtonEnabled: true,
      myLocationEnabled: true,
    );
  }
}
