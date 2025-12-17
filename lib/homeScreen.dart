// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:quran_app/qaurantab.dart';
import 'package:quran_app/sbhatab.dart';

import 'hadithtab.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});
  static const String routeName = 'Home';

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  int selectedindex = 0;

  List<Widget> tabs = [
    Qaurantab(),
    HadithTab(),
    Sebhatab(),
  ];
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Image.asset("assets/images/mainbacklight.png",
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.fill,
        ),
        Scaffold(
          appBar: AppBar(
            title: Text("qurany", style: Theme
                .of(context)
                .textTheme
                .bodyLarge,),
          ),
          bottomNavigationBar: Theme(
            data: Theme.of(context).copyWith(
              canvasColor: Theme
                  .of(context)
                  .primaryColor,
            ),
            child: BottomNavigationBar(
              currentIndex: selectedindex,
              onTap: (index) {
                setState(() {
                  selectedindex = index;
                });
              },
              items: [
                BottomNavigationBarItem(
                  icon: Image(
                    image: AssetImage("assets/images/moshaf_gold.png",),
                    width: 25,
                    height: 25,),
                  label: "Quran",
                ),
                BottomNavigationBarItem(
                  icon: Image(image: AssetImage(
                      "assets/images/quran-quran-svgrepo-com.png"),
                    width: 25,
                    height: 25,),
                  label: "hadith",
                ),
                BottomNavigationBarItem(
                  icon: Image(image: AssetImage("assets/images/sebha.png"),
                    width: 25,
                    height: 25,),
                  label: "sebha",
                ),
              ],
            ),
          ),
          body: tabs[selectedindex],
        )

      ],
    );
  }
}