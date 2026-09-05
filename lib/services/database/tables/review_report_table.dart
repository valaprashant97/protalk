import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../../models/session_report.dart';

class SessionReportModel {
  final int? id;
  final String sessionId;
  final String module;
  final double overallScore;
  final List<ReportMetric> metrics;
  final List<String> strengths;
  final List<FeedbackItem> areasToImprove;
  final List<ImprovementTipItem> improvementTips;
  final DateTime createdAt;
  final int messageCount;

  SessionReportModel({
    this.id,
    required this.sessionId,
    required this.module,
    required this.overallScore,
    required this.metrics,
    required this.strengths,
    required this.areasToImprove,
    required this.improvementTips,
    DateTime? createdAt,
    int? messageCount,
  })  : createdAt = createdAt ?? DateTime.now(),
        messageCount = messageCount ?? 0;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'session_id': sessionId,
      'module': module,
      'overall_score': overallScore,
      'metrics_json': jsonEncode(metrics.map((m) => {'name': m.name, 'score': m.score}).toList()),
      'strengths_json': jsonEncode(strengths),
      'areas_to_improve_json': jsonEncode(areasToImprove.map((a) => {'category': a.category, 'description': a.description}).toList()),
      'improvement_tips_json': jsonEncode(improvementTips.map((t) => {'category': t.category, 'tip': t.tip}).toList()),
      'created_at': createdAt.toIso8601String(),
      'message_count': messageCount,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  factory SessionReportModel.fromMap(Map<String, dynamic> map) {
    List<ReportMetric> parsedMetrics = [];
    if (map['metrics_json'] != null) {
      try {
        final raw = jsonDecode(map['metrics_json']) as List;
        parsedMetrics = raw.map((item) => ReportMetric(name: item['name'] ?? '', score: (item['score'] as num? ?? 0).toInt())).toList();
      } catch (_) {}
    }

    List<String> parsedStrengths = [];
    if (map['strengths_json'] != null) {
      try {
        parsedStrengths = List<String>.from(jsonDecode(map['strengths_json']));
      } catch (_) {}
    }

    List<FeedbackItem> parsedAreas = [];
    if (map['areas_to_improve_json'] != null) {
      try {
        final raw = jsonDecode(map['areas_to_improve_json']) as List;
        parsedAreas = raw.map((item) => FeedbackItem(category: item['category'] ?? '', description: item['description'] ?? '')).toList();
      } catch (_) {}
    }

    List<ImprovementTipItem> parsedTips = [];
    if (map['improvement_tips_json'] != null) {
      try {
        final raw = jsonDecode(map['improvement_tips_json']) as List;
        parsedTips = raw.map((item) => ImprovementTipItem(category: item['category'] ?? '', tip: item['tip'] ?? '')).toList();
      } catch (_) {}
    }

    return SessionReportModel(
      id: map['id'] as int?,
      sessionId: map['session_id'] ?? '',
      module: map['module'] ?? 'interview',
      overallScore: (map['overall_score'] as num? ?? 8.0).toDouble(),
      metrics: parsedMetrics,
      strengths: parsedStrengths,
      areasToImprove: parsedAreas,
      improvementTips: parsedTips,
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      messageCount: (map['message_count'] as num? ?? 0).toInt(),
    );
  }

  SessionReport toSessionReport() {
    return SessionReport(
      module: module,
      overallScore: overallScore,
      metrics: metrics,
      strengths: strengths,
      areasToImprove: areasToImprove,
      improvementTips: improvementTips,
    );
  }
}

class ReviewReportTable {
  static const String tableName = 'session_reports';

  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT NOT NULL,
        module TEXT NOT NULL,
        overall_score REAL NOT NULL,
        metrics_json TEXT NOT NULL,
        strengths_json TEXT NOT NULL,
        areas_to_improve_json TEXT NOT NULL,
        improvement_tips_json TEXT NOT NULL,
        created_at TEXT NOT NULL,
        message_count INTEGER DEFAULT 0
      )
    ''');

    // Idempotent migration for existing database installations
    try {
      await db.execute('ALTER TABLE $tableName ADD COLUMN message_count INTEGER DEFAULT 0');
    } catch (_) {
      // Column already exists
    }
  }

  static Future<void> insertReport(Database db, SessionReportModel report) async {
    await db.transaction((txn) async {
      await txn.delete(
        tableName,
        where: 'session_id = ?',
        whereArgs: [report.sessionId],
      );
      await txn.insert(
        tableName,
        report.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  static Future<SessionReportModel?> getReportForSession(Database db, String sessionId) async {
    final maps = await db.query(
      tableName,
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'id DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return SessionReportModel.fromMap(maps.first);
    }
    return null;
  }
}
