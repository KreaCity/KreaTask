/// <reference path="../pb_data/types.d.ts" />

// Partie 1 du plan · les données.
// Une carte appartient à un projet et a un responsable, qui est un utilisateur.
// Chaque carte porte un titre, un responsable, une échéance, un statut et sa
// place dans la colonne.
//
// Lecture ouverte (le tableau s'affiche sans connexion).
// Création, modification et suppression : fermées (null = réservé à
// l'administrateur). Les ouvrir fait partie de la partie 2.

migrate((app) => {
  // Les utilisateurs : la collection « users » fournie par PocketBase.
  // On ouvre la lecture de leur nom et de leur avatar ; l'e-mail reste masqué
  // (il n'est montré que si la personne coche « e-mail visible »).
  const users = app.findCollectionByNameOrId("users");
  users.listRule = "";
  users.viewRule = "";
  app.save(users);

  const projets = new Collection({
    type: "base",
    name: "projets",
    listRule: "",
    viewRule: "",
    createRule: null,
    updateRule: null,
    deleteRule: null,
    fields: [
      { name: "nom", type: "text", required: true, max: 120, presentable: true },
      {
        name: "membres",
        type: "relation",
        collectionId: users.id,
        maxSelect: 50,
        cascadeDelete: false,
      },
      {
        name: "couverture",
        type: "file",
        maxSelect: 1,
        maxSize: 5242880,
        mimeTypes: ["image/jpeg", "image/png", "image/webp"],
      },
      { name: "created", type: "autodate", onCreate: true, onUpdate: false },
      { name: "updated", type: "autodate", onCreate: true, onUpdate: true },
    ],
  });
  app.save(projets);

  const cartes = new Collection({
    type: "base",
    name: "cartes",
    listRule: "",
    viewRule: "",
    createRule: null,
    updateRule: null,
    deleteRule: null,
    fields: [
      { name: "titre", type: "text", required: true, max: 200, presentable: true },
      {
        name: "projet",
        type: "relation",
        required: true,
        collectionId: projets.id,
        maxSelect: 1,
        cascadeDelete: true,
      },
      {
        name: "responsable",
        type: "relation",
        collectionId: users.id,
        maxSelect: 1,
        cascadeDelete: false,
      },
      { name: "echeance", type: "date" },
      {
        name: "statut",
        type: "select",
        required: true,
        maxSelect: 1,
        values: ["À faire", "En cours", "Fait"],
      },
      { name: "position", type: "number" },
      { name: "date_fin", type: "date" },
      { name: "created", type: "autodate", onCreate: true, onUpdate: false },
      { name: "updated", type: "autodate", onCreate: true, onUpdate: true },
    ],
    indexes: ["CREATE INDEX idx_cartes_colonne ON cartes (projet, statut, position)"],
  });
  app.save(cartes);
}, (app) => {
  app.delete(app.findCollectionByNameOrId("cartes"));
  app.delete(app.findCollectionByNameOrId("projets"));

  const users = app.findCollectionByNameOrId("users");
  users.listRule = "id = @request.auth.id";
  users.viewRule = "id = @request.auth.id";
  app.save(users);
});
