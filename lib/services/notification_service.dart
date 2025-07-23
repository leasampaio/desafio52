import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin
  _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    try {
      if (kDebugMode) {
        print('=== INICIANDO NOTIFICATION SERVICE ===');
      }

      tz.initializeTimeZones();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
          );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (kDebugMode) {
            print('Notificação clicada: ${response.payload}');
          }
        },
      );

      final androidImplementation = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
        await androidImplementation.requestExactAlarmsPermission();
      }

      await _createNotificationChannels();

      if (kDebugMode) {
        print('✅ NotificationService inicializado com sucesso');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao inicializar NotificationService: $e');
      }
    }
  }

  static Future<void> _createNotificationChannels() async {
    try {
      const List<AndroidNotificationChannel> channels = [
        AndroidNotificationChannel(
          'instant_notification_channel',
          'Notificações Instantâneas',
          description: 'Notificações que aparecem imediatamente',
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
        ),
        AndroidNotificationChannel(
          'saving_reminder_channel',
          'Lembretes de Poupança',
          description: 'Lembretes para poupar dinheiro semanalmente',
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
        ),
      ];

      final androidImplementation = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation != null) {
        for (final channel in channels) {
          await androidImplementation.createNotificationChannel(channel);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao criar canais: $e');
      }
    }
  }

  static tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    return tz.TZDateTime.from(dateTime, tz.getLocation('America/Sao_Paulo'));
  }

  static Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'instant_notification_channel',
            'Notificações Instantâneas',
            channelDescription: 'Notificações que aparecem imediatamente',
            importance: Importance.max,
            priority: Priority.max,
            icon: '@mipmap/ic_launcher',
            enableVibration: true,
            playSound: true,
            autoCancel: false,
          );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );

      if (kDebugMode) {
        print('✅ Notificação instantânea enviada: $title');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao enviar notificação instantânea: $e');
      }
      rethrow;
    }
  }

  static Future<void> scheduleSavingReminderWithSchedule({
    required int dayOfWeek,
    required int hour,
    required int minute,
  }) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(1000);

      final now = DateTime.now();
      DateTime nextNotification = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      int daysToAdd = (dayOfWeek - now.weekday) % 7;
      if (daysToAdd == 0 && nextNotification.isBefore(now)) {
        daysToAdd = 7;
      }
      nextNotification = nextNotification.add(Duration(days: daysToAdd));

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'saving_reminder_channel',
            'Lembretes de Poupança',
            channelDescription: 'Lembretes para poupar dinheiro semanalmente',
            importance: Importance.max,
            priority: Priority.max,
            icon: '@mipmap/ic_launcher',
            enableVibration: true,
            playSound: true,
            autoCancel: false,
          );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      try {
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          1000,
          '💰 Hora de Poupar!',
          'Não esqueça de separar o dinheiro desta semana para seu desafio!',
          _convertToTZDateTime(nextNotification),
          platformChannelSpecifics,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      } catch (e) {
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          1000,
          '💰 Hora de Poupar!',
          'Não esqueça de separar o dinheiro desta semana para seu desafio!',
          _convertToTZDateTime(nextNotification),
          platformChannelSpecifics,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao agendar lembrete de poupança: $e');
      }
      rethrow;
    }
  }

  static Future<void> cancelSavingReminder() async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(1000);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao cancelar lembrete: $e');
      }
    }
  }

  static Future<void> showWeekCompletedNotification(
    int weekNumber,
    double amount,
  ) async {
    await showInstantNotification(
      title: 'Semana $weekNumber Concluída! ✅',
      body:
          'Você economizou R\$ ${amount.toStringAsFixed(2)} esta semana. Continue assim!',
    );
  }

  static Future<void> showChallengeCompletedNotification() async {
    await showInstantNotification(
      title: '🎉 DESAFIO COMPLETADO! 🎉',
      body: 'Parabéns! Você concluiu todas as 52 semanas do desafio!',
    );
  }

  static Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao cancelar notificações: $e');
      }
    }
  }
}
