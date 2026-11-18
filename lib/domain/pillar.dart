import 'package:flutter/material.dart';

/// 4 Pilar Atribut. Nama enum disimpan di database — jangan diubah.
enum Pillar {
  vitality('Vitality', 'Fisik', Icons.favorite_rounded, Color(0xFFFB7185)),
  intellect(
    'Intellect',
    'Kognitif',
    Icons.auto_stories_rounded,
    Color(0xFF818CF8),
  ),
  discipline('Discipline', 'Eksekusi', Icons.bolt_rounded, Color(0xFFFBBF24)),
  mindfulness('Mindfulness', 'Mental', Icons.spa_rounded, Color(0xFF2DD4BF));

  const Pillar(this.label, this.subtitle, this.icon, this.color);

  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
}
