import 'dart:convert';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:get/get.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiffiny/Screens/phone.dart';
import 'package:tiffiny/Screens/splash.dart';
import 'package:tiffiny/utils/sharedpref.dart';
import 'package:tiffiny/widgets/big_text.dart';
import 'package:tiffiny/widgets/small_text.dart';
import 'package:restart_app/restart_app.dart';
import 'home_body.dart';
import 'package:http/http.dart' as http;
import 'package:json_annotation/json_annotation.dart';

class MyHome extends StatefulWidget {
  String phone = "";
  MyHome({required this.phone});

  @override
  State<MyHome> createState() => _MyHomeState();
}

class _MyHomeState extends State<MyHome> {
  ScrollController _controller = new ScrollController();
  late String phone = "";
  // void load() async {
  //   phone = SharedPrefUtils.readPrefStr('phone').toString();
  // }
  String currentVal = "";
  late Future myFuture;
  final auth = FirebaseAuth.instance;
  List User_detail = [];
  int i = 0;
  SharedPrefUtils prefs = SharedPrefUtils();
  Future<String> fetchUser() async {
    phone = await SharedPrefUtils.readPrefStr('phone');
    print("phone" + phone);
    var data = {"phone_no": phone};
    var url = "https://mytiffiny.000webhostapp.com/Display_User.php";

    // var response = await http.get(Uri.parse(url));
    var response = await http.post(Uri.parse(url), body: data);
    // var message = jsonDecode(response.body);
    // print(message);

    if (response.statusCode == 200) {
      var items = await jsonDecode(response.body);

      setState(() {
        User_detail = items;
        print(User_detail);
      });
      currentVal = User_detail[0]['A_ID'].toString();
      return "Loaded";
    } else {
      throw Exception("Failed to load data");
    }
  }

  var curr_latitude = "Getting latitude".obs;
  var curr_longitude = "Getting longitude".obs;
  List kitchen = [];
  Future<void> logout() async {
    // await auth.signOut().then((value) => Navigator.of(context).pushReplacement(
    //     MaterialPageRoute(builder: (context) => const SplashScreen())));
    await FirebaseAuth.instance.signOut().then((value) => Navigator.of(context)
        .pushReplacement(
            MaterialPageRoute(builder: (context) => const SplashScreen())));
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  fetchkitchen() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    curr_latitude.value = '${position.latitude}';
    curr_longitude.value = '${position.longitude}';
    var url = "https://mytiffiny.000webhostapp.com/display.php";
    var response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      var items = json.decode(response.body);

      setState(() {
        kitchen = items;
        // for (int i = 0; i < kitchen.length; i++) {
        //   print(kitchen[i]['Tiffin_Name']);
        // }
        // print(kitchen.length);
        // final List<KitchenDataModel> kitchendata = List.generate(
        //     kitchen.length,
        //     (index) => KitchenDataModel(
        //         '${kitchen[index]['name']}', '${kitchen[index]['city']}'));
      });
    } else {
      setState(() {
        kitchen = [];
      });
    }
    for (int i = 0; i < kitchen.length; i++) {
      kitchen[i]["distance"] = calculateDistance(
              double.parse(kitchen[i]["Latitude"].toString()),
              double.parse(kitchen[i]["Longitude"].toString()),
              double.parse(curr_latitude.toString()),
              double.parse(curr_longitude.toString()))
          .toStringAsFixed(1)
          .toString();
    }
    kitchen.sort((a, b) {
      return double.parse(a["distance"].toString())
          .compareTo(double.parse(b["distance"].toString()));
    });
    // print(kitchen);
  }

  @override
  void initState() {
    // TODO: implement initState
    myFuture = fetchUser();
    // load();
    this.fetchkitchen();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: LiquidPullToRefresh(
      onRefresh: () async {
        await fetchkitchen();
      },
      color: Colors.amber,
      height: 100,
      backgroundColor: Colors.amberAccent[200],
      showChildOpacityTransition: false,
      springAnimationDurationInMilliseconds: 500,
      child: Column(
        children: [
          Container(
            child: Container(
              margin: EdgeInsets.only(top: 45, bottom: 15),
              padding: EdgeInsets.only(left: 20, right: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Column(
                  //   children: [
                  //     BigText(text: "India", color: Colors.amber),
                  //     Row(
                  //       children: [
                  //         SmallText(text: "Gujarat"),
                  //         Icon(Icons.arrow_drop_down_rounded)
                  //       ],
                  //     )
                  //   ],
                  // ),
                  FutureBuilder<dynamic>(
                      future: myFuture,
                      builder: ((context, snapshot) {
                        if (!snapshot.hasData) {
                          return Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        return Column(
                          children: [
                            DropdownButton(
                              iconEnabledColor: Colors.amber,
                              iconSize: 40,
                              isExpanded: false,
                              dropdownColor: Colors.amber,
                              items: User_detail.map((item) {
                                return DropdownMenuItem(
                                  child: Row(
                                    children: [
                                      BigText(text: item['HouseName'] + " "),
                                      SmallText(text: item['Street'])
                                    ],
                                  ),
                                  value: item['A_ID'].toString(),
                                );
                              }).toList(),
                              onChanged: (newVal) {
                                setState(() {
                                  print(newVal);
                                  HomeBody(
                                      kitchen: kitchen,
                                      addr: newVal.toString(),
                                      phone: phone);
                                  currentVal = newVal.toString();
                                });
                              },
                              value: currentVal,
                            )
                          ],
                        );
                      })),
                  Center(
                    child: Container(
                      width: 45,
                      height: 45,
                      // ignore: sort_child_properties_last
                      child: IconButton(
                        onPressed: () async {
                          await auth.signOut().then((value) {
                            Navigator.pushNamed(context, 'splash');
                          });
                        },
                        // onPressed: () {
                        //   logout();
                        // },
                        icon: Icon(Icons.logout),
                        color: Colors.white,
                      ),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.amber),
                    ),
                  )
                ],
              ),
            ),
          ),
          Expanded(
              child: SingleChildScrollView(
            // physics: NeverScrollableScrollPhysics(),
            child: HomeBody(
                kitchen: kitchen, addr: currentVal.toString(), phone: phone),
          )),
        ],
      ),
    ));
  }
}
