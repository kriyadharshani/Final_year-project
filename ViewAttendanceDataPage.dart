import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ViewAttendanceDataPage extends StatefulWidget {
  @override
  _ViewAttendanceDataPageState createState() => _ViewAttendanceDataPageState();
}

class _ViewAttendanceDataPageState extends State<ViewAttendanceDataPage> {
  late Stream<QuerySnapshot> _AttendanceDataStream;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Fetch the Attendance data stream from Firestore
    _AttendanceDataStream = FirebaseFirestore.instance.collection('Face_Attendances').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('View Attendance Data'),
        backgroundColor: Colors.blue, // Set app bar background color to blue
        foregroundColor: Colors.white,
      ),


      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _AttendanceDataStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text('No Attendance data available.'),
                  );
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      DataColumn(label: Text('Attendance Date & Time                  ')),
                      DataColumn(label: Text('Photo           ')),
                    ],
                    rows: _filteredRows(snapshot.data!.docs),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<DataRow> _filteredRows(List<DocumentSnapshot> data) {
    List<DocumentSnapshot> filteredData = _searchController.text.isEmpty
        ? data
        : data.where((document) {
      Map<String, dynamic> rowData = document.data() as Map<String, dynamic>;
      return rowData.values.any((value) =>
          value.toString().toLowerCase().contains(_searchController.text.toLowerCase()));
    }).toList();

    return filteredData.map((document) {
      Map<String, dynamic> data = document.data() as Map<String, dynamic>;
      return DataRow(
        cells: [
          DataCell(Text(_getFormattedDate(data['date_time']))),
          DataCell(
            GestureDetector(
              onTap: () => _showFullImage(data['photo_path'] ?? ''),
              child: Image.network(
                data['photo_path'] ?? '',
                height: 50,
                width: 50,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      );
    }).toList();
  }

  String _getFormattedDate(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }

  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            child: Image.network(imageUrl),
          ),
        );
      },
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: ViewAttendanceDataPage(),
  ));
}
