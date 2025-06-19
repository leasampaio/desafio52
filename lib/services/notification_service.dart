import 'package:flutter/foundation.dart';

class NotificationService {
  static Future<void> initialize() async {
    // Simplified initialization for demo
    if (kDebugMode) {
      print('NotificationService initialized');
    }
  }

  static Future<void> scheduleWeeklyReminder() async {
    // Simplified reminder setup for demo
    if (kDebugMode) {
      print('Weekly reminder scheduled');
    }
  }

  static Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    // Show notification in console for demo
    if (kDebugMode) {
      print('NOTIFICATION: $title - $body');
    }
  }

  static Future<void> cancelAllNotifications() async {
    // Cancel notifications for demo
    if (kDebugMode) {
      print('All notifications cancelled');
    }
  }

  static Future<void> showChallengeCompletedNotification() async {
    await showInstantNotification(
      title: 'Parabéns! Desafio52 Concluído! 🎉',
      body: 'Você completou o desafio de 52 semanas! Sua disciplina financeira é incrível!',
    );
  }

  static Future<void> showWeekCompletedNotification(int weekNumber, double amount) async {
    await showInstantNotification(
      title: 'Semana $weekNumber Concluída! ✅',
      body: 'Você economizou R\$ ${amount.toStringAsFixed(2)} esta semana. Continue assim!',
    );
  }
} 