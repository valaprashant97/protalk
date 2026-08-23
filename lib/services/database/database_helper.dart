import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'tables/chat_history_table.dart';
import 'tables/review_report_table.dart';
import 'tables/session_config_table.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'pcs_demo.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await SessionConfigTable.createTable(db);
    await ChatHistoryTable.createTables(db);
    await ReviewReportTable.createTable(db);
  }

  /// Saves a complete session configuration from Module Selection
  Future<void> saveSessionConfig(SessionConfigModel config) async {
    final db = await database;
    await SessionConfigTable.insertOrUpdate(db, config);
  }

  /// Retrieves a session configuration by sessionId
  Future<SessionConfigModel?> getSessionConfig(String sessionId) async {
    final db = await database;
    return await SessionConfigTable.getConfig(db, sessionId);
  }

  /// Saves or updates a ChatSession
  Future<void> saveChatSession(ChatSessionModel session) async {
    final db = await database;
    await ChatHistoryTable.saveSession(db, session);
  }

  /// Updates title for a ChatSession
  Future<void> updateChatSessionTitle(String sessionId, String newTitle) async {
    final db = await database;
    await ChatHistoryTable.updateSessionTitle(db, sessionId, newTitle);
  }

  /// Retrieves all ChatSessions ordered by recent update time
  Future<List<ChatSessionModel>> getAllChatSessions() async {
    final db = await database;
    return await ChatHistoryTable.getAllSessions(db);
  }

  /// Checks if any chat sessions exist in database
  Future<bool> hasAnySessions() async {
    final db = await database;
    return await ChatHistoryTable.hasAnySessions(db);
  }

  /// Retrieves rich session summaries (with last message & first user prompt) ordered by recent update time
  Future<List<SessionSummaryModel>> getAllSessionSummaries() async {
    final db = await database;
    return await ChatHistoryTable.getSessionSummaries(db);
  }

  /// Saves a ChatMessage
  Future<void> saveChatMessage(ChatMessageModel message) async {
    final db = await database;
    await ChatHistoryTable.saveMessage(db, message);
  }

  /// Retrieves all ChatMessages for a session
  Future<List<ChatMessageModel>> getChatMessages(String sessionId) async {
    final db = await database;
    return await ChatHistoryTable.getMessagesForSession(db, sessionId);
  }

  /// Syncs session chat messages after deletions
  Future<void> syncChatMessages(String sessionId, List<ChatMessageModel> messages) async {
    final db = await database;
    await ChatHistoryTable.syncMessagesForSession(db, sessionId, messages);
  }

  /// Deletes a chat session and its associated messages, config, and reports
  Future<void> deleteChatSession(String sessionId) async {
    final db = await database;
    await ChatHistoryTable.deleteSession(db, sessionId);
    await db.delete('session_configs', where: 'session_id = ?', whereArgs: [sessionId]);
    await db.delete('session_reports', where: 'session_id = ?', whereArgs: [sessionId]);
  }

  /// Saves a SessionReport
  Future<void> saveSessionReport(SessionReportModel report) async {
    final db = await database;
    await ReviewReportTable.insertReport(db, report);
  }

  /// Retrieves a SessionReport for a session
  Future<SessionReportModel?> getSessionReport(String sessionId) async {
    final db = await database;
    return await ReviewReportTable.getReportForSession(db, sessionId);
  }

  /// Clears all stored data
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('session_reports');
    await db.delete('chat_messages');
    await db.delete('chat_sessions');
    await db.delete('session_configs');
  }
}
