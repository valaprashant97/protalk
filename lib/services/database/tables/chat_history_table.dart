import 'package:sqflite/sqflite.dart';

class ChatSessionModel {
  final String sessionId;
  final String title;
  final String module;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatSessionModel({
    required this.sessionId,
    required this.title,
    required this.module,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'session_id': sessionId,
      'title': title,
      'module': module,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ChatSessionModel.fromMap(Map<String, dynamic> map) {
    return ChatSessionModel(
      sessionId: map['session_id'] ?? '',
      title: map['title'] ?? 'Practice Session',
      module: map['module'] ?? 'interview',
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class ChatMessageModel {
  final int? id;
  final String sessionId;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessageModel({
    this.id,
    required this.sessionId,
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'session_id': sessionId,
      'text': text,
      'is_user': isUser ? 1 : 0,
      'timestamp': timestamp.toIso8601String(),
    };
    if (id != null) map['id'] = id;
    return map;
  }

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) {
    return ChatMessageModel(
      id: map['id'] as int?,
      sessionId: map['session_id'] ?? '',
      text: map['text'] ?? '',
      isUser: (map['is_user'] as int? ?? 0) == 1,
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}

class SessionSummaryModel {
  final String sessionId;
  final String title;
  final String module;
  final String? firstUserMessage;
  final String? lastMessage;
  final bool? lastMessageIsUser;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;

  SessionSummaryModel({
    required this.sessionId,
    required this.title,
    required this.module,
    this.firstUserMessage,
    this.lastMessage,
    this.lastMessageIsUser,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.messageCount = 0,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  String get timeFormatted {
    final now = DateTime.now();
    final difference = now.difference(updatedAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24 && now.day == updatedAt.day) {
      final hour = updatedAt.hour == 0 ? 12 : (updatedAt.hour > 12 ? updatedAt.hour - 12 : updatedAt.hour);
      final minute = updatedAt.minute.toString().padLeft(2, '0');
      final period = updatedAt.hour >= 12 ? 'PM' : 'AM';
      return 'Today, $hour:$minute $period';
    } else if (difference.inDays == 1 || (difference.inHours < 48 && now.day - updatedAt.day == 1)) {
      final hour = updatedAt.hour == 0 ? 12 : (updatedAt.hour > 12 ? updatedAt.hour - 12 : updatedAt.hour);
      final minute = updatedAt.minute.toString().padLeft(2, '0');
      final period = updatedAt.hour >= 12 ? 'PM' : 'AM';
      return 'Yesterday, $hour:$minute $period';
    } else {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final month = months[updatedAt.month - 1];
      final hour = updatedAt.hour == 0 ? 12 : (updatedAt.hour > 12 ? updatedAt.hour - 12 : updatedAt.hour);
      final minute = updatedAt.minute.toString().padLeft(2, '0');
      final period = updatedAt.hour >= 12 ? 'PM' : 'AM';
      return '$month ${updatedAt.day}, $hour:$minute $period';
    }
  }

  SessionSummaryModel copyWith({
    String? sessionId,
    String? title,
    String? module,
    String? firstUserMessage,
    String? lastMessage,
    bool? lastMessageIsUser,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? messageCount,
  }) {
    return SessionSummaryModel(
      sessionId: sessionId ?? this.sessionId,
      title: title ?? this.title,
      module: module ?? this.module,
      firstUserMessage: firstUserMessage ?? this.firstUserMessage,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageIsUser: lastMessageIsUser ?? this.lastMessageIsUser,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messageCount: messageCount ?? this.messageCount,
    );
  }
}

class ChatHistoryTable {
  static const String tableSessions = 'chat_sessions';
  static const String tableMessages = 'chat_messages';

  static Future<void> createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableSessions (
        session_id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        module TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableMessages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT NOT NULL,
        text TEXT NOT NULL,
        is_user INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES $tableSessions (session_id) ON DELETE CASCADE
      )
    ''');
  }

  static Future<void> saveSession(Database db, ChatSessionModel session) async {
    await db.insert(
      tableSessions,
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> updateSessionTitle(Database db, String sessionId, String newTitle) async {
    await db.update(
      tableSessions,
      {
        'title': newTitle,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }

  static Future<List<ChatSessionModel>> getAllSessions(Database db) async {
    final maps = await db.query(
      tableSessions,
      orderBy: 'updated_at DESC',
    );
    return maps.map((map) => ChatSessionModel.fromMap(map)).toList();
  }

  static Future<bool> hasAnySessions(Database db) async {
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $tableSessions');
    final count = Sqflite.firstIntValue(result) ?? 0;
    return count > 0;
  }

  static Future<List<SessionSummaryModel>> getSessionSummaries(Database db) async {
    final sessions = await getAllSessions(db);
    final List<SessionSummaryModel> summaries = [];

    for (final session in sessions) {
      // Query last message
      final lastMsgResult = await db.query(
        tableMessages,
        columns: ['text', 'is_user', 'timestamp'],
        where: 'session_id = ?',
        whereArgs: [session.sessionId],
        orderBy: 'id DESC',
        limit: 1,
      );

      // Query first user message
      final firstUserMsgResult = await db.query(
        tableMessages,
        columns: ['text'],
        where: 'session_id = ? AND is_user = 1',
        whereArgs: [session.sessionId],
        orderBy: 'id ASC',
        limit: 1,
      );

      // Query total message count
      final countResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $tableMessages WHERE session_id = ?',
        [session.sessionId],
      );
      final count = Sqflite.firstIntValue(countResult) ?? 0;

      String? lastMessageText;
      bool? lastMsgIsUser;
      if (lastMsgResult.isNotEmpty) {
        lastMessageText = lastMsgResult.first['text'] as String?;
        lastMsgIsUser = (lastMsgResult.first['is_user'] as int? ?? 0) == 1;
      }

      String? firstUserText;
      if (firstUserMsgResult.isNotEmpty) {
        firstUserText = firstUserMsgResult.first['text'] as String?;
      }

      summaries.add(
        SessionSummaryModel(
          sessionId: session.sessionId,
          title: session.title,
          module: session.module,
          firstUserMessage: firstUserText,
          lastMessage: lastMessageText,
          lastMessageIsUser: lastMsgIsUser,
          createdAt: session.createdAt,
          updatedAt: session.updatedAt,
          messageCount: count,
        ),
      );
    }

    return summaries;
  }

  static Future<ChatSessionModel?> getSession(Database db, String sessionId) async {
    final maps = await db.query(
      tableSessions,
      where: 'session_id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return ChatSessionModel.fromMap(maps.first);
    }
    return null;
  }

  static Future<void> saveMessage(Database db, ChatMessageModel message) async {
    await db.insert(tableMessages, message.toMap());
    await db.update(
      tableSessions,
      {'updated_at': DateTime.now().toIso8601String()},
      where: 'session_id = ?',
      whereArgs: [message.sessionId],
    );
  }

  static Future<List<ChatMessageModel>> getMessagesForSession(Database db, String sessionId) async {
    final maps = await db.query(
      tableMessages,
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'id ASC',
    );
    return maps.map((map) => ChatMessageModel.fromMap(map)).toList();
  }

  static Future<void> syncMessagesForSession(Database db, String sessionId, List<ChatMessageModel> remainingMessages) async {
    await db.delete(
      tableMessages,
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
    for (final msg in remainingMessages) {
      await db.insert(tableMessages, msg.toMap());
    }
  }

  static Future<void> deleteSession(Database db, String sessionId) async {
    await db.delete(
      tableMessages,
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
    await db.delete(
      tableSessions,
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }
}
