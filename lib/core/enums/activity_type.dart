import 'package:flutter/material.dart';

enum ActivityType {
  call('Call', Icons.phone, 'Connected call with prospect'),
  meeting('Meeting', Icons.calendar_today, 'In-person or video meeting'),
  note('Note', Icons.note_alt_outlined, 'Internal note or observation'),
  whatsApp('WhatsApp', Icons.chat, 'WhatsApp message sent'),
  email('Email', Icons.email_outlined, 'Email sent or received'),
  task('Task', Icons.check_circle_outline, 'Follow-up task completed'),
  system('System', Icons.settings, 'System-generated activity');

  final String label;
  final IconData icon;
  final String description;

  const ActivityType(this.label, this.icon, this.description);
}

enum ActivityOutcome {
  connected('Connected', true),
  noAnswer('No Answer', false),
  voicemail('Voicemail', false),
  interested('Interested', true),
  followUp('Follow-up Needed', true),
  notInterested('Not Interested', false),
  completed('Completed', true),
  cancelled('Cancelled', false);

  final String label;
  final bool isPositive;

  const ActivityOutcome(this.label, this.isPositive);
}
