import 'package:flutter/material.dart';
import 'package:quran_app/constans/appcolor.dart';

class Sebhatab extends StatefulWidget {
  @override
  State<Sebhatab> createState() => _SebhatabState();
}

class _SebhatabState extends State<Sebhatab> {
  int counter = 0;
  double anglr = 0.0;

  Map<int, String> map = {
    0: "سبحان الله",
    34: "الحمد لله",
    67: "الله أكبر",
    100: "لا إله إلا الله",
  };

  String tsabihText(int x) {
    if (x > 0 && x <= 33) {
      return map[0]!;
    } else if (x > 33 && x <= 66) {
      return map[34]!;
    } else if (x > 66 && x <= 99) {
      return map[67]!;
    } else if (x == 100) {
      return map[100]!;
    } else {
      return "سبحان الله";
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          SizedBox(height: 50),
          Stack(
            alignment: Alignment.topCenter,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 45),

                child: Image.asset("assets/images/head of seb7a.png"),
              ),
              GestureDetector(
                onTap: () {
                  if (counter == 100) {
                    counter = 0;
                    anglr += 4;
                  } else {
                    counter++;
                    anglr += 4;
                  }
                  setState(() {});
                },
                child: Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height * 0.040,
                    bottom: 26.0,
                  ),
                  child: Transform.rotate(
                    angle: anglr,
                    child: Image.asset("assets/images/body of seb7a.png"),
                  ),
                ),
              ),
            ],
          ),
          Text("عدد التسبيحات", style: Theme.of(context).textTheme.bodySmall),
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            decoration: BoxDecoration(
              color: Appcolor.brimarycolor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "$counter",
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 20),
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
            decoration: BoxDecoration(
              color: Appcolor.brimarycolor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              tsabihText(counter),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
