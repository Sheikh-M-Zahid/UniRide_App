import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart'; // লোকেশন পারমিশন ও পজিশনের জন্য
import 'package:geocoding/geocoding.dart';   // অক্ষাংশ থেকে ঠিকানা বের করার জন্য

void main() => runApp(MaterialApp(home: PlanYourRidePage()));

class PlanYourRidePage extends StatefulWidget {
  @override
  _PlanYourRidePageState createState() => _PlanYourRidePageState();
}

class _PlanYourRidePageState extends State<PlanYourRidePage> {
  late GoogleMapController mapController;
  static const LatLng _center = LatLng(23.8103, 90.4125); // প্রাথমিক সেন্টার

  String rideTime = "Pick-up now";
  String currentAddress = "Detecting current location..."; // ডিফল্ট টেক্সট

  @override
  void initState() {
    super.initState();
    // অ্যাপ চালু হওয়ার সাথে সাথে লোকেশন ধরার চেষ্টা করবে
    _determinePosition();
  }

  // ডিভাইস থেকে আসল লোকেশন এবং ঠিকানা বের করার ফাংশন
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // ১. লোকেশন সার্ভিস অন আছে কি না চেক
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => currentAddress = "Location services are disabled.");
      return;
    }

    // ২. পারমিশন চেক ও রিকোয়েস্ট
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => currentAddress = "Location permissions are denied");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => currentAddress = "Permissions are permanently denied.");
      return;
    }

    // ৩. বর্তমান পজিশন নেওয়া
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    // ৪. কোঅর্ডিনেট থেকে ঠিকানায় (Address) রূপান্তর
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          // এটি আপনার ডিভাইসের আসল ঠিকানা সেট করবে
          currentAddress = "${place.name}, ${place.subLocality}, ${place.locality}";
        });

        // ম্যাপের ক্যামেরা বর্তমান লোকেশনে নিয়ে যাওয়া
        mapController.animateCamera(CameraUpdate.newLatLng(
          LatLng(position.latitude, position.longitude),
        ));
      }
    } catch (e) {
      setState(() => currentAddress = "Unnamed Road");
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ১. গুগল ম্যাপ
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(target: _center, zoom: 15.0),
            myLocationEnabled: true,
            zoomControlsEnabled: false,
          ),

          // ২. ব্যাক বাটন
          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // ৩. ড্রাগেবল পপআপ (BottomSheet)
          DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12)],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.all(20),
                  children: [
                    Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                    SizedBox(height: 20),
                    Text("Plan your ride", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    SizedBox(height: 20),

                    Row(
                      children: [
                        _buildTimeDropdown(),
                        SizedBox(width: 10),
                        // ড্রপডাউন সাইন ছাড়া For me বাটন
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
                          child: Row(
                            children: [
                              Icon(Icons.person, size: 18),
                              SizedBox(width: 5),
                              Text("For me", style: TextStyle(fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),

                    _buildLocationBox(),

                    SizedBox(height: 25),
                    _buildListTile(Icons.public, "Search in a different city"),
                    _buildListTile(Icons.search, "Get more results"),
                    _buildListTile(Icons.location_on, "Set location on map"),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimeDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: rideTime == "Pick-up now" ? "Now" : "Later",
          icon: Icon(Icons.keyboard_arrow_down),
          items: ["Now", "Later"].map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
          onChanged: (val) {
            setState(() {
              rideTime = val == "Now" ? "Pick-up now" : "Pick-up later";
            });
          },
        ),
      ),
    );
  }

  Widget _buildLocationBox() {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.circle, size: 12, color: Colors.black),
              SizedBox(width: 15),
              Expanded(
                child: Text(
                  currentAddress, // ডিভাইসের আসল লোকেশন এখানে দেখাবে
                  style: TextStyle(fontSize: 15, color: Colors.black, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          Divider(height: 30, thickness: 1, indent: 30),
          Row(
            children: [
              Icon(Icons.square, size: 12, color: Colors.black),
              SizedBox(width: 15),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(hintText: "Where to?", border: InputBorder.none, isDense: true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: Colors.grey[100], child: Icon(icon, color: Colors.black, size: 20)),
          SizedBox(width: 15),
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}