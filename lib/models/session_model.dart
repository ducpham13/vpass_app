import 'package:cloud_firestore/cloud_firestore.dart';

class SessionModel {
  final String id;
  final String cardId;
  final String userId;
  final String gymId;
  final String date; // "YYYY-MM-DD"
  final DateTime timestamp;
  final double valueCharged;
  final String checkedInBy;

  SessionModel({
    required this.id,
    required this.cardId,
    required this.userId,
    required this.gymId,
    required this.date,
    required this.timestamp,
    required this.valueCharged,
    required this.checkedInBy,
  });

  factory SessionModel.fromMap(String id, Map<String, dynamic> data) {
    return SessionModel(
      id: id,
      cardId: data['cardId'] ?? '',
      userId: data['userId'] ?? '',
      gymId: data['gymId'] ?? '',
      date: data['date'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      valueCharged: (data['valueCharged'] ?? 0).toDouble(),
      checkedInBy: data['checkedInBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cardId': cardId,
      'userId': userId,
      'gymId': gymId,
      'date': date,
      'timestamp': Timestamp.fromDate(timestamp),
      'valueCharged': valueCharged,
      'checkedInBy': checkedInBy,
    };
  }
}
