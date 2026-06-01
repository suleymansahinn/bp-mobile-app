int calculateLevel(int xp) => (xp ~/ 100) + 1;

double levelProgress(int xp) => (xp % 100) / 100;