# Design System Inspired by Kolej Ibu Zain (KIZ)

## 1. Visual Theme & Atmosphere

The Kolej Ibu Zain design system embodies educational excellence, community leadership, and natural sustainability through a vibrant yet grounded visual language. The design draws inspiration from the institution's lush campus environment and commitment to holistic student development. Bright lime-green accents symbolize growth, innovation, and environmental consciousness, while deep charcoal and navy tones provide sophistication and trustworthiness. The system balances playful, energetic elements with refined institutional authority, creating an atmosphere that feels both welcoming to students and authoritative to stakeholders. Typography is bold and readable, emphasizing clarity and confident communication across digital and print contexts.

**Key Characteristics**
- Vibrant lime-green primary accent (`#C3DC52`, `#FFFF9D`) symbolizing growth and sustainability
- Deep charcoal (`#374151`) and navy (`#111827`) for stability and institutional trust
- Clean, contemporary typography using Poppins and League Spartan for hierarchy
- Generous whitespace and light surfaces creating airy, modern aesthetics
- Organic, natural color palette reflecting the campus's green environment
- High contrast and accessibility-first color choices for legibility

## 2. Color Palette & Roles

### Primary
- **Lime Green** (`#C3DC52`): Primary brand accent for CTAs, highlights, and emphasis elements; represents growth and innovation
- **Bright Yellow** (`#FFFF9D`): Secondary bright accent for supporting highlights and decorative elements

### Accent Colors
- **Cobalt Blue** (`#3B82F6`): Interactive links, secondary CTAs, and information states
- **Deep Blue** (`#2563EB`): Enhanced focus and active link states
- **Dark Navy** (`#060138`): Rich background overlay and premium sections

### Interactive
- **Deep Charcoal** (`#374151`): Default button text, navigation links, and interactive element text
- **Black** (`#000000`): High-contrast text for buttons and critical interactive elements

### Neutral Scale
- **White** (`#FFFFFF`): Primary background, card surfaces, and text on dark backgrounds
- **Off-White** (`#F9FAFB`): Subtle background sections and content areas
- **Cream** (`#FEFFF5`): Light background wash for sections needing warmth
- **Light Gray** (`#F7F7EF`): Secondary background and container surfaces
- **Medium Gray** (`#636D6B`): Secondary text and disabled states
- **Near-White** (`#F9F9F9`): Tertiary background layer

### Surface & Borders
- **Dark Gray** (`#444343`): Subtle borders and dividers
- **Charcoal** (`#111827`): Primary text on light backgrounds and strong borders

### Semantic / Status
- **Warning Yellow** (`#E8FD0A`): Alert and warning notification states
- **Bright Warning** (`#D2F72D`): Attention-grabbing warning indicators

## 3. Typography Rules

### Font Family
**Primary:** Poppins (`Poppins, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`)
**Secondary:** League Spartan (`League Spartan, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`)
**Fallback:** System UI (`system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", "Roboto", sans-serif`)

### Hierarchy

| Role | Font | Size | Weight | Line Height | Letter Spacing | Notes |
|------|------|------|--------|-------------|----------------|-------|
| Display / Hero | League Spartan | 70px | 700 | 84px | 0px | Page hero headlines, maximum visual impact |
| Heading 1 | Poppins | 18px | 400 | 21.6px | 0px | Section headings and major content headers |
| Heading 3 | League Spartan | 40px | 700 | 48px | 0px | Subsection titles and card headers |
| Body Large | Poppins | 25px | 700 | 35px | 0px | Featured content, emphasis text |
| Body Regular | system-ui | 16px | 400 | 18.4px | 0px | Primary body text, general content |
| Body Small | system-ui | 14px | 400 | 16.1px | 0px | Metadata, secondary text |
| Navigation | Poppins | 14px | 600 | 14px | 0px | Menu items, navigation links |
| Button | system-ui | 16px | 400 | 18.4px | 0px | Primary call-to-action text |
| Caption | system-ui | 12px | 400 | 13.8px | 0px | Image captions, helper text |
| Code | `Courier New` | 14px | 400 | 16.1px | 0px | Code snippets and technical content |

### Principles
- **Bold Hierarchy:** Use weight and size contrast to create clear visual hierarchy; prioritize League Spartan for major headlines
- **Readability First:** Maintain minimum `16px` for body text on all devices; prioritize legibility over aesthetic minimalism
- **Consistent Rhythm:** Adhere to specified line-height values to maintain vertical rhythm and scanning ease
- **Web-Safe Stacks:** All fonts load from Google Fonts with system fallbacks for performance
- **Limited Palette:** Restrict to three fonts maximum to maintain design coherence and load performance

