#!/data/data/com.termux/files/usr/bin/env bash
set -e

GITHUB_REPO="${OKSI_GITHUB_REPO:-nurshia/oksitool}"
INSTALL_DIR="${OKSI_INSTALL_DIR:-$HOME/.oksitool}"
ARCH="aarch64"

C_R='\033[0m'; C_CYAN='\033[96m'; C_MAG='\033[95m'; C_RED='\033[91m'
C_GREEN='\033[92m'; C_YEL='\033[93m'; C_GRAY='\033[90m'; C_BOLD='\033[1m'

info()  { printf "${C_CYAN}ℹ${C_R}  %s\n" "$*"; }
ok()    { printf "${C_GREEN}✓${C_R}  %s\n" "$*"; }
warn()  { printf "${C_YEL}⚠${C_R}  %s\n" "$*"; }
err()   { printf "${C_RED}✗${C_R}  %s\n" "$*" >&2; }
dim()   { printf "${C_GRAY}%s${C_R}\n" "$*"; }

banner() {
    printf "\n"
    printf "${C_MAG}  ██████╗ ██╗  ██╗███████╗██╗\n"
    printf "  ██╔═══██╗██║ ██╔╝██╔════╝██║\n"
    printf "  ██║   ██║█████╔╝ ███████╗██║\n"
    printf "  ██║   ██║██╔═██╗ ╚════██║██║\n"
    printf "  ╚██████╔╝██║  ██╗███████║██║\n"
    printf "   ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝${C_R}\n"
    printf "${C_GRAY}  oksi.dev${C_R}\n\n"
}
banner

TERMUX_PREFIX_DEFAULT="/data/data/com.termux/files/usr"
IS_TERMUX=0
[ -n "${TERMUX_VERSION:-}" ] && IS_TERMUX=1
[ -n "${PREFIX:-}" ] && [ -d "$PREFIX" ] && [ "$PREFIX" = "$TERMUX_PREFIX_DEFAULT" ] && IS_TERMUX=1
[ -d "$TERMUX_PREFIX_DEFAULT" ] && IS_TERMUX=1
command -v pkg >/dev/null 2>&1 && IS_TERMUX=1

if [ "$IS_TERMUX" -ne 1 ]; then
    err "Termux algılanamadı."
    exit 1
fi

if [ -z "${PREFIX:-}" ] || [ ! -d "${PREFIX:-/dev/null}" ]; then
    PREFIX="$TERMUX_PREFIX_DEFAULT"
    export PREFIX
fi

case ":$PATH:" in
    *":$PREFIX/bin:"*) ;;
    *) export PATH="$PREFIX/bin:$PATH" ;;
esac

BIN_LINK="$PREFIX/bin/oksitool"

ARCH_RAW=$(uname -m)
case "$ARCH_RAW" in
    aarch64|arm64) ARCH=aarch64 ;;
    *) err "Desteklenmeyen mimari: $ARCH_RAW"; exit 1 ;;
esac

ok "Hazırlanıyor..."

pkg update -y >/dev/null 2>&1 || true

NEED=""
command -v node >/dev/null 2>&1 || NEED="$NEED nodejs-lts"
command -v curl >/dev/null 2>&1 || NEED="$NEED curl"
command -v jq   >/dev/null 2>&1 || NEED="$NEED jq"
command -v tar  >/dev/null 2>&1 || NEED="$NEED tar"

if [ -n "$NEED" ]; then
    info "Bileşenler yükleniyor..."
    pkg install -y $NEED >/dev/null 2>&1
fi

API_URL="https://api.github.com/repos/$GITHUB_REPO/releases/latest"
LATEST_JSON=$(curl -fsSL --connect-timeout 15 "$API_URL" 2>/dev/null || true)
if [ -z "$LATEST_JSON" ]; then
    err "İndirme sunucusuna ulaşılamadı."
    exit 1
fi

TAG=$(printf "%s" "$LATEST_JSON" | jq -r '.tag_name // empty')
ASSET_URL=$(printf "%s" "$LATEST_JSON" | jq -r ".assets[] | select(.name | test(\"oksitool-termux-$ARCH-v.*\\\\.tar\\\\.gz\")) | .browser_download_url" | head -n1)

if [ -z "$TAG" ] || [ -z "$ASSET_URL" ]; then
    err "Sürüm bulunamadı."
    exit 1
fi

mkdir -p "$INSTALL_DIR"
TMP=$(mktemp -d)
trap "rm -rf $TMP" EXIT

info "İndiriliyor..."
curl -fsSL --progress-bar "$ASSET_URL" -o "$TMP/oksitool.tar.gz"

if pgrep -f "$INSTALL_DIR/oksitool" >/dev/null 2>&1; then
    pkill -f "$INSTALL_DIR/oksitool" 2>/dev/null || true
    sleep 1
fi

info "Kuruluyor..."
tar -xzf "$TMP/oksitool.tar.gz" -C "$INSTALL_DIR"
chmod +x "$INSTALL_DIR/oksitool"

cd "$INSTALL_DIR"
npm install --no-audit --no-fund --silent --omit=dev >/dev/null 2>&1 || {
    err "Kurulum başarısız."
    exit 1
}

ln -sf "$INSTALL_DIR/oksitool" "$BIN_LINK"

echo
ok "${C_BOLD}OKSI TOOL kuruldu${C_R}"
echo
dim "  Çalıştır: ${C_GREEN}oksitool${C_R}"
dim "  Sürüm: $TAG"
echo
