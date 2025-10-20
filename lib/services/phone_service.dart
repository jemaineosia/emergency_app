import 'package:url_launcher/url_launcher.dart';

class PhoneService {
  Future<bool> makeCall(String phoneNumber) async {
    // Remove any spaces or special characters except + and digits
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    final Uri phoneUri = Uri(scheme: 'tel', path: cleanNumber);

    if (await canLaunchUrl(phoneUri)) {
      return await launchUrl(phoneUri);
    }
    return false;
  }
}
