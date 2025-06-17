import 'package:url_launcher/url_launcher.dart';

class PhoneService {
  // Method to make a phone call
  static Future<void> makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      throw 'Could not launch phone call to $phoneNumber';
    }
  }
  
  // Method to send SMS
  static Future<void> sendSMS(String phoneNumber, [String? message]) async {
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: message != null ? {'body': message} : null,
    );
    
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      throw 'Could not launch SMS to $phoneNumber';
    }
  }
  
  // Method to open WhatsApp chat
  static Future<void> openWhatsApp(String phoneNumber, [String? message]) async {
    final Uri whatsappUri = Uri.parse(
      'https://wa.me/$phoneNumber${message != null ? '?text=${Uri.encodeComponent(message)}' : ''}'
    );
    
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch WhatsApp for $phoneNumber';
    }
  }
}