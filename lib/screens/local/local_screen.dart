
import 'package:flutter/material.dart';

class LocalScreen extends StatelessWidget {
  const LocalScreen({super.key});

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildHeader(),
      ),
      body: const Center(
        child: Text('Explore local markets'),
      ),
    );
  }


  /** Things we need to build */


// A header with the location title and a statemenet (Top gaineers)
  Widget _buildHeader(){
  /** 
   * Things needed: Parent -> we are returning a column 
   * - Location Icon and title (e.g. "Netherlands") in a row
   * - Some metadata about the state of the local markert (e.g. "Martket open etc")
   * - More metadata about the market (e.g. "Top gainers: ASML, Adyen, etc")
   */
    return Column(children: [
      // we need a row for the location icon and title
      Row(children: [
        Icon(Icons.location_on_outlined, color: Colors.pink),
        SizedBox(width: 8),
        Text("Netherlands"),
        SizedBox(width: 8),
        Container( 
        padding: EdgeInsets.symmetric(horizontal: 5, vertical: 4), 
        decoration: BoxDecoration( 
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
              BoxShadow(
                color: Colors.pink.withOpacity(0.5),
                blurRadius: 7,
                offset: Offset(0, 2),
              )
            ]
          ),
        child:  Text("NL", style: TextStyle(fontSize: 15))
        ),
      ]),
      FractionallySizedBox(widthFactor: 0.2),
      // we need a row widget for the market status
      Row(children: []),
      FractionallySizedBox(widthFactor: 0.2),
      // we need a row widget for the top gainers
      Row(children: [])

      ]);
  }

// Trending in Region section. It should be a list which is rendered 
// as a horizontal list of cards.
  Widget _trendingInRegion (){
    return Text("Hi");
  }

  // A dedicated stocks section for the local market.
  // It should be a list which is rendered as horizontal cards in column. 
  Widget _localStocks(){
    return Text("Hi");
  }

  // Trending news section. 
  // It should be a list which is rendered as horizontal cards in column.
  Widget _trendingNews(){
    return Text("Hi");
  }
}

