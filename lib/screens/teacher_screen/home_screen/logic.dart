import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Grade {
  final String? id;
  final DateTime date;
  final String testName;
  final int score;

  Grade(
      {this.id,
      required this.date,
      required this.testName,
      required this.score});

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'testName': testName,
        'score': score,
      };

  factory Grade.fromJson(Map<String, dynamic> json) =>
      Grade(
        id: json['id'],
        date: DateTime.parse(json['date']),
        testName: json['testName'],
        score: json['score'],
      );
}

class GradeRepository {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getGradesWithId(
      String studentUid, bool isOfficial) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(studentUid)
          .collection('grades')
          .where('isOfficial', isEqualTo: isOfficial)
          .orderBy('date')
          .get();

      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                'grade': Grade(
                  id: doc.id,
                  date: DateTime.parse(doc['date']),
                  testName: doc['testName'],
                  score: doc['score'],
                ),
              })
          .toList();
    } catch (e) {
      print('Error getting grades: $e');
      return [];
    }
  }
}
