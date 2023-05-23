import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'download_historical_jeep_as_table.dart';

class DownloadHistoricalJeepCSV extends StatelessWidget {
  const DownloadHistoricalJeepCSV({
    super.key,
    required this.route_choice,
    required DateTime selectedDateTime,
  }) : _selectedDateTime = selectedDateTime;

  final int route_choice;
  final DateTime _selectedDateTime;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () async {
          await downloadHistoricalJeepCollectionAsCSV(route_choice, Timestamp.fromDate(_selectedDateTime));
        },
        child: const Center(child: Icon(Icons.download_outlined, size: 20, color: Colors.lightBlue))
    );
  }
}