class PushNotificationService {
  /// We mock the backend request here.
  /// In a production environment, this should call your Cloud Function
  /// or backend endpoint, which will securely use the FCM HTTP v1 API.
  Future<bool> sendDriverNotificationToParent({
    required String parentId,
    required String studentName,
    required String notificationType, // e.g., 'NEAR', 'ARRIVING'
  }) async {
    try {
      String title = '';
      String body = '';

      if (notificationType == 'NEAR') {
        title = 'Bus is near!';
        body = 'The school bus for $studentName is approaching your location.';
      } else if (notificationType == 'ARRIVING') {
        title = 'Arriving in 1 minute';
        body =
            'The school bus for $studentName will arrive in approximately 1 minute.';
      }

      print('Mock API Call: Sending FCM to Parent $parentId');
      print('Title: $title');
      print('Body: $body');

      // TODO: Replace with your actual backend endpoint later
      // final response = await http.post(
      //   Uri.parse('https://your-backend.com/api/send-fcm'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: jsonEncode({
      //     'parentId': parentId,
      //     'title': title,
      //     'body': body,
      //   }),
      // );

      // if (response.statusCode == 200) return true;

      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (e) {
      print('Error sending push notification: $e');
      return false;
    }
  }
}
