#!/bin/bash
# amalgame-captcha — Test Runner. Requires amc 0.7.7+.
#
# Link recipe condensed from CMSPress's own build.sh (proven working
# there for a much larger project) — resolves real dependencies
# (amalgame-crypto, amalgame-random) via `amc package add`, compiles
# facade.am + the test directly as local sources (no fake package-cache
# mocking needed for THIS package, unlike amalgame-yaml/amalgame-image's
# harnesses — simpler because nothing here vendors its own C code).
set -u

if [ $# -ge 1 ]; then AMC="$1"
elif [ -n "${AMC:-}" ]; then :
elif command -v amc >/dev/null 2>&1; then AMC="$(command -v amc)"
else echo "ERROR: amc not found." >&2; exit 2
fi
[ -x "$AMC" ] || { echo "ERROR: amc not executable: $AMC" >&2; exit 2; }
AMC="$(cd "$(dirname "$AMC")" && pwd)/$(basename "$AMC")"

AMC_DIR="$(cd "$(dirname "$AMC")" && pwd)"
AMC_RUNTIME=""
for cand in "$HOME/.local/share/amalgame/runtime" "/usr/local/share/amalgame/runtime"; do
    [ -d "$cand" ] && { AMC_RUNTIME="$cand"; break; }
done
[ -n "$AMC_RUNTIME" ] || { echo "ERROR: amc runtime/ not found." >&2; exit 2; }
LIBAMALGAME=""
for cand in "$HOME/.local/share/amalgame/lib/libamalgame.a" "/usr/local/share/amalgame/lib/libamalgame.a"; do
    [ -f "$cand" ] && { LIBAMALGAME="$cand"; break; }
done
[ -n "$LIBAMALGAME" ] || { echo "ERROR: libamalgame.a not found." >&2; exit 2; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PKG_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'

echo ""
echo "════════════════════════════════════════════"
echo "  amalgame-captcha — Test Suite"
echo "════════════════════════════════════════════"
echo "  amc:     $AMC ($("$AMC" --version 2>&1 | head -1))"
echo "  package: $PKG_ROOT"
echo ""

BUILD_DIR="$(mktemp -d -t acaptcha-tests-XXXXXX)"
trap 'rm -rf "$BUILD_DIR"' EXIT
cd "$BUILD_DIR"

echo "── Résolution des dépendances (crypto, random) ──"
"$AMC" package add crypto random || { echo -e "${RED}FAIL${NC} (package resolution)"; exit 1; }
echo ""

cp "$PKG_ROOT/facade.am" ./captcha_facade.am
cp "$SCRIPT_DIR/stdlib_captcha.am" ./test.am

echo "── amc: génération du .c ──"
# captcha_facade.am AVANT test.am : cgen amc est mono-passe pour l'accès
# aux champs de struct (test.am lit c1.Question/c1.Token directement sur
# un CaptchaChallenge) — même gotcha documenté dans CMSPress (server.am
# doit précéder tout fichier qui lit ses champs). Compiler dans l'autre
# ordre échoue au lien gcc avec "invalid use of incomplete typedef".
if ! "$AMC" captcha_facade.am test.am -o test 2>&1; then
    echo -e "${RED}FAIL${NC} (amc)"
    exit 1
fi
[ -f test.c ] || { echo -e "${RED}FAIL${NC} (pas de test.c)"; exit 1; }

echo "── gcc: compilation + lien contre les paquets résolus ──"
PKG_INCLUDES=()
PKG_ARCHIVES=()
SYS_LIBS=()
if [ -d "$HOME/.amalgame/packages/github.com/amalgame-lang" ]; then
    for pkg_parent in "$HOME/.amalgame/packages/github.com/amalgame-lang"/*/; do
        latest=$(ls -1 "$pkg_parent" 2>/dev/null | sort -V | tail -1)
        [ -z "$latest" ] && continue
        PKG_CACHE="${pkg_parent}${latest}"
        runtime_dir="$PKG_CACHE/runtime"
        [ -d "$runtime_dir" ] && PKG_INCLUDES+=(-I"$runtime_dir")
        # Paquet multi-classes (ex: amalgame-crypto, "classes = [...]") —
        # essayé en premier ; repli sur la forme singulière "class = ..."
        # sinon. amc nomme l'archive d'après la PREMIÈRE classe listée
        # dans les deux cas.
        CLS=$(awk '/^classes/,/]/' "$PKG_CACHE/amalgame.toml" 2>/dev/null \
              | grep -oE '"[A-Z][A-Za-z0-9_]+"' | head -1 | tr -d '"')
        if [ -z "$CLS" ]; then
            CLS=$(grep -E '^[[:space:]]*class[[:space:]]*=' "$PKG_CACHE/amalgame.toml" 2>/dev/null \
                  | grep -oE '"[A-Za-z_][A-Za-z0-9_]*"' | head -1 | tr -d '"')
        fi
        [ -z "$CLS" ] && continue
        ARCHIVE="$PKG_CACHE/build/linux-x86_64/libamalgame-pkg-${CLS}.a"
        [ -f "$ARCHIVE" ] && PKG_ARCHIVES+=("$ARCHIVE")
        while IFS= read -r lib; do
            [ -n "$lib" ] && SYS_LIBS+=("-l$lib")
        done < <(awk '/^libs[[:space:]]*=/,/]/' "$PKG_CACHE/amalgame.toml" 2>/dev/null \
                 | grep -oE '"[a-z0-9_+-]+"' | tr -d '"')
    done
fi

if ! gcc -O2 -I"$AMC_RUNTIME" "${PKG_INCLUDES[@]}" test.c "${PKG_ARCHIVES[@]}" "$LIBAMALGAME" \
        -lgc -lm -lcurl -lz -ldl -lpthread "${SYS_LIBS[@]}" -o test 2>&1; then
    echo -e "${RED}FAIL${NC} (gcc link)"
    exit 1
fi
[ -x ./test ] || { echo -e "${RED}FAIL${NC} (pas de binaire produit)"; exit 1; }
echo ""

echo "── Amalgame.Captcha ────────────────────────"
OUTPUT="$(./test 2>&1)"
echo "$OUTPUT" | sed 's/^/  /'
echo ""

PASS=$(echo "$OUTPUT" | grep -c '^\[PASS\]')
FAIL=$(echo "$OUTPUT" | grep -c '^\[FAIL\]')

echo "────────────────────────────────────────────"
echo -e "  ${GREEN}PASS: $PASS${NC}  |  ${RED}FAIL: $FAIL${NC}"
echo "────────────────────────────────────────────"
echo ""
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
