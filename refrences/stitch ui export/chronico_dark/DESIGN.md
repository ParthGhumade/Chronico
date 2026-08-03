---
name: Chronico Dark
colors:
  surface: '#131313'
  surface-dim: '#131313'
  surface-bright: '#393939'
  surface-container-lowest: '#0e0e0e'
  surface-container-low: '#1c1b1b'
  surface-container: '#201f1f'
  surface-container-high: '#2a2a2a'
  surface-container-highest: '#353534'
  on-surface: '#e5e2e1'
  on-surface-variant: '#c2c6d5'
  inverse-surface: '#e5e2e1'
  inverse-on-surface: '#313030'
  outline: '#8c909f'
  outline-variant: '#424753'
  surface-tint: '#adc6ff'
  primary: '#adc6ff'
  on-primary: '#002e69'
  primary-container: '#4d8efe'
  on-primary-container: '#00285c'
  inverse-primary: '#005ac1'
  secondary: '#c1c7cd'
  on-secondary: '#2b3136'
  secondary-container: '#41474d'
  on-secondary-container: '#b0b6bc'
  tertiary: '#ffb780'
  on-tertiary: '#4e2600'
  tertiary-container: '#db760f'
  on-tertiary-container: '#442000'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#d8e2ff'
  primary-fixed-dim: '#adc6ff'
  on-primary-fixed: '#001a41'
  on-primary-fixed-variant: '#004494'
  secondary-fixed: '#dde3e9'
  secondary-fixed-dim: '#c1c7cd'
  on-secondary-fixed: '#161c21'
  on-secondary-fixed-variant: '#41474d'
  tertiary-fixed: '#ffdcc4'
  tertiary-fixed-dim: '#ffb780'
  on-tertiary-fixed: '#2f1400'
  on-tertiary-fixed-variant: '#6f3800'
  background: '#131313'
  on-background: '#e5e2e1'
  surface-variant: '#353534'
typography:
  display:
    fontFamily: Inter
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  headline-md:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.02em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  xs: 4px
  sm: 12px
  md: 24px
  lg: 40px
  xl: 64px
  gutter: 24px
  margin-mobile: 16px
  margin-desktop: 32px
---

## Brand & Style

This design system transitions into a sophisticated, high-utility dark environment tailored for productivity and deep focus. The brand personality remains professional and systematic, but the shift to a dark interface emphasizes reduced eye strain and a "heads-up display" aesthetic. 

The design style is **Corporate Modern** with a focus on **Tonal Layering**. By utilizing a deep, neutral base, the UI allows functional colors to communicate urgency and status without visual noise. High-quality whitespace is replaced with "space-air"—generous dark margins that provide a sense of calm and organization.

## Colors

The palette is anchored by a deep charcoal base (`#121212`), providing a stable, low-glare foundation. The primary blue has been shifted to a slightly lighter, more desaturated variant (`#4285f4`) to ensure it meets WCAG AA contrast standards against dark surfaces.

Status colors are tuned for vibrancy on dark backgrounds:
- **Success (Green):** A vivid emerald that cuts through the dark without glowing.
- **Warning (Amber):** A warm, golden yellow to ensure distinction from background elements.
- **Error (Red):** A bright, punchy crimson for immediate visibility.

Neutral grays are used to define hierarchy, with lighter grays reserved for secondary text and borders to maintain a soft, accessible contrast ratio.

## Typography

This design system utilizes **Inter** across all levels to maintain a clean, utilitarian feel. In dark mode, font weights are slightly adjusted visually—heavy weights are used sparingly for headlines to prevent "blooming" effects on high-brightness screens.

- **Headlines:** Use tighter letter-spacing for large displays to maintain a compact, modern look.
- **Body Text:** Uses a slightly increased line-height to improve readability against dark backgrounds.
- **Labels:** Set in medium weight to ensure legibility at small scales, particularly for metadata and interface controls.

## Layout & Spacing

The layout follows a **Fluid Grid** model with a standard 8px baseline rhythm. 

- **Desktop:** 12-column grid with 24px gutters and 32px outer margins.
- **Tablet:** 8-column grid with 20px gutters.
- **Mobile:** 4-column grid with 16px gutters.

Padding within containers is generous to prevent the dark UI from feeling cramped. Elements should align to the 8px grid to maintain structural integrity and visual rhythm.

## Elevation & Depth

In this dark mode environment, depth is communicated through **Tonal Layering** rather than traditional shadows. 

- **Level 0 (Base):** `#121212` - The canvas.
- **Level 1 (Cards/Sidebar):** `#1e1e1e` - Subtle lift via color lightness.
- **Level 2 (Modals/Popovers):** `#2d2d2d` - Highest contrast against the base.

While subtle shadows are permitted for modals to provide a soft "glow" (0px 8px 24px rgba(0,0,0,0.5)), the primary driver of hierarchy is the incremental lightening of surface colors as they move "closer" to the user.

## Shapes

The design system employs a **Rounded** shape language to soften the industrial feel of the dark theme. 

- **Standard Elements:** 0.5rem (8px) for buttons, inputs, and small cards.
- **Large Elements:** 1rem (16px) for main content containers and modals.
- **Interactive States:** Focus rings should follow the object’s corner radius with a 2px offset.

## Components

### Buttons
- **Primary:** Solid `#4285f4` with white or high-contrast black text. 
- **Secondary:** Outlined with a 1px border using the secondary gray.
- **Ghost:** No background, primary color text; uses a subtle `#ffffff10` background on hover.

### Input Fields
- **Background:** Set to a slightly lighter shade than the parent container (`#252525`).
- **Border:** 1px solid `#3c4043`. On focus, the border changes to the primary blue with a subtle outer glow.

### Cards
- Use `surface_elevated` (`#1e1e1e`) to distinguish sections. 
- Borders are optional; if used, they should be low-contrast (`#ffffff10`).

### Chips & Tags
- Used for filtering and status. Backgrounds should be semi-transparent versions of the status colors (e.g., success color at 15% opacity) to keep the UI from feeling "heavy."

### Progress & Loading
- Use the primary blue for active states. Skeleton loaders should pulse between `#1e1e1e` and `#2d2d2d`.