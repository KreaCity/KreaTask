/// <reference path="../pb_data/types.d.ts" />

// Le projet de démonstration : deux personnes fictives, un projet, six cartes.
// La couverture vient du dossier demo/ du kit. Les deux personnes n'ont pas
// de photo : la page affiche une pastille à l'initiale de leur prénom.
// Les échéances sont calculées au premier lancement, pour que le tableau
// ne montre jamais des cartes en retard de plusieurs mois.

migrate((app) => {
  const dossierDemo = app.dataDir() + "/../demo/";
  const image = (nom) => $filesystem.fileFromPath(dossierDemo + nom);

  // Une date « dans n jours », au format de PocketBase.
  const jour = (n) => {
    const d = new Date();
    d.setUTCHours(12, 0, 0, 0);
    d.setUTCDate(d.getUTCDate() + n);
    return d.toISOString().replace("T", " ");
  };

  const users = app.findCollectionByNameOrId("users");
  const personne = (prenom, email) => {
    const r = new Record(users);
    r.set("name", prenom);
    r.setEmail(email);
    r.setPassword("demo-cartes-2026");
    r.setVerified(true);
    app.save(r);
    return r;
  };
  const lea = personne("Léa", "lea@exemple.test");
  const karim = personne("Karim", "karim@exemple.test");

  const projet = new Record(app.findCollectionByNameOrId("projets"));
  projet.set("nom", "Lancement de l'offre d'hiver");
  projet.set("membres", [lea.id, karim.id]);
  projet.set("couverture", image("couverture-projet.jpg"));
  app.save(projet);

  const collectionCartes = app.findCollectionByNameOrId("cartes");
  const cartes = [
    // [titre, responsable, échéance (jours), statut, position, fin (jours)]
    ["Écrire la page de l'offre", lea, 6, "À faire", 1, null],
    ["Préparer le mail aux anciens clients", karim, 8, "À faire", 2, null],
    ["Fixer le prix des trois formules", lea, 2, "En cours", 1, null],
    ["Rappeler les cinq clients les plus intéressés", karim, 3, "En cours", 2, null],
    ["Choisir la date de lancement", lea, -3, "Fait", 1, -4],
    ["Lister les clients à rappeler", karim, -1, "Fait", 2, -2],
  ];
  for (const [titre, responsable, echeance, statut, position, fin] of cartes) {
    const c = new Record(collectionCartes);
    c.set("titre", titre);
    c.set("projet", projet.id);
    c.set("responsable", responsable.id);
    c.set("echeance", jour(echeance));
    c.set("statut", statut);
    c.set("position", position);
    if (fin !== null) c.set("date_fin", jour(fin));
    app.save(c);
  }
}, (app) => {
  for (const nom of ["cartes", "projets"]) {
    const collection = app.findCollectionByNameOrId(nom);
    for (const r of app.findAllRecords(collection)) app.delete(r);
  }
  for (const email of ["lea@exemple.test", "karim@exemple.test"]) {
    try {
      app.delete(app.findAuthRecordByEmail("users", email));
    } catch (_) {
      // déjà supprimé
    }
  }
});
