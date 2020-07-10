import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int temperature;
  String lokasi = 'Denpasar';
  int woeid = 1047372;
  String cuaca = 'clear';
  String singkatan = '';
  String pesanError = '';

  final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;

  Position _currentPosition;
  String _currentAddress;

  String searchUrl = 'https://www.metaweather.com/api/location/search/?query=';
  String lokasiUrl = 'https://www.metaweather.com/api/location/';

  initState() {
    super.initState();
    fetchLokasi();
  }

  void fetchSearch(String input) async {
    try {
      var searchResult = await http.get(searchUrl + input);
      var result = json.decode(searchResult.body)[0];

      setState(() {
        lokasi = result["title"];
        woeid = result["woeid"];
        pesanError = '';
      });
    } catch (error) {
      setState(() {
        pesanError =
            "Maaf, kota yang anda cari tidak ada pada database kami. Coba cari kota lain.";
      });
    }
  }

  void fetchLokasi() async {
    var lokasiResult = await http.get(lokasiUrl + woeid.toString());
    var result = json.decode(lokasiResult.body);
    var consolidatedCuaca = result["consolidated_weather"];
    var data = consolidatedCuaca[0];

    setState(() {
      temperature = data["the_temp"].round();
      cuaca = data["weather_state_name"].replaceAll(' ', '').toLowerCase();
      singkatan = data["weather_state_abbr"];
    });
  }

  void onTextFieldSubmitted(String input) async {
    await fetchSearch(input);
    await fetchLokasi();
  }

  _getCurrentLocation() {
    geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
        .then((Position position) {
      setState(() {
        _currentPosition = position;
      });

      _getAddressFromLatLng();
    }).catchError((e) {
      print(e);
    });
  }

  _getAddressFromLatLng() async {
    try {
      List<Placemark> p = await geolocator.placemarkFromCoordinates(
          _currentPosition.latitude, _currentPosition.longitude);

      Placemark place = p[0];

      setState(() {
        _currentAddress =
            "${place.locality}, ${place.postalCode}, ${place.country}";
      });
      onTextFieldSubmitted(place.locality);
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/$cuaca.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: temperature == null
            ? Center(child: CircularProgressIndicator())
            : Scaffold(
                appBar: AppBar(
                  actions: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(right: 20.0),
                      child: GestureDetector(
                        onTap: () {
                          _getCurrentLocation();
                        },
                        child: Icon(
                          Icons.location_on,
                          size: 35.0,
                        ),
                      ),
                    )
                  ],
                  backgroundColor: Colors.transparent,
                  elevation: 0.0,
                ),
                backgroundColor: Colors.transparent,
                body: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        Center(
                          child: Image.network(
                            'https://www.metaweather.com/static/img/weather/png/$singkatan.png',
                            width: 100.0,
                          ),
                        ),
                        Center(
                          child: Text(
                            temperature.toString() + ' °C',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 60.0,
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            lokasi,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 50.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: <Widget>[
                        Container(
                          width: 300.0,
                          child: TextField(
                            onSubmitted: (String input) {
                              onTextFieldSubmitted(input);
                            },
                            style: TextStyle(
                              color: Colors.white,
                            ),
                            decoration: InputDecoration(
                                hintText: 'Cari tempat lainnya...',
                                hintStyle: TextStyle(
                                    color: Colors.white, fontSize: 18.0),
                                prefixIcon:
                                    Icon(Icons.search, color: Colors.white)),
                          ),
                        ),
                        Text(pesanError,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: Platform.isAndroid ? 15.0 : 20.0))
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
