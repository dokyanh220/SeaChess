import 'package:flutter_riverpod/legacy.dart';

class MatchState {
  final String matchId;
  final String fen;
  final String myColor;

  MatchState({this.matchId = '', this.fen = '', this.myColor = ''});

  MatchState coppyWith({String? matchId, String? fen, String? myColor}) {
    return MatchState(
      matchId: matchId ?? this.matchId,
      fen: fen ?? this.fen,
      myColor: myColor ?? this.myColor,
    );
  }
}

class MatchStateNotifier extends StateNotifier<MatchState> {
  MatchStateNotifier() : super(MatchState());

  void initMatch(String id, String fen, String color) {
    state = MatchState(matchId: id, fen: fen, myColor: color);
  }

  void updateFen(String newFen) {
    state = state.coppyWith(fen: newFen);
  }
}

final matchStateProvider =
    StateNotifierProvider<MatchStateNotifier, MatchState>((ref) {
      return MatchStateNotifier();
    });
