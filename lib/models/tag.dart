/// Modèle représentant un tag (élément d'une liste, ex: aliment, tâche...)
class Tag {
  final String id;
  final String nom;
  final String categorieId;
  final bool like;
  final bool dislike;
  final String? quantite;
  final String? commentaire;

  Tag({
    required this.id,
    required this.nom,
    required this.categorieId,
    this.like = false,
    this.dislike = false,
    this.quantite,
    this.commentaire,
  });

  factory Tag.fromMap(Map<String, dynamic> data) => Tag(
        id: data['id'] ?? '',
        nom: data['nom'] ?? '',
        categorieId: data['categorieId'] ?? '',
        like: data['like'] ?? false,
        dislike: data['dislike'] ?? false,
        quantite: data['quantite'],
        commentaire: data['commentaire'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'nom': nom,
        'categorieId': categorieId,
        'like': like,
        'dislike': dislike,
        if (quantite != null) 'quantite': quantite,
        if (commentaire != null) 'commentaire': commentaire,
      };
} 