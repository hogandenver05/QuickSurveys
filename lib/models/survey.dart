enum QuestionType {
  shortAnswer,
  paragraph,
  multipleChoice,
  checkboxes,
  linearScale,
}

class Survey {
  final String id;
  final String title;
  final String description;
  final bool isPublished;
  final List<Question> questions;

  // Survey settings
  final bool allowAnonymousResponses;
  final bool requireRespondentName;
  final bool requireRespondentEmail;

  const Survey({
    required this.id,
    required this.title,
    required this.description,
    required this.isPublished,
    this.questions = const [],

    // Default settings
    this.allowAnonymousResponses = true,
    this.requireRespondentName = false,
    this.requireRespondentEmail = false,
  });

  Survey copyWith({
    String? id,
    String? title,
    String? description,
    bool? isPublished,
    List<Question>? questions,
    bool? allowAnonymousResponses,
    bool? requireRespondentName,
    bool? requireRespondentEmail,
  }) {
    return Survey(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isPublished: isPublished ?? this.isPublished,
      questions: questions ?? this.questions,

      allowAnonymousResponses:
      allowAnonymousResponses ?? this.allowAnonymousResponses,

      requireRespondentName:
      requireRespondentName ?? this.requireRespondentName,

      requireRespondentEmail:
      requireRespondentEmail ?? this.requireRespondentEmail,
    );
  }
}

class Question {
  final String id;
  final String text;
  final QuestionType type;
  final bool isRequired;
  final List<String> options;

  // Linear scale settings
  final int scaleMin;
  final int scaleMax;
  final String scaleMinLabel;
  final String scaleMaxLabel;

  const Question({
    required this.id,
    required this.text,
    required this.type,
    required this.isRequired,
    required this.options,
    this.scaleMin = 1,
    this.scaleMax = 5,
    this.scaleMinLabel = '',
    this.scaleMaxLabel = '',
  });
}