## 4. Component Stylings

### Buttons

#### Primary Button
- **Background:** `#C3DC52`
- **Text Color:** `#111827`
- **Padding:** `12px 24px`
- **Border Radius:** `5px`
- **Border:** `0px none`
- **Font:** Poppins, 16px, 600 weight
- **Line Height:** `18.4px`
- **Hover State:** Background `#B8D649`, shadow `0px 4px 12px rgba(195, 220, 82, 0.3)`
- **Active State:** Background `#A3C73D`
- **Disabled State:** Background `#E8FD0A`, text color `#B8B8B8`, opacity `0.6`

#### Secondary Button
- **Background:** `#3B82F6`
- **Text Color:** `#FFFFFF`
- **Padding:** `12px 24px`
- **Border Radius:** `5px`
- **Border:** `2px solid #3B82F6`
- **Font:** Poppins, 16px, 600 weight
- **Line Height:** `18.4px`
- **Hover State:** Background `#2563EB`, shadow `0px 4px 12px rgba(59, 130, 246, 0.3)`
- **Active State:** Background `#1D4ED8`
- **Focus State:** Outline `3px solid #FFFFFF`, outline-offset `2px`

#### Ghost Button
- **Background:** `transparent`
- **Text Color:** `#374151`
- **Padding:** `12px 24px`
- **Border Radius:** `5px`
- **Border:** `2px solid #374151`
- **Font:** Poppins, 16px, 600 weight
- **Line Height:** `18.4px`
- **Hover State:** Background `#F9FAFB`, border color `#111827`
- **Active State:** Background `#E5E7EB`, text color `#111827`

#### Contact CTA Button (Lime Green)
- **Background:** `#C3DC52`
- **Text Color:** `#FFFFFF`
- **Padding:** `10px 20px`
- **Border Radius:** `4px`
- **Font:** Poppins, 14px, 600 weight
- **Line Height:** `16.8px`
- **Hover State:** Background `#B8D649`
- **Icon Margin:** `6px` left of text

### Cards & Containers

#### Feature Card (Lime Green Background)
- **Background:** `#C3DC52` or gradient `#D2F72D`
- **Text Color:** `#111827`
- **Padding:** `24px`
- **Border Radius:** `12px`
- **Border:** `0px none`
- **Box Shadow:** `0px 4px 16px rgba(195, 220, 82, 0.2)`
- **Min Height:** `360px`
- **Icon Background:** `rgba(107, 140, 0, 0.2)`, radius `8px`, padding `12px`
- **Icon Color:** `#6B8C00`
- **Hover State:** Shadow `0px 8px 24px rgba(195, 220, 82, 0.35)`, transform `translateY(-2px)`

#### Content Card
- **Background:** `#FFFFFF`
- **Text Color:** `#374151`
- **Padding:** `20px`
- **Border Radius:** `8px`
- **Border:** `1px solid #E5E7EB`
- **Box Shadow:** `none`
- **Hover State:** Shadow `0px 2px 8px rgba(0, 0, 0, 0.08)`, border `1px solid #D1D5DB`

#### Section Container
- **Background:** `#F9FAFB` or `#FEFFF5`
- **Padding:** `60px 40px`
- **Border Radius:** `0px`
- **Border:** `0px none`
- **Max Width:** `1200px`

### Inputs & Forms

#### Text Input
- **Background:** `#FFFFFF`
- **Border:** `2px solid #D1D5DB`
- **Border Radius:** `6px`
- **Padding:** `12px 16px`
- **Font:** system-ui, 16px, 400 weight
- **Text Color:** `#374151`
- **Placeholder Color:** `#9CA3AF`
- **Focus State:** Border `2px solid #3B82F6`, outline `none`, box-shadow `0px 0px 0px 3px rgba(59, 130, 246, 0.1)`
- **Error State:** Border `2px solid #EF4444`, background `#FEE2E2`
- **Disabled State:** Background `#F3F4F6`, text color `#9CA3AF`, border `2px solid #E5E7EB`

