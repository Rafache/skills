# Communication & Posture
- Rester concis, professionnel et directement compréhensible.
- Privilégier des phrases courtes et éviter les explications inutiles.

# Méthode de travail & Qualité
- **Édition** : Préférer des modifications chirurgicales, préserver les commentaires existants et ne pas reformater des fichiers entiers sans demande.
- **Validation technique** : Toujours vérifier la syntaxe, les builds ou le statut des services après modification avant de clore la tâche.

# Contributions & Outils distants
- **Validation préalable** : Tout texte destiné à être envoyé, publié ou enregistré dans un outil distant doit être présenté pour validation avant envoi.
- **Résultat final** : Décrire uniquement le résultat final dans les contenus persistants (commits, PR/MR, tickets, docs, code).
- **Commits Git** : Ne jamais committer sans demande explicite de l'utilisateur. Découper ou amender en plusieurs commits si plusieurs sujets distincts sont traités. Titre uniquement sur une seule ligne (*conventional commit*, en anglais), sans corps ni description. Dans une PR, ajuster les commits avec --fixup plutôt que d'empiler des correctifs.
- **Signature IA** : Ne jamais mentionner « généré avec une IA », ni signature ou co-auteur IA.

# Navigation Web & Navigateur Headless
- **Furtivité navigateur** : Lors de tout appel de pilotage navigateur headless (ex. `navigate_page`), injecter systématiquement l'`initScript` pour masquer `webdriver`, assainir l'`User-Agent` et aligner le WebGL sur la Radeon 780M de l'hôte :
  ```javascript
  delete Object.getPrototypeOf(navigator).webdriver;
  const cleanUa = navigator.userAgent.replace('HeadlessChrome', 'Chrome');
  Object.defineProperty(navigator, 'userAgent', { get: () => cleanUa });
  const hook = (proto) => {
    if (!proto || !proto.getParameter) return;
    const orig = proto.getParameter;
    proto.getParameter = function(p) {
      if (p === 37445) return 'Google Inc. (AMD)';
      if (p === 37446) return 'ANGLE (AMD, AMD Radeon 780M, OpenGL 4.6)';
      return orig.apply(this, arguments);
    };
  };
  if (typeof WebGLRenderingContext !== 'undefined') hook(WebGLRenderingContext.prototype);
  if (typeof WebGL2RenderingContext !== 'undefined') hook(WebGL2RenderingContext.prototype);
  ```
