import 'package:cloud_functions/cloud_functions.dart';

class EmailService {
  // Development mode: true = mock email, false = real email via Firebase
  // Set to TRUE for emulator testing (Firebase doesn't work well on emulator)
  // Set to FALSE when testing on real device
  static const bool _isDevelopmentMode = true;

  static Future<bool> sendOTP(String recipientEmail, String otp) async {
    try {
      // Development mode: just log the OTP without sending real email
      if (_isDevelopmentMode) {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('📧 [DEVELOPMENT MODE] OTP Email');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('To: $recipientEmail');
        print('OTP Code: $otp');
        print('Valid for: 5 minutes');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('✅ Mock email sent successfully!');
        print('💡 Use this OTP to verify: $otp');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        // Simulate network delay
        await Future.delayed(Duration(milliseconds: 500));
        return true;
      }

      // Production mode: send real email via Firebase Functions
      print('📧 Sending email via Firebase Functions...');
      print('To: $recipientEmail');
      print('OTP: $otp');

      final callable = FirebaseFunctions.instance.httpsCallable('sendOTP');
      final result = await callable.call({'email': recipientEmail, 'otp': otp});

      print('✅ Firebase Functions response: ${result.data}');

      if (result.data['success'] == true) {
        print('✅ Email sent successfully to $recipientEmail');
        return true;
      } else {
        print('❌ Failed to send email: ${result.data}');
        return false;
      }
    } catch (e) {
      print('❌ Error sending email: $e');

      // In development, still return true to allow testing
      if (_isDevelopmentMode) {
        print('⚠️ Email failed but continuing in dev mode');
        return true;
      }
      return false;
    }
  }
}
