# amalgame-captcha

CAPTCHA arithmétique auto-hébergé pour [Amalgame](https://github.com/amalgame-lang/Amalgame).
Pas de service tiers (Google reCAPTCHA, hCaptcha, etc.) — un défi
"a + b = ?" généré côté serveur, signé (HMAC-SHA-256, `amalgame-crypto`)
dans un jeton auto-porteur. Construit pour le formulaire de contact de
[CMSPress](https://github.com/BastienMOUGET/CMSPress), extrait en
paquet réutilisable.

## Pourquoi pas reCAPTCHA ?

Pour un site de presse indépendant, dépendre d'un service tiers pour
filtrer ses propres formulaires n'a pas de sens — ni pour la ligne
éditoriale, ni pour l'infrastructure. Ce paquet n'arrête pas un
attaquant déterminé qui cible spécifiquement votre site (comme la
plupart des CAPTCHA), mais filtre l'écrasante majorité du spam de
formulaire automatisé générique, sans embarquer de script/iframe
externe ni envoyer de données à un tiers.

## Install

```bash
amc package add github.com/amalgame-lang/amalgame-captcha@v0.1.0
```

Requiert **amc 0.7.7+**. Dépend de `amalgame-crypto` (>=0.8.0) et
`amalgame-random` (>=0.1.0) — résolus automatiquement.

## Surface

```amalgame
import Amalgame.Captcha

// Génère un défi — à afficher côté client, le jeton part avec le
// formulaire (champ caché) et revient tel quel à la soumission.
let challenge = Captcha.NewMathChallenge(mySecret)
// challenge.Question -> "3 + 7"  (affiché à l'utilisateur)
// challenge.Token    -> jeton opaque signé (champ caché du formulaire)

// À la soumission — la réponse saisie par l'utilisateur + le jeton
// (renvoyé tel quel) suffisent à vérifier, aucun état serveur requis.
if (Captcha.Verify(submittedToken, submittedAnswer, mySecret)) {
    // humain (probable) — traiter le formulaire
} else {
    // bot (probable) ou jeton expiré/altéré — rejeter
}
```

`mySecret` : une clé déjà présente côté serveur (ex. le secret de
signature de session de l'application hôte) — jamais transmise au
client, seul le jeton signé l'est.

## Format du jeton

`"<réponseAttendue>:<hmacHex>"` — auto-porteur, aucune session/DB
nécessaire pour vérifier. Pas d'expiration ni de marque "déjà utilisé"
intégrée (rejouable indéfiniment tant que la réponse reste correcte) :
suffisant pour un filtre anti-spam bas risque. Un appelant qui a besoin
d'un jeton à usage unique doit le tracker lui-même côté application.

## Limites (honnêtes)

- Filtre le spam de masse générique, pas une attaque ciblée sur votre
  site précis (un humain, ou un bot écrit spécifiquement contre votre
  formulaire, résout le calcul sans difficulté — la question est en
  clair).
- Uniquement des additions à un chiffre (1..9) pour l'instant — pas de
  challenge à base d'image (demanderait un rasterizer de police, pas
  disponible dans l'écosystème Amalgame actuel).

## Tests

```bash
./tests/run_tests.sh /path/to/amc
```

Déterministe pour toute la logique de vérification (signature,
altération, mauvais secret, jeton malformé) ; les opérandes eux-mêmes
viennent d'entropie réelle (`Random.FromSystem`), pas mockée.

## Licence

Apache-2.0 — voir [`LICENSE`](LICENSE) et [`NOTICE.md`](NOTICE.md).
