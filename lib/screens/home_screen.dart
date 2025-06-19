import 'package:flutter/material.dart';
import '../models/challenge.dart';
import '../models/week.dart';
import '../services/challenge_service.dart';
import '../services/notification_service.dart';
import 'setup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _challengeService = ChallengeService();
  Challenge? _challenge;
  bool _isLoading = true;

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
    }

    if (_challenge!.isCompleted) {
      await NotificationService.showChallengeCompletedNotification();
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_challenge == null) {
      return const SetupScreen();
    }

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: const Text(
          'Desafio52',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue.shade600,
        elevation: 0,
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Resetar Desafio'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'reset') {
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
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
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
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
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
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
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.flag,
                  color: Colors.orange.shade600,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  'Seu Objetivo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              _challenge!.goalDescription,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildWeeksList() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
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
        color: week.isCompleted 
            ? Colors.green.shade50 
            : Colors.grey.shade50,
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
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            if (week.isCompleted && week.completedDate != null)
              Text(
                'Concluída em ${week.completedDate!.day.toString().padLeft(2, '0')}/${week.completedDate!.month.toString().padLeft(2, '0')}/${week.completedDate!.year}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green.shade600,
                ),
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
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
