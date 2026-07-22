// === MMD Thunderbird ===
// Enable userChrome.css / userContent.css (the MMD monochrome theme).
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// Our GTK theme derives from HighContrastInverse; TB would otherwise detect
// "GTK high-contrast" and force light system colors. Disable that so our
// dark chrome + prefers-color-scheme apply.
user_pref("widget.content.gtk-high-contrast.enabled", false);

// Force dark chrome (MMD is dark-only).
user_pref("ui.systemUsesDarkTheme", 1);
