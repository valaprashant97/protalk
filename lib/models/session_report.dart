class FeedbackItem {
  final String category;
  final String description;

  FeedbackItem({
    required this.category,
    required this.description,
  });
}

class ImprovementTipItem {
  final String category;
  final String tip;

  ImprovementTipItem({
    required this.category,
    required this.tip,
  });
}

class ReportMetric {
  final String name;
  final int score;

  ReportMetric({
    required this.name,
    required this.score,
  });
}

class SessionReport {
  final String module;
  final double overallScore;
  final List<ReportMetric> metrics;
  final List<String> strengths;
  final List<FeedbackItem> areasToImprove;
  final List<ImprovementTipItem> improvementTips;

  SessionReport({
    required this.module,
    required this.overallScore,
    required this.metrics,
    required this.strengths,
    required this.areasToImprove,
    required this.improvementTips,
  });
}
