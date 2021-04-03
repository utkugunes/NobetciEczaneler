import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:nobetci_eczaneler/common/app_constants.dart';
import 'package:nobetci_eczaneler/model/pharmacy.dart';
import 'package:url_launcher/url_launcher.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Completer<GoogleMapController> _controller = Completer();

  List<Pharmacy> pharmacyList = [];
  List<LatLng> latLongList = [];
  List<String> districtList = [];
  String selectedDistrict = "";
  Set<Marker> markers = Set<Marker>();
  bool isVisible = true;

  @override
  void initState() {
    super.initState();
    getData().then((value) => fillMarkerList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
      body: isVisible ? progressIndicatior : mapBody,
    );
  }

  AppBar get appBar {
    return AppBar(
      title: Text("${Constants.APP_TITLE}"),
      actions: [goToCity(), buildDropdownList()],
    );
  }

  Card buildDropdownList() {
    return Card(
      child: DropdownButton<String>(
        value: selectedDistrict,
        items: districtList.map((String value) {
          return new DropdownMenuItem<String>(
            value: value,
            child: new Text(value),
          );
        }).toList(),
        onChanged: (String district) async {
          await getDataByDistrict(district);
          await moveCamera(latLongList.first);
          setState(() {
            selectedDistrict = district;
          });
        },
      ),
    );
  }

  Center get progressIndicatior => Center(child: CircularProgressIndicator());

  Stack get mapBody {
    return Stack(
      children: [
        Container(
          height: double.infinity,
          child: GoogleMap(
            mapType: MapType.normal,
            markers: markers,
            initialCameraPosition:
                CameraPosition(target: latLongList.first, zoom: 15),
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          ),
        ),
        buildCardView(),
      ],
    );
  }

  void fillMarkerList() {
    markers.clear();
    latLongList.clear();

    pharmacyList.forEach((element) {
      double lat = double.parse(element.loc.split(",").first.trim());
      double long = double.parse(element.loc.split(",").last.trim());

      latLongList.add(LatLng(lat, long));

      if (!districtList.contains(element.dist)) districtList.add(element.dist);

      markers.add(Marker(
          markerId: MarkerId("$element"),
          icon: BitmapDescriptor.defaultMarker,
          position: LatLng(lat, long),
          visible: true,
          infoWindow: InfoWindow(
              title: "${element.name}", snippet: "${element.address}"),
          onTap: () {}));
    });

    selectedDistrict = districtList.first;

    setState(() {
      isVisible = false;
    });
  }

  Container buildCardView() {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height * 0.25,
      child: PageView.builder(
        physics: BouncingScrollPhysics(),
        controller: PageController(viewportFraction: 0.8),
        itemCount: pharmacyList.length,
        itemBuilder: (context, index) => buildPharmacyCard(index),
        onPageChanged: (index) async {
          await moveCamera(latLongList[index]);
        },
      ),
    );
  }

  Padding buildPharmacyCard(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: InkWell(
        onTap: () async => await launch("tel:${pharmacyList[index].phone}"),
        child: Card(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                "${pharmacyList[index].name}",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text("${pharmacyList[index].dist}"),
              Text(
                "${pharmacyList[index].address}",
                textAlign: TextAlign.center,
              ),
              Text("${pharmacyList[index].phone}"),
              Text("Eczaneyi aramak için dokunun.",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  IconButton goToCity() {
    return IconButton(
      icon: Icon(Icons.gps_fixed),
      tooltip: "${Constants.CITY}",
      onPressed: () async => await moveCamera(LatLng(41.6835978, 26.4636759)),
    );
  }

  Future<void> getData() async {
    final http.Response httpResponse = await http
        .get(Uri.parse(Constants.BASE_URL_WITH_CITY), headers: <String, String>{
      'authorization': '${Constants.COLLECT_API_KEY}',
      'content-type': 'application/json',
    });

    if (httpResponse.statusCode == HttpStatus.ok) {
      final responseData = jsonDecode(httpResponse.body);
      final responseList = responseData["result"] as List;
      pharmacyList = responseList.map((e) => Pharmacy.fromJson(e)).toList();
    }
  }

  Future<void> getDataByDistrict(String district) async {
    final http.Response httpResponse = await http.get(
        Uri.parse("${Constants.BASE_URL}?ilce=$district&il=${Constants.CITY}"),
        headers: <String, String>{
          'authorization': '${Constants.COLLECT_API_KEY}',
          'content-type': 'application/json',
        });

    if (httpResponse.statusCode == HttpStatus.ok) {
      final responseData = jsonDecode(httpResponse.body);
      final responseList = responseData["result"] as List;
      pharmacyList = responseList.map((e) => Pharmacy.fromJson(e)).toList();

      markers.clear();
      latLongList.clear();
      pharmacyList.forEach((element) {
        double lat = double.parse(element.loc.split(",").first.trim());
        double long = double.parse(element.loc.split(",").last.trim());

        latLongList.add(LatLng(lat, long));

        if (!districtList.contains(element.dist))
          districtList.add(element.dist);

        markers.add(Marker(
            markerId: MarkerId("$element"),
            icon: BitmapDescriptor.defaultMarker,
            position: LatLng(lat, long),
            visible: true,
            infoWindow: InfoWindow(
                title: "${element.name}", snippet: "${element.address}"),
            onTap: () {}));
      });
    }
  }

  Future<void> moveCamera(LatLng target) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: target,
      zoom: 15,
    )));
  }
}
