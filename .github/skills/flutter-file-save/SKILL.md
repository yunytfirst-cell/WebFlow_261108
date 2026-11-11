---
name: flutter-file-save
description: 'Handle and verify Flutter/Dart text-file saving, file names, overwrite behavior, invalid characters, paths, and user-visible save errors. Use when implementing or debugging save/load features.'
argument-hint: 'Describe the Flutter file-saving behavior to implement or verify.'
---

# Flutter File Save

## Highest-Priority Change Control

Before editing, review this Skill, the workspace instructions, and the user's
explicit request. Define the allowed scope and expected files. Before finishing,
review every changed file and diff; remove unrelated edits, opportunistic
refactors, and unnecessary formatting changes. If an unrelated change is
necessary to preserve the requested behavior, record why and verify it.

After implementation, verification, and the final scope review are complete,
show a VS Code completion notification popup with a brief summary and
verification result. If the current environment cannot invoke a VS Code popup,
state that limitation explicitly in the final response and provide the same
completion summary there.

## Purpose

Implement reliable text-file saving in this Flutter project and compare new
file-related problems against the failure patterns recorded here.

## Architecture Rule

Keep file saving modular. UI widgets collect input and display status; services
own path handling, serialization, and filesystem access; models hold data.
Place new code in the existing `lib/models/`, `lib/services/`, or
`lib/widgets/` classification instead of growing an unrelated monolithic file.
If a responsibility is reused by multiple screens, extract it into a focused
service or helper and update all callers and tests.

## Git Repository Rules

- Keep the Git repository at the project root:
  `C:\AppProject\02.Project\01.FlowWork_260201\flow`.
- Store tracked source and project files under this repository location:
  `C:\AppProject\02.Project\01.FlowWork_260201\flow\`.
- Keep this file-management Skill at:
  `C:\AppProject\02.Project\01.FlowWork_260201\flow\.github\skills\flutter-file-save\SKILL.md`.
- Keep application source under `...\flow\lib\`, tests under `...\flow\test\`,
  project instructions under `...\flow\.github\`, and Git configuration at
  `...\flow\.git\`. Do not save project files in the desktop or outside this
  repository unless the user explicitly requests an export or copy.
- If the repository does not exist, initialize it at that project root before
  saving tracked work; do not create a nested repository in `lib/`, `test/`,
  or generated-output folders.
- Save source, tests, configuration, and documentation changes in this
  repository. Keep generated build output, caches, and temporary files
  untracked according to `.gitignore`.
- Before finishing a code change, review `git status` and the diff, then commit
  the requested changes when the user asks to save or update the repository.
- A GitHub remote is separate from the local repository. Do not invent or
  publish to a remote without an explicit repository URL and authorization.
- When the user provides a GitHub repository URL, configure it as `origin`,
  confirm the target branch, and push only after reviewing the commit and
  working-tree status.
- Use the project `main` branch as the default GitHub target unless the user
  specifies another branch. Verify that local `main` and `origin/main` are
  synchronized after a successful push.
- Check tracked files against GitHub's file-size limits before pushing. Do not
  commit generated output, caches, or oversized source archives; add them to
  `.gitignore` when they are not required at runtime, or use Git LFS only when
  the user explicitly requests and authorizes it.
- If a push is rejected, read the remote error, make the smallest necessary
  repository-only correction, amend or create a follow-up commit as
  appropriate, and retry. Never delete the local source file merely to make a
  push pass.

## File Management Rules

- Inspect a file's location, references, and current state before creating,
  moving, overwriting, or deleting it.
- When a save/file behavior is fixed in one screen, immediately search for
  sibling implementations with the same responsibility (for example goal and
  awareness lists) and compare them. Apply the same rule to every matching
  surface in the same change; do not assume one widget is the only caller.
- Do not arbitrarily move or delete existing files. When a move is required,
  update imports, asset paths, runtime loading, tests, and documentation in the
  same change.
- Keep source, tests, assets, platform code, and generated build output in
  their existing classifications. Do not edit generated `build/` files as
  source.
- Do not create duplicate or temporary files in source folders. Use a focused
  name and the existing module directory.
- Restrict deletion to explicitly scoped, resolved paths; never use broad
  recursive deletion, wildcards, or root-level cleanup.
- Before finishing, verify that file paths are valid on the target platform,
  the intended file is the only file overwritten, and no unrelated files were
  changed.

## UI Layout Rule

Use responsive auto-layout for every save/load surface. Apply the shared
`flutter-ui-layout` standard: 360px mobile, 768px tablet, and 1280px desktop
review widths; Material Icons at 16/20/24/32px; and icon button hit areas of at
least 44px. Prefer `Expanded`/`Flexible`/`Wrap`/`LayoutBuilder`/`MediaQuery`
and scrollable containers over fixed dimensions or absolute positioning.
Check long titles, localized messages, narrow windows, resize, maximize, and
restore states for overflow before considering the feature complete.

## Required Checks

1. Inspect the complete save/load lifecycle before editing:
   - title or user input used to construct a path
   - file picker return values
   - current file path ownership and widget lifecycle
   - new-file, load-file, save, rename, close, and reopen flows
2. Never concatenate unvalidated user text into a Windows path.
3. Normalize file names before creating a `File`:
   - replace Windows-invalid characters (`< > : " / \ | ? *` and controls)
     with ` x`
   - handle trailing dots/spaces and reserved names (`CON`, `PRN`, `AUX`,
     `NUL`, `COM1`-`COM9`, `LPT1`-`LPT9`)
   - avoid duplicate `.txt` extensions
   - do not silently reject a title only because its filename is invalid;
     convert it, report the conversion, and reject only an actual filesystem
     write failure
4. Preserve the selected or loaded file path. After a file is opened, saving
   must overwrite that path even when the displayed title changes. Clear the
   path only for an explicit new-file action.
5. Use explicit goal block markers (`[GOAL:n]` and `[END_GOAL]`) when
   serializing multiline list items. Strip those markers while loading so they
   never appear in the UI. Keep legacy numbered-list parsing for existing files.
   Apply the same rule to awareness items with `[AWARE_ITEM:n]` and
   `[END_AWARE_ITEM]`. Both list screens must accept and restore either marker
   format, so a goal file can be opened as awareness data and vice versa without
   splitting multiline text into extra items.
6. Surface failures explicitly. A save failure dialog must show:
   - the attempted file location
   - the invalid character(s), when known
   - the underlying filesystem error
7. Surface successful saves explicitly too. Show the final file name, complete
   path, and any automatic character conversions, with an action to open the
   storage folder for the actual saved file, including when an existing file
   was loaded from outside the application's default folder.
8. Use `flush: true` for completed text writes when persistence is important.

## Verification

- Run `dart format` on changed Dart files.
- Run `flutter analyze` on the changed files.
- Run `flutter test`.
- Manually verify:
  1. a title containing invalid Windows characters is converted using ` x`;
  2. loading `A.txt`, changing the title, and saving still changes only
     `A.txt`;
  3. closing and reopening the sidebar preserves the loaded path;
  4. a filesystem failure displays location, character information, and error.
  5. a file saved by either list can be opened by the other list with each
     multiline item restored as one item.
  6. both sidebar file pickers open the same shared directory and preserve
     execution-counter records when files move between list types.

## Recorded Failure Patterns

- Using the title directly as a file name caused intermittent Windows save
  failures for invalid characters, trailing dots/spaces, and reserved names.
- Recomputing the path from the current title after loading created a second
  file when the title changed.
- Catching a filesystem exception with only a generic SnackBar hid the path
  and the offending input, making the failure appear intermittent.
- Keeping both a text field controller and a separate model string without
  synchronizing before saving could write stale or apparently missing text.
  Treat the controller as the final input source at save time and notify the
  owning state when the list changes.
- Showing only a file name after saving hid the application-data folder and made
  valid saves with normalized names appear to be missing. Always show the full
  path and offer to open its folder.
- Opening the default application folder after saving a file loaded from another
  folder made the updated file appear to be missing. Open the parent folder of
  the actual saved path and display the actual saved basename.
- Fixing only the first matching list widget left parallel list screens with
  older save behavior. Treat analogous widgets as one feature surface and
  verify them together.
- Keeping analogous lists in separate storage directories made saved files
  unavailable from the sibling list. Use one shared directory, a common
  cross-marker parser/serializer, and shared execution records for both lists.

When a new related issue is fixed, add its reusable cause and verification
case to this section rather than recording only the specific symptom.
