import 'package:cloud_firestore/cloud_firestore.dart';

class Book {
  final String? id;  // Add this line
  final String? isbn;
  final String title;
  final String author;
  final String description;
  final String categories;
  final int pageCount;
  final Timestamp? publishedDate;
  final String? imageUrl;

  Book({
    this.id,  // Add this line
    this.isbn,
    required this.title,
    required this.author,
    this.description = '',
    this.categories = '',
    this.pageCount = 0,  
    this.publishedDate,
    this.imageUrl,
  });

  factory Book.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Book(
      id: doc.id,  // Add this line
      isbn: data['isbn'],
      title: data['title'] ?? '',
      author: data['author'] ?? '',
      description: data['description'] ?? '',
      categories: data['categories'] ?? '',
      pageCount: int.tryParse(data['page_count']?.toString() ?? '0') ?? 0,
      publishedDate: data['published_date'] as Timestamp?,
      imageUrl: data['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'isbn': isbn,
      'title': title,
      'author': author,
      'description': description,
      'categories': categories,
      'page_count': pageCount,
      'published_date': publishedDate,
      'imageUrl': imageUrl,
    };
  }
}