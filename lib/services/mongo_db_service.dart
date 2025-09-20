import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MongoDBService {
  static final MongoDBService _instance = MongoDBService._internal();
  Db? _db;
  
  // Private constructor
  MongoDBService._internal();

  // Factory constructor to return the same instance
  factory MongoDBService() => _instance;

  // Get database instance
  Db? get db => _db;

  // Connect to MongoDB
  Future<void> connect() async {
    try {
      if (_db == null) {
        await dotenv.load(fileName: ".env");
        final connectionString = dotenv.env['MONGODB_URI'] ?? 
            'mongodb://localhost:27017/career_guide';
        
        _db = await Db.create(connectionString);
        await _db!.open();
        print('Connected to MongoDB');
      }
    } catch (e) {
      print('Error connecting to MongoDB: $e');
      rethrow;
    }
  }

  // Get a collection
  DbCollection collection(String collectionName) {
    if (_db == null) {
      throw Exception('Database not connected. Call connect() first.');
    }
    return _db!.collection(collectionName);
  }

  // Close the database connection
  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
      print('Disconnected from MongoDB');
    }
  }
}
