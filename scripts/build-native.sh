#!/usr/bin/env bash
# Builds livekit_ffi from the rust-sdks submodule for the host platform and drops it where
# LivekitRtc.csproj packs it from: LivekitRtc/runtimes/<rid>/native/.
#
#   scripts/build-native.sh                # release build for the host
#   CARGO_RUST_PROFILE=dev scripts/build-native.sh
#   CARGO_TARGET=x86_64-pc-windows-msvc scripts/build-native.sh
#
# The submodule's rust-toolchain.toml pins the Rust version; rustup installs it on first use.
# Windows needs the MSVC build tools; Linux needs clang, lld and protoc (see .github/workflows/ci.yml
# for the exact package set on manylinux). The first build downloads the prebuilt libwebrtc that
# webrtc-sys pins.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SDK="$ROOT/LivekitRtc/rust-sdks"
PROFILE="${CARGO_RUST_PROFILE:-release}"

# cargo resolves a relative CARGO_TARGET_DIR against the directory it runs in, which is not the
# caller's; make it absolute here so cargo and the copy below agree on where the library is.
if [ -n "${CARGO_TARGET_DIR:-}" ]; then
  mkdir -p "$CARGO_TARGET_DIR"
  CARGO_TARGET_DIR="$(cd "$CARGO_TARGET_DIR" && pwd)"
  export CARGO_TARGET_DIR
fi

case "$(uname -s)" in
  Linux*)                RID="linux-x64"; LIB="liblivekit_ffi.so" ;;
  Darwin*)               RID="osx-$([ "$(uname -m)" = "arm64" ] && echo arm64 || echo x64)"; LIB="liblivekit_ffi.dylib" ;;
  MINGW*|MSYS*|CYGWIN*)  RID="win-x64"; LIB="livekit_ffi.dll" ;;
  *) echo "unsupported host: $(uname -s)" >&2; exit 1 ;;
esac

if [ ! -f "$SDK/livekit-ffi/Cargo.toml" ]; then
  echo "rust-sdks submodule is not checked out; run: git submodule update --init --recursive" >&2
  exit 1
fi

# Upstream builds from inside livekit-ffi (see rust-sdks/.github/workflows/ffi-builds.yml); the
# workspace target dir is still <sdk>/target.
(cd "$SDK/livekit-ffi" && cargo build --profile "$PROFILE" ${CARGO_TARGET:+--target "$CARGO_TARGET"} "$@")

PROFILE_DIR="$PROFILE"; [ "$PROFILE" = "dev" ] && PROFILE_DIR="debug"
TARGET_DIR="${CARGO_TARGET_DIR:-$SDK/target}"
BUILT="$TARGET_DIR/${CARGO_TARGET:+$CARGO_TARGET/}$PROFILE_DIR/$LIB"
DEST="$ROOT/LivekitRtc/runtimes/$RID/native"
mkdir -p "$DEST"
cp "$BUILT" "$DEST/$LIB"
echo "native: $DEST/$LIB"
