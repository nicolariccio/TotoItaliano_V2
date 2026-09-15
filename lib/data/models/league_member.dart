import 'package:freezed_annotation/freezed_annotation.dart';

part 'league_member.freezed.dart';

enum LeagueMemberRole { owner, member }

/// Membro di una lega, in `leagues/{leagueId}/members/{userId}`.
///
/// `username`/`photoUrl` sono denormalizzati dal profilo utente al momento
/// dell'adesione, per poter mostrare la classifica di lega senza una
/// lettura per ogni membro. Possono disallinearsi se l'utente cambia
/// username/avatar dopo l'adesione — accettabile per l'MVP.
@freezed
abstract class LeagueMember with _$LeagueMember {
  const factory LeagueMember({
    required String userId,
    required String leagueId,
    required String username,
    String? photoUrl,
    required DateTime joinedAt,
    @Default(LeagueMemberRole.member) LeagueMemberRole role,
    @Default(0) int totalPoints,
    // Esito (corretto/sbagliato) degli ultimi pronostici segnati, più
    // recente per primo, al massimo 5 — quanto basta per la striscia
    // "ultimi 5" in classifica. Denormalizzato qui (non ricavato da una
    // query su `predictions`) perché le Security Rules non permettono a un
    // membro di leggere i pronostici di un altro: solo il riepilogo
    // aggregato è pubblico, non le scelte partita per partita altrui.
    @Default(<bool>[]) List<bool> last5,
    // Conteggio pronostici a risultato esatto indovinati in questa lega.
    @Default(0) int exactCount,
  }) = _LeagueMember;
}
