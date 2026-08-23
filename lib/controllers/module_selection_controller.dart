import 'package:get/get.dart';
import '../services/database/database_helper.dart';
import '../services/database/tables/session_config_table.dart';

class ModuleSelectionController extends GetxController {
  // Common Module Selection
  var selectedModule = 'interview'.obs; // 'interview' or 'english'

  // --- 1. Interview Preparation Fields ---
  var selectedInterviewType = RxnString();
  var selectedJobRole = RxnString();
  var specificSkills = ''.obs; // Custom typed skills
  var selectedCourse = RxnString();
  var selectedSpecialization = RxnString();
  var selectedInterviewDifficulty = 'Beginner'.obs;
  var companyName = ''.obs;

  // Horizontal Scrollable Skill Chips Data
  final List<String> softSkills = [
    'Communication',
    'Problem Solving',
    'Technical Knowledge',
    'Teamwork',
    'Adaptability',
    'Leadership',
    'Time Management',
    'Critical Thinking',
  ];

  final List<String> technicalSkills = [
    'C',
    'C++',
    'C#',
    'Java',
    'Python',
    'JavaScript',
    'TypeScript',
    'Dart',
    'Kotlin',
    'Swift',

    'MERN Stack',
    'MEAN Stack',
    'MEVN Stack',
    'ASP.NET',
    '.NET',
    'Spring Boot',
    'Django',
    'Laravel',
    'Ruby on Rails',

    'Flutter',
    'React',
    'Angular',
    'Vue.js',
    'Node.js',
    'Express.js',

    'AI & Machine Learning',
    'Deep Learning',
    'Data Science',
    'Generative AI',
    'Natural Language Processing',
    'Computer Vision',

    'SQL',
    'MySQL',
    'PostgreSQL',
    'MongoDB',
    'Firebase',

    'DevOps',
    'Docker',
    'Kubernetes',
    'AWS',
    'Microsoft Azure',
    'Google Cloud',

    'Cybersecurity',
    'Blockchain',
    'IoT',
    'Git & GitHub',
  ];

  // Selected Skills List
  var selectedSkills = <String>[].obs;

  void toggleSkill(String skill) {
    if (selectedSkills.contains(skill)) {
      selectedSkills.remove(skill);
    } else {
      selectedSkills.add(skill);
    }
  }

  // --- 2. English Conversation Fields ---
  var conversationTopic = ''.obs;
  var selectedConversationTopic = RxnString();
  var customConversationTopic = ''.obs;
  var selectedEnglishDifficulty = 'Beginner'.obs;
  var selectedAiPersonality = RxnString();
  var selectedLanguage = ''.obs;
  var selectedCorrectionMode = ''.obs;
  var selectedConversationStyle = ''.obs;
  var selectedResponseStyle = ''.obs;

  final List<String> conversationTopics = [
    'Daily Life',
    'College Life',
    'Friends & Social Life',
    'Travel',
    'Technology',
    'Job & Career',
    'Interview',
    'Business',
    'Random Conversation',
    'Custom Topic',
  ];

  String get effectiveConversationTopic {
    if (selectedConversationTopic.value == 'Custom Topic') {
      return customConversationTopic.value.trim().isNotEmpty
          ? customConversationTopic.value.trim()
          : 'Custom Topic';
    }
    return selectedConversationTopic.value ?? conversationTopic.value;
  }

  // Predefined Lists
  final List<String> interviewTypes = [
    'Technical',
    'Non Technical',
    'HR',
    'Internship / Placement',
  ];
  final List<String> jobRoles = [
    'Software Engineer',
    'Full Stack Developer',
    'Frontend Developer',
    'Backend Developer',
    'Flutter Developer',
    'Data Analyst',
    'AI/ML Engineer',
    'DevOps Engineer',
    'UI/UX Designer',
    'Computer Engineering',
    'Civil Engineer',
    'Mechanical Engineering',
    'Electrical Engineering',
    'Cybersecurity Engineer',
    'HR Executive',
    'Business Executive',
    'Teaching Assistant',
  ];
  final List<String> courses = [
    'B.Tech (CSE)',
    'B.Tech (AI & ML)',
    'B.Tech (Civil Engineering)',
    'B.Tech (ECE)',
    'B.Tech (Mechanical Engineering)',
    'BCA',
    'B.Sc. (Information Technology)',
    'B.Sc. (Honors - Computer Science)',
    'B.Sc. (Honors - AI & ML)',
    'B.Com',
    'BBA',
    'BBA (Digital Marketing)',
    'BBA (Entrepreneurship & Family Business)',
    'B.Sc. (Microbiology)',
    'M.Tech (Software Engineering)',
    'M.Tech (Structural Engineering)',
    'M.Tech (Transportation Engineering)',
    'M.Tech (Construction Project Management)',
    'M.Tech (Advanced Design & Manufacturing)',
    'MCA',
    'MBA',
    'Diploma (Computer Engineering)',
    'Diploma (Civil Engineering)',
    'Diploma (Electrical Engineering)',
    'Diploma (Mechanical Engineering)',
    'Ph.D',
  ];

  final List<String> difficultyLevels = [
    'Beginner',
    'Intermediate',
    'Advanced',
  ];

  final List<String> aiPersonalities = [
    'Friendly',
    'Professional',
    'Teacher',
    'Casual',
    'Motivational',
  ];

  final List<String> languages = [
    'English',
    'Hindi + English',
    'Gujarati + English',
  ];

  final List<String> correctionModes = [
    'Correct Every Mistake',
    'Correct Important Mistakes',
    'Don\'t Interrupt, Give Feedback Later',
  ];

  final List<String> conversationStyles = [
    'Normal Conversation',
    'Ask Me Questions',
    'Debate',
    'Role Play',
    'Storytelling',
    'Situation Based',
  ];

  final List<String> responseStyles = [
    'Short & Simple',
    'Natural Conversation',
    'Detailed',
    'Professional',
  ];

  // --- Validation State & Logic ---
  var showValidationErrors = false.obs;

  bool get isCourseValid => selectedCourse.value != null && selectedCourse.value!.isNotEmpty;
  bool get isInterviewTypeValid => selectedInterviewType.value != null && selectedInterviewType.value!.isNotEmpty;
  bool get isJobRoleValid => selectedJobRole.value != null && selectedJobRole.value!.isNotEmpty;
  bool get isSkillsValid => selectedSkills.isNotEmpty;

  bool get isTopicValid {
    if (selectedConversationTopic.value == null || selectedConversationTopic.value!.isEmpty) {
      return false;
    }
    if (selectedConversationTopic.value == 'Custom Topic') {
      return customConversationTopic.value.trim().isNotEmpty;
    }
    return true;
  }

  bool get isAiPersonalityValid => selectedAiPersonality.value != null && selectedAiPersonality.value!.isNotEmpty;
  bool get isLanguageValid => selectedLanguage.value.isNotEmpty;
  bool get isCorrectionModeValid => selectedCorrectionMode.value.isNotEmpty;
  bool get isConversationStyleValid => selectedConversationStyle.value.isNotEmpty;
  bool get isResponseStyleValid => selectedResponseStyle.value.isNotEmpty;

  /// Validates form fields based on the selected practice module
  bool validateForm() {
    showValidationErrors.value = true;
    if (selectedModule.value == 'interview') {
      return isCourseValid && isInterviewTypeValid && isJobRoleValid && isSkillsValid;
    } else {
      return isTopicValid &&
          isAiPersonalityValid &&
          isLanguageValid &&
          isCorrectionModeValid &&
          isConversationStyleValid &&
          isResponseStyleValid;
    }
  }

  void setModule(String id) {
    selectedModule.value = id;
    showValidationErrors.value = false;
  }

  Future<void> saveSessionConfig(Map<String, dynamic> config) async {
    final sessionId = config['sessionId'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    config['sessionId'] = sessionId;

    final model = SessionConfigModel(
      sessionId: sessionId,
      module: config['module'] ?? 'interview',
      course: config['course'],
      interviewType: config['interviewType'],
      jobRole: config['jobRole'],
      skills: config['skills'] != null ? List<String>.from(config['skills']) : null,
      company: config['company'],
      difficulty: config['difficulty'],
      englishTopic: config['englishTopic'],
      aiPersonality: config['aiPersonality'],
      language: config['language'],
      correctionMode: config['correctionMode'],
      conversationStyle: config['conversationStyle'],
      responseStyle: config['responseStyle'],
    );

    await DatabaseHelper.instance.saveSessionConfig(model);
  }
}
