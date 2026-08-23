/// Represents the current voice interaction state of the application.
enum VoiceState {
  idle, // No voice activity
  listening, // Listening state
  aiSpeaking, // AI speaking state
  processing, // AI is processing/thinking response
}

/// Represents an individual chat message in the session.
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isGenerating;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.isGenerating = false,
  }) : timestamp = timestamp ?? DateTime.now();

  String get timeFormatted {
    final hour = timestamp.hour == 0
        ? 12
        : (timestamp.hour > 12 ? timestamp.hour - 12 : timestamp.hour);
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = timestamp.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

/// Represents a brief summary of a recent session for history sidebar/list.
class RecentHistory {
  final String id;
  final String title;

  RecentHistory({required this.id, required this.title});

  RecentHistory copyWith({
    String? id,
    String? title,
  }) {
    return RecentHistory(
      id: id ?? this.id,
      title: title ?? this.title,
    );
  }
}
