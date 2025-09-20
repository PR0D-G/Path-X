# MongoDB Integration for PathX

This guide will help you set up MongoDB for the PathX application.

## Prerequisites

1. MongoDB Atlas account (https://www.mongodb.com/cloud/atlas/register)
2. Node.js and npm installed (for running the migration script)
3. Flutter SDK installed

## Setup Instructions

### 1. Create a MongoDB Atlas Cluster

1. Log in to your MongoDB Atlas account
2. Create a new project (e.g., "PathX")
3. Build a new cluster (Free tier is sufficient for development)
4. Note down your connection string

### 2. Set Up Environment Variables

1. Create a `.env` file in the root of your project:
   ```
   MONGODB_URI=your_mongodb_connection_string
   ```

   Replace `your_mongodb_connection_string` with your actual MongoDB connection string.

2. Make sure to add `.env` to your `.gitignore` file (already done)

### 3. Install Dependencies

Run the following command to install the required dependencies:

```bash
flutter pub get
```

### 4. Run the Migration Script

To migrate your existing jobs data from the JSON file to MongoDB, run the migration script:

```bash
dart run scripts/migrate_jobs_to_mongodb.dart
```

This will:
1. Read the jobs from `assets/data/jobs.json`
2. Connect to your MongoDB database
3. Import all jobs into the `jobs` collection

### 5. Update Your Application Code

The application code has already been updated to use MongoDB. The main changes are:

1. `lib/services/mongo_db_service.dart` - Handles the MongoDB connection
2. `lib/services/job_service.dart` - Updated to use MongoDB instead of local JSON
3. `lib/main.dart` - Initializes the MongoDB connection on app start

## Verifying the Setup

1. Start your Flutter application:
   ```bash
   flutter run
   ```

2. The app should now be using MongoDB for job data. You can verify this by:
   - Checking the app logs for a successful MongoDB connection message
   - Verifying that job data is displayed in your app
   - Checking your MongoDB Atlas dashboard to see the imported data

## Troubleshooting

1. **Connection Issues**
   - Ensure your IP is whitelisted in MongoDB Atlas
   - Verify your connection string is correct
   - Check that your network allows outbound connections to MongoDB (port 27017)

2. **Migration Issues**
   - Make sure the `jobs.json` file exists in the correct location
   - Check that you have write permissions to your MongoDB database
   - Look for any error messages in the console output

3. **Runtime Issues**
   - Ensure the MongoDB service is running
   - Check that the environment variables are properly set
   - Look for any error messages in the app logs

## Next Steps

- Consider implementing data validation in your MongoDB schema
- Set up proper error handling for database operations
- Implement data caching for better performance
- Set up database backups and monitoring in production

## Support

If you encounter any issues, please refer to the MongoDB documentation or open an issue in the repository.
