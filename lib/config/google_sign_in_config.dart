/// Web OAuth client ID from Firebase (`google-services.json` oauth_client
/// with `client_type: 3`). Required by `google_sign_in` on Android as
/// `serverClientId` so Firebase can verify the ID token.
///
/// Android `applicationId` MUST match the package in google-services.json /
/// Google Cloud OAuth (currently `com.example.massmanager`). Changing only
/// the package string in JSON without recreating the OAuth client causes
/// `ApiException: 10` (DEVELOPER_ERROR).
///
/// To use a production id like `app.massmanager`:
/// 1. Firebase Console → add Android app `app.massmanager`
/// 2. Add Debug SHA-1: `1DEA06D6BD7105137408EBCF77A45594D327B69E`
/// 3. Enable Authentication → Google
/// 4. Download a fresh `google-services.json` (do not hand-edit)
/// 5. Set `applicationId` to `app.massmanager`
const String kGoogleServerClientId =
    '524958440002-ju8uajfk1h38atj4dld6ck80bnisstel.apps.googleusercontent.com';
