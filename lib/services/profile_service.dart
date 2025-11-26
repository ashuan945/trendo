import 'package:shared_preferences/shared_preferences.dart';

class ProfileService {
  static const String _keyUserName = 'user_name';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserPhone = 'user_phone';
  static const String _keyUserAddress = 'user_address';
  static const String _keyUserProfileImage = 'user_profile_image';

  // Save profile data
  static Future<bool> saveProfile({
    required String name,
    required String email,
    String? phone,
    String? address,
    String? profileImagePath,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString(_keyUserName, name);
      await prefs.setString(_keyUserEmail, email);
      
      if (phone != null && phone.isNotEmpty) {
        await prefs.setString(_keyUserPhone, phone);
      } else {
        await prefs.remove(_keyUserPhone);
      }
      
      if (address != null && address.isNotEmpty) {
        await prefs.setString(_keyUserAddress, address);
      } else {
        await prefs.remove(_keyUserAddress);
      }
      
      if (profileImagePath != null && profileImagePath.isNotEmpty) {
        await prefs.setString(_keyUserProfileImage, profileImagePath);
      } else {
        await prefs.remove(_keyUserProfileImage);
      }
      
      return true;
    } catch (e) {
      print('Error saving profile: $e');
      return false;
    }
  }

  // Load profile data
  static Future<Map<String, String?>> loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      return {
        'name': prefs.getString(_keyUserName) ?? 'Unknown',
        'email': prefs.getString(_keyUserEmail) ?? 'unknown@example.com',
        'phone': prefs.getString(_keyUserPhone),
        'address': prefs.getString(_keyUserAddress),
        'profileImagePath': prefs.getString(_keyUserProfileImage),
      };
    } catch (e) {
      print('Error loading profile: $e');
      return {
        'name': 'Unknown',
        'email': 'unknown@example.com',
        'phone': null,
        'address': null,
        'profileImagePath': null,
      };
    }
  }

  // Clear all profile data
  static Future<bool> clearProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUserName);
      await prefs.remove(_keyUserEmail);
      await prefs.remove(_keyUserPhone);
      await prefs.remove(_keyUserAddress);
      await prefs.remove(_keyUserProfileImage);
      return true;
    } catch (e) {
      print('Error clearing profile: $e');
      return false;
    }
  }

  // Update individual field
  static Future<bool> updateField(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
      return true;
    } catch (e) {
      print('Error updating field: $e');
      return false;
    }
  }
}