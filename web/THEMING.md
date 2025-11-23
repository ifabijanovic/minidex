# MiniDex Theming & Styling Guidelines

## Core Principles

- Reference the brand palette defined in `app/theme.ts`. Do **not** invent ad hoc colors.
- Use the MUI theme everywhere (palette, typography, spacing). Prefer `sx` or theme-aware styled components over raw CSS.
- Keep global CSS minimal—only typography resets or browser quirks belong there.

## Light vs Dark Mode

- The app automatically follows the user’s system preference via `prefers-color-scheme`.
- To test light/dark, override your OS/browser setting; the theme switches on the next render.
- If a component needs mode-specific styling, read `theme.palette.mode` inside `sx`.

## Component Styling

- Layout & utility styling: use `Box`, `Stack`, and `sx` props.
- Reusable visuals: create custom components that read from `theme`. Avoid CSS modules unless you need complex selectors not covered by MUI.
- Buttons:
  - `variant="contained"` → primary actions (navy background).
  - `variant="outlined"` → secondary actions (neutral borders).
  - `variant="text"` → tertiary links.
- Cards:
  - Use `Card` with `elevation={0}`; rely on `border` + `backgroundColor` from theme.
  - Keep shapes rounded (theme `shape.borderRadius`).
- Inputs:
  - Use `TextField` or `OutlinedInput` variants; the theme already defines base colors/borders.

## Color Usage

- Primary navy (`palette.primary.main`) for structure: headers, call-to-action buttons, active nav.
- Burnt red (`palette.secondary.main`) sparingly for warnings or accent CTAs.
- Backgrounds: `background.default` (page), `background.paper` (containers/cards).
- Text:
  - `text.primary` for body copy.
  - `text.secondary` for supporting text, captions, icons.
- Dividers/borders: `divider`.

## Accessibility

- Maintain at least AA contrast. When unsure, default to primary/navy text on light backgrounds or inverse text on dark backgrounds.
- Avoid heavy shadows; rely on tone differences (paper vs default backgrounds) and borders for hierarchy.

## Checklist for New UI

1. Use MUI components; avoid plain HTML unless necessary.
2. Style with `sx` or `styled`, passing values from `theme`.
3. Check visuals in both light and dark mode.
4. Keep color usage restrained (no more than three prominent colors at once).
5. Verify buttons, links, and text meet accessibility contrast requirements.
