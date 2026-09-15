import '../models/team.dart';

/// Le 20 squadre di Serie A, condivise tra [MockFootballDataService] (dati
/// demo) e l'import rapido dell'admin globale ("importa squadre Serie A"
/// nel pannello admin, vedi AdminFootballDatasource.seedTeams): un'unica
/// fonte di verità per non tenerle sincronizzate a mano in due punti.
const List<Team> serieATeams = [
  Team(
      id: 't1',
      name: 'Inter',
      shortName: 'INT',
      city: 'Milano',
      stadium: 'Stadio Giuseppe Meazza'),
  Team(
      id: 't2',
      name: 'Milan',
      shortName: 'MIL',
      city: 'Milano',
      stadium: 'Stadio Giuseppe Meazza'),
  Team(
      id: 't3',
      name: 'Juventus',
      shortName: 'JUV',
      city: 'Torino',
      stadium: 'Allianz Stadium'),
  Team(
      id: 't4',
      name: 'Napoli',
      shortName: 'NAP',
      city: 'Napoli',
      stadium: 'Stadio Diego Armando Maradona'),
  Team(
      id: 't5',
      name: 'Roma',
      shortName: 'ROM',
      city: 'Roma',
      stadium: 'Stadio Olimpico'),
  Team(
      id: 't6',
      name: 'Lazio',
      shortName: 'LAZ',
      city: 'Roma',
      stadium: 'Stadio Olimpico'),
  Team(
      id: 't7',
      name: 'Atalanta',
      shortName: 'ATA',
      city: 'Bergamo',
      stadium: 'Gewiss Stadium'),
  Team(
      id: 't8',
      name: 'Fiorentina',
      shortName: 'FIO',
      city: 'Firenze',
      stadium: 'Stadio Artemio Franchi'),
  Team(
      id: 't9',
      name: 'Bologna',
      shortName: 'BOL',
      city: 'Bologna',
      stadium: "Stadio Renato Dall'Ara"),
  Team(
      id: 't10',
      name: 'Torino',
      shortName: 'TOR',
      city: 'Torino',
      stadium: 'Stadio Olimpico Grande Torino'),
  Team(
      id: 't11',
      name: 'Udinese',
      shortName: 'UDI',
      city: 'Udine',
      stadium: 'Bluenergy Stadium'),
  Team(
      id: 't12',
      name: 'Sassuolo',
      shortName: 'SAS',
      city: 'Sassuolo',
      stadium: 'Mapei Stadium'),
  Team(
      id: 't13',
      name: 'Empoli',
      shortName: 'EMP',
      city: 'Empoli',
      stadium: 'Stadio Carlo Castellani'),
  Team(
      id: 't14',
      name: 'Salernitana',
      shortName: 'SAL',
      city: 'Salerno',
      stadium: 'Stadio Arechi'),
  Team(
      id: 't15',
      name: 'Genoa',
      shortName: 'GEN',
      city: 'Genova',
      stadium: 'Stadio Luigi Ferraris'),
  Team(
      id: 't16',
      name: 'Cagliari',
      shortName: 'CAG',
      city: 'Cagliari',
      stadium: 'Unipol Domus'),
  Team(
      id: 't17',
      name: 'Hellas Verona',
      shortName: 'VER',
      city: 'Verona',
      stadium: 'Stadio Marcantonio Bentegodi'),
  Team(
      id: 't18',
      name: 'Lecce',
      shortName: 'LEC',
      city: 'Lecce',
      stadium: 'Stadio Via del Mare'),
  Team(
      id: 't19',
      name: 'Parma',
      shortName: 'PAR',
      city: 'Parma',
      stadium: 'Stadio Ennio Tardini'),
  Team(
      id: 't20',
      name: 'Monza',
      shortName: 'MON',
      city: 'Monza',
      stadium: 'U-Power Stadium'),
];
