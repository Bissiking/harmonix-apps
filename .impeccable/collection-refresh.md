# Harmonix collections — direction contract

Mode: Operate. Existing adaptive Flutter app, Moon Resonance identity retained.
Scope: Bibliothèque, Harmonix Night, Explorer and Paramètres; catalogue visibility
and chronological ordering. User chose recent additions as the library's primary
entry. Code-led implementation in the existing visual world; no generated comp.

## First viewport

Library: a clear title, play/search actions, persistent collection tabs and an
artwork shelf of the latest additions, followed by the full list. Night: one
useful session control with an explicit duration and start action, alongside the
music on tablet/desktop; controls precede artwork on phone. Explorer: search,
an actual playable release, album covers and the catalogue. Settings: task-based
sections and real theme previews instead of an undifferentiated form.

## Interaction

Library tabs pin on scroll. Local title/artist/album filtering keeps the current
source and sort. Cover tiles directly play that selection. Night's time presets,
exact stop time and end-of-track choice remain native controls. Theme changes
persist through the existing appearance controller. No decorative animation or
effect over the music; native focus, ripple and selection states do the work.

## Constraints

Preserve playback, files, playlists, SSO, Cast/Rift and per-account storage.
Honor light appearance, text scaling and reduced motion. Server Night flags and
the exact harmonix:night tag keep tracks out of all ordinary lists. Actual server
import dates take precedence over first-seen timestamps. Sonora's local adapter
now exposes its existing uploaded_at; production requires deployment of that
separate server change, not inferred from a successful app build.

## Evidence

test/collection_surfaces_test.dart renders the four real screen widgets within
AppShell at 390x844, 834x1112, 1440x1000, 320x844 with text x2, and daylight
390x844. These are Flutter test renders, not browser, emulator or hardware
screenshots. Data is synthetic, with two pre-existing local Sonora covers reused
only during FLOW_CAPTURE. No claim of native hardware or audio validation.

## Review bounds

Capture paths: .impeccable/review/{library,night,catalog,settings}-{mobile,tablet,
desktop,large-text,daylight}.png. All twenty are required. No HTML/CSS detector:
this target is Flutter. Remaining hardware validation: Android/iOS audio,
Android Auto, gesture behavior and real device performance.