#### Textarea
- **Background:** `#FFFFFF`
- **Border:** `2px solid #D1D5DB`
- **Border Radius:** `6px`
- **Padding:** `12px 16px`
- **Font:** system-ui, 16px, 400 weight
- **Min Height:** `120px`
- **Resize:** `vertical`
- **Focus State:** Border `2px solid #3B82F6`, box-shadow `0px 0px 0px 3px rgba(59, 130, 246, 0.1)`

#### Checkbox & Radio
- **Size:** `20px × 20px`
- **Border:** `2px solid #D1D5DB`
- **Border Radius:** `4px` (checkbox), `50%` (radio)
- **Checked Background:** `#3B82F6`
- **Checked Border:** `2px solid #3B82F6`
- **Focus Ring:** `0px 0px 0px 3px rgba(59, 130, 246, 0.1)`

### Navigation

#### Primary Navigation Bar
- **Background:** `#759600`
- **Padding:** `12px 20px`
- **Height:** `64px`
- **Align Items:** `center`
- **Box Shadow:** `0px 2px 8px rgba(0, 0, 0, 0.1)`

#### Navigation Link
- **Color:** `#374151`
- **Font:** Poppins, 14px, 600 weight
- **Padding:** `8px 16px`
- **Border Radius:** `4px`
- **Hover State:** Background `rgba(255, 255, 255, 0.1)`, color `#111827`
- **Active State:** Background `#C3DC52`, color `#111827`, border-bottom `3px solid #111827`

#### Dropdown Menu
- **Background:** `#FFFFFF`
- **Border Radius:** `6px`
- **Box Shadow:** `rgba(50, 50, 93, 0.25) 0px 50px 100px -20px, rgba(0, 0, 0, 0.3) 0px 30px 60px -30px`
- **Padding:** `8px 0px`
- **Min Width:** `200px`
- **Border:** `1px solid #E5E7EB`

#### Dropdown Item
- **Padding:** `12px 16px`
- **Color:** `#374151`
- **Font:** system-ui, 14px, 400 weight
- **Hover State:** Background `#F9FAFB`, color `#111827`
- **Selected State:** Background `#E5E7EB`, color `#111827`

### Badges

#### Badge (Green)
- **Background:** `rgba(195, 220, 82, 0.2)`
- **Text Color:** `#6B8C00`
- **Padding:** `4px 12px`
- **Border Radius:** `6px`
- **Font:** Poppins, 12px, 600 weight
- **Border:** `1px solid #C3DC52`

#### Badge (Blue)
- **Background:** `rgba(59, 130, 246, 0.1)`
- **Text Color:** `#1E40AF`
- **Padding:** `4px 12px`
- **Border Radius:** `6px`
- **Font:** Poppins, 12px, 600 weight
- **Border:** `1px solid #3B82F6`

#### Badge (Warning)
- **Background:** `rgba(234, 253, 10, 0.2)`
- **Text Color:** `#92660D`
- **Padding:** `4px 12px`
- **Border Radius:** `6px`
- **Font:** Poppins, 12px, 600 weight
- **Border:** `1px solid #E8FD0A`

### Tabs

#### Tab Container
- **Background:** `#FFFFFF`
- **Border Bottom:** `2px solid #E5E7EB`
- **Padding:** `0px`
- **Display:** `flex`
- **Gap:** `0px`

#### Tab Item (Inactive)
- **Padding:** `16px 24px`
- **Color:** `#6B7280`
- **Font:** Poppins, 16px, 600 weight
- **Border Bottom:** `2px solid transparent`
- **Cursor:** `pointer`
- **Hover State:** Color `#374151`, border-bottom `2px solid #E5E7EB`

#### Tab Item (Active)
- **Padding:** `16px 24px`
- **Color:** `#111827`
- **Font:** Poppins, 16px, 600 weight
- **Border Bottom:** `2px solid #C3DC52`
- **Background:** `rgba(195, 220, 82, 0.05)`

## 5. Layout Principles

### Spacing System
Base unit: `4px`. All spacing derives from multiples of this unit, creating harmonious, predictable layouts.

- `4px`: Minimal padding for compact components
- `8px`: Tight spacing between elements
- `12px`: Standard compact padding
- `16px`: Standard gap between grid items
- `20px`: Standard padding for cards and containers
- `24px`: Moderate margin between sections
- `32px`: Gap for related component groups
- `40px`: Moderate section margin
- `60px`: Large gap between major sections
- `100px`: Extra-large padding for hero sections
- `160px`: Maximum margin for layout isolation

### Grid & Container
- **Max Container Width:** `1200px`
- **Gutter:** `16px` between columns
- **Column Strategy:** 12-column responsive grid; collapses to 6 columns on tablet, single column on mobile
- **Section Patterns:** Full-width backgrounds with contained content; alternating left/right layouts for visual rhythm
- **Padding:** `40px` horizontal on desktop, `24px` on tablet, `20px` on mobile

### Whitespace Philosophy
Embrace generous whitespace to create breathing room and reduce cognitive load. Use whitespace as a design element equal to content. Align all elements to the spacing system to maintain consistency. Avoid cramped layouts; prioritize clarity and scanability over information density.

### Border Radius Scale
- `2px`: Minimal rounding for technical components
- `4px`: Subtle rounding for inputs and small elements
- `5px`: Standard rounding for buttons
- `6px`: Badges and form elements
- `8px`: Cards and medium containers
- `12px`: Feature cards and larger components
- `16px`: Large modals and overlay elements
- `50%`: Perfect circles for avatars and icon buttons

## 6. Depth & Elevation

| Level | Treatment | Use |
|-------|-----------|-----|
| Flat | No shadow | Base surfaces (backgrounds, sections) |
| Level 1 | `0px 2px 8px rgba(0, 0, 0, 0.08)` | Cards, modest elevation |
| Level 2 | `0px 4px 12px rgba(195, 220, 82, 0.3)` | Feature cards, green components |
| Level 3 | `0px 4px 16px rgba(59, 130, 246, 0.2)` | Interactive elements, hover states |
| Level 4 (Dropdown) | `rgba(50, 50, 93, 0.25) 0px 50px 100px -20px, rgba(0, 0, 0, 0.3) 0px 30px 60px -30px` | Dropdowns, floating panels, modals |
| Level 5 (Modal) | `0px 25px 50px -12px rgba(0, 0, 0, 0.25)` | Full-page modals, overlays |

**Shadow Philosophy**
Elevation uses subtle, naturalistic shadows that suggest light from above. Shadows are reserved for interactive and floating elements, never base layouts. Lime-green components use warmer shadow tones; blue components use cooler tones. Shadows increase in blur and spread as elements rise, creating clear visual hierarchy. Maximum shadow blur never exceeds `100px` to maintain refinement.

## 7. Do's and Don'ts

### Do
- Use `#C3DC52` lime green for all primary CTAs and brand emphasis
- Maintain minimum `16px` font size for body text; never go below `12px` for captions
- Combine Poppins with League Spartan for a contemporary, educational aesthetic
- Keep brand color usage bold and confident; don't dilute with low opacity
- Align all elements to the `4px` spacing grid for consistency
- Use `#374151` charcoal for default button and navigation text
- Employ generous whitespace; never pack content into tight containers
- Test all color combinations for WCAG AA contrast compliance (minimum 4.5:1 for text)
- Use full-width colored sections with contained content for maximum visual impact
- Apply subtle shadows only to elevated, interactive elements

### Don't
- Avoid using lime green at opacity below `0.8`; the color needs vibrancy
- Never use `#111827` navy as a background unless paired with white text; it's too dark
- Don't mix more than three font families; stick to Poppins, League Spartan, and system-ui
- Avoid border-radius values not in the defined scale; use only `2px`, `4px`, `5px`, `6px`, `8px`, `12px`, `16px`, `50%`
- Never apply shadows to base surfaces or non-interactive elements; reserve shadows for elevation only
- Don't use primary blue (`#3B82F6`) for body text; reserve for links and secondary CTAs only
- Avoid low-contrast text combinations; charcoal on light gray fails accessibility standards
- Never stretch cards beyond `360px` width without clear design justification
- Don't use all-caps text for body content; reserve for labels and metadata only
- Avoid removing hover and focus states; always provide clear interactive feedback

## 8. Responsive Behavior

### Breakpoints

| Name | Width | Key Changes |
|------|-------|-------------|
| Mobile | `320px` - `640px` | Single column, `20px` padding, `14px` navigation font, stacked cards |
| Tablet | `641px` - `1024px` | 6-column grid, `24px` padding, `16px` navigation font, 2-column card layout |
| Desktop | `1025px`+ | 12-column grid, `40px` padding, full navigation, 3+ column card layout, `1200px` max width |
| Large Desktop | `1441px`+ | Same as desktop with increased section padding to `60px` |

### Touch Targets
- **Minimum Button Size:** `44px × 44px` (all interactive elements)
- **Minimum Link Target:** `48px × 48px` (touch-friendly navigation)
- **Tap Spacing:** `8px` minimum between adjacent touch targets
- **Icon Buttons:** `40px × 40px` minimum, with `8px` internal padding
- **Form Inputs:** Minimum height `44px`, width `100%` on mobile

### Collapsing Strategy
- **Mobile Navigation:** Collapse primary navigation into hamburger menu at `640px` breakpoint
- **Card Layouts:** Stack cards vertically on mobile (`320px`-`640px`), two columns on tablet (`641px`-`1024px`), three columns on desktop
- **Hero Text:** Reduce display font from `70px` to `40px` on tablet, `28px` on mobile; maintain line-height proportions
- **Spacing Reduction:** Decrease margin/padding by 50% on mobile; decrease by 25% on tablet
- **Image Scaling:** Images scale to `100%` width on mobile; maintain aspect ratio; use responsive `srcset` attributes
- **Feature Sections:** Convert side-by-side layouts (text + image) to stacked layouts on tablet and mobile

## 9. Agent Prompt Guide

### Quick Color Reference
- **Primary CTA:** Lime Green (`#C3DC52`) — all primary buttons, brand highlights
- **Secondary CTA:** Cobalt Blue (`#3B82F6`) — alternative actions, links
- **Background:** White (`#FFFFFF`) or Off-White (`#F9FAFB`) — default surfaces
- **Heading Text:** Deep Gray (`#111827`) or Charcoal (`#374151`) — high contrast, readable
- **Body Text:** Charcoal (`#374151`) — primary content, main readability
- **Navigation Bar:** Olive Green (`#759600`) — top bar background
- **Success/Growth:** Lime Green (`#C3DC52`) — positive states
- **Warning:** Yellow (`#E8FD0A`, `#D2F72D`) — alerts and caution states
- **Disabled:** Medium Gray (`#636D6B`) — inactive elements
- **Borders/Dividers:** Light Gray (`#E5E7EB`, `#D1D5DB`) — subtle separation

### Iteration Guide

1. **Primary Brand Expression:** Always use `#C3DC52` lime green as the dominant accent for CTAs, hero highlights, and brand emphasis. This is the institution's signature color representing growth and innovation.

2. **Navigation & Hierarchy:** Leverage League Spartan (`700` weight) for all major headings (`40px` and above); use Poppins for body hierarchy. Maintain strict font-weight contrast: headlines `600`-`700`, body `400`.

3. **Spacing Consistency:** All margins, padding, and gaps must be multiples of `4px`. Common values: `20px` (card padding), `24px` (section margin), `40px` (large section padding), `16px` (grid gap).

4. **Component Elevation:** Apply shadows **only** to interactive elements and floating components. Use shadow Level 1 (`0px 2px 8px rgba(0, 0, 0, 0.08)`) for hover states on cards; Level 4 for dropdowns/modals.

5. **Touch & Accessibility:** All interactive targets must be minimum `44px × 44px`. Ensure text contrast ratio ≥ 4.5:1 (WCAG AA). Never hide focus states; use clear visual focus rings (`3px solid outline`).

6. **Responsive Typography:** Display headlines scale from `70px` (desktop) → `40px` (tablet) → `28px` (mobile). Body text remains `16px` minimum across all breakpoints. Use fluid typography scaling within breakpoint ranges if supported.

7. **Form Styling:** All inputs use `2px` borders, `6px` border-radius, and `12px` padding. Focus state adds `3px` inset ring: `0px 0px 0px 3px rgba(59, 130, 246, 0.1)`. Error states change border to `#EF4444`.

8. **Card & Container Design:** Feature cards must use `#C3DC52` background with `24px` padding and `12px` border-radius. Apply subtle shadow and `translateY(-2px)` on hover for interactive feedback. Maintain `360px` minimum width on desktop.

9. **Color Application Rules:** Lime green (`#C3DC52`) for primary actions; cobalt blue (`#3B82F6`) for secondary actions and links; charcoal (`#374151`) for default text; white (`#FFFFFF`) for clean surfaces. Never layer lime green at opacity below `0.8`; maintain vibrancy.

10. **Responsive Grid Layout:** Implement 12-column grid on desktop (`1025px`+), collapse to 6 columns on tablet, single column on mobile. Use `16px` gutters. Section containers max-width `1200px` centered with `40px` horizontal padding (desktop), `24px` (tablet), `20px` (mobile).