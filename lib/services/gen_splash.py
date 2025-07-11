from PIL import Image

# Chemin vers ton motif de base
motif_path = r"C:\Users\ohagege\Desktop\ProjetFlutterApp\MyListe\assets\images\splash_myliste.png"
# Chemin de sortie pour la grande image splash
output_path = r"C:\Users\ohagege\Desktop\ProjetFlutterApp\MyListe\assets\images\splash4096.png"

# Taille finale de l'image splash (modifie si besoin)
final_width = 4096
final_height = 4096

# Ouvre le motif
motif = Image.open(motif_path)
motif_width, motif_height = motif.size

# Crée une nouvelle image vide
splash = Image.new("RGBA", (final_width, final_height), (0, 0, 0, 0))

# Répète le motif sur toute la surface
for x in range(0, final_width, motif_width):
    for y in range(0, final_height, motif_height):
        splash.paste(motif, (x, y))

# Sauvegarde l'image finale
splash.save(output_path)
print(f"Splash généré : {output_path}")