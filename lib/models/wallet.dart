import 'package:flutter/material.dart';

class Wallet {
  final int id;
  final String name;
  final String type; // cash, bank, emoney, other
  final String typeLabel;
  final double initialBalance;
  final double currentBalance;
  final String color;
  final String icon;
  final bool isArchived;
  final DateTime? createdAt;

  Wallet({
    required this.id,
    required this.name,
    required this.type,
    required this.typeLabel,
    required this.initialBalance,
    required this.currentBalance,
    required this.color,
    required this.icon,
    required this.isArchived,
    this.createdAt,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? 'Dompet',
      type: json['type']?.toString() ?? 'cash',
      typeLabel: json['type_label']?.toString() ?? 'Tunai',
      initialBalance: (json['initial_balance'] is num)
          ? (json['initial_balance'] as num).toDouble()
          : double.tryParse(json['initial_balance']?.toString() ?? '0') ?? 0.0,
      currentBalance: (json['current_balance'] is num)
          ? (json['current_balance'] as num).toDouble()
          : double.tryParse(json['current_balance']?.toString() ?? '0') ?? 0.0,
      color: json['color']?.toString() ?? '#10B981',
      icon: json['icon']?.toString() ?? 'cash',
      isArchived: json['is_archived'] == true || json['is_archived'] == 1,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'type_label': typeLabel,
      'initial_balance': initialBalance,
      'current_balance': currentBalance,
      'color': color,
      'icon': icon,
      'is_archived': isArchived,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  Color get parsedColor {
    try {
      String hex = color.replaceAll('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return const Color(0xFF10B981);
    }
  }

  IconData get iconData {
    switch (type.toLowerCase()) {
      case 'bank':
        return Icons.account_balance_rounded;
      case 'emoney':
        return Icons.account_balance_wallet_rounded;
      case 'other':
        return Icons.category_rounded;
      case 'cash':
      default:
        return Icons.payments_rounded;
    }
  }
}
