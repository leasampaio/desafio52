import 'package:flutter/material.dart';
import '../models/challenge.dart';
import '../models/week.dart';
import '../services/challenge_service.dart';
import '../services/notification_service.dart';
import 'setup_screen.dart';
import 'edit_challenge_screen.dart';
import 'notification_settings_screen.dart';

// Cleaned up version with only essential notification functionality

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _challengeService = ChallengeService();
  Challenge? _challenge;
  bool _isLoading = true;
  bool _savingRemindersEnabled = false; // Lembrete de poupança
  int _savingReminderDayOfWeek = 7; // Domingo por padrão para poupança
  TimeOfDay _savingReminderTime = const TimeOfDay(
    hour: 18,
    minute: 0,
  ); // 18:00 por padrão para poupança

  String _formatCurrency(double value) {
    return 'R\$ ${value.toStringAsFixed(2)}';
  }

  @override
  void initState() {
    super.initState();
    _loadChallenge();
  }

  Future<void> _loadChallenge() async {
    try {
      final challenge = await _challengeService.loadChallenge();
      setState(() {
        _challenge = challenge;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleSavingReminders() async {
    // Se está ativando pela primeira vez, mostra diálogo explicativo
    if (!_savingRemindersEnabled) {
      final confirmed = await _showSavingRemindersDialog();
      if (confirmed != true) return;

      // Após confirmar, abre as configurações de horário
      final settings = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(
          builder: (context) => NotificationSettingsScreen(
            currentDayOfWeek: _savingReminderDayOfWeek,
            currentTime: _savingReminderTime,
            title: 'Configurar Lembrete de Poupança',
            subtitle: 'Escolha quando deseja ser lembrado de poupar',
          ),
        ),
      );

      if (settings != null) {
        setState(() {
          _savingReminderDayOfWeek = settings['dayOfWeek'];
          _savingReminderTime = settings['time'];
        });
      } else {
        // Se cancelou as configurações, não ativa as notificações
        return;
      }
    }

    setState(() {
      _savingRemindersEnabled = !_savingRemindersEnabled;
    });

    if (_savingRemindersEnabled) {
      try {
        await NotificationService.scheduleSavingReminderWithSchedule(
          dayOfWeek: _savingReminderDayOfWeek,
          hour: _savingReminderTime.hour,
          minute: _savingReminderTime.minute,
        );
        if (mounted) {
          final days = [
            'Segunda',
            'Terça',
            'Quarta',
            'Quinta',
            'Sexta',
            'Sábado',
            'Domingo',
          ];
          final dayName = days[_savingReminderDayOfWeek - 1];
          final timeFormatted = _savingReminderTime.format(context);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '💰 Lembretes de poupança ativados para $dayName às $timeFormatted',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '⚠️ Lembretes de poupança ativados, mas com precisão limitada',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      }
    } else {
      await NotificationService.cancelSavingReminder();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔕 Lembretes de poupança desativados!'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _configureSavingReminderSchedule() async {
    final settings = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => NotificationSettingsScreen(
          currentDayOfWeek: _savingReminderDayOfWeek,
          currentTime: _savingReminderTime,
          title: 'Configurar Lembrete de Poupança',
          subtitle: 'Escolha quando deseja ser lembrado de poupar',
        ),
      ),
    );

    if (settings != null) {
      setState(() {
        _savingReminderDayOfWeek = settings['dayOfWeek'];
        _savingReminderTime = settings['time'];
      });

      // Reagenda as notificações com as novas configurações
      if (_savingRemindersEnabled) {
        try {
          await NotificationService.cancelSavingReminder();
          await NotificationService.scheduleSavingReminderWithSchedule(
            dayOfWeek: _savingReminderDayOfWeek,
            hour: _savingReminderTime.hour,
            minute: _savingReminderTime.minute,
          );

          if (mounted) {
            final days = [
              'Segunda',
              'Terça',
              'Quarta',
              'Quinta',
              'Sexta',
              'Sábado',
              'Domingo',
            ];
            final dayName = days[_savingReminderDayOfWeek - 1];
            final timeFormatted = _savingReminderTime.format(context);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '⚙️ Lembrete de poupança atualizado para $dayName às $timeFormatted',
                ),
                backgroundColor: Colors.blue,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '⚠️ Configurações salvas, mas lembretes podem ter precisão limitada',
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }
    }
  }

  Future<bool?> _showSavingRemindersDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.savings, color: Colors.green.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Lembretes de Poupança',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Os lembretes de poupança irão:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSavingReminderFeature(
                    Icons.attach_money,
                    'Lembrar de Poupar',
                    'Te motivar a separar o dinheiro da semana atual',
                  ),
                  const SizedBox(height: 12),
                  _buildSavingReminderFeature(
                    Icons.schedule,
                    'Criar Rotina',
                    'Ajudar a estabelecer o hábito regular de poupança',
                  ),
                  const SizedBox(height: 12),
                  _buildSavingReminderFeature(
                    Icons.trending_up,
                    'Manter Disciplina',
                    'Evitar que você esqueça de fazer sua poupança semanal',
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info,
                          color: Colors.green.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Você pode configurar o dia e horário ideais para seus lembretes',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Ativar Lembretes'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSavingReminderFeature(
    IconData icon,
    String title,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: Colors.green.shade600),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _toggleWeekCompletion(Week week) async {
    if (_challenge == null) return;

    final newStatus = !week.isCompleted;
    setState(() {
      week.isCompleted = newStatus;
      week.completedDate = newStatus ? DateTime.now() : null;
    });

    await _challengeService.updateWeek(_challenge!, week.weekNumber, newStatus);

    if (newStatus) {
      await NotificationService.showWeekCompletedNotification(
        week.weekNumber,
        week.amount,
      );
      // Mostra pop-up de parabéns ao completar uma semana
      await _showWeekCompletedDialog(week);
    }

    if (_challenge!.isCompleted) {
      await NotificationService.showChallengeCompletedNotification();
      // Mostra pop-up especial para conclusão total do desafio
      await _showChallengeCompletedDialog();
    }
  }

  Future<void> _editChallenge() async {
    if (_challenge == null) return;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => EditChallengeScreen(challenge: _challenge!),
      ),
    );

    // Se houve mudança (result = true), recarrega o desafio
    if (result == true) {
      await _loadChallenge();
    }
  }

  Future<void> _resetChallenge() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resetar Desafio'),
        content: const Text(
          'Tem certeza que deseja resetar o desafio? Todo o progresso será perdido.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Resetar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _challengeService.resetChallenge();
      await NotificationService.cancelAllNotifications();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const SetupScreen()),
        );
      }
    }
  }

  Future<void> _showWeekCompletedDialog(Week week) async {
    final completedWeeks = _challenge!.completedWeeks;
    final totalSaved = _challenge!.totalSaved;
    final progressPercentage = (_challenge!.progressPercentage * 100).round();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: EdgeInsets.zero,
          content: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.green.shade50, Colors.green.shade100],
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: 48,
                    color: Colors.green.shade600,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Parabéns! 🎉',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Semana ${week.weekNumber} concluída!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Valor economizado:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              'R\$ ${week.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                              textAlign: TextAlign.end,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total economizado:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              'R\$ ${totalSaved.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                              textAlign: TextAlign.end,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progresso:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              '$completedWeeks/52 ($progressPercentage%)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                              textAlign: TextAlign.end,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Continue assim! Você está fazendo um ótimo trabalho na sua jornada de economia! 💪',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Continuar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showChallengeCompletedDialog() async {
    final totalSaved = _challenge!.totalSaved;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: EdgeInsets.zero,
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: SingleChildScrollView(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.amber.shade50, Colors.orange.shade50],
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Icon(
                        Icons.celebration,
                        size: 56,
                        color: Colors.amber.shade600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '🎊 INCRÍVEL! 🎊',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Desafio Completado!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.amber.shade200,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.savings,
                            size: 40,
                            color: Colors.amber.shade600,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Você economizou',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'R\$ ${totalSaved.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'em 52 semanas!',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Parabéns! Você demonstrou disciplina, determinação e conquistou seu objetivo! Você é um verdadeiro campeão da economia! 🏆',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: const Text(
                          'Comemorar! 🎉',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_challenge == null) {
      return const SetupScreen();
    }

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: const Text(
          'Desafio52',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade600,
        elevation: 0,
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Editar Desafio',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'saving_reminders',
                child: Row(
                  children: [
                    Icon(
                      _savingRemindersEnabled
                          ? Icons.savings
                          : Icons.savings_outlined,
                      color: _savingRemindersEnabled
                          ? Colors.green
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _savingRemindersEnabled
                            ? 'Desativar Poupança'
                            : 'Ativar Poupança',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (_savingRemindersEnabled)
                const PopupMenuItem(
                  value: 'configure_saving_reminders',
                  child: Row(
                    children: [
                      Icon(Icons.timer, color: Colors.green),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Configurar Poupança',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Resetar Desafio',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'edit') {
                _editChallenge();
              } else if (value == 'saving_reminders') {
                _toggleSavingReminders();
              } else if (value == 'configure_saving_reminders') {
                _configureSavingReminderSchedule();
              } else if (value == 'reset') {
                _resetChallenge();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProgressCard(),
            const SizedBox(height: 20),
            _buildGoalCard(),
            const SizedBox(height: 20),
            _buildWeeksList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    final progress = _challenge!.progressPercentage;
    final completedWeeks = _challenge!.completedWeeks;
    final totalSaved = _challenge!.totalSaved;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [Colors.blue.shade600, Colors.blue.shade800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Progresso Geral',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '$completedWeeks/52',
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 15),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white30,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Economizado',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                    Text(
                      _formatCurrency(totalSaved),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Meta',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                    Text(
                      _formatCurrency(_challenge!.goalAmount),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('🎯', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text(
                      //   'Seu Objetivo',
                      //   style: TextStyle(
                      //     fontSize: 14,
                      //     fontWeight: FontWeight.w500,
                      //     color: Colors.grey.shade600,
                      //   ),
                      // ),
                      const SizedBox(height: 4),
                      Text(
                        _challenge!.goalDescription,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeksList() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Colors.green.shade600,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  'Semanas do Desafio',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _challenge!.weeks.length,
              itemBuilder: (context, index) {
                final week = _challenge!.weeks[index];
                return _buildWeekTile(week);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekTile(Week week) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: week.isCompleted ? Colors.green.shade50 : Colors.grey.shade50,
        border: Border.all(
          color: week.isCompleted
              ? Colors.green.shade300
              : Colors.grey.shade300,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: week.isCompleted
                ? Colors.green.shade600
                : Colors.grey.shade400,
          ),
          child: Center(
            child: Text(
              week.weekNumber.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          'Semana ${week.weekNumber}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatCurrency(week.amount),
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            if (week.isCompleted && week.completedDate != null)
              Text(
                'Concluída em ${week.completedDate!.day.toString().padLeft(2, '0')}/${week.completedDate!.month.toString().padLeft(2, '0')}/${week.completedDate!.year}',
                style: TextStyle(fontSize: 12, color: Colors.green.shade600),
              ),
          ],
        ),
        trailing: GestureDetector(
          onTap: () => _toggleWeekCompletion(week),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: week.isCompleted
                    ? Colors.green.shade600
                    : Colors.grey.shade400,
                width: 2,
              ),
              color: week.isCompleted
                  ? Colors.green.shade600
                  : Colors.transparent,
            ),
            child: week.isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : null,
          ),
        ),
      ),
    );
  }
}
