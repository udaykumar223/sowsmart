Project: SowSmart, a Flutter + Firebase weather-aware crop scheduler and profit tracker.
Read PROJECT_RULES.md and README.md before doing anything.

ARCHITECTURE
- Layers: screens -> Provider state -> pure Dart domain -> repositories -> Firestore / assets / Open-Meteo.
- Screens never call Firestore or HTTP directly.
- lib/domain has no Flutter, Firebase or HTTP imports.
- Repositories sit behind abstract classes so tests can use fakes.
- Use Provider only. No Cloud Functions, no custom server.

RULES
- Build only the phase I ask for. Do not add features or packages I did not list.
- Keep code simple, with short comments explaining why. I must be able to explain every file.
- Every domain class gets unit tests. Run flutter analyze and flutter test and show me the output.
- Every screen needs loading, error and empty states.
- Never invent agronomy data, thresholds as facts, or metrics. Placeholder crop data must be marked REPLACE WITH VERIFIED DATA and carry a source field.
- Show weather advice as guidance, with a short disclaimer in the app.
- Ask me before deleting files or changing the data model.
- End each phase with: what changed, how to run it, what to test manually, and what I should be able to explain.
