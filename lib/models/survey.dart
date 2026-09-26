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

  const Survey({
    required this.id,
    required this.title,
    required this.description,
    required this.isPublished,
    this.questions = const [],
  });

  Survey copyWith({
    String? id,
    String? title,
    String? description,
    bool? isPublished,
    List<Question>? questions,
  }) {
    return Survey(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isPublished: isPublished ?? this.isPublished,
      questions: questions ?? this.questions,
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


