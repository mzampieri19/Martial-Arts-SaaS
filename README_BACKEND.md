# Backend Integration Guide

This project has been refactored to use a proper backend API instead of making direct database calls from the Flutter frontend.

## Architecture

```
Flutter App → Express API → Supabase Database
```

### Benefits

1. **Security**: Database credentials and business logic stay on the server
2. **Centralization**: All data operations go through the backend
3. **Validation**: Backend enforces data integrity and business rules
4. **Scalability**: Easier to add features like webhooks, notifications, etc.

## Backend Setup

### 1. Install Dependencies

```bash
cd backend
npm install
```

### 2. Configure Environment Variables

Create a `.env` file in the `backend` directory:

```env
SUPABASE_URL=https://nopgyqscrjjkyapwcqwf.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here
PORT=3000
```

**Important**: You need to get your Supabase Service Role Key from:
- Go to your Supabase project dashboard
- Settings → API → Service Role Key (copy this)

### 3. Run the Backend

Development mode (with auto-reload):
```bash
npm run dev
```

Production mode:
```bash
npm run build
npm start
```

The API will be available at `http://localhost:3000`

## API Endpoints

### Authentication
- `POST /api/auth/login` - User login
- `POST /api/auth/signup` - User registration

### Classes
- `GET /api/classes` - Get all classes
- `GET /api/classes/:id` - Get specific class
- `POST /api/classes` - Create new class
- `PUT /api/classes/:id` - Update class
- `DELETE /api/classes/:id` - Delete class

### Student Classes
- `GET /api/student-classes?user_id=xxx` - Get user's registered classes
- `POST /api/student-classes` - Register for a class

### Goals
- `GET /api/goals` - Get all goals

### Profiles
- `GET /api/profiles/:id` - Get user profile

### Progress
- `GET /api/user-progress/:userId` - Get user progress data
- `POST /api/toggle-mark` - Toggle goal completion mark

### Coaches
- `GET /api/coaches` - Get list of coaches

## Frontend Integration

The frontend has been updated to use the new API service. The key file is:

- `frontend/lib/api_service.dart` - Contains all API communication logic

### How It Works

Instead of calling Supabase directly like this:
```dart
await Supabase.instance.client.from('classes').select();
```

We now use the API service:
```dart
await ApiService.getClasses();
```

## Running the Full Application

### Terminal 1: Start Backend
```bash
cd backend
npm run dev
```

### Terminal 2: Start Flutter App
```bash
cd frontend
flutter run
```

## Important Notes

1. **Network Configuration**: Make sure your Flutter app can connect to `localhost:3000`
   - For iOS Simulator: Use `localhost` or `127.0.0.1`
   - For Android Emulator: Use `10.0.2.2` instead of `localhost`
   - For physical devices: Use your computer's IP address

2. **Update API URL**: If needed, update the base URL in `frontend/lib/api_service.dart`:
   ```dart
   static const String baseUrl = 'http://YOUR_IP:3000/api';
   ```

3. **Keep Supabase**: The app still uses Supabase for authentication session management. The backend uses the service role key for all operations.

## Migration Status

✅ Backend API created with all endpoints
✅ API service created in Flutter
✅ HTTP package installed
⏳ Frontend files still need to be refactored to use API service (in progress)

## Next Steps

The following files still need to be updated to use the new API:
- `log_in.dart` - Use `ApiService.login()`
- `sign_up.dart` - Use `ApiService.signup()`
- `calendar.dart` - Use `ApiService.getClasses()` and `ApiService.registerForClass()`
- `create_classes.dart` - Use `ApiService.createClass()`
- `edit_class.dart` - Use `ApiService.updateClass()`
- `track_progress_page.dart` - Use `ApiService.getUserProgress()` and `ApiService.toggleMark()`
- And other files as needed

Would you like me to continue refactoring these files to use the backend API?
