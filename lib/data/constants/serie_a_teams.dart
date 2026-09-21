import '../models/team.dart';

/// Le 20 squadre di Serie A 2026/27, condivise tra [MockFootballDataService]
/// (dati demo) e l'import rapido dell'admin globale ("importa squadre Serie A"
/// nel pannello admin, vedi AdminFootballDatasource.seedTeams): un'unica
/// fonte di verità per non tenerle sincronizzate a mano in due punti.
///
/// Aggiornata a inizio stagione 2026/27 (promosse dalla Serie B: Frosinone,
/// Monza, Venezia; retrocesse: Cremonese, Pisa, Hellas Verona) — se cambia
/// la composizione del campionato, questo è l'unico file da aggiornare.
const List<Team> serieATeams = [
  Team(
      id: 't1',
      name: 'Atalanta',
      shortName: 'ATA',
      city: 'Bergamo',
      stadium: "Stadio Atleti Azzurri d'Italia"),
  Team(
      id: 't2',
      name: 'Bologna',
      shortName: 'BOL',
      city: 'Bologna',
      stadium: "Stadio Renato Dall'Ara"),
  Team(
      id: 't3',
      name: 'Cagliari',
      shortName: 'CAG',
      city: 'Cagliari',
      stadium: 'Stadio Sant\'Elia'),
  Team(
      id: 't4',
      name: 'Como',
      shortName: 'COM',
      city: 'Como',
      stadium: 'Stadio Giuseppe Sinigaglia'),
  Team(
      id: 't5',
      name: 'Fiorentina',
      shortName: 'FIO',
      city: 'Firenze',
      stadium: 'Stadio Artemio Franchi'),
  Team(
      id: 't6',
      name: 'Frosinone',
      shortName: 'FRO',
      city: 'Frosinone',
      stadium: 'Stadio Benito Stirpe'),
  Team(
      id: 't7',
      name: 'Genoa',
      shortName: 'GEN',
      city: 'Genova',
      stadium: 'Stadio Luigi Ferraris'),
  Team(
      id: 't8',
      name: 'Inter',
      shortName: 'INT',
      city: 'Milano',
      stadium: 'Stadio Giuseppe Meazza'),
  Team(
      id: 't9',
      name: 'Juventus',
      shortName: 'JUV',
      city: 'Torino',
      stadium: 'Allianz Stadium'),
  Team(
      id: 't10',
      name: 'Lazio',
      shortName: 'LAZ',
      city: 'Roma',
      stadium: 'Stadio Olimpico'),
  Team(
      id: 't11',
      name: 'Lecce',
      shortName: 'LEC',
      city: 'Lecce',
      stadium: 'Stadio Via del Mare'),
  Team(
      id: 't12',
      name: 'Milan',
      shortName: 'MIL',
      city: 'Milano',
      stadium: 'Stadio Giuseppe Meazza'),
  Team(
      id: 't13',
      name: 'Monza',
      shortName: 'MON',
      city: 'Monza',
      stadium: 'Stadio Brianteo'),
  Team(
      id: 't14',
      name: 'Napoli',
      shortName: 'NAP',
      city: 'Napoli',
      stadium: 'Stadio Diego Armando Maradona'),
  Team(
      id: 't15',
      name: 'Parma',
      shortName: 'PAR',
      city: 'Parma',
      stadium: 'Stadio Ennio Tardini'),
  Team(
      id: 't16',
      name: 'Roma',
      shortName: 'ROM',
      city: 'Roma',
      stadium: 'Stadio Olimpico'),
  Team(
      id: 't17',
      name: 'Sassuolo',
      shortName: 'SAS',
      city: 'Reggio Emilia',
      stadium: 'Mapei Stadium'),
  Team(
      id: 't18',
      name: 'Torino',
      shortName: 'TOR',
      city: 'Torino',
      stadium: 'Stadio Olimpico Grande Torino'),
  Team(
      id: 't19',
      name: 'Udinese',
      shortName: 'UDI',
      city: 'Udine',
      stadium: 'Bluenergy Stadium'),
  Team(
      id: 't20',
      name: 'Venezia',
      shortName: 'VEN',
      city: 'Venezia',
      stadium: 'Stadio Pier Luigi Penzo'),
];
