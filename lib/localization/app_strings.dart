import '../models/player.dart';
import '../providers/game_provider.dart';

class AppStrings {
  final AppLanguage language;

  const AppStrings(this.language);

  bool get isFr => language == AppLanguage.fr;

  String get appTitle => 'Undercover';
  String get playerManagement =>
      isFr ? 'Gestion des joueurs' : 'Manage players';
  String get statistics => isFr ? 'Statistiques' : 'Statistics';
  String get wordPacks => isFr ? 'Packs de mots' : 'Word packs';
  String get importWordPack => isFr ? 'Importer un pack' : 'Import a pack';
  String get noCustomPacks =>
      isFr ? 'Aucun pack additionnel importé' : 'No additional pack imported';
  String importPackSuccess(String name, int count) => isFr
      ? 'Pack "$name" importé avec $count paire(s).'
      : 'Pack "$name" imported with $count pair(s).';
  String importPackFailure(String message) => isFr
      ? "Impossible d'importer ce pack : $message"
      : 'Could not import this pack: $message';
  String get deletePack => isFr ? 'Supprimer ce pack' : 'Delete this pack';
  String get importedPacks => isFr ? 'Packs importés' : 'Imported packs';
  String pairsCount(int count) => isFr ? '$count paire(s)' : '$count pair(s)';
  String get menu => isFr ? 'Menu' : 'Menu';
  String get playerCount => isFr ? 'Nombre de joueurs' : 'Number of players';
  String get players => isFr ? 'joueurs' : 'players';
  String get difficulty => isFr ? 'Difficulté' : 'Difficulty';
  String get easy => isFr ? 'Facile' : 'Easy';
  String get hard => isFr ? 'Difficile' : 'Hard';
  String get start => isFr ? 'Commencer' : 'Start';
  String get citizens => isFr ? 'Civils' : 'Citizens';
  String get citizen => isFr ? 'Civil' : 'Citizen';
  String get undercovers => 'Undercover';
  String get mrWhite => 'Mr White';
  String get choosePlayers => isFr ? 'Choix des joueurs' : 'Choose players';
  String get gameOrder => isFr ? "Joueurs de la manche" : "Round players";
  String get tableOrderHint => isFr
      ? "L'ordre de jeu sera tiré au sort au lancement."
      : "Playing order will be randomized at launch.";
  String get newPlayerName =>
      isFr ? 'Nom du nouveau joueur' : 'New player name';
  String get add => isFr ? 'Ajouter' : 'Add';
  String get noRegisteredPlayers =>
      isFr ? 'Aucun joueur enregistré' : 'No saved players';
  String get removeFromGame =>
      isFr ? 'Retirer de cette partie' : 'Remove from this game';
  String get launchRound => isFr ? 'Lancer la manche' : 'Start round';
  String selectMorePlayers(int count) => isFr
      ? 'Sélectionnez encore $count joueur(s)'
      : 'Select $count more player(s)';
  String get maxPlayers => isFr ? '14 joueurs maximum' : '14 players maximum';
  String playersCount(int count) => isFr ? '$count joueurs' : '$count players';
  String get newRoleDistribution =>
      isFr ? 'Nouvelle répartition des rôles :' : 'New role distribution:';
  String get cancel => isFr ? 'Annuler' : 'Cancel';
  String get roleDiscovery => isFr ? 'Découverte du rôle' : 'Role reveal';
  String playerProgress(int current, int total) =>
      isFr ? 'Joueur $current sur $total' : 'Player $current of $total';
  String get revealRoleHint => isFr
      ? 'Appuyez sur le bouton pour voir votre rôle.\nAssurez-vous que les autres joueurs ne regardent pas.'
      : 'Press the button to see your role.\nMake sure the other players are not looking.';
  String get revealMyRole => isFr ? 'Révéler mon rôle' : 'Reveal my role';
  String get yourRole => isFr ? 'Votre rôle :' : 'Your role:';
  String get yourWord => isFr ? 'Votre mot :' : 'Your word:';
  String get noWord => isFr ? "Vous n'avez pas de mot." : 'You have no word.';
  String get nextPlayer => isFr ? 'Joueur suivant' : 'Next player';
  String get roundInProgress => isFr ? 'Manche en cours' : 'Round in progress';
  String roundNumber(int round) => isFr ? 'Tour $round' : 'Turn $round';
  String get votePrompt => isFr
      ? 'Sélectionnez le joueur éliminé par le vote à main levée.'
      : 'Select the player eliminated by the vote.';
  String get discussWord => isFr
      ? "Discutez de votre mot dans l'ordre affiché. "
      : 'Discuss your word in the displayed order. ';
  String get firstPlayer => isFr ? 'Premier joueur : ' : 'First player: ';
  String get passToVote => isFr ? 'Passer au vote' : 'Go to vote';
  String get confirmElimination =>
      isFr ? "Confirmer l'élimination" : 'Confirm elimination';
  String eliminatedQuestion(String name) =>
      isFr ? '$name a bien été éliminé ?' : 'Was $name eliminated?';
  String get confirm => isFr ? 'Confirmer' : 'Confirm';
  String get eliminationResult =>
      isFr ? "Résultat de l'élimination" : 'Elimination result';
  String eliminatedSentence(String name) =>
      isFr ? '$name a été éliminé.' : '$name was eliminated.';
  String roleLabel(String role) => isFr ? 'Rôle : $role' : 'Role: $role';
  String get continueText => isFr ? 'Continuer' : 'Continue';
  String get mrWhiteGuessTitle =>
      isFr ? 'Proposition de Mr White' : 'Mr White guess';
  String get mrWhiteGuessPrompt => isFr
      ? 'Mr White doit deviner le mot des civils.'
      : 'Mr White must guess the citizens’ word.';
  String mrWhiteGuessLabel(String name) =>
      isFr ? 'Proposition de $name' : "$name's guess";
  String get everyMrWhiteMustGuess => isFr
      ? 'Chaque Mr White doit proposer un mot.'
      : 'Every Mr White must enter a word.';
  String get submit => isFr ? 'Valider' : 'Submit';
  String get viewSummary => isFr ? 'Voir le résumé' : 'View summary';
  String get correctAnswer => isFr ? 'Bonne réponse !' : 'Correct answer!';
  String get wrongAnswer => isFr ? 'Mauvaise réponse' : 'Wrong answer';
  String get mrWhiteFoundWord => isFr
      ? 'Mr White a trouvé le mot des civils.'
      : 'Mr White found the citizens’ word.';
  String get mrWhiteMissedWord => isFr
      ? "Mr White n'a pas trouvé le mot des civils."
      : 'Mr White did not find the citizens’ word.';
  String get roundSummary => isFr ? 'Résumé de la manche' : 'Round summary';
  String get citizenPoints => isFr ? 'Points des civils' : 'Citizen points';
  String get undercoverPoints =>
      isFr ? 'Points des Undercover' : 'Undercover points';
  String get mrWhitePoints => isFr ? 'Points de Mr White' : 'Mr White points';
  String mrWhiteFoundBy(String names) => isFr
      ? 'Mr White a trouvé le mot : $names'
      : 'Mr White found the word: $names';
  String get leaderboard => isFr ? 'Classement' : 'Leaderboard';
  String points(int points) => isFr ? '$points pt(s)' : '$points pt(s)';
  String roundPoints(int points) =>
      isFr ? 'Cette manche : +$points' : 'This round: +$points';
  String get nextRound => isFr ? 'Manche suivante' : 'Next round';
  String get stopGame => isFr ? 'Arrêter la partie' : 'End game';
  String get savedPlayers => isFr ? 'Joueurs enregistrés' : 'Saved players';
  String get playerName => isFr ? 'Nom du joueur' : 'Player name';
  String get deletePermanently =>
      isFr ? 'Supprimer définitivement' : 'Delete permanently';
  String get resetStatistics =>
      isFr ? 'Réinitialiser les statistiques' : 'Reset statistics';
  String get resetStatisticsMessage => isFr
      ? 'Toutes les statistiques et le dernier classement seront effacés.'
      : 'All statistics and the last leaderboard will be erased.';
  String get reset => isFr ? 'Réinitialiser' : 'Reset';
  String get noLastLeaderboard => isFr
      ? "Aucun classement final enregistré pour l'instant."
      : 'No final leaderboard saved yet.';
  String get statsPlayersTab => isFr ? 'Joueurs' : 'Players';
  String statsSummary(int rounds, int wins, int rate) => isFr
      ? '$rounds manche(s), $wins victoire(s), $rate% de réussite'
      : '$rounds round(s), $wins win(s), $rate% win rate';
  String statLine(int played, int won) =>
      isFr ? '$played jouée(s) / $won gagnée(s)' : '$played played / $won won';
  String get wordsGuessedAsMrWhite =>
      isFr ? 'Mots devinés en Mr White' : 'Words guessed as Mr White';
  String get createWordPack => isFr ? "Créer un pack" : 'Create a pack';
  String get createWordPackTitle =>
      isFr ? "Nouveau pack de mots" : 'New word pack';
  String get packName => isFr ? 'Nom du pack' : 'Pack name';
  String get civilWord => isFr ? 'Mot civil' : 'Civil word';
  String get undercoverWord => isFr ? 'Mot undercover' : 'Undercover word';
  String get addPair => isFr ? 'Ajouter' : 'Add pair';
  String get savePack => isFr ? 'Sauvegarder le pack' : 'Save pack';
  String get noPairsYet =>
      isFr ? 'Aucune paire ajoutée' : 'No pairs added yet';
  String get packNameRequired =>
      isFr ? 'Donnez un nom au pack.' : 'Pack name is required.';
  String get atLeastOnePair => isFr
      ? 'Ajoutez au moins une paire de mots.'
      : 'Add at least one word pair.';
  String get sharePack => isFr ? 'Partager ce pack' : 'Share this pack';
  String sharePackSubject(String name) =>
      isFr ? 'Pack Undercover : $name' : 'Undercover pack: $name';
  String sharePackHeader(String name, int count, String lang, String diff) =>
      isFr
      ? 'Pack Undercover : "$name"\n$count paires | $lang | $diff\nDestinataire : groodep@yahoo.fr'
      : 'Undercover pack: "$name"\n$count pairs | $lang | $diff\nRecipient: groodep@yahoo.fr';
  String winnerMessage(WinningTeam? winner) => switch ((winner, isFr)) {
    (WinningTeam.citizens, true) => 'Les civils gagnent !',
    (WinningTeam.undercovers, true) => 'Les Undercover gagnent !',
    (WinningTeam.mrWhite, true) => 'Mr White gagne !',
    (WinningTeam.citizens, false) => 'Citizens win!',
    (WinningTeam.undercovers, false) => 'Undercovers win!',
    (WinningTeam.mrWhite, false) => 'Mr White wins!',
    (null, _) => '',
  };

  String roleNameLabel(PlayerRole? role) => switch ((role, isFr)) {
    (PlayerRole.citizen, true) => 'Civil',
    (PlayerRole.citizen, false) => 'Citizen',
    (PlayerRole.undercover, _) => 'Undercover',
    (PlayerRole.mrWhite, _) => 'Mr White',
    (null, true) => 'Inconnu',
    (null, false) => 'Unknown',
  };

  String eliminationOutcome(WinningTeam? winner) => winner != null
      ? '${winnerMessage(winner)} ${isFr ? "Une condition de victoire est atteinte." : "A win condition has been reached."}'
      : isFr
          ? "Aucune condition de victoire n'est atteinte. La manche continue."
          : 'No win condition has been reached. The round continues.';

  String get discardPackTitle =>
      isFr ? 'Abandonner ce pack ?' : 'Discard this pack?';
  String get discardPackMessage => isFr
      ? 'Les paires saisies ne seront pas sauvegardées.'
      : 'The entered pairs will not be saved.';
  String get discardConfirm => isFr ? 'Abandonner' : 'Discard';
  String get pairWordsIdentical => isFr
      ? 'Les deux mots doivent être différents.'
      : 'Both words must be different.';
}
