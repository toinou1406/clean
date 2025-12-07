# Application Blueprint

## Overview

This document outlines the design, features, and development plan for the FastClean application. The app's primary purpose is to help users clean and manage their photo library by identifying and deleting unnecessary images like duplicates, blurry photos, and screenshots.

## Style and Design (New UI - Logo-Based)

The entire application UI will be redesigned to match the provided logo, creating a simple, modern, and almost childlike aesthetic.

*   **Color Palette**:
    *   **Primary Green (Seed Color)**: A vibrant teal/jade green inspired by the main body of the trash can logo.
    *   **Accent Green**: A bright, energetic lime green from the lightning bolt, used for highlights and interactive elements.
    *   **Dark Blue/Teal**: A deep, dark color from the logo's outlines, used for text and secondary elements to provide contrast.
    *   **Greys**: Light and dark greys for backgrounds, surfaces, and disabled states, taken from the logo's lid and shadows.
    *   **Texture**: A subtle noise texture will be applied to the main background to add a premium, tactile feel.

*   **Typography**:
    *   **Font**: `Nunito` from Google Fonts will be used as the primary font family. Its rounded and friendly appearance is a perfect match for the desired aesthetic.
    *   **Hierarchy**: Font sizes will be expressive to create a clear visual hierarchy (e.g., large, bold titles, smaller body text).

*   **Iconography**:
    *   Icons will be simple, rounded, and filled, complementing the `Nunito` font and the overall friendly theme.

*   **Components & Effects**:
    *   **Buttons**: Rounded corners, with a subtle glow or shadow effect on interaction.
    *   **Cards/Containers**: Soft, deep drop shadows to create a "lifted" look and a sense of depth.
    *   **Layout**: Clean, spacious, and balanced layouts with generous padding and margins.

## Features

*   **Photo Analysis**: Scans the user's photo library directly on the device.
*   **Junk Detection**: Identifies blurry photos, bad screenshots, and duplicates.
*   **Image Deletion**: Allows users to delete selected photos to free up space.
*   **Localization**: Supports multiple languages (English, French, Spanish, Chinese).
*   **Privacy-Focused**: All processing is done on-device; no images are uploaded to servers.

## Current Action Plan: UI Redesign

1.  **Setup**: Add `google_fonts` and `provider` packages.
2.  **Theme Implementation**:
    *   Create a central `ThemeProvider` to manage light/dark modes.
    *   Define `ThemeData` for both modes using the new color palette and `Nunito` font.
    *   Customize default styles for `AppBar`, `ElevatedButton`, etc.
3.  **Asset Integration**:
    *   Add the app logo and a noise texture image to the project assets.
    *   Update `pubspec.yaml` to include the new assets.
4.  **Screen Redesign**:
    *   **`main.dart`**: Overhaul the main application entry point to use the new theme.
    *   **`PermissionScreen`**: Restyle the permission request screen.
    *   **`LanguageSettingsScreen`**: Restyle the language selection screen.
    *   **Custom Widgets**: Update all custom widgets (`ActionButton`, `AuroraCircularIndicator`, etc.) to conform to the new design language.
