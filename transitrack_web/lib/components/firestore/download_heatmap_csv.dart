import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'download_heatmap_as_table.dart';

class DownloadHeatMapCSV extends StatelessWidget {
  const DownloadHeatMapCSV({
    super.key,
    required this.route_choice,
    required DateTime selectedDateStart,
    required DateTime selectedDateEnd,
  }) : _selectedDateStart = selectedDateStart, _selectedDateEnd = selectedDateEnd;

  final int route_choice;
  final DateTime _selectedDateStart;
  final DateTime _selectedDateEnd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () async {
          await downloadHeatMapCollectionAsCSV(route_choice, Timestamp.fromDate(_selectedDateStart), Timestamp.fromDate(_selectedDateEnd));
        },
        child: const Center(child: Icon(Icons.download_outlined, size: 20, color: Colors.lightBlue))
    );
  }
}