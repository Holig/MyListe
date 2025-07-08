/// Modèle représentant une catégorie (ex: Fruits, Légumes, etc.)
class Categorie {
  final String id;
  final String nom;
  final int ordre;
  final String superlisteId; // ID de la superliste à laquelle appartient cette catégorie

  Categorie({
    required this.id,
    required this.nom,
    required this.ordre,
    required this.superlisteId,
  });

  factory Categorie.fromMap(Map<String, dynamic> data) => Categorie(
        id: data['id'] ?? '',
        nom: data['nom'] ?? '',
        ordre: data['ordre'] ?? 0,
        superlisteId: data['superlisteId'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'nom': nom,
        'ordre': ordre,
        'superlisteId': superlisteId,
      };
} 