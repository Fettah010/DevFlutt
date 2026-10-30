# Accessibility review checklist

Use this checklist on each release candidate and record the device, OS, app
commit, Flutter version, reviewer, date, and observed result. Widget tests and
Flutter's `AccessibilityGuideline` checks cover only the specific generated
fixtures; they do not establish WCAG conformance or replace assistive technology
review.

## Manual review record

- App commit:
- Device and OS version:
- Flutter version:
- Reviewer and date:
- Result: Not run / Pass with findings / Follow-up required
- Findings and follow-up issues:

## Device checks

- [ ] Android TalkBack can reach every action in a logical order, announces
  control purpose and state, and can activate buttons, dismiss messages, use
  dialogs, and navigate back.
- [ ] Android keyboard or switch navigation exposes visible focus and follows
  the visual reading order. Text fields can be reached, edited, and submitted.
- [ ] At the largest supported system font setting, important text, controls,
  validation feedback, dialogs, and bottom sheets remain visible and usable.
- [ ] Light and dark themes keep text, icons, borders, and focus indicators
  distinguishable. Do not rely on color alone to convey status.
- [ ] Arabic is right-to-left, mixed Arabic/Latin content remains readable, and
  directional icons and control order match the action.
- [ ] With Android's remove-animations setting enabled, navigation and state
  changes remain understandable and immediate; no required information depends
  on animation.

## Evidence boundary

Until a reviewer records the manual review above, device-level TalkBack,
keyboard/switch, contrast, and reduced-motion behavior remain unverified. This
checklist is a release procedure, not evidence that a device review has occurred.

## Framework references

- [Flutter accessibility testing](https://docs.flutter.dev/ui/accessibility/accessibility-testing)
- [Flutter accessibility design and styling](https://docs.flutter.dev/ui/accessibility/ui-design-and-styling)
- [Flutter accessibility](https://docs.flutter.dev/ui/accessibility)
