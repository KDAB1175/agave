import 'package:flutter/cupertino.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_charts/sparkcharts.dart';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

late int budget;

Future<void> main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Ensure Flutter binding is initialized

  // Initialize Firebase
  //await Firebase.initializeApp();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  /*final Stream<QuerySnapshot> _usersStream = FirebaseFirestore.instance
      .collection('admin_agave')
      .snapshots(includeMetadataChanges: true);*/
  getSP();

  runApp(const MyApp());
}

class Item {
  String id;
  String category;
  String description;
  int price;
  String time;
  Item(
      {required this.id,
      required this.category,
      required this.description,
      required this.price,
      required this.time});

/*static Item fromJson(Map<String, dynamic> json) => Item(
      id: json['id'],
      category: json['category'],
      description: json['description'],
      price: json['price']);*/
}

/*Stream<List<Item>> readUsers() => FirebaseFirestore.instance
    .collection('admin_agave')
    .snapshots()
    .map((snapshot) =>
        snapshot.docs.map((doc) => Item.fromJson(doc.data())).toList());*/

Future addToDB(
    {required String id,
    required String category,
    required String description,
    required int price,
    required String time}) async {
  const chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  Random rnd = Random();
  String id = String.fromCharCodes(Iterable.generate(
      20, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));

  final docUser = FirebaseFirestore.instance
      .collection('admin_agave')
      .doc(id); //if i were to put value into doc, there would be the id String

  final json = {
    'id': id,
    'category': category,
    'description': description,
    'price': price,
    'time': time
  };

  await docUser.set(json);
}

Future removeFromDB(String id) async {
  final docUser = FirebaseFirestore.instance.collection('admin_agave').doc(id);
  docUser.delete();
}

void getSP() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  budget = prefs.getInt('budget') ?? 0;
  /*print("budget first $budget");
  budget = 10;
  prefs.setInt('budget', budget);
  budget = prefs.getInt('budget') ?? 0;
  print("budget second $budget");*/
}

