class Week {
  final int weekNumber;
  final double amount;
  bool isCompleted;
  DateTime? completedDate;

  Week({
    required this.weekNumber,
    required this.amount,
    this.isCompleted = false,
    this.completedDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'weekNumber': weekNumber,
      'amount': amount,
      'isCompleted': isCompleted,
      'completedDate': completedDate?.millisecondsSinceEpoch,
    };
  }

  factory Week.fromMap(Map<String, dynamic> map) {
    return Week(
      weekNumber: map['weekNumber'],
      amount: map['amount'],
      isCompleted: map['isCompleted'] ?? false,
      completedDate: map['completedDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['completedDate'])
          : null,
    );
  }

  Week copyWith({
    int? weekNumber,
    double? amount,
    bool? isCompleted,
    DateTime? completedDate,
  }) {
    return Week(
      weekNumber: weekNumber ?? this.weekNumber,
      amount: amount ?? this.amount,
      isCompleted: isCompleted ?? this.isCompleted,
      completedDate: completedDate ?? this.completedDate,
    );
  }
} 