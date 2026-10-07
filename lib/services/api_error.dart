import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';


/// Returns true when Firebase Auth is not set up in Firebase Console.
bool isFirebaseAuthConfigError(Object error) {
  if (error is FirebaseAuthException) {
    if (error.code == 'configuration-not-found') return true;
    if (error.code == 'internal-error') {
      return (error.message ?? '').contains('CONFIGURATION_NOT_FOUND');
    }
  }
  final text = error.toString();
  return text.contains('CONFIGURATION_NOT_FOUND');
}

String firebaseAuthSetupMessage() {
  return 'Firebase Authentication enable nahi hai.\n\n'
      'Ye steps follow karein:\n'
      '1. console.firebase.google.com open karein\n'
      '2. Project: fixxi-f0d1c select karein\n'
      '3. Build → Authentication → Get started\n'
      '4. Sign-in method → Email/Password → Enable → Save\n'
      '5. App band karke dubara run karein';
}

String friendlyApiError(Object error) {
  if (isFirebaseAuthConfigError(error)) {
    return firebaseAuthSetupMessage();
  }

  if (error is FirebaseFunctionsException) {
    switch (error.code) {
      case 'deadline-exceeded':
        return error.message ?? 'OTP code expired. Please request a new one.';
      case 'invalid-argument':
        return error.message ?? 'Invalid OTP code';
      case 'resource-exhausted':
        return error.message ?? 'Too many attempts. Please try again later.';
      case 'not-found':
        final msg = (error.message ?? '').trim();
        if (msg.isEmpty || msg.toUpperCase() == 'NOT_FOUND') {
          return 'OTP Cloud Functions deploy nahi hui.\n\n'
              'Terminal mein ye commands run karein:\n'
              '1. cd C:\\Users\\bilaw\\AndroidStudioProjects\\fixxi\\functions\n'
              '2. Copy .env.example to .env aur Gmail App Password set karein\n'
              '3. cd .. && npx firebase-tools login\n'
              '4. npx firebase-tools deploy --only functions,firestore:rules';
        }
        return msg;
      case 'failed-precondition':
        return error.message ?? 'Email service is not configured yet.';
      case 'unavailable':
        return 'Service temporarily unavailable. Please try again.';
      default:
        return error.message ?? error.code;
    }
  }

  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password';
      case 'invalid-email':
        return 'Please enter a valid email';
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'weak-password':
        return 'Password is too weak (minimum 6 characters)';
      case 'network-request-failed':
        return 'No internet connection. Check your network and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a few minutes and try again.';
      default:
        return error.message ?? error.code;
    }
  }

  if (error is FirebaseException) {
    if (error.code == 'permission-denied') {
      return 'Permission denied. Firebase Console mein Firestore rules deploy karein '
          '(firestore.rules file project folder mein hai).';
    }
    if (error.code == 'failed-precondition') {
      return 'Database query needs setup. Please try again later.';
    }
    return error.message ?? error.code;
  }

  final text = error.toString();
  if (text.startsWith('Exception: ')) {
    return text.substring('Exception: '.length);
  }
  return text;
}
