import 'package:cricket/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('player data round-trips through JSON', () {
    const PlayerData original = PlayerData(coins: 420, games: 3, totalScore: 96, shots: 36, hits: 20, unlockedBats: <int>{0, 1});
    final PlayerData restored = PlayerData.decode(original.encode());
    expect(restored.coins, 420);
    expect(restored.averageScore, 32);
    expect(restored.unlockedBats, <int>{0, 1});
  });
}
