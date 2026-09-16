# Flick Design

## Product

Flick is a local-only macOS 14+ utility that anchors a compact task status capsule at the MacBook notch and expands into a focused personal task board. It borrows the notch expansion interaction pattern only; its visual language, data model, and task workflow are original.

## Architecture

The SwiftUI application uses an AppKit `NSPanel` for the non-activating floating surface, a menu-bar-only application lifecycle, SwiftData for persistence, and five source modules: `NotchWindow`, `TaskBoard`, `TaskStore`, `TaskPersistence`, and `Settings`. `TaskStore` is the sole mutation API; views render state and issue intent methods.

## Data Model

`TodoTask` stores an id, title, bucket (`now`, `today`, `later`), priority (`low`, `medium`, `high`), optional due date, optional note, creation time, completion time, archive time, and per-bucket sort order. A completed task stays visible in the board's collapsed completed section until the next daily archive pass. Archived tasks remain restorable for 30 days.

## Window Behavior

The panel is `.nonactivatingPanel`, has no title bar or shadow, appears on all Spaces, ignores window cycling, and is positioned from the selected display's visible frame. On a notch display, its collapsed top edge aligns with the safe-area top inset; on displays without a notch it is a centered top capsule. Expanding changes only the panel frame and SwiftUI state using a 0.22-second spring. Panel clicks are interactive; the current foreground application remains key.

## Interaction Contract

- Collapsed state shows task count when enabled and a dot in the highest active priority.
- Click, menu-bar action, or Option-Space opens or closes the panel.
- Opening focuses the quick-add field. Escape, an outside click, or inactivity closes it. Default inactivity is five seconds and is configurable.
- Quick add creates a `today` task on Return. Cards expose completion, editing, contextual priority changes, defer-to-tomorrow, and deletion.
- Dragging a card changes its bucket and places it after the target item's order. Keyboard users can change the bucket through the editor/context menu.
- Dates due within 24 hours use an orange treatment. No notification APIs are used.

## Persistence and Recovery

The persistent SwiftData store is local. Startup validates the model container; on failure the corrupt store is moved to Application Support recovery storage, a fresh store is created, and the UI presents an actionable recovery message. JSON imports are decoded and validated before insertion in one transaction. Exports include active and retained archived tasks.

## Accessibility and Appearance

The board supports system light/dark mode, SF system typography, VoiceOver labels and actions, visible keyboard focus, and `accessibilityReduceMotion`. Reduced motion replaces spring animations with an immediate or opacity transition. The card palette is red/high, blue/medium, gray/low, and orange/due-soon.
