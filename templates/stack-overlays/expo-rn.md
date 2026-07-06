# Stack overlay: React Native + Expo

Read alongside `plan.md` when `stack.yml` includes `expo-rn`.

## Workflow

- **Expo SDK (managed)** by default. Bare workflow only if a needed native module can't be installed via `expo install`.
- **Dev client** (`expo-dev-client`) for projects with config plugins. Plain Expo Go for the simplest apps.
- **EAS Build** for release builds. Never publish builds from a developer laptop.
- **EAS Update** for OTA JS-bundle updates within an SDK major. Don't OTA across SDK versions.

## Project layout

- Expo Router (file-based): `app/(tabs)/index.tsx`, `app/_layout.tsx`. Use it for new projects; older RN navigators only when migrating.
- Shared UI: `components/`, hooks: `hooks/`, services: `services/`, types: `types/`.
- Native config in `app.json` / `app.config.ts` with config plugins; avoid hand-editing `ios/` and `android/` unless you've ejected.

## Navigation

- **Expo Router** for new code; otherwise **React Navigation 6+**.
- Stack > Tab > Drawer composition is the default mental model.
- Deep links: declare schemes in `app.config.ts`, test with `xcrun simctl openurl` (iOS) and `adb shell am start` (Android).

## State

- Server state: RTK Query or React Query.
- Local state: component state, `useReducer`, or a small store (Zustand). Avoid Redux for new RN projects unless RTK Query is already in.
- Persistence: `@react-native-async-storage/async-storage` (small), `expo-sqlite` or `MMKV` (medium), `react-native-mmkv` (fast).

## Performance

- **FlatList / SectionList** with `keyExtractor`, `getItemLayout` where possible. No `.map()` of 100+ items in a `ScrollView`.
- Avoid inline functions in lists' `renderItem` — use `useCallback`.
- Memoize heavy components with `React.memo` and stable keys.
- Animations via `react-native-reanimated` v3 (worklets) > Animated API.
- Image caching: `expo-image` > `Image` from `react-native`.

## Platform differences

- `Platform.OS === 'ios' | 'android' | 'web'` for divergent behavior.
- iOS-specific concerns: safe area (`react-native-safe-area-context`), tap-target sizing, keyboard avoidance.
- Android-specific: hardware back button (`BackHandler`), notch handling, `elevation` for shadows.

## Testing

- **Unit/component:** `@testing-library/react-native` + jest.
- **E2E:** Detox (mature) or Maestro (lighter setup). Run on CI in a simulator.
- **Always test on real devices before submitting** — simulator-only validation has caused incidents.

## Deploy

- **EAS Build** with profiles for `development`, `preview`, `production`.
- **Submit:** `eas submit --platform ios` / `eas submit --platform android`.
- TestFlight for iOS internal, Play Store internal track for Android.
- Version bumping via `versionCode`/`buildNumber` automation.

## Pitfalls

- Forgetting to add a native dep to `app.config.ts` plugins → works in dev, breaks in EAS build.
- Storing PII in AsyncStorage unencrypted.
- Animations that drop frames on Android because they're not on the UI thread (use Reanimated).
- iOS App Transport Security blocking non-HTTPS dev endpoints — configure exceptions in `app.config.ts`.
- Universal links that work on simulator but not real device because of provisioning profile mismatch.
