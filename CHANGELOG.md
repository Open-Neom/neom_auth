### 2.0.0 - Security & UX Improvements

This release focuses on security enhancements and improved user experience during authentication flows.

**Security Improvements:**

* **Credential Clearing on Logout:**
    * Email and password fields are now automatically cleared when users sign out or delete their account.
    * Prevents sensitive data from persisting in memory after logout.
    * Firebase credentials are also nullified to ensure complete session cleanup.

**Bug Fixes:**

* **Google Sign-In Cancellation Handling:**
    * Users canceling Google Sign-In no longer see technical error messages.
    * Cancellation is now handled silently with proper logging.
    * Specific handling for `GoogleSignInException` with `canceled` code.

* **Apple Sign-In Cancellation:**
    * Properly handles `SignInWithAppleAuthorizationException` for user cancellations.
    * Only shows error messages for actual failures, not user-initiated cancellations.

**Code Quality:**

* **Removed Unused Imports:**
    * Cleaned up unused imports (`common_translation_constants`, `validator`).
    * Improved code organization and reduced bundle size.

* **Enhanced Email Detection:**
    * Improved logic for detecting user email from Firebase `providerData`.
    * Prioritizes email over provider UID for modern authentication flows.

**New Features:**

* **New Translation Constants:**
    * Added `loginError` and `loginFailed` translation keys for better localized error messages.

**Roadmap (Future Versions):**

* Cross-app authentication synchronization within the Open Neom ecosystem.
* Enhanced phone number verification with SMS.
* Biometric authentication support.

---

### 1.0.0 - Initial Release & Decoupling from neom_commons

This marks the **initial official release (v1.0.0)** of `neom_auth` as a standalone, independent module within the Open Neom ecosystem. Previously, authentication functionalities were often tightly coupled within other modules or directly managed by the main application (`neom_app`) and relied heavily on `neom_commons` for UI. This decoupling is a crucial step in formalizing the authentication layer, enhancing modularity, and strengthening Open Neom's adherence to Clean Architecture principles.

**Key Highlights of this Release:**

* **Module Decoupling & Self-Containment:**
    * `neom_auth` now encapsulates all authentication-related UI, logic, and routing, completely separated from other modules.
    * This ensures that `neom_auth` is a highly focused and reusable component for managing user access.

* **Centralized Authentication Management:**
    * Provides a comprehensive set of authentication flows, including:
        * User Registration (Sign Up) with email/password.
        * User Login (Sign In) via email/password, Google, and Apple.
        * Password Reset functionality.
        * Account and Profile removal processes.
        * Phone number verification (SMS code).

* **Direct External Dependencies:**
    * Now directly manages its external authentication dependencies (`firebase_auth`, `google_sign_in`, `sign_in_with_apple`), centralizing their usage within this module.

* **Enhanced Maintainability & Scalability:**
    * As a dedicated and self-contained module, `neom_auth` is now significantly easier to maintain, test, and extend without impacting other parts of the application.
    * This aligns perfectly with the overall architectural vision of Open Neom, fostering a more collaborative and efficient development environment for sensitive functionalities.

* **Leverages Core Open Neom Modules:**
    * Built upon `neom_core` for foundational services (like `LoginService`, `UserService`) and routing constants, and `neom_commons` for shared UI components and theming, ensuring consistency and seamless integration within the ecosystem.