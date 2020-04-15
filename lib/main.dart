import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:location/location.dart';
import 'package:flutter_nfc_reader/flutter_nfc_reader.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

// const address = "98:D3:61:FD:53:40";

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Google Maps Demo',
      home: MapSample(),
    );
  }
}

class MapSample extends StatefulWidget {
  MapSample({Key key, this.title}) : super(key: key);

  final String title;

  @override
  State<MapSample> createState() => MapSampleState();
}

class GoogleMapsServices {
  Future<List> getRouteCoordinates(LatLng l1, LatLng l2) async {
    String url =
        "http://www.mapquestapi.com/directions/v2/route?key=3BPfaoMC8tXMqKpIAOGlKV5uQee1drAE&from=${l1.latitude},${l1.longitude}&to=${l2.latitude},${l2.longitude}";
    http.Response response = await http.get(url);
    Map values = jsonDecode(response.body);
    print(values);
    return values["route"]["legs"][0]["maneuvers"];
  }
}

class MapSampleState extends State<MapSample> {
  Completer<GoogleMapController> _controller = Completer();
  PanelController _panel = PanelController();

  static LatLng latLng;
  LocationData currentLocation;

  Set<Marker> markers = Set();

  bool loading = true;
  final Set<Polyline> _polyLines = {};
  GoogleMapsServices _googleMapsServices = GoogleMapsServices();
  Set<Polyline> get polyLines => _polyLines;

  String sensorValue = "N/A";
  bool ledState = false;

  get markerId => null;

  @override
  void initState() {
    super.initState();

    getData();
    getLocation();
    loading = true;
  }

  getData() async {
    markers.addAll([
      Marker(
        markerId: MarkerId('1'),
        position: LatLng(37.583539, 127.025733),
        infoWindow: InfoWindow(
          title: "A123",
        ),
      ),
      Marker(
        markerId: MarkerId('2'),
        position: LatLng(37.586595, 127.029244),
        infoWindow: InfoWindow(
          title: "A124",
        ),
      ),
      Marker(
        markerId: MarkerId('3'),
        position: LatLng(37.588762, 127.028659),
        infoWindow: InfoWindow(
          title: "A125",
        ),
      ),
      Marker(
          markerId: MarkerId('98:D3:C1:FD:36:9A'),
          position: LatLng(37.583202, 127.029689),
          infoWindow: InfoWindow(
            title: "A126",
          ),
          onTap: () {
            openLock('98:D3:C1:FD:36:9A');
          }),
      Marker(
        markerId: MarkerId('5'),
        position: LatLng(37.581222, 127.027785),
        infoWindow: InfoWindow(
          title: "A127",
        ),
      ),
      Marker(
        markerId: MarkerId('6'),
        position: LatLng(37.584639, 127.031580),
        infoWindow: InfoWindow(
          title: "A128",
        ),
      ),
    ]);

    setState(() {
      // adding a new marker to map
      markers = markers;
    });
  }

  getLocation() async {
    var location = new Location();
    location.onLocationChanged().listen((currentLocation) {
      print(currentLocation.latitude);
      print(currentLocation.longitude);
      setState(() {
        latLng = LatLng(currentLocation.latitude, currentLocation.longitude);
      });

      print("getLocation:$latLng");
      // _onAddMarkerButtonPressed();
      loading = false;
    });
  }

  void sendRequest() async {
    LatLng destination = LatLng(37.583202, 127.029689);
    // _polyLines.add(Polyline(
    //     polylineId: PolylineId(latLng.toString()),
    //     width: 4,
    //     points: [
    //     LatLng(37.583394, 127.026212),
    //     LatLng(37.582818, 127.026633),
    //     LatLng(37.583607, 127.028422),
    //     LatLng(37.583513, 127.029473),
    //     LatLng(37.583020, 127.029570)
    //     ], color: Colors.red));+
    List route =
        await _googleMapsServices.getRouteCoordinates(latLng, destination);
    print(route);
    createRoute(route);
    // _addMarker(destination,"KTHM Collage");
    _goToTheTrashBin();
  }

  void openLock(address) async {
    FlutterNfcReader.write("path_prefix", "tag content").then((response) {
      print(response.content);
    });
    nfc(context);
  }

