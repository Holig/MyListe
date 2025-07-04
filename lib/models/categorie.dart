/// Modèle représentant une catégorie (ex: Fruits, Légumes, etc.)
class Categorie {
  final String id;
  final String nom;
  final int ordre;
  final bool commune;

  Categorie({
    required this.id,
    required this.nom,
    required this.ordre,
    this.commune = false,
  });

  factory Categorie.fromMap(Map<String, dynamic> data) => Categorie(
        id: data['id'] ?? '',
        nom: data['nom'] ?? '',
        ordre: data['ordre'] ?? 0,
        commune: data['commune'] ?? false,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'nom': nom,
        'ordre': ordre,
        'commune': commune,
      };
} 