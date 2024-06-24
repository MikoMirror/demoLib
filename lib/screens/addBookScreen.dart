import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_storage/firebase_storage.dart';
import '/services/FirestoreService.dart';
import '../models/book.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../widgets/CustomAppBar.dart';
import '../widgets/StylizedTextField.dart';
import '../widgets/StylizedButton.dart';
import '../widgets/bookImageWidget.dart';

class AddBookScreen extends StatefulWidget {
  final String collectionId;
  final String googleBooksApiKey;
  final Book? initialBook;
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const AddBookScreen({
    required this.collectionId,
    required this.googleBooksApiKey,
    this.initialBook,
    required this.isDarkMode,
    required this.onThemeToggle,
    Key? key,
  }) : super(key: key);

  @override
  _AddBookScreenState createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _publishedDateController = TextEditingController();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _isbnController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoriesController = TextEditingController();
  final TextEditingController _pageCountController = TextEditingController();

  Timestamp? _selectedDate;
  File? _selectedImage;
  String? _imageUrl;
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _initializeTextControllers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _isbnController.dispose();
    _descriptionController.dispose();
    _categoriesController.dispose();
    _pageCountController.dispose();
    _publishedDateController.dispose();
    super.dispose();
  }

  void _initializeTextControllers() {
    final initialBook = widget.initialBook;

    _titleController.text = initialBook?.title ?? '';
    _authorController.text = initialBook?.author ?? '';
    _isbnController.text = initialBook?.isbn ?? '';
    _descriptionController.text = initialBook?.description ?? '';
    _categoriesController.text = initialBook?.categories ?? '';
    _pageCountController.text = initialBook?.pageCount.toString() ?? '';

    _selectedDate = initialBook?.publishedDate;
    _imageUrl = initialBook?.externalImageUrl;  
    _publishedDateController.text = initialBook?.publishedDate != null
        ? DateFormat('yyyy-MM-dd').format(initialBook!.publishedDate!.toDate())
        : DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate?.toDate() ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate?.toDate()) {
      setState(() {
        _selectedDate = Timestamp.fromDate(picked);
        _publishedDateController.text =
            DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _pickImage() async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.gallery);

  if (pickedFile != null) {
    Uint8List imageBytes = await pickedFile.readAsBytes(); 

    setState(() {
      _selectedImage = File(pickedFile.path); 
      _imageBytes = imageBytes; 
    });
  }
}

  Future<String?> _uploadImageToStorage(Uint8List imageBytes) async {
  try {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();

    if (kIsWeb) {
      // Web Upload Logic:
      firebase_storage.Reference storageRef = firebase_storage
          .FirebaseStorage.instance
          .ref()
          .child('book_covers/$fileName.jpg');
      final metadata =
          firebase_storage.SettableMetadata(contentType: 'image/jpeg');
      firebase_storage.UploadTask uploadTask =
          storageRef.putData(imageBytes, metadata);
      firebase_storage.TaskSnapshot storageTaskSnapshot =
          await uploadTask.whenComplete(() {});
      return await storageTaskSnapshot.ref.getDownloadURL();
    } else {
      // Mobile/Desktop Upload Logic:
      Reference storageRef =
          FirebaseStorage.instance.ref().child('book_covers/$fileName.jpg');
      UploadTask uploadTask = storageRef.putFile(File(_selectedImage!.path));
      TaskSnapshot storageTaskSnapshot = await uploadTask.whenComplete(() {});
      return await storageTaskSnapshot.ref.getDownloadURL();
    }
  } catch (e) {
    print('Error uploading image: $e');
    return null;
  }
}

 void _submitForm() async {
  if (_formKey.currentState!.validate()) {
    _formKey.currentState!.save();
    
    String? imageUrl;
    if (_selectedImage != null) {
      imageUrl = await _uploadImageToStorage(_imageBytes!);
    } else if (widget.initialBook?.externalImageUrl != null) {
      imageUrl = widget.initialBook!.externalImageUrl;
    }

    Book newBook = Book(
      title: _titleController.text,
      author: _authorController.text,
      isbn: _isbnController.text,
      description: _descriptionController.text,
      categories: _categoriesController.text,
      pageCount: int.tryParse(_pageCountController.text) ?? 0,
      publishedDate: _selectedDate,
      externalImageUrl: imageUrl,
    );

    await _firestoreService.addBook(widget.collectionId, newBook);
    _formKey.currentState!.reset();
    Navigator.of(context).pop(true);
    Navigator.of(context).pop(true);
  }
}



 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Add Book',
        isDarkMode: widget.isDarkMode,
        onThemeToggle: widget.onThemeToggle,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              if (widget.initialBook != null || _selectedImage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _selectedImage != null
                      ? Image.memory(_imageBytes!, height: 200.0, width: 200.0)
                      : BookImageWidget(
                          book: widget.initialBook!,
                          height: 200,
                        ),
                ),
              StylizedTextField(
                controller: _titleController,
                labelText: 'Title',
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a title'
                    : null,
              ),
              const SizedBox(height: 16),
              StylizedTextField(
                controller: _authorController,
                labelText: 'Author',
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter an author'
                    : null,
              ),
              const SizedBox(height: 16),
              StylizedTextField(
                controller: _isbnController,
                labelText: 'ISBN',
              ),
              const SizedBox(height: 16),
              StylizedTextField(
                controller: _descriptionController,
                labelText: 'Description',
              ),
              const SizedBox(height: 16),
              StylizedTextField(
                controller: _categoriesController,
                labelText: 'Categories',
              ),
              const SizedBox(height: 16),
              StylizedTextField(
                controller: _pageCountController,
                labelText: 'Page Count',
              ),
              const SizedBox(height: 16),
              StylizedTextField(
                controller: _publishedDateController,
                labelText: 'Published Date',
              ),
              const SizedBox(height: 16.0),
              StylizedButton(
                onPressed: _pickImage,
                text: 'Choose Image',
              ),
              const SizedBox(height: 20),
              StylizedButton(
                onPressed: _submitForm,
                text: 'Add Book',
              ),
            ],
          ),
        ),
      ),
    );
  }
}