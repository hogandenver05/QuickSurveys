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

  const Survey({
    required this.id,
    required this.title,
    required this.description,
    required this.isPublished,
  });

  Survey copyWith({
    String? id,
    String? title,
    String? description,
    bool? isPublished,
  }) {
    return Survey(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isPublished: isPublished ?? this.isPublished,
    );
  }
}

class Question {
  final String id;
  final String text;
  final QuestionType type;
  final bool isRequired;
  final List<String> options;

  const Question({
    required this.id,
    required this.text,
    required this.type,
    required this.isRequired,
    required this.options,
  });
}
