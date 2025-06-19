import '../models/challenge.dart';
import '../models/week.dart';

class ChallengeService {
  static Challenge? _currentChallenge;
  static bool _hasActiveChallenge = false;

  Future<void> saveChallenge(Challenge challenge) async {
    _currentChallenge = challenge;
    _hasActiveChallenge = true;
  }

  Future<Challenge?> loadChallenge() async {
    return _currentChallenge;
  }

  Future<bool> hasActiveChallenge() async {
    return _hasActiveChallenge;
  }

  Future<void> updateWeek(Challenge challenge, int weekNumber, bool isCompleted) async {
    final weekIndex = challenge.weeks.indexWhere((week) => week.weekNumber == weekNumber);
    if (weekIndex != -1) {
      challenge.weeks[weekIndex] = challenge.weeks[weekIndex].copyWith(
        isCompleted: isCompleted,
        completedDate: isCompleted ? DateTime.now() : null,
      );
      await saveChallenge(challenge);
    }
  }

  Future<void> resetChallenge() async {
    _currentChallenge = null;
    _hasActiveChallenge = false;
  }

  Future<Challenge> createNewChallenge({
    required double goalAmount,
    required String goalDescription,
    String? goalImagePath,
  }) async {
    final challenge = Challenge(
      goalAmount: goalAmount,
      startDate: DateTime.now(),
      weeks: Challenge.generateWeeks(goalAmount),
      goalImagePath: goalImagePath,
      goalDescription: goalDescription,
    );
    
    await saveChallenge(challenge);
    return challenge;
  }

  Future<void> updateGoalImage(Challenge challenge, String? imagePath) async {
    final updatedChallenge = challenge.copyWith(goalImagePath: imagePath);
    await saveChallenge(updatedChallenge);
  }
} 