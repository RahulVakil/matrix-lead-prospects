import 'package:flutter/material.dart';

enum NextActionType {
  callback('Callback', Icons.phone_callback, 'Schedule a call back'),
  meeting('Meeting', Icons.event, 'Schedule a meeting'),
  sendProposal('Send Proposal', Icons.description, 'Share a proposal document'),
  sendDocs('Send Docs', Icons.attach_file, 'Share supporting documents'),
  waitForClient('Wait for Client', Icons.hourglass_empty, 'Awaiting client response'),
  none('None', Icons.do_disturb_on_outlined, 'No follow-up required');

  final String label;
  final IconData icon;
  final String description;

  const NextActionType(this.label, this.icon, this.description);
}
