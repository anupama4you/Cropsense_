import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  final CollectionReference diseases =
  FirebaseFirestore.instance.collection('diseases');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('History'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: diseases.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No Diseases Found'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var disease = snapshot.data!.docs[index];
              var diseaseData = disease.data() as Map<String, dynamic>;

              return Card(
                child: ListTile(
                  leading: Image.network(
                    diseaseData['imageUrl'],
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                  title: Text(diseaseData['diseaseName']),
                  subtitle: Text(
                    'Date: ${diseaseData['timestamp'].toDate()}',
                  ),
                  onTap: () => _showDiseaseInfoDialog(context, diseaseData),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDiseaseInfoDialog(BuildContext context,
      Map<String, dynamic> diseaseData) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(diseaseData['diseaseName']),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Image.network(
                  diseaseData['imageUrl'],
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
                SizedBox(height: 10),
                Text(
                  'Info: ${diseaseData['diseaseInfo']}',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 10),
                Text(
                  'Date: ${diseaseData['timestamp'].toDate()}',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

