import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  Widget build(BuildContext context) {
    // Create the initialization Future outside of `build`:
    final Future<FirebaseApp> _initialization = Firebase.initializeApp();

    return FutureBuilder(
      future: _initialization,
      builder: (context, AsyncSnapshot snap) {
        if (snap.connectionState == ConnectionState.done) {
          return MaterialApp(
            home: Scaffold(body: SlideShow()),
            debugShowCheckedModeBanner: false,
          );
        }
        return Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}

// Slideshow
class SlideShow extends StatefulWidget {
  createState() => SlideShowState();
}

class SlideShowState extends State<SlideShow> {
  final PageController ctrl = PageController(viewportFraction: 0.8);

  // to interact with firebase
  final FirebaseFirestore db = FirebaseFirestore.instance;
  Stream slides; // data

  // user can filter the slides based on certain tag
  String activeTag = 'favourite';

  // keep track of current page to avoid unnecessary renders
  int currentPage = 0;

  @override
  void initState() {
    // the component will query the data when it is rendered
    // and it will re-render whenever the user change the activeTag
    _queryDb();

    // set state when page changes
    ctrl.addListener(() {
      int next = ctrl.page.round();

      if (currentPage != next) {
        setState(() {
          currentPage = next;
        });
      }
    });

    super.initState();
  }

  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: slides,
      initialData: [],
      builder: (context, AsyncSnapshot snap) {
        List slideList = snap.data.toList();

        return PageView.builder(
          controller: ctrl,

          // +1 is for the initial page where list of tags are displayed
          itemCount: slideList.length + 1,
          itemBuilder: (context, int currentIdx) {
            if (currentIdx == 0) {
              return _buildTagPage();
            } else if (slideList.length >= currentIdx) {
              // Active page
              bool active = currentIdx == currentPage;
              return _buildStoryPage(slideList[currentIdx - 1], active);
            }
            return Container();
          },
        );
      },
    );
  }

  void _queryDb({String tag: 'favourite'}) {
    // Make query for a subset of collect
    Query query = db.collection('stories').where('tags', arrayContains: tag);

    // Map the document to data payload
    slides =
        query.snapshots().map((snap) => snap.docs.map((doc) => doc.data()));

    // Update the active tag
    setState(() {
      activeTag = tag;
    });
  }

  // Builder Functions

  _buildStoryPage(Map data, bool active) {
    // Animated Properties
    final double blur = active ? 30 : 0;
    final double offset = active ? 20 : 0;
    final double top = active ? 100 : 200;

    return AnimatedContainer(
      duration: Duration(milliseconds: 500),
      curve: Curves.easeOutQuint,
      margin: EdgeInsets.only(top: top, bottom: 50, right: 30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          fit: BoxFit.cover,
          image: NetworkImage(data['img']),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black87,
            blurRadius: blur,
            offset: Offset(offset, offset),
          )
        ],
      ),
      child: Center(
        child: Text(
          data['title'],
          style: TextStyle(fontSize: 40, color: Colors.white),
        ),
      ),
    );
  }

  _buildButton(tag) {
    Color color = tag == activeTag ? Colors.purple : Colors.white;
    return FlatButton(
      color: color,
      child: Text('#$tag'),
      onPressed: () => _queryDb(tag: tag),
    );
  }

  _buildTagPage() {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Stories',
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
          ),
          Text('FILTER', style: TextStyle(color: Colors.black26)),
          _buildButton('favourite'),
          _buildButton('happy'),
          _buildButton('sad'),
        ],
      ),
    );
  }
}

// // Simple working of a PageView widget
// class SimplePageView extends StatelessWidget {
//   // controller to control the behaviour of the PageView
//   final PageController ctrl = PageController();

//   // direction along which the PageView will scroll
//   final Axis scrollDirection;

//   SimplePageView({this.scrollDirection = Axis.horizontal});

//   Widget build(BuildContext context) {
//     return PageView(
//       scrollDirection: scrollDirection,
//       controller: ctrl,
//       children: [
//         Container(color: Colors.blue),
//         Container(color: Colors.green),
//         Container(color: Colors.red),
//         Container(color: Colors.orange),
//         Container(color: Colors.pink),
//       ],
//     );
//   }
// }
