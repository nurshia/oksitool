# OKSI TOOL

Premium Discord selfbot terminal aracı — Windows, Linux, macOS ve **Termux (Android)** üzerinde çalışır.

> Web: [oksi.dev](https://oksi.dev) · Discord: [discord.gg/oksi](https://discord.gg/oksi)

---

## Termux (Android) kurulum

```bash
curl -fsSL https://raw.githubusercontent.com/nurshia/oksitool/main/install-termux.sh | bash
```

Script otomatik olarak şunları yapar:

- `nodejs-lts`, `curl`, `jq`, `tar` paketlerini kurar
- GitHub'tan son sürüm tarball'ını indirir
- `~/.oksitool/` altına kurar
- `$PREFIX/bin/oksitool` komutunu bağlar

Sonrasında:

```bash
oksitool
```

### Güncelleme

Aynı komutu tekrar çalıştır:

```bash
curl -fsSL https://raw.githubusercontent.com/nurshia/oksitool/main/install-termux.sh | bash
```

### Kaldırma

```bash
rm -rf ~/.oksitool
rm -f $PREFIX/bin/oksitool
```

---

## Diğer platformlar

Windows, Linux, macOS için installer'lar: [oksi.dev/download](https://oksi.dev/download)

---

## Releases

Tüm sürümler [Releases](https://github.com/nurshia/oksitool/releases) sayfasından indirilebilir.

| Tag | Platform | Asset |
|---|---|---|
| `termux-vX.Y.Z` | Android aarch64 | `oksitool-termux-aarch64-vX.Y.Z.tar.gz` |

---

## Lisans

PROPRIETARY. Kaynak kod paylaşılmaz. Binary'lerin kullanımı tool içindeki kullanıcı sözleşmesine tabidir.
