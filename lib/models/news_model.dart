class NewsModel {
  final String id;
  final String title;
  final String content;
  final String imageUrl;
  final DateTime publishDate;
  final String author;
  final bool isImportant;

  NewsModel({
    required this.id,
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.publishDate,
    required this.author,
    this.isImportant = false,
  });

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    return NewsModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      publishDate: DateTime.parse(json['publishDate'] ?? DateTime.now().toIso8601String()),
      author: json['author'] ?? '',
      isImportant: json['isImportant'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'publishDate': publishDate.toIso8601String(),
      'author': author,
      'isImportant': isImportant,
    };
  }
} 