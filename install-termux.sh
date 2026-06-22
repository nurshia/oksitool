#!/data/data/com.termux/files/usr/bin/env bash
# OKSI TOOL — Termux installer
#
# Kullanım:
#   curl -fsSL https://oksi.dev/install-termux.sh | bash
#
# Bu script Termux içinde çalışır. Termux dışında çalışırsa erken çıkar.

set -e

GITHUB_REPO="${OKSI_GITHUB_REPO:-nurshia/oksitool}"
INSTALL_DIR="${OKSI_INSTALL_DIR:-$HOME/.oksitool}"
BIN_LINK="${PREFIX:-/data/data/com.termux/files/usr}/bin/oksitool"
ARCH="aarch64"

# ─── Renkli loglar ─────────────────────────────────────────────────
C_R='\033[0m'; C_CYAN='\033[96m'; C_MAG='\033[95m'; C_RED='\033[91m'
C_GREEN='\033[92m'; C_YEL='\033[93m'; C_GRAY='\033[90m'; C_BOLD='\033[1m'

info()  { printf "${C_CYAN}ℹ${C_R}  %s\n" "$*"; }
ok()    { printf "${C_GREEN}✓${C_R}  %s\n" "$*"; }
warn()  { printf "${C_YEL}⚠${C_R}  %s\n" "$*"; }
err()   { printf "${C_RED}✗${C_R}  %s\n" "$*" >&2; }
dim()   { printf "${C_GRAY}%s${C_R}\n" "$*"; }

# ─── Banner ────────────────────────────────────────────────────────
banner() {
    printf "\n"
    printf "${C_MAG}  ██████╗ ██╗  ██╗███████╗██╗\n"
    printf "  ██╔═══██╗██║ ██╔╝██╔════╝██║\n"
    printf "  ██║   ██║█████╔╝ ███████╗██║\n"
    printf "  ██║   ██║██╔═██╗ ╚════██║██║\n"
    printf "  ╚██████╔╝██║  ██╗███████║██║\n"
    printf "   ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝${C_R}\n"
    printf "${C_GRAY}  Termux installer · oksi.dev${C_R}\n\n"
}
banner

# ─── Ortam kontrolü ────────────────────────────────────────────────
# Termux birden fazla sinyal verir — birinin tutması yeter:
#   - $PREFIX env (Termux otomatik set eder, bazen alt-shell'de düşer)
#   - $TERMUX_VERSION env
#   - /data/data/com.termux/files/usr klasörü
#   - pkg komutu PATH'te
TERMUX_PREFIX_DEFAULT="/data/data/com.termux/files/usr"

IS_TERMUX=0
if [ -n "${TERMUX_VERSION:-}" ]; then IS_TERMUX=1; fi
if [ -n "${PREFIX:-}" ] && [ -d "$PREFIX" ] && [ "$PREFIX" = "$TERMUX_PREFIX_DEFAULT" ]; then IS_TERMUX=1; fi
if [ -d "$TERMUX_PREFIX_DEFAULT" ]; then IS_TERMUX=1; fi
if command -v pkg >/dev/null 2>&1; then IS_TERMUX=1; fi

if [ "$IS_TERMUX" -ne 1 ]; then
    err "Termux algılanamadı."
    err "  PREFIX=${PREFIX:-<boş>}"
    err "  TERMUX_VERSION=${TERMUX_VERSION:-<boş>}"
    err "  $TERMUX_PREFIX_DEFAULT exists: $([ -d "$TERMUX_PREFIX_DEFAULT" ] && echo yes || echo no)"
    err "  pkg in PATH: $(command -v pkg >/dev/null 2>&1 && echo yes || echo no)"
    err "Termux: https://termux.dev/"
    exit 1
fi

# PREFIX'i kesinleştir (curl | bash içinde bazen düşüyor)
if [ -z "${PREFIX:-}" ] || [ ! -d "${PREFIX:-/dev/null}" ]; then
    PREFIX="$TERMUX_PREFIX_DEFAULT"
    export PREFIX
fi

# PATH'e Termux bin'i ekle (gerekirse)
case ":$PATH:" in
    *":$PREFIX/bin:"*) ;;
    *) export PATH="$PREFIX/bin:$PATH" ;;