void setSP(int budgetNew) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  budget = budgetNew;
  prefs.setInt('budget', budget);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'agave',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //CollectionReference users = FirebaseFirestore.instance.collection('users');
  final Stream<QuerySnapshot> _usersStream = FirebaseFirestore.instance
      .collection('admin_agave')
      .snapshots(includeMetadataChanges: true);
  TextEditingController controller = TextEditingController();
  TextEditingController controllerDescription = TextEditingController();
  TextEditingController controllerTitle = TextEditingController();
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String text = "Press button to speak";
  double confidence = 0.0;

  int textNum = 0;
  int id =
      0; //to implement if wanted ------------------------------------------------------------------------------------------------------------------------------------
  int counter = 0;
  bool _customTileExpanded = false;
  final db = FirebaseFirestore.instance;
  List<Item> items = List.empty(growable: true);
  late List<Item> remove;
  String selectedItem = "Food";
  List<String> dropdownCategories = [
    "Food",
    "Materialistic Desire",
    "Entertainment",
    "Rent",
    "Medical",
    "Travel",
    "Travel Acc.",
    "Transportation",
    "Business Expense",
    "Self Improvement",
    "Gift",
    "Other"
  ];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  String stripper(String toBeStripped) {
    if (toBeStripped.length >= 10) {
      toBeStripped = toBeStripped.substring(0, toBeStripped.length - 10);
    }

    return toBeStripped;
  }

  Widget getRow(int index, Item item) {
    if (items.isEmpty) {
      items.add(
        Item(
          id: item.id,
          category: item.category,
          description: item.description,
          price: item.price,
          time: item.time,
        ),
      );
    }
    while (counter < items.length && item.id != items[counter].id) {
      counter = counter + 1;
    }

    if (counter >= items.length) {
      items.add(
        Item(
          id: item.id,
          category: item.category,
          description: item.description,
          price: item.price,
          time: item.time,
        ),
      );
      print("added");
      print("item: ${item.id}");
    }

    counter = 0;

    print("items: $items");
    print("item: ${item.id}");

    return Container(
      margin: const EdgeInsets.only(
        left: 8.0,
        right: 8.0,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white30,
          ),
        ),
      ),
      child: Slidable(
        startActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: [
            SlidableAction(
              onPressed: (context) {
                setState(() {
                  removeFromDB(item.id);
                  int removeCounter = 0;
                  while (removeCounter < items.length) {
                    if (items[removeCounter].id != item.id) {
                      remove.add(
                        Item(
                          id: items[removeCounter].id,
                          category: items[removeCounter].category,
                          description: items[removeCounter].description,
                          price: items[removeCounter].price,
                          time: items[removeCounter].time,
                        ),
                      );
                    }
                    removeCounter = removeCounter + 1;
                  }
                  //items.remove(item);
                });
              }, //here ---------------------------------------------------------------------------------------------------------------**************
              icon: CupertinoIcons.trash,
              backgroundColor: Colors.red,
            ),
          ],
        ),
        child: ExpansionTile(
          //leading:

          title: Text(
            "${item.price.toString()} \$",
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
          subtitle: Text(
            item.description,
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
          trailing: const IconTheme(
            data: IconThemeData(color: Colors.white),
            child: Icon(
              Icons.arrow_drop_down_outlined,
              color: Colors
                  .white, //to do if necessary -------------------------------------------------------------------------------------------------
              /*_customTileExpanded
                  ? Icons.arrow_drop_down_circle_outlined
                  : Icons.arrow_drop_down_outlined,*/
            ),
          ),
          children: <Widget>[
            ListTile(
              title: Text(
                item.category,
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 13,
                ),
              ),
              subtitle: Text(
                stripper(item.time),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
              trailing: Text(
                item.id,
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
          onExpansionChanged: (bool expanded) {
            setState(() {
              _customTileExpanded = expanded;
            });
          },
        ),
      ),
    );
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            text = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              confidence = val.confidence;
            }
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      drawer: Drawer(
        backgroundColor: Colors.black,
        child: ListView(
          children: [
            const Padding(
              padding: EdgeInsets.all(
                16.0,
              ),
            ),
            const UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                color: Colors.black,
              ),
              accountName: Text("Agave Admin"),
              accountEmail: Text("wellhaveourownadresssoon@gmail.com"),
              currentAccountPicture: Text(
                "AA",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.add_outlined,
                color: Colors.white,
              ),
              title: const Text(
                "Add new",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              onTap: () {
                // Do something
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.history_rounded,
                color: Colors.white,
              ),
              title: const Text(
                "History",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              onTap: () {
                // Do something
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline, color: Colors.white),
              title: const Text(
                "Help",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              onTap: () async {
                String email =
                    Uri.encodeComponent("wellhaveourownadresssoon@gmail.com");
                String subject = Uri.encodeComponent("Issue/Bug");
                String body =
                    Uri.encodeComponent("Describe your issue here...");
                //print(subject); //output: Hello%20Flutter
                Uri mail =
                    Uri.parse("mailto:$email?subject=$subject&body=$body");
                if (await launchUrl(mail)) {
                  //email app opened
                  Fluttertoast.showToast(
                    msg: "Successfully opened your email app",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    timeInSecForIosWeb: 1,
                    textColor: Colors.white,
                  );
                } else {
                  //email app is not opened
                  Fluttertoast.showToast(
                    msg:
                        "Failed to opened your mail app, try checking if you have the Gmail app installed",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    timeInSecForIosWeb: 1,
                    textColor: Colors.white,
                  );
                }
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
              icon: const Icon(
                Icons.menu_outlined,
              ),
            );
          },
        ),
        title: TextField(
          controller: controllerTitle,
          cursorColor: Colors.white,
          style: const TextStyle(color: Colors.white),
          onChanged: (text) {
            print('First text field: $text');
          },
          decoration: InputDecoration(
            prefixIcon: IconButton(
              color: Colors.white,
              icon: const Icon(
                Icons.mic_none_outlined,
              ),
              onPressed: () {
                Fluttertoast.showToast(
                  msg: "Mic was clicked",
                  toastLength: Toast.LENGTH_SHORT,
                  timeInSecForIosWeb: 1,
                  backgroundColor: Colors.black,
                  textColor: Colors.white,
                  fontSize: 16.0,
                );
              },
            ),
            contentPadding: const EdgeInsets.all(16.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(
                width: 2,
                color: Colors.black,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(
                width: 2,
                color: Colors.black,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            hintText: 'Hello World!',
            fillColor: Colors.black,
            filled: true,
            hintStyle: const TextStyle(
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              getSP();
              setState(() {
                items = items;
              });
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AnalyticsPage(
                    items: items,
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.analytics_outlined,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          /*StreamBuilder(
            stream: db.collection('admin_agave').snapshots(),
          ),*/
          /* items.isEmpty
              ? const Expanded(
                  child: Center(
                    child: Text(
                      "Empty list...",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                )
              : */
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _usersStream,
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      "Something went wrong",
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Text(
                      "Loading...",
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  );
                }

                return ListView(
                  children:
                      snapshot.data!.docs.map((DocumentSnapshot document) {
                    Map<String, dynamic> data =
                        document.data()! as Map<String, dynamic>;
                    return getRow(
                        0,
                        Item(
                          id: data['id'],
                          category: data['category'],
                          description: data['description'],
                          price: data['price'],
                          time: data['time'],
                        )); /*ListTile(
                        title: Text(data['full_name']),
                        subtitle: Text(data['company']),
                      );*/
                  }).toList(),
                );
              },
            ),
          ),
          Container(
            color: Colors.black,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                cursorColor: Colors.white,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  prefixIcon: IconButton(
                    color: Colors.white,
                    icon: const Icon(
                      Icons.mic_none_outlined,
                    ),
                    onPressed: () {
                      _listen();
                      print(text);
                      Fluttertoast.showToast(
                        msg: "Mic was clicked",
                        toastLength: Toast.LENGTH_SHORT,
                        timeInSecForIosWeb: 1,
                        backgroundColor: Colors.black,
                        textColor: Colors.white,
                        fontSize: 16.0,
                      );
                    },
                  ),
                  suffixIcon: IconButton(
                    color: Colors.white,
                    icon: const Icon(
                      Icons.send_outlined,
                    ),
                    onPressed: () {
                      text = controller.text.trim();
                      if (RegExp(r'[0-9]').hasMatch(text) == true) {
                        textNum = int.parse(text);
                      } else {
                        Fluttertoast.showToast(
                          msg: "Invalid number",
                          toastLength: Toast.LENGTH_SHORT,
                          timeInSecForIosWeb: 1,
                          backgroundColor: Colors.black,
                          textColor: Colors.white,
                          fontSize: 16.0,
                        );
                      }
                      if (text.isNotEmpty) {
                        showDialog<String>(
                          context: context,
                          builder: (BuildContext context) => AlertDialog(
                            backgroundColor: Colors.black,
                            title: const Center(
                              child: Text(
                                "Finish the inputting",
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            content: Wrap(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 16.0,
                                      right: 16.0,
                                      bottom: 8.0,
                                      top: 8.0),
                                  child: TextField(
                                    controller: controllerDescription,
                                    cursorColor: Colors.white,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      prefixIcon: IconButton(
                                        color: Colors.white,
                                        icon: const Icon(
                                          Icons.mic_none_outlined,
                                        ),
                                        onPressed: () {
                                          //to do -------------------------------------------------------------------------------
                                          Fluttertoast.showToast(
                                            msg: "Mic was clicked",
                                            toastLength: Toast.LENGTH_SHORT,
                                            timeInSecForIosWeb: 1,
                                            backgroundColor: Colors.black,
                                            textColor: Colors.white,
                                            fontSize: 16.0,
                                          );
                                        },
                                      ),
                                      contentPadding:
                                          const EdgeInsets.all(16.0),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                          width: 2,
                                          color: Colors.white,
                                        ),
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                          width: 2,
                                          color: Colors.white,
                                        ),
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      hintText: 'Enter a description',
                                      fillColor: Colors.black,
                                      filled: true,
                                      hintStyle: const TextStyle(
                                        color: Colors.white24,
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 16.0,
                                    right: 16.0,
                                    bottom: 8.0,
                                    top: 8.0,
                                  ),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                          color: Colors.black),
                                      child: DropdownButtonFormField<String>(
                                        dropdownColor: Colors.black,
                                        decoration: InputDecoration(
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              24.0,
                                            ),
                                            borderSide: const BorderSide(
                                              width: 2,
                                              color: Colors.white,
                                            ),
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(24),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              width: 2,
                                              color: Colors.white,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(24),
                                          ),
                                        ),
                                        value: selectedItem,
                                        items: dropdownCategories
                                            .map(
                                              (item) =>
                                                  DropdownMenuItem<String>(
                                                value: item,
                                                child: Text(
                                                  item,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (item) {
                                          setState(() {
                                            selectedItem = item!;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            actions: <Widget>[
                              TextButton(
                                //to do -------------------------------------------------------------------------------------------------------------
                                onPressed: () =>
                                    Navigator.pop(context, "Cancel"),
                                child: const Text(
                                  "Cancel",
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  if (controllerDescription.text.isNotEmpty) {
                                    setState(() {
                                      /*items.add(
                                        Item(
                                          id: id,
                                          category: selectedItem,
                                          description:
                                              controllerDescription.text.trim(),
                                          price: textNum,
                                          time: DateTime.now(),
                                        ),
                                      );*/
                                    });
                                    addToDB(
                                      id: "0",
                                      category: selectedItem,
                                      description:
                                          controllerDescription.text.trim(),
                                      price: textNum,
                                      time: DateTime.now().toString(),
                                    );
                                    controller.clear();
                                    controllerDescription.clear();
                                    Navigator.pop(context, "OK");
                                  } else {
                                    Fluttertoast.showToast(
                                      msg: "Invalid description",
                                      toastLength: Toast.LENGTH_SHORT,
                                      timeInSecForIosWeb: 1,
                                      backgroundColor: Colors.black,
                                      textColor: Colors.white,
                                      fontSize: 16.0,
                                    );
                                  }
                                },
                                child: const Text(
                                  "OK",
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      //to do ----------------------------------------------------------------------------------------------------------------------------
                      Fluttertoast.showToast(
                        msg: "Send was clicked",
                        toastLength: Toast.LENGTH_SHORT,
                        timeInSecForIosWeb: 1,
                        backgroundColor: Colors.black,
                        textColor: Colors.white,
                        fontSize: 16.0,
                      );
                    },
                  ),
                  contentPadding: const EdgeInsets.all(16.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      width: 2,
                      color: Colors.white,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      width: 2,
                      color: Colors.white,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  hintText: 'Enter a number',
                  fillColor: Colors.black,
                  filled: true,
                  hintStyle: const TextStyle(
                    color: Colors.white24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Stats {
  String category;
  int price;

  Stats({required this.category, required this.price});
}

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({Key? key, required this.items}) : super(key: key);

  final List<Item> items;

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  TextEditingController controller = TextEditingController();
  String text = "";
  //bool _customTileExpanded = false;
  final db = FirebaseFirestore.instance;
  late List<Stats> _stats;
  late TooltipBehavior _tooltipBehavior;
  int counter = 0;
  int innerCounter = 0;
  int result = 0;
  int minIndex = 0;
  int maxIndex = 0;
  List<Stats> stats = List.empty(growable: true);
  //List<Item> chartList = List.empty(growable: true);

  int search() {
    while (innerCounter < stats.length &&
        widget.items[counter].category != stats[innerCounter].category) {
      innerCounter = innerCounter + 1;
    }

    if (innerCounter < stats.length) {
      return innerCounter;
    }

    return -1;
  }

  List<Stats> getData() {
    while (counter < widget.items.length) {
      result = search();
      if (result != -1) {
        stats[result].price = stats[result].price + widget.items[counter].price;
      } else {
        stats.add(
          Stats(
              category: widget.items[counter].category,
              price: widget.items[counter].price),
        );
      }
      counter = counter + 1;
      innerCounter = 0;
    }
    return stats;
  }

  String getHint() {
    int max = getStats(0);

    switch (stats[maxIndex].category) {
      case "Food":
        return "Try eating out less or buy cheaper products";
      case "Materialistic Desire":
        return "Try making more educated purchases";
      case "Entertainment":
        return "Go touch some grass!";
      case "Rent":
        return "Try looking for a new place to stay or talk to your landlord";
      case "Medical":
        return "";
      case "Travel":
        return "Look for cheaper cheaper tickets";
      case "Travel Acc.":
        return "Try finding cheaper places to stay at";
      case "Transportation":
        return "Try using the public transport";
      case "Business Expense":
        return "You might want to see your boss about your business expenses";
      case "Self Improvement":
        return "Everyone should want to be better, but courses help you only so much...";
      case "Gift":
        return "Make sure your gifts are being appreciated and not thrown away";
      case "Other":
        return "Look at that other expenses too!";
    }

    return "There are no hints as of now";
  }

  Color textColor() {
    int sum = getStats(2);
    if (sum > budget) {
      return Colors.red;
    }
    if (70 < (sum / budget) * 100) {
      return Colors.orange;
    }
    return Colors.green;
  }

  int getMax() {
    int max = 0;
    int maxCounter = 0;

    while (maxCounter < stats.length) {
      if (stats[maxCounter].price > max) {
        max = stats[maxCounter].price;
        maxIndex = maxCounter;
      }
      maxCounter = maxCounter + 1;
    }

    return max;
  }

  int getMin() {
    int min = stats[0].price;
    int minCounter = 0;

    while (minCounter < stats.length) {
      if (stats[minCounter].price < min) {
        min = stats[minCounter].price;
        minIndex = minCounter;
      }
      minCounter = minCounter + 1;
    }

    return min;
  }

  int getSum() {
    int sum = 0;
    int sumCounter = 0;

    while (sumCounter < stats.length) {
      sum = sum + stats[sumCounter].price;
      sumCounter = sumCounter + 1;
    }

    return sum;
  }

  int getStats(int argument) {
    switch (argument) {
      case 0: //max value
        return getMax();
      case 1: //min value
        return getMin();
      case 2: //overall
        return getSum();
    }
    return 0;
  }

  @override
  void initState() {
    _stats = getData();
    int counter = 0;

    while (counter < widget.items.length) {
      print(widget.items[counter].price);
      counter = counter + 1;
    }
    _tooltipBehavior = TooltipBehavior(enable: true);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          leading: Builder(
            builder: (BuildContext context) {
              return IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(
                  Icons.arrow_back_ios_new_outlined,
                  color: Colors.white,
                ),
              );
            },
          ),
        ),
        body: ListView.builder(
          itemCount: 1,
          itemBuilder: (context, index) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                      left: 16.0, right: 16.0, bottom: 8.0),
                  child: ListTile(
                    leading: const Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                    ),
                    title: Text(
                      "Tip: ${getHint()}",
                      style: const TextStyle(
                        color: Colors.blue,
                      ),
                    ),
                    //trailing: Text("category", style: TextStyle(color: Colors.white,),),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    cursorColor: Colors.white,
                    style: const TextStyle(color: Colors.white),
                    onChanged: (text) {
                      setState(() {
                        budget = int.parse(text);
                      });
                      setState(() {
                        setSP(int.parse(controller.text.trim()));
                      });
                    },
                    decoration: InputDecoration(
                      prefixIcon: IconButton(
                        color: Colors.white,
                        icon: const Icon(
                          Icons.mic_none_outlined,
                        ),
                        onPressed: () {
                          //to do -------------------------------------------------------------------------------
                          Fluttertoast.showToast(
                            msg: "Mic was clicked",
                            toastLength: Toast.LENGTH_SHORT,
                            timeInSecForIosWeb: 1,
                            backgroundColor: Colors.black,
                            textColor: Colors.white,
                            fontSize: 16.0,
                          );
                        },
                      ),
                      /*suffixIcon: IconButton(
                        color: Colors.white,
                        icon: const Icon(
                          Icons.send_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            setSP(int.parse(controller.text.trim()));
                          });
                          Fluttertoast.showToast(
                            msg: "Budget was set to ${controller.text.trim()}",
                            toastLength: Toast.LENGTH_SHORT,
                            timeInSecForIosWeb: 1,
                            backgroundColor: Colors.black,
                            textColor: Colors.white,
                            fontSize: 16.0,
                          );
                        },
                      ),*/
                      contentPadding: const EdgeInsets.all(16.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          width: 2,
                          color: Colors.white,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          width: 2,
                          color: Colors.white,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      hintText: "Current budget: $budget. Enter a new one!",
                      fillColor: Colors.black,
                      filled: true,
                      hintStyle: const TextStyle(
                        color: Colors.white60,
                      ),
                    ),
                  ),
                ),
                SfCircularChart(
                  title: ChartTitle(
                    text: "Spending by categories",
                    textStyle: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  legend: const Legend(
                    isVisible: true,
                    textStyle: TextStyle(
                      color: Colors.white,
                    ),
                    overflowMode: LegendItemOverflowMode.wrap,
                  ),
                  tooltipBehavior: _tooltipBehavior,
                  series: [
                    RadialBarSeries<Stats, String>(
                      useSeriesColor: true,
                      trackOpacity: 0.3,
                      cornerStyle: CornerStyle.bothCurve,
                      //maximumValue: getStats(2).toDouble(),//budget.toDouble(),
                      dataSource: _stats, //widget.items,
                      xValueMapper: (Stats data, _) => data.category,
                      yValueMapper: (Stats data, _) => data.price,
                      dataLabelSettings: const DataLabelSettings(
                          isVisible: true, color: Colors.white24),
                      enableTooltip: true,
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: ListTile(
                    title: Text(
                      "You have already spent ${getStats(2)} \$ out of $budget \$",
                      style: TextStyle(
                        color: textColor(),
                      ),
                    ),
                    //trailing: Text("category", style: TextStyle(color: Colors.white,),),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: ListTile(
                    title: Text(
                      "You have already spent ${((getStats(2) / budget) * 100).round()} % of your budget",
                      style: TextStyle(
                        color: textColor(),
                      ),
                    ),
                    //trailing: Text("category", style: TextStyle(color: Colors.white,),),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: ListTile(
                    title: Text(
                      "You spent the most (${getStats(0)} \$) on: ${stats[maxIndex].category}",
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    /*trailing: const Text(
                      "category",
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),*/
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: ListTile(
                    title: Text(
                      "You spent the least (${getStats(1)} \$) on: ${stats[minIndex].category}",
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    /*trailing: const Text(
                      "category",
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),*/
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
