import 'dart:convert';
import 'package:sqflite/sqflite.dart';

class SessionConfigModel {
  final String sessionId;
  final String module; // 'interview' or 'english'
  final String? course;
  final String? interviewType;
  final String? jobRole;
  final List<String>? skills;
  final String? company;
  final String? difficulty;
  final String? englishTopic;
  final String? aiPersonality;
  final String? language;
  final String? correctionMode;
  final String? conversationStyle;
  final String? responseStyle;
  final DateTime createdAt;

  SessionConfigModel({
    required this.sessionId,
    required this.module,
    this.course,
    this.interviewType,
    this.jobRole,
    this.skills,
    this.company,
    this.difficulty,
    this.englishTopic,
    this.aiPersonality,
    this.language,
    this.correctionMode,
    this.conversationStyle,
    this.responseStyle,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'session_id': sessionId,
      'module': module,
      'course': course,
      'interview_type': interviewType,
      'job_role': jobRole,
      'skills_json': skills != null ? jsonEncode(skills) : null,
      'company': company,
      'difficulty': difficulty,
      'english_topic': englishTopic,
      'ai_personality': aiPersonality,
      'language': language,
      'correction_mode': correctionMode,
      'conversation_style': conversationStyle,
      'response_style': responseStyle,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SessionConfigModel.fromMap(Map<String, dynamic> map) {
    List<String>? parsedSkills;
    if (map['skills_json'] != null && map['skills_json'].toString().isNotEmpty) {
      try {
        parsedSkills = List<String>.from(jsonDecode(map['skills_json']));
      } catch (_) {}
    }

    return SessionConfigModel(
      sessionId: map['session_id'] ?? '',
      module: map['module'] ?? 'interview',
      course: map['course'],
      interviewType: map['interview_type'],
      jobRole: map['job_role'],
      skills: parsedSkills,
      company: map['company'],
      difficulty: map['difficulty'],
      englishTopic: map['english_topic'],
      aiPersonality: map['ai_personality'],
      language: map['language'],
      correctionMode: map['correction_mode'],
      conversationStyle: map['conversation_style'],
      responseStyle: map['response_style'],
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toSessionConfigMap() {
    final Map<String, dynamic> result = {
      'sessionId': sessionId,
      'module': module,
    };
    if (course != null) result['course'] = course;
    if (interviewType != null) result['interviewType'] = interviewType;
    if (jobRole != null) result['jobRole'] = jobRole;
    if (skills != null) result['skills'] = skills;
    if (company != null) result['company'] = company;
    if (difficulty != null) result['difficulty'] = difficulty;
    if (englishTopic != null) result['englishTopic'] = englishTopic;
    if (aiPersonality != null) result['aiPersonality'] = aiPersonality;
    if (language != null) result['language'] = language;
    if (correctionMode != null) result['correctionMode'] = correctionMode;
    if (conversationStyle != null) result['conversationStyle'] = conversationStyle;
    if (responseStyle != null) result['responseStyle'] = responseStyle;
    return result;
  }
}

class SessionConfigTable {
  static const String tableName = 'session_configs';

  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        session_id TEXT PRIMARY KEY,
        module TEXT NOT NULL,
        course TEXT,
        interview_type TEXT,
        job_role TEXT,
        skills_json TEXT,
        company TEXT,
        difficulty TEXT,
        english_topic TEXT,
        ai_personality TEXT,
        language TEXT,
        correction_mode TEXT,
        conversation_style TEXT,
        response_style TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  static Future<void> insertOrUpdate(Database db, SessionConfigModel config) async {
    await db.insert(
      tableName,
      config.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<SessionConfigModel?> getConfig(Database db, String sessionId) async {
    final maps = await db.query(
      tableName,
      where: 'session_id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return SessionConfigModel.fromMap(maps.first);
    }
    return null;
  }
}
