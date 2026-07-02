import 'package:flutter/material.dart';

class JourneyPresentationData {
  const JourneyPresentationData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
}
