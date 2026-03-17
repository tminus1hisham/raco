# Eagles Eye - UI Improvement Tracker

## App Overview
**Name:** Eagles Eye (Vehicle Tracking App)
**Framework:** Flutter with GetX state management
**Primary Color:** Blue (#287ec3) | **Accent:** Green (#2dda94), Red (#E62727)
**Background:** Light Grey (#F2F2F2) | **Cards:** White with soft shadows

---

## Current Design System Audit

### Design Tokens (lib/config/constants.dart)
| Token | Value | Usage |
|-------|-------|-------|
| `kBlue` | `#287ec3` | Primary actions, headers, active states |
| `kWhite` | `#FFFFFF` | Backgrounds, text on primary |
| `kBlack` | `#000000` | Primary text |
| `kGrey` | `#7A7A73` | Secondary text, inactive states |
| `kBgGrey` | `#F2F2F2` | Screen backgrounds |
| `kRed` | `#E62727` | Errors, offline, violations |
| `kSuccessGreen` | `#2dda94` | Online, success states |
| `kLightGrey` | `#BDBDBD` | Borders, dividers |

### Typography
- No custom font family defined (uses Material default)
- Font sizes: 12px (caption), 14px (body), 16px (button/body), 18px (subtitle), 20-25px (heading)
- Font weights: w500 (regular), w600 (semibold), w700/bold (heading)

### Spacing
- Screen padding: 20px horizontal
- Card padding: 16-20px
- Section gaps: 10-20px SizedBox
- **Issue:** Inconsistent spacing values across screens

### Border Radius
- Buttons: 15px
- Cards: 12-16px
- Input fields: 12px
- Headers: 16px
- Status badges: 20px (pill shape)

### Shadows
- Cards: `BoxShadow(color: black.withOpacity(0.04-0.08), blurRadius: 6-10, offset: (0, 2-4))`
- Map controls: `BoxShadow(color: black.withOpacity(0.1), blurRadius: 8, offset: (0, 2))`

---

## Screen-by-Screen UI Issues & Improvements

### 1. Onboarding Screen (`views/auth/onboarding_screen.dart`)
- [x] **Audit complete**
- [ ] Logo is too large (200x200) - takes up too much screen real estate
- [ ] `Padding(padding: const EdgeInsets.all(0.0))` - redundant zero padding wrapper
- [ ] Carousel images reuse `image_1.jpg` for items 3 and 4
- [ ] "Powered by Atom" footer looks disconnected from the rest of the design
- [ ] Skip button uses `Colors.grey.shade400` border instead of design token
- [ ] No page transition animation between carousel items
- [ ] Bottom buttons area has no visual separation from content

### 2. Login Screen (`views/auth/login_screen.dart`)
- [x] **Audit complete**
- [ ] Logo (180x180) still large - consider 120-140px for login
- [ ] Biometric button is commented out but UI still allocates Row space
- [ ] "This filed is required" - typo in validation message
- [ ] No visual feedback on button press (no ripple/press state on CustomButton)
- [ ] Password field and phone field have no vertical spacing label
- [ ] Terms text wraps awkwardly with `\n` - needs better line flow
- [ ] Loading overlay uses `Colors.black.withOpacity(0.3)` - could be more refined

### 3. Dashboard / Bottom Navigation (`views/dashboard.dart`)
- [x] **Audit complete**
- [ ] Bottom nav uses hardcoded `Colors.grey` instead of `kGrey`
- [ ] No smooth transition between bottom nav tabs
- [ ] Notification badge uses hardcoded `Colors.red` instead of `kRed`
- [ ] Badge text `fontSize: 10` is very small on some devices
- [ ] No selected/unselected icon variants (filled vs outlined)
- [ ] `selectedFontSize: 16` and `unselectedFontSize: 14` gap is too large

### 4. Home Screen - Map Tab (`views/home_screen.dart`)
- [x] **Audit complete**
- [ ] Search bar uses `borderRadius: 5` while rest of app uses 12-16 - inconsistent
- [ ] Map control buttons are repetitive - 8 identical Container/BoxDecoration blocks that could use a shared builder
- [ ] Map controls stack is very tall (8 buttons) - may overflow on smaller screens
- [ ] Countdown timer button shows raw number - no label explaining what it is
- [ ] Vehicle bottom sheet has duplicate `SizedBox(height: 10)` at lines 1144-1146
- [ ] Bottom sheet "More Details" button lacks accessibility label
- [ ] `isVehicleActive` logic is inverted (`ignitionStatus == 0` = active?)
- [ ] Quick action buttons in bottom sheet use different styling than SelectedCarScreen
- [ ] Tab bar container has hardcoded `Colors.grey[100]` background

### 5. Cars Screen / List Tab (`views/cars/cars_screen.dart`)
- [x] **Audit complete**
- [ ] Stats cards (Online/Offline) have small icon (16px in 32px container)
- [ ] No pull-to-refresh on vehicle list
- [ ] Loading overlay identical to login - should be extracted to shared widget
- [ ] List has no separator/gap between CarInfoCards (only 5px top padding)
- [ ] No empty state when no vehicles exist

### 6. Car Info Card (`widgets/cards/car_info_card.dart`)
- [x] **Audit complete**
- [ ] "Renew Certificate" button uses hardcoded `Colors.green` instead of `kSuccessGreen`
- [ ] Plan bottom sheet is duplicated identically in `selected_car_screen.dart` - should be extracted
- [ ] "This filed is required" - same typo as login
- [ ] Card vertical padding is tight (10px) compared to horizontal (20px)
- [ ] Status badge pill and speed text could be better aligned

### 7. Selected Car Screen (`views/cars/selected_car_screen.dart`)
- [x] **Audit complete**
- [ ] Quick action buttons use different styling than home screen bottom sheet version
- [ ] "violations" label is lowercase while others are title case
- [ ] `_buildCommandItem` and `_buildSettingsCard` are near-identical to settings_screen.dart - duplication
- [ ] Engine ON/OFF switch has `onChanged: (bool value) {}` - empty handler, confusing UX
- [ ] Plan bottom sheet is copy-pasted from `car_info_card.dart` (~100 lines duplicated)
- [ ] Vehicle details hardcodes "KDG001A" instead of using `widget.licensePlate`
- [ ] "infomation" typo in subtitle text
- [ ] "See your the vehicle" - grammatical error in subtitle

### 8. Playback Screen (`views/playback_screen.dart`)
- [x] **Audit complete**
- [ ] Only screen that uses colored AppBar (`backgroundColor: kBlue`) - inconsistent with other screens
- [ ] Control panel at bottom is very tall, may overlap map on small screens
- [ ] Date picker buttons are 80px tall - could be more compact
- [ ] Speed label `${_playbackSpeed.toStringAsFixed(1)}x` lacks context
- [ ] Two empty state variants are nearly identical code blocks
- [ ] "Clear Dates" button style differs from other buttons in app

### 9. Notification Screen (`views/notification_screen.dart`)
- [x] **Audit complete**
- [ ] "Mark all as read" button could be icon-only on small screens
- [ ] Notification detail bottom sheet uses DraggableScrollableSheet inconsistently with other sheets
- [ ] Empty state icon (80px) is very large
- [ ] No animation for marking as read
- [ ] No swipe-to-dismiss or swipe-to-read gesture

### 10. Settings Screen (`views/settings_screen.dart`)
- [x] **Audit complete**
- [ ] "Support" section has trailing `_buildDivider()` after last item
- [ ] "Logout" section also has trailing divider after the single item
- [ ] `SizedBox(height: 100)` at bottom is excessive padding
- [ ] Section headers use `Colors.grey.shade600` instead of `kGrey`

### 11. Custom Header Widget (`widgets/custom_header.dart`)
- [x] **Audit complete**
- [ ] Class name `customHeader` violates Dart naming convention (should be PascalCase)
- [ ] `showBackButton` is not `final` (mutable field in StatelessWidget)
- [ ] Gradient always goes from full kBlue to 30% opacity - limited flexibility
- [ ] Fixed 70x50 icon container may not scale well across screen sizes

### 12. Custom Button (`widgets/buttons/custom_button.dart`)
- [x] **Audit complete**
- [ ] Wraps ElevatedButton in Container with same border radius - redundant nesting
- [ ] No disabled state styling
- [ ] No loading state variant
- [ ] StatefulWidget but has no mutable state - could be StatelessWidget
- [ ] No press animation/feedback

### 13. Input Field (`widgets/inputs/custom_input.dart`)
- [x] **Audit complete**
- [ ] Error text hidden with `height: 0, fontSize: 0` hack instead of proper approach
- [ ] No focus border color change
- [ ] No label text support (only hint text)
- [ ] Background is `Colors.grey.shade100` instead of design token

### 14. Notification Card (`widgets/cards/notifications_card.dart`)
- [x] **Audit complete**
- [ ] Unread indicator relies only on icon/background color - no unread dot
- [ ] Message truncated to 1 line with no way to preview more
- [ ] Card bottom margin is only 5px - cards feel crammed

---

## Cross-Cutting UI Issues

### Consistency Issues
1. **Hardcoded colors** used instead of design tokens in many places (Colors.grey, Colors.green, Colors.red)
2. **Border radius values** vary: 5, 8, 10, 12, 15, 16, 20 - should be standardized
3. **Shadow styles** differ across components with slight opacity/blur variations
4. **Font sizes** are ad-hoc per screen rather than following a type scale
5. **Spacing** uses arbitrary values (5, 8, 10, 12, 16, 20, 24, 30, 32, 40) with no clear system

### Missing UI Patterns
1. No **ThemeData** configuration (only AppBarTheme for status bar)
2. No **dark mode** support
3. No **responsive breakpoints** or adaptive layouts
4. No **skeleton/shimmer** loading states (uses spinner everywhere)
5. No **pull-to-refresh** on list screens
6. No **page transitions** defined (uses default MaterialPageRoute)
7. No **haptic feedback** on button presses
8. No **empty state** illustrations (only text + icon)

### Code Duplication (UI-related)
1. Plan bottom sheet code duplicated in `car_info_card.dart` and `selected_car_screen.dart`
2. `_buildSettingsCard`, `_buildSettingsItem`, `_buildDivider` patterns duplicated across settings and selected car screens
3. Loading overlay (black + spinner) duplicated in 4+ screens
4. Quick action button widget defined separately in `home_screen.dart` and `selected_car_screen.dart`
5. Map control button container repeated 8 times with identical decoration

### Accessibility Concerns
1. No semantic labels on icon buttons
2. Insufficient color contrast in some grey text on light backgrounds
3. Touch targets on some buttons may be too small (45x45 map controls)
4. No support for large text/accessibility scaling

---

## Recommended Improvement Priority

### Phase 1: Foundation (Design System)
- [ ] Define comprehensive `ThemeData` with `ColorScheme`, `TextTheme`, `ButtonTheme`
- [ ] Create spacing constants (4, 8, 12, 16, 20, 24, 32, 40, 48)
- [ ] Standardize border radius (small: 8, medium: 12, large: 16, pill: 24)
- [ ] Define elevation/shadow levels (low, medium, high)
- [ ] Add a custom font (e.g., Inter, Poppins) for brand identity

### Phase 2: Shared Components
- [ ] Extract loading overlay to shared widget
- [ ] Extract plan bottom sheet to shared widget
- [ ] Unify quick action button styles
- [ ] Add shimmer/skeleton loading states
- [ ] Add empty state widget with illustration
- [ ] Improve button states (disabled, loading, pressed)

### Phase 3: Screen-Level Polish
- [ ] Tighten onboarding layout, reduce logo size
- [ ] Redesign home screen map controls (floating action menu or collapsible panel)
- [ ] Improve car info cards with better information hierarchy
- [ ] Polish playback controls panel
- [ ] Add pull-to-refresh to list screens
- [ ] Add smooth page transitions

### Phase 4: Delight
- [ ] Add subtle animations (list item entrance, tab transitions)
- [ ] Add haptic feedback on key interactions
- [ ] Improve empty states with Lottie animations
- [ ] Add dark mode support
- [ ] Micro-interactions (badge count animation, status change transitions)

---

## File Inventory

### Screens (20 files)
| File | Screen | Status |
|------|--------|--------|
| `views/auth/onboarding_screen.dart` | Onboarding carousel | Audited |
| `views/auth/login_screen.dart` | Login | Audited |
| `views/auth/register_screen.dart` | Registration | Needs audit |
| `views/auth/forgot_password_screen.dart` | Forgot password | Needs audit |
| `views/auth/reset_password_screen.dart` | Reset password | Needs audit |
| `views/auth/verification_screen.dart` | OTP verification | Needs audit |
| `views/dashboard.dart` | Bottom nav shell | Audited |
| `views/home_screen.dart` | Map + search | Audited |
| `views/cars/cars_screen.dart` | Vehicle list | Audited |
| `views/cars/car_list_screen.dart` | Filtered vehicle list | Needs audit |
| `views/cars/selected_car_screen.dart` | Vehicle detail | Audited |
| `views/cars/vehicle_details.dart` | Vehicle info | Needs audit |
| `views/cars/vehicle_live_location.dart` | Live location map | Needs audit |
| `views/cars/driver_behaviour.dart` | Charts & metrics | Needs audit |
| `views/cars/commands.dart` | Device commands | Needs audit |
| `views/cars/command_history.dart` | Command log | Needs audit |
| `views/cars/geofencing_screen.dart` | Geofence setup | Needs audit |
| `views/cars/general_reports.dart` | Reports view | Needs audit |
| `views/playback_screen.dart` | Trip replay | Audited |
| `views/violations_screen.dart` | Violations list | Needs audit |
| `views/reports_screen.dart` | Report generation | Needs audit |
| `views/notification_screen.dart` | Notifications | Audited |
| `views/settings_screen.dart` | Settings | Audited |
| `views/settings/account_screen.dart` | Profile management | Needs audit |
| `views/settings/change_password.dart` | Password change | Needs audit |
| `views/settings/delete_account.dart` | Account deletion | Needs audit |
| `views/settings/about_us.dart` | About page | Needs audit |
| `views/settings/contact_us.dart` | Contact form | Needs audit |
| `views/settings/privacy_policy.dart` | Privacy policy | Needs audit |
| `views/settings/terms_and_conditions.dart` | Terms | Needs audit |
| `views/technician/technician_home_screen.dart` | Tech dashboard | Needs audit |
| `views/technician/devices_screen.dart` | Device management | Needs audit |
| `views/technician/create_device.dart` | Device creation | Needs audit |
| `views/transport managers/manager_screen.dart` | Manager view | Needs audit |
| `views/transport managers/manager_car_list.dart` | Manager car list | Needs audit |

### Widgets (10 files)
| File | Widget | Status |
|------|--------|--------|
| `widgets/buttons/custom_button.dart` | Primary button | Audited |
| `widgets/buttons/custom_border_button.dart` | Outline button | Needs audit |
| `widgets/inputs/custom_input.dart` | Text input | Audited |
| `widgets/cards/car_info_card.dart` | Vehicle card | Audited |
| `widgets/cards/notifications_card.dart` | Notification item | Audited |
| `widgets/cards/command_card.dart` | Command card | Needs audit |
| `widgets/cards/manager_car_card.dart` | Manager car card | Needs audit |
| `widgets/cards/manager_info_card.dart` | Manager info card | Needs audit |
| `widgets/custom_header.dart` | Gradient header | Audited |
| `widgets/modal/custom_alert.dart` | Alert dialog | Needs audit |
| `widgets/modal/infomation_modal.dart` | Action dialog | Needs audit |
| `widgets/modal/no_internet_modal.dart` | No internet dialog | Needs audit |

---

## Change Log

| Date | Change | Files Modified | Status |
|------|--------|---------------|--------|
| 2026-03-12 | Initial audit & tracker created | N/A | Complete |
| | | | |

