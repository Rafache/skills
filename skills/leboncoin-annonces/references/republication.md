# Republier une annonce existante

1. Identifier l'annonce par son compte, son titre et son identifiant. Comparer les détails avec la demande pour éviter un homonyme.
2. Avant suppression, enregistrer localement le texte intégral, le prix, les attributs, le lieu, les modes de remise et toutes les photos dans leur ordre. Vérifier le nombre et l'ouverture des fichiers ; garder la sauvegarde jusqu'à la confirmation de la nouvelle annonce.
3. Vérifier qu'un chemin d'envoi des photos est utilisable. Si l'outil d'envoi refuse les fichiers locaux, le navigateur peut récupérer les URL d'images accessibles et fournir des objets `File` au champ via `DataTransfer` et un événement `change`. Vérifier ensuite que le site a reçu chaque photo ; ne pas se fier au seul contenu du champ.
4. Supprimer l'annonce ciblée après la sauvegarde et la validation du contenu requise par les consignes du projet. Choisir un motif fidèle à la situation, puis vérifier qu'elle n'apparaît plus dans « Mes annonces ».
5. Recréer l'annonce avec les valeurs d'origine, sauf modifications demandées. Les valeurs prédites par le formulaire, notamment la description, la catégorie et le prix, ne remplacent pas les valeurs validées.
6. Relire les champs immédiatement avant le dépôt. Si une saisie automatisée semble se perdre ou altérer des caractères, corriger par une méthode qui déclenche les événements du formulaire, puis vérifier la valeur après un nouveau rendu.
7. Après dépôt, vérifier le titre, le prix, le nombre de photos et le statut dans le compte. Si la page affiche « En cours de vérification », signaler que la publication reste soumise au contrôle du site.

Lors de l'inspection du réseau, ne restituer que les champs nécessaires à la vérification ; masquer les cookies, les jetons et les coordonnées du compte.
