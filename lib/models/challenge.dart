import 'week.dart';

class Challenge {
  final double goalAmount;
  final DateTime startDate;
  final List<Week> weeks;
  final String? goalImagePath;
  final String goalDescription;

  Challenge({
    required this.goalAmount,
    required this.startDate,
    required this.weeks,
    this.goalImagePath,
    this.goalDescription = '',
  });

  double get totalSaved {
    return weeks
        .where((week) => week.isCompleted)
        .fold(0.0, (sum, week) => sum + week.amount);
  }

  double get totalToSave {
    return weeks.fold(0.0, (sum, week) => sum + week.amount);
  }

  int get completedWeeks {
    return weeks.where((week) => week.isCompleted).length;
  }

  double get progressPercentage {
    return completedWeeks / weeks.length;
  }

  bool get isCompleted {
    return completedWeeks == weeks.length;
  }

  static List<Week> generateWeeks(double goalAmount) {
    List<Week> weeks = [];

    // Desafio tradicional: R$ 1 na semana 1, R$ 2 na semana 2, etc.
    // Total seria R$ 1.378,00 (soma de 1 a 52)
    // Mas vamos escalar para atingir a meta do usuário
    double traditionalTotal = (52 * 53) / 2; // Soma aritmética de 1 a 52 = 1378
    double scaleFactor = goalAmount / traditionalTotal;

    for (int i = 1; i <= 52; i++) {
      double amount = i * scaleFactor;
      amount = amount
          .round()
          .toDouble(); // Garante que seja sempre um número inteiro
      weeks.add(Week(weekNumber: i, amount: amount));
    }

    return weeks;
  }

  Map<String, dynamic> toMap() {
    return {
      'goalAmount': goalAmount,
      'startDate': startDate.millisecondsSinceEpoch,
      'weeks': weeks.map((week) => week.toMap()).toList(),
      'goalImagePath': goalImagePath,
      'goalDescription': goalDescription,
    };
  }

  factory Challenge.fromMap(Map<String, dynamic> map) {
    return Challenge(
      goalAmount: map['goalAmount'],
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate']),
      weeks: (map['weeks'] as List<dynamic>)
          .map((weekMap) => Week.fromMap(weekMap))
          .toList(),
      goalImagePath: map['goalImagePath'],
      goalDescription: map['goalDescription'] ?? '',
    );
  }

  Challenge copyWith({
    double? goalAmount,
    DateTime? startDate,
    List<Week>? weeks,
    String? goalImagePath,
    String? goalDescription,
  }) {
    return Challenge(
      goalAmount: goalAmount ?? this.goalAmount,
      startDate: startDate ?? this.startDate,
      weeks: weeks ?? this.weeks,
      goalImagePath: goalImagePath ?? this.goalImagePath,
      goalDescription: goalDescription ?? this.goalDescription,
    );
  }
}