  void createRoute(List route) {
    _polyLines.add(Polyline(
        polylineId: PolylineId(latLng.toString()),
        width: 4,
        points: _convertToLatLng(route),
        color: Colors.red));
  }

  List _decodePoly(String poly) {
    var list = poly.codeUnits;
    var lList = new List();
    int index = 0;
    int len = poly.length;
    int c = 0;
    do {
      var shift = 0;
      int result = 0;
      do {
        c = list[index] - 63;
        result |= (c & 0x1F) << (shift * 5);
        index++;
        shift++;
      } while (c >= 32);
      if (result & 1 == 1) {
        result = ~result;
      }
      var result1 = (result >> 1) * 0.00001;
      lList.add(result1);
    } while (index < len);
    for (var i = 2; i < lList.length; i++) lList[i] += lList[i - 2];
    print(lList.toString());
    return lList;
  }

  void onCameraMove(CameraPosition position) {
    latLng = position.target;
  }

  List<LatLng> _convertToLatLng(List points) {
    List<LatLng> result = <LatLng>[];
    for (int i = 0; i < points.length; i++) {
      result.add(LatLng(
          points[i]["startPoint"]["lat"], points[i]["startPoint"]["lng"]));
    }
    return result;
  }

  static final CameraPosition _anam = CameraPosition(
    // target: LatLng(37.584307, 127.029416),
    target: latLng,
    zoom: 16,
  );

  static final CameraPosition _trashbin =
      CameraPosition(target: LatLng(37.583202, 127.029689), zoom: 16);

  @override
  Widget build(BuildContext context) {
    BorderRadiusGeometry radius = BorderRadius.only(
      topLeft: Radius.circular(25.0),
      topRight: Radius.circular(25.0),
    );

    return new Scaffold(
      body: loading
          ? Container(
              color: Colors.red,
            )
          : Stack(children: <Widget>[
              GoogleMap(
                polylines: polyLines,
                mapType: MapType.normal,
                initialCameraPosition: _anam,
                myLocationButtonEnabled: true,
                myLocationEnabled: true,
                onCameraMove: onCameraMove,
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                },
                markers: markers,
              ),
              SlidingUpPanel(
                panel: Center(
                    child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      height: 120.0,
                      width: 120.0,
                      decoration: new BoxDecoration(
                        image: DecorationImage(
                          image: new AssetImage('assets/coin.png'),
                          fit: BoxFit.fill,
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Divider(
                      height: 100,
                      color: Colors.transparent,
                    ),
                    Text('Mileage',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 25)),
                    Text('123 Points!',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 25)),
                  ],
                )),
                minHeight: 25,
                maxHeight: MediaQuery.of(context).size.height,
                backdropEnabled: true,
                collapsed: Container(
                  decoration: BoxDecoration(
                    color: Colors.blueGrey,
                    borderRadius: radius,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.keyboard_arrow_up,
                      color: Colors.white,
                    ),
                  ),
                ),
                body: Center(),
                borderRadius: radius,
              )
            ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          sendRequest();
        },
        label: Text("Let's Go!"),
        icon: Icon(Icons.restore_from_trash),
      ),
    );
  }

  Future<void> _goToTheTrashBin() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(_trashbin));
  }
}

Future<void> nfc(BuildContext context) {
  return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(32.0))),
            // contentPadding: EdgeInsets.only(top: 10.0),
            content: Container(
              width: 300.0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    height: 100.0,
                    width: 100.0,
                    child: Image.asset(
                      'assets/nfc.png',
                      width: 100,
                      height: 100,
                    ),
                  ),
                  Divider(
                    height: 20.0,
                    color: Colors.transparent,
                  ),
                  Text(
                    "NFC 리더기에 핸드폰을 대주세요",
                    textAlign: TextAlign.center,
                  ),
                  Divider(
                    height: 20.0,
                    color: Colors.transparent,
                  ),
                  InkWell(
                    child: Container(
                      color: Colors.lightBlue,
                      width: 300,
                      child: FlatButton(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(32.0),
                                bottomRight: Radius.circular(32.0)),
                          ),
                          child: Text(
                            "OK",
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          })),
                  ),
                ],
              ),
            ));
      });
}
