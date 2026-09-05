import 'package:flutter_test/flutter_test.dart';
import 'package:protalk/models/session_report.dart';
import 'package:protalk/services/api/review_analytics_service.dart';
import 'package:protalk/services/database/tables/review_report_table.dart';

void main() {
  group('ReviewAnalyticsService - Dynamic Counts & Consistency', () {
    final service = ReviewAnalyticsService();

    test('Local analytics returns 0 areas to improve and 0 tips when user performance has no issues', () async {
      final messages = [
        {'text': 'Hello, could you tell me about yourself?', 'isUser': false},
        {'text': 'I am a passionate software engineer with extensive experience building scalable web architectures.', 'isUser': true},
        {'text': 'What technologies do you prefer working with?', 'isUser': false},
        {'text': 'I specialize in Flutter for frontend mobile development and Go for high-throughput distributed microservices.', 'isUser': true},
        {'text': 'How do you approach debugging complex production issues?', 'isUser': false},
        {'text': 'I methodically inspect structured telemetry logs, reproduce the issue in staging, and apply automated unit tests.', 'isUser': true},
      ];

      final report = await service.generateReview(
        sessionConfig: {'module': 'interview', 'jobRole': 'Software Engineer'},
        conversationMessages: messages,
      );

      // Strengths are detected from substantive answers and good vocab
      expect(report.strengths.isNotEmpty, isTrue);
      // High quality responses with no fillers or fragments should result in 0 areas to improve
      expect(report.areasToImprove.isEmpty, isTrue);
      // 0 areas to improve means 0 tips
      expect(report.improvementTips.isEmpty, isTrue);
      // Overall score must strictly match average of metrics
      final metricsAvg = report.metrics.fold<num>(0, (s, m) => s + m.score) / report.metrics.length;
      final expectedScore = (metricsAvg / 10.0 * 10).roundToDouble() / 10.0;
      expect(report.overallScore, equals(expectedScore));
    });

    test('Local analytics dynamically generates targeted areas to improve and matching tips when issues exist', () async {
      final messages = [
        {'text': 'Tell me about yourself.', 'isUser': false},
        {'text': 'um yeah ok', 'isUser': true},
        {'text': 'What are your hobbies?', 'isUser': false},
        {'text': 'like playing games', 'isUser': true},
        {'text': 'What kind of games?', 'isUser': false},
        {'text': 'uh mobile games', 'isUser': true},
      ];

      final report = await service.generateReview(
        sessionConfig: {'module': 'english', 'englishTopic': 'Hobbies'},
        conversationMessages: messages,
      );

      // Brief responses with fillers must trigger specific areas to improve
      expect(report.areasToImprove.isNotEmpty, isTrue);
      // Tips must match detected areas
      expect(report.improvementTips.length, equals(report.areasToImprove.length));
      expect(report.areasToImprove.any((a) => a.category == 'Response Elaboration'), isTrue);
      expect(report.areasToImprove.any((a) => a.category == 'Filler Words'), isTrue);
    });
  });

  group('SessionReportModel - Persistence & Message Count', () {
    test('SessionReportModel serializes and deserializes messageCount correctly', () {
      final model = SessionReportModel(
        sessionId: 'session_123',
        module: 'english',
        overallScore: 8.5,
        metrics: [ReportMetric(name: 'Fluency', score: 85)],
        strengths: ['Great articulation'],
        areasToImprove: [],
        improvementTips: [],
        messageCount: 7,
      );

      final map = model.toMap();
      expect(map['session_id'], 'session_123');
      expect(map['message_count'], 7);
      expect(map['strengths_json'], '["Great articulation"]');
      expect(map['areas_to_improve_json'], '[]');
      expect(map['improvement_tips_json'], '[]');

      final restored = SessionReportModel.fromMap(map);
      expect(restored.sessionId, 'session_123');
      expect(restored.messageCount, 7);
      expect(restored.strengths.length, 1);
      expect(restored.areasToImprove.isEmpty, isTrue);
      expect(restored.improvementTips.isEmpty, isTrue);
    });
  });
}
