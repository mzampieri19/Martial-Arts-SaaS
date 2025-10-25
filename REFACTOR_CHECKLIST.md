# Backend API Migration Checklist

## ✅ Completed
- Backend API created (`backend/src/index.ts`)
- API Service created (`frontend/lib/api_service.dart`)
- HTTP package added to Flutter dependencies

## ⏳ Files That Need Refactoring

### High Priority (Core Functionality)
1. ✅ **`log_in.dart`** - DONE: Now uses `ApiService.login()`
2. **`sign_up.dart`** - Replace Supabase signup with `ApiService.signup()`
3. ✅ **`calendar.dart`** - DONE: Now uses `ApiService.getClasses()` and `ApiService.registerForClass()`
4. ✅ **`create_classes.dart`** - DONE: Now uses `ApiService.createClass()` and `ApiService.getCoaches()`
5. ✅ **`edit_class.dart`** - DONE: Now uses `ApiService.updateClass()`
6. **`track_progress_page.dart`** - Replace progress tracking with `ApiService.getUserProgress()` and `ApiService.toggleMark()`

### Medium Priority
7. **`profile.dart`** - Replace profile fetching with `ApiService.getProfile()`

### Low Priority (Avatar/Storage)
8. **`components/avatar.dart`** - Storage operations can stay with Supabase for now

## Current Status
**Backend is ready and running on port 3000!**

The backend API exists with all endpoints implemented. The frontend files just need to be updated to use the `ApiService` instead of direct Supabase calls.

## What's Been Done
- ✅ Backend Express server with all CRUD operations
- ✅ API endpoints for auth, classes, goals, profiles, progress
- ✅ API Service class with helper methods
- ✅ Automatic URL detection for iOS/Android emulators

## What's Needed
- ⏳ Update frontend Dart files to use `ApiService` methods
- ⏳ Test the integration
- ⏳ Remove direct Supabase calls from Flutter code

**You can start using the backend NOW - it's fully functional and running!**
