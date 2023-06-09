import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'download_historical_jeep_as_table.dart';

class DownloadHistoricalJeepCSV extends StatelessWidget {
  const DownloadHistoricalJeepCSV({
    super.key,
    required this.route_choice,
    required DateTime selectedStartDateTime,
    required DateTime selectedEndDateTime,
  }) : _selectedStartDateTime = selectedStartDateTime, _selectedEndDateTime = selectedEndDateTime;

  final int route_choice;
  final DateTime _selectedStartDateTime;
  final DateTime _selectedEndDateTime;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () async {
          await downloadHistoricalJeepCollectionAsCSV(route_choice, Timestamp.fromDate(_selectedStartDateTime), Timestamp.fromDate(_selectedEndDateTime));
        },
        child: const Center(child: Icon(Icons.download_outlined, size: 20, color: Colors.lightBlue))
    );
  }
}