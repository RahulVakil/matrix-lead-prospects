/// Mock notification + email queue for the prototype.
/// In production these fire via backend push + email service. Here we
/// accumulate entries in-memory so they can be inspected in the debug panel.
class MockNotificationQueue {
  MockNotificationQueue._();

  static final List<MockNotification> inApp = [];
  static final List<MockEmail> emails = [];

  static void pushInApp({
    required String recipientId,
    required String recipientName,
    required String title,
    required String body,
    String? deepLink,
  }) {
    inApp.add(MockNotification(
      recipientId: recipientId,
      recipientName: recipientName,
      title: title,
      body: body,
      deepLink: deepLink,
      createdAt: DateTime.now(),
    ));
  }

  static void pushEmail({
    required String to,
    String? cc,
    required String subject,
    required String body,
  }) {
    emails.add(MockEmail(
      to: to,
      cc: cc,
      subject: subject,
      body: body,
      createdAt: DateTime.now(),
    ));
  }

  static void clear() {
    inApp.clear();
    emails.clear();
  }
}

class MockNotification {
  final String recipientId;
  final String recipientName;
  final String title;
  final String body;
  final String? deepLink;
  final DateTime createdAt;

  const MockNotification({
    required this.recipientId,
    required this.recipientName,
    required this.title,
    required this.body,
    this.deepLink,
    required this.createdAt,
  });
}

class MockEmail {
  final String to;
  final String? cc;
  final String subject;
  final String body;
  final DateTime createdAt;

  const MockEmail({
    required this.to,
    this.cc,
    required this.subject,
    required this.body,
    required this.createdAt,
  });
}
