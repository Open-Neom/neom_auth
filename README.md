# neom_auth

[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)](https://github.com/Open-Neom/neom_auth)
[![License](https://img.shields.io/badge/license-Apache%202.0-green.svg)](LICENSE)

neom_auth is a fundamental module within the Open Neom ecosystem,
exclusively responsible for handling all user authentication processes.
It provides a secure, robust, and user-friendly gateway for users to access the platform,
whether through traditional email/password, social logins (Google, Apple), or phone number verification.

This module is meticulously designed to ensure the highest standards of security and user data protection,
aligning with Open Neom's commitment to decentralization and user autonomy. 
It fully adheres to the Clean Architecture principles, ensuring its logic is highly testable,
maintainable, and decoupled from external frameworks. neom_auth seamlessly integrates with neom_core
for core user services and neom_commons for shared UI components, providing a cohesive authentication experience.

🌟 Features & Responsibilities
neom_auth provides a comprehensive set of authentication functionalities:
•	User Registration (Sign Up): Allows new users to create accounts using email/password,
    collecting essential initial information.
•	User Login (Sign In): Supports various login methods including:
o	Email and Password.
o	Google Sign-In.
o	Apple Sign-In (for iOS 13+ devices).
o	Phone Number Verification (via SMS code).
•	Password Management: Includes functionality for password reset (forgot password flow) through email.
•	User Session Management: Manages the authentication state of the user, determining if they are logged in,
    logging out, or in a transitional state.
•	Account & Profile Removal: Orchestrates the process for users to remove their account
    or specific profiles from the platform.
•	Terms and Conditions Agreement: Integrates the acceptance of legal terms during the sign-up process.
•	Authentication Status Tracking: Provides an observable authentication status (AuthStatus)
    to inform other parts of the application about the user's login state.
•	Error Handling: Implements robust error handling for authentication failures,
    providing clear feedback to the user.

📦 Technical Highlights / Why it Matters (for developers)
For developers, neom_auth is an excellent module to study for understanding:
•	Firebase Authentication Integration: Demonstrates best practices for integrating Firebase Authentication
    for various login providers (Email/Password, Google, Apple, Phone).
•	Interface-Based Services: Showcases the implementation of LoginService, SignUpService, and ForgotPasswordService
    interfaces, ensuring that the authentication logic is decoupled from UI and concrete implementations.
    This is a prime example of the Dependency Inversion Principle (DIP).
•	GetX for State Management: Utilizes GetX for managing authentication-related state
    (LoginController, SignUpController, ForgotPasswordController), handling reactive variables
    (RxBool, Rx<AuthStatus>), and orchestrating complex authentication flows.
•	Secure Credential Handling: Implements methods for securely handling user credentials and integrating
    with platform-specific authentication flows (e.g., Apple ID).
•	Input Validation: Incorporates robust client-side validation for user inputs
    (email, password, names) to ensure data integrity.
•	Cross-Platform Adaptability: Includes logic to conditionally enable/disable social login options
    based on platform (web vs. mobile) and device version (iOS 13+).
•	Error Handling and User Feedback: Provides clear examples of catching and handling FirebaseAuthException
    errors and delivering user-friendly messages.

How it Supports the Open Neom Initiative
neom_auth is fundamental to the entire Open Neom ecosystem and the Tecnozenism vision by:
•	Securing the Ecosystem: Provides the essential security layer for user access, protecting personal
    data and ensuring the integrity of the platform.
•	Enabling User Participation: By offering diverse and accessible login methods, it lowers the barrier to entry for users,
    fostering broader participation in the Open Neom community and its research initiatives.
•	Upholding Decentralization: While leveraging centralized authentication services (like Firebase),
    its modular design allows for future flexibility and potential integration with decentralized identity
    solutions as the Tecnozenism vision evolves.
•	Showcasing Architectural Excellence: As a critical, yet self-contained, module, it exemplifies Open Neom's
    commitment to Clean Architecture, demonstrating how complex and sensitive functionalities
    can be built with high quality and maintainability.
•	Foundation for Personalization: Secure authentication is the first step towards personalized experiences,
    allowing users to access their unique "Huella Armónica" and engage with tailored content.

🚀 Usage
This module provides all the necessary routes and UI components for user authentication.
It is typically the first module encountered by a new or returning user, guiding them through login,
sign-up, or password recovery processes.

🛠️ Dependencies
neom_auth relies on neom_core for core services, models, and routing constants, and on neom_commons
for reusable UI components, themes, and utility functions. It also directly depends on firebase_auth,
google_sign_in, and sign_in_with_apple for authentication functionalities.

🤝 Contributing
We welcome contributions to the neom_auth module! If you're passionate about security, user authentication flows,
or integrating new identity providers, your contributions can significantly strengthen the foundation of Open Neom.

To understand the broader architectural context of Open Neom and how neom_auth fits into the overall vision of Tecnozenism,
please refer to the main project's MANIFEST.md.

For guidance on how to contribute to Open Neom and to understand the various levels of learning and engagement
possible within the project, consult our comprehensive guide: Learning Flutter Through Open Neom: A Comprehensive Path.

📄 License
This project is licensed under the Apache License, Version 2.0, January 2004. See the LICENSE file for details.
