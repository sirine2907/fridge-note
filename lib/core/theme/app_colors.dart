import 'package:flutter/material.dart';

/// All the colors used in the app, in one place.
class AppColors {
  AppColors._();

  // Light
  static const lavender = Color(0xFFE4E0F0);
  static const white = Color(0xFFFFFFFF);
  static const violet = Color(0xFF7360F2);
  static const violetSoft = Color(0xFFF1EEFC);
  static const ink = Color(0xFF16161D);
  static const muted = Color(0xFF8A8A99);
  static const yellow = Color(0xFFFFE94D);
  static const border = Color(0xFFECEAF3);
  static const red = Color(0xFFFF4D5E);

  static const mint = Color(0xFFDDF5E3);
  static const sky = Color(0xFFDCEBFA);
  static const lilac = Color(0xFFECE6FD);
  static const peach = Color(0xFFFDE8DC);

  // Dark
  static const darkPage = Color(0xFF0C0B12);
  static const darkScreen = Color(0xFF15141D);
  static const darkCard = Color(0xFF1C1B26);
  static const darkVioletSoft = Color(0xFF2A2547);
  static const darkInk = Color(0xFFF4F3FA);
  static const darkMuted = Color(0xFF9B99AE);
  static const darkBorder = Color(0xFF2B2938);

  static const darkMint = Color(0xFF1C3427);
  static const darkSky = Color(0xFF1B2B3E);
  static const darkLilac = Color(0xFF2B2548);
  static const darkPeach = Color(0xFF3A2A22);

  /// Colors people can pick for their avatar.
  static const avatarChoices = <Color>[
    Color(0xFF7360F2),
    Color(0xFF2FB67C),
    Color(0xFFF2994A),
    Color(0xFFE85D9A),
    Color(0xFF3B9BE8),
    Color(0xFF16161D),
  ];
}

/// Colors that change between light and dark mode.
/// Read them in widgets with `context.colors`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.page,
    required this.screen,
    required this.card,
    required this.primary,
    required this.primarySoft,
    required this.ink,
    required this.muted,
    required this.border,
    required this.yellow,
    required this.mint,
    required this.sky,
    required this.lilac,
    required this.peach,
  });

  final Color page;
  final Color screen;
  final Color card;
  final Color primary;
  final Color primarySoft;
  final Color ink;
  final Color muted;
  final Color border;
  final Color yellow;
  final Color mint;
  final Color sky;
  final Color lilac;
  final Color peach;

  static const light = AppPalette(
    page: AppColors.lavender,
    screen: AppColors.white,
    card: AppColors.white,
    primary: AppColors.violet,
    primarySoft: AppColors.violetSoft,
    ink: AppColors.ink,
    muted: AppColors.muted,
    border: AppColors.border,
    yellow: AppColors.yellow,
    mint: AppColors.mint,
    sky: AppColors.sky,
    lilac: AppColors.lilac,
    peach: AppColors.peach,
  );

  static const dark = AppPalette(
    page: AppColors.darkPage,
    screen: AppColors.darkScreen,
    card: AppColors.darkCard,
    primary: AppColors.violet,
    primarySoft: AppColors.darkVioletSoft,
    ink: AppColors.darkInk,
    muted: AppColors.darkMuted,
    border: AppColors.darkBorder,
    yellow: AppColors.yellow,
    mint: AppColors.darkMint,
    sky: AppColors.darkSky,
    lilac: AppColors.darkLilac,
    peach: AppColors.darkPeach,
  );

  @override
  AppPalette copyWith({Color? primary}) {
    return AppPalette(
      page: page,
      screen: screen,
      card: card,
      primary: primary ?? this.primary,
      primarySoft: primarySoft,
      ink: ink,
      muted: muted,
      border: border,
      yellow: yellow,
      mint: mint,
      sky: sky,
      lilac: lilac,
      peach: peach,
    );
  }

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      page: Color.lerp(page, other.page, t)!,
      screen: Color.lerp(screen, other.screen, t)!,
      card: Color.lerp(card, other.card, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      border: Color.lerp(border, other.border, t)!,
      yellow: Color.lerp(yellow, other.yellow, t)!,
      mint: Color.lerp(mint, other.mint, t)!,
      sky: Color.lerp(sky, other.sky, t)!,
      lilac: Color.lerp(lilac, other.lilac, t)!,
      peach: Color.lerp(peach, other.peach, t)!,
    );
  }
}

extension AppPaletteX on BuildContext {
  AppPalette get colors => Theme.of(this).extension<AppPalette>()!;
}
