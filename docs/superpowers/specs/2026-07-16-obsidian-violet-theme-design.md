# Obsidian Violet Theme Design

## Goal

Make the dark Galaxy Noir experience more comfortable for long Arabic reading
by replacing its blue-cyan palette with a charcoal-and-violet palette.

## Scope

- Change only `AppTheme.galaxyNoir` semantic token values.
- Keep the preset identifier, two-theme selector, typography, layout, and
  Starlight Paper unchanged.
- Preserve AA contrast for primary text, secondary text, and text on the
  primary action.

## Token decisions

| Token | Value | Purpose |
| --- | --- | --- |
| canvas | `#121014` | near-black plum charcoal, not pure black |
| surface | `#1B1720` | cards and normal surfaces |
| surfaceRaised | `#26202E` | elevated rows and inputs |
| contentPrimary | `#EEE9F2` | reading and main UI text |
| contentSecondary | `#C9C1D0` | supporting text |
| brand | `#B9A6FF` | selected and primary actions |
| onBrand | `#21152D` | readable text on the violet action |
| brandContainer | `#35264A` | selected containers |
| onBrandContainer | `#E8DEFF` | text on selected containers |
| outline | `#393240` | borders and dividers |
| warning | `#E8C77D` | restrained reading/VIP emphasis |

Status colors remain semantically distinct but are softened for the new dark
surfaces. The selected color is never used for long body text.

## Verification

The existing semantic-palette and contrast tests are updated first, run red,
then production tokens are changed minimally and tested green. Run formatting,
the app-theme test file, and static analysis afterward.
