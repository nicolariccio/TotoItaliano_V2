/// Rappresentazione UI-safe di un errore.
///
/// Ogni repository/service converte le eccezioni tecniche (FirebaseException,
/// SocketException, ecc.) in un [Failure] con un messaggio pensato per
/// l'utente finale. Nessuno stack trace o messaggio tecnico deve raggiungere
/// la UI: vedi [AppExceptionMapper].
sealed class Failure {
  const Failure(this.message);

  final String message;
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Connessione assente. Riprova.']);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure(
      [super.message = 'La richiesta ha impiegato troppo tempo. Riprova.']);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class NotAuthenticatedFailure extends Failure {
  const NotAuthenticatedFailure(
      [super.message = 'Devi effettuare l\'accesso per continuare.']);
}

class NotAuthorizedFailure extends Failure {
  const NotAuthorizedFailure(
      [super.message = 'Non hai i permessi per questa operazione.']);
}

class PredictionLockedFailure extends Failure {
  const PredictionLockedFailure(
      [super.message = 'I pronostici per questa partita sono chiusi.']);
}

class MatchAlreadyStartedFailure extends Failure {
  const MatchAlreadyStartedFailure(
      [super.message = 'La partita è già iniziata.']);
}

class LeagueNotFoundFailure extends Failure {
  const LeagueNotFoundFailure([super.message = 'Codice lega non valido.']);
}

class InvalidReferralFailure extends Failure {
  const InvalidReferralFailure([super.message = 'Codice referral non valido.']);
}

class CompetitionClosedFailure extends Failure {
  const CompetitionClosedFailure(
      [super.message = 'Questa competizione non è più attiva.']);
}

class PaymentFailure extends Failure {
  const PaymentFailure([super.message = 'Pagamento non riuscito. Riprova.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class ServerFailure extends Failure {
  const ServerFailure(
      [super.message = 'Qualcosa è andato storto. Riprova più tardi.']);
}

class UnknownFailure extends Failure {
  const UnknownFailure(
      [super.message = 'Errore imprevisto. Riprova più tardi.']);
}
