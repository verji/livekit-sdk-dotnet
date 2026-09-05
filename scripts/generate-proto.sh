#!/usr/bin/env bash
# Regenerates LivekitRtc/Proto/*.g.cs from the FFI protocol in the rust-sdks submodule.
# The generated files are committed; CI regenerates them and fails on drift, so the C# in the
# package always matches the native library it ships with. Needs protoc on PATH.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROTO="$ROOT/LivekitRtc/rust-sdks/livekit-ffi/protocol"
OUT="$ROOT/LivekitRtc/Proto"

if [ ! -d "$PROTO" ]; then
  echo "rust-sdks submodule is not checked out; run: git submodule update --init --recursive" >&2
  exit 1
fi
command -v protoc >/dev/null || { echo "protoc not found on PATH" >&2; exit 1; }

mkdir -p "$OUT"
protoc -I="$PROTO" --csharp_out="$OUT" --csharp_opt=file_extension=.g.cs \
  "$PROTO/audio_frame.proto" \
  "$PROTO/ffi.proto" \
  "$PROTO/handle.proto" \
  "$PROTO/participant.proto" \
  "$PROTO/room.proto" \
  "$PROTO/track.proto" \
  "$PROTO/track_publication.proto" \
  "$PROTO/video_frame.proto" \
  "$PROTO/e2ee.proto" \
  "$PROTO/stats.proto" \
  "$PROTO/rpc.proto" \
  "$PROTO/data_stream.proto" \
  "$PROTO/data_track.proto"
echo "generated: $OUT"
