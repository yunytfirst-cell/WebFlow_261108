---
name: flutter-ui-layout
description: 'Design, implement, or review responsive Flutter UI layouts and Material icons. Use for web, desktop, mobile, resizing, overflow, spacing, icon sizing, and accessibility.'
argument-hint: 'Describe the Flutter UI or responsive layout to implement or review.'
---

# Flutter UI Layout

## Highest-Priority Change Control

Before editing, review this Skill, the workspace instructions, and the user's
explicit request. Before finishing, inspect every changed file and diff to
remove changes outside the requested UI/layout scope. Do not mix unrelated
refactors or formatting changes into a layout change.

## Responsive Layout Standard

- Treat 360px as the mobile baseline, 768px as the tablet breakpoint, and
  1280px as the desktop breakpoint.
- Prefer `Expanded`, `Flexible`, `Wrap`, `LayoutBuilder`, `MediaQuery`, and
  scrollable parents over fixed dimensions and absolute positioning.
- Test narrow, normal, wide, maximized, restored, and resized states.
- Prevent overflow from long Korean/English text, localization, and larger
  accessibility text. Use wrapping, ellipsis, scrolling, and explicit
  min/max constraints deliberately.
- Keep responsive calculations in the owning widget or a focused layout helper;
  do not duplicate breakpoint logic across unrelated widgets.

## Material Icon Standard

- Prefer Material Icons and use 16, 20, 24, or 32px sizes.
- Keep icon button hit areas at least 44px.
- Use consistent icon meaning and visual weight within a toolbar or action row.
- Add a tooltip or accessible label when an icon's meaning is not obvious.
- Do not use decorative icons as the only source of critical information.

## Verification

1. Run `dart format` on changed Dart files.
2. Run `flutter analyze` on the changed files.
3. Run `flutter test`.
4. Manually check the 360px, 768px, and 1280px widths and a resized desktop
   window for overflow, clipping, unusable controls, and icon alignment.