esac

# Önerilen BIN_LINK'i de PREFIX'ten türet
BIN_LINK="$PREFIX/bin/oksitool"

ARCH_RAW=$(uname -m)
case "$ARCH_RAW" in
    aarch64|arm64) ARCH=aarch64 ;;
    *)
        err "Desteklenmeyen mimari: $ARCH_RAW"
        err "OKSI TOOL şu an sadece aarch64 (64-bit ARM) cihazlarda çalışır."
        exit 1
        ;;
esac

ok "Termux algılandı · arch=$ARCH · prefix=$PREFIX"

# ─── Sistem paketleri ──────────────────────────────────────────────
info "Sistem paketleri kontrol ediliyor (nodejs-lts, curl, jq)..."
pkg update -y >/dev/null 2>&1 || true

NEED=""
command -v node >/dev/null 2>&1 || NEED="$NEED nodejs-lts"
command -v curl >/dev/null 2>&1 || NEED="$NEED curl"
command -v jq   >/dev/null 2>&1 || NEED="$NEED jq"
command -v tar  >/dev/null 2>&1 || NEED="$NEED tar"

if [ -n "$NEED" ]; then
    info "Yüklenecek:$NEED"
    pkg install -y $NEED
fi

ok "Node $(node --version) hazır"

# ─── Latest release fetch ─────────────────────────────────────────
info "GitHub'tan son sürüm aranıyor..."
API_URL="https://api.github.com/repos/$GITHUB_REPO/releases/latest"

LATEST_JSON=$(curl -fsSL --connect-timeout 15 "$API_URL" 2>/dev/null || true)
if [ -z "$LATEST_JSON" ]; then
    err "GitHub API erişilemedi. İnternet bağlantını kontrol et."
    exit 1
fi

TAG=$(printf "%s" "$LATEST_JSON" | jq -r '.tag_name // empty')
ASSET_URL=$(printf "%s" "$LATEST_JSON" | jq -r ".assets[] | select(.name | test(\"oksitool-termux-$ARCH-v.*\\\\.tar\\\\.gz\")) | .browser_download_url" | head -n1)

if [ -z "$TAG" ] || [ -z "$ASSET_URL" ]; then
    err "Termux release asset bulunamadı (tag=$TAG)."
    exit 1
fi

ok "Sürüm: $TAG"
dim "  URL: $ASSET_URL"

# ─── İndir + ayıkla ────────────────────────────────────────────────
mkdir -p "$INSTALL_DIR"
TMP=$(mktemp -d)
trap "rm -rf $TMP" EXIT

info "İndiriliyor..."
curl -fsSL --progress-bar "$ASSET_URL" -o "$TMP/oksitool.tar.gz"

# Eski binary çalışıyorsa öldür
if pgrep -f "$INSTALL_DIR/oksitool" >/dev/null 2>&1; then
    warn "Eski oksitool çalışıyor — durduruluyor..."
    pkill -f "$INSTALL_DIR/oksitool" || true
    sleep 1
fi

info "Kuruluyor → $INSTALL_DIR"
tar -xzf "$TMP/oksitool.tar.gz" -C "$INSTALL_DIR"
chmod +x "$INSTALL_DIR/oksitool"

# ─── Runtime npm deps (bytenode + pacote) ─────────────────────────
cd "$INSTALL_DIR"
info "Runtime bileşenleri kuruluyor (bytenode + pacote)..."
npm install --no-audit --no-fund --silent --omit=dev 2>&1 | tail -n 3 || {
    err "npm install başarısız."
    exit 1
}

# ─── Symlink ───────────────────────────────────────────────────────
info "Komut bağlanıyor → $BIN_LINK"
ln -sf "$INSTALL_DIR/oksitool" "$BIN_LINK"

# ─── Bitti ─────────────────────────────────────────────────────────
echo
ok "${C_BOLD}OKSI TOOL kuruldu!${C_R}"
echo
dim "  Çalıştır: ${C_GREEN}oksitool${C_R}"
dim "  Kurulum dizini: $INSTALL_DIR"
dim "  Sürüm: $TAG"
echo
dim "  Güncelleme için: curl -fsSL https://oksi.dev/install-termux.sh | bash"
echo
