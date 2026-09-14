import 'package:flutter/material.dart';

class OnboardingPageData {
  const OnboardingPageData({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

const List<OnboardingPageData> onboardingPages = [
  OnboardingPageData(
    icon: Icons.sports_soccer_rounded,
    title: 'PRONOSTICA',
    description: 'Dimostra quanto conosci il calcio italiano.',
  ),
  OnboardingPageData(
    icon: Icons.groups_rounded,
    title: 'SFIDA I TUOI AMICI',
    description: 'Crea una lega privata e sfida i tuoi amici.',
  ),
  OnboardingPageData(
    icon: Icons.emoji_events_rounded,
    title: 'SCALA LA CLASSIFICA',
    description: 'Accumula punti e conquista la vetta.',
  ),
];
