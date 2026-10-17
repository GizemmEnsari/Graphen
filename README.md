# GraphStudio

An on-device graphing tool for iOS (SwiftUI + Swift Charts). No server, no
third-party add-ons — everything runs locally.

## Status: Phase 2–3 complete
- Project scaffold (xcodegen-generated Xcode project)
- Data models: `Graph`, `Series`, `DataPoint`, `GraphStyle`, plus enums
- Phase 4/5 screens and services are in place as labelled stubs so the project
  builds and the structure is visible.

## Layout
- `GraphStudio/Models/`     — `Graph`, `Series`, `DataPoint`, `GraphStyle`, color + enum types
- `GraphStudio/Views/`      — Phase 4 screens (placeholders)
- `GraphStudio/Services/`   — CSV + equation parsing (Phase 5 stubs)
- `GraphStudio/Exporters/`  — "Generate Code" feature (Phase 5 stub)
- `GraphStudio/Resources/`  — sample CSV
- `project.yml`             — xcodegen project spec

## Key decisions (locked at Phase 2)
- **Storage:** models are plain `Codable` value types now. SwiftData is deferred
  to Phase 5 so the model layer stays UI-free and testable.
- **Colors:** stored as hex `ColorValue`, not SwiftUI `Color`, so the model
  layer and the code exporters (SwiftUI / HTML / Python) stay UI-independent.
- **DataPoint:** `x` / `y` are `Double`; categorical / datetime axes are handled
  via an optional `label` plus axis config, not a polymorphic value type.
- **Equations:** a hand-rolled parser (Phase 5) — no math dependency.

## Build / run
```
xcodegen generate
open GraphStudio.xcodeproj
```
The `.xcodeproj` is committed so you can open it directly, but it is
regenerated from `project.yml`.
