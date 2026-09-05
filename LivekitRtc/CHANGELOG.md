# Changelog (Release Notes)

## 0.2.0 (Verji fork, `LiveKitSdk.Bindings`)

- First release from [verji/livekit-sdk-dotnet](https://github.com/verji/livekit-sdk-dotnet). Package id is
  `LiveKitSdk.Bindings`; the namespace stays `LiveKit.Rtc`.
- The native `livekit_ffi` is built from the [verji/rust-sdks](https://github.com/verji/rust-sdks) fork at
  `verji-main` (upstream `main` at `90a9e45b`, livekit-ffi 0.12.76 line) instead of downloaded from an
  upstream release. Shipped runtimes: win-x64, linux-x64 (manylinux_2_28).
- Protos regenerated with protoc 25.2. The FFI protocol is byte-identical between the previous pin
  (upstream `2d9f01ab`) and this one; the diff in `Proto/*.g.cs` is protoc output style only.
- `KeyProviderOptions.KeyDerivationFunction` (`Proto.KeyDerivationFunction`; PBKDF2, the upstream default, or HKDF). Upstream hard-coded
  PBKDF2, which cannot decrypt frames from a livekit-client peer that imported raw per-participant key
  bytes, since that path derives with HKDF.
- The linux-x64 native is built in plain `manylinux_2_28` without CUDA, so it lacks the NVIDIA hardware
  codecs upstream's release binary carries. Irrelevant for a data-channel or audio-only participant.

## 0.1.4

- Update rust-sdks to [livekit-ffi/v0.12.76](https://github.com/livekit/rust-sdks/releases/tag/livekit-ffi%2Fv0.12.76)
- Add all the missing `TrackPublishOptions` fields, reaching parity with the Node/Python/Rust
  RTC SDKs: `VideoCodec` (select the codec of published video tracks: VP8, H264, AV1, VP9...),
  `Dtx`, `Red`, `Stream`, `PreconnectBuffer`, `FrameMetadataFeatures`, `ScalabilityMode`
  (SVC publishing for VP9/AV1), `VideoEncoder` (preferred encoder backend) and
  `DegradationPreference`. All new options are nullable and unset keeps the previous
  behavior (the SDK defaults). The `TrackPublishOptions` → `Proto.TrackPublishOptions`
  mapping is now covered by unit tests, including a parity guard that fails when a future
  FFI proto regeneration introduces fields not exposed by the SDK.

## 0.1.3

- Update rust-sdks to [livekit-ffi/v0.12.60](https://github.com/livekit/rust-sdks/releases/tag/livekit-ffi%2Fv0.12.60)

## 0.1.2

- Update rust-sdks to [livekit-ffi/v0.12.50](https://github.com/livekit/rust-sdks/releases/tag/livekit-ffi%2Fv0.12.50)

## 0.1.1

- Update livekit/protocol to [v1.45.1](https://github.com/livekit/protocol/releases/tag/%40livekit%2Fprotocol%401.45.1)

## 0.1.0

- Initial release of Livekit.Rtc.Dotnet SDK.