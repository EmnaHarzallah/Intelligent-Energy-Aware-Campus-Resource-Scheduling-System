pb de salles par creneau( 20 salles et donc une explosion combinatoire)=>utilsiser once et donc tester une salle ( prendre la premiere dispo ) par session 
pb de 60 sessions à inserer et capacite de creneaux dans l'emploi => j'ai crée une contrainte ( 17 sessions pour gl3 et 14 pour gl4 et gl2 par semaine)
dans la règle valid_assignment_v2 (dans KB.pl)
=>
Il va vous lister tous les emplois du temps possibles en changeant les heures et les jours.
Mais pour chaque emploi du temps, il ne vous montrera qu'une seule configuration de salles (la première qui a marché).