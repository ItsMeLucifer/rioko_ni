import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'theme_state.dart';
part 'theme_cubit.freezed.dart';
part 'theme_cubit.g.dart';

@HiveType(typeId: 0)
enum ThemeDataType {
  @HiveField(0)
  classic,
  @HiveField(1)
  humani,
  @HiveField(2)
  neoDark,
  @HiveField(3)
  monochrome,
}

extension ThemeDataTypeExtension on ThemeDataType {
  String get title {
    switch (this) {
      case ThemeDataType.classic:
        return tr('core.themes.classic');
      case ThemeDataType.humani:
        return tr('core.themes.humani');
      case ThemeDataType.neoDark:
        return tr('core.themes.neoDark');
      case ThemeDataType.monochrome:
        return tr('core.themes.monochrome');
    }
  }
}

class ThemeCubit extends Cubit<ThemeDataType> {
  ThemeCubit({ThemeDataType? type})
      : type = type ?? ThemeDataType.classic,
        super(type ?? ThemeDataType.classic);

  ThemeDataType type = ThemeDataType.classic;

  bool get isLight =>
      type == ThemeDataType.classic || type == ThemeDataType.humani;

  static List<Shadow> getShadows({
    Color color = Colors.black,
    double offsetValue = 1.0,
    double blurRadius = 8.0,
  }) =>
      [
        Shadow(
          offset: Offset(offsetValue, -offsetValue),
          blurRadius: blurRadius,
          color: color,
        ),
        Shadow(
          offset: Offset(offsetValue, offsetValue),
          blurRadius: blurRadius,
          color: color,
        ),
        Shadow(
          offset: Offset(-offsetValue, offsetValue),
          blurRadius: blurRadius,
          color: color,
        ),
        Shadow(
          offset: Offset(-offsetValue, -offsetValue),
          blurRadius: blurRadius,
          color: color,
        ),
      ];

  final ThemeData _default = ThemeData.light(
    useMaterial3: true,
  ).copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color.fromARGB(255, 46, 196, 182),
    ).copyWith(
      surface: const Color.fromARGB(255, 240, 244, 255),
      primary: const Color.fromARGB(255, 159, 139, 232),
      onPrimary: const Color.fromARGB(255, 175, 153, 255),
      secondary: const Color.fromARGB(255, 255, 104, 107),
      onSecondary: const Color.fromARGB(255, 255, 166, 158),
      tertiary: Colors.grey,
      onTertiary: Colors.grey,
      outline: Colors.black,
      onSurface: Colors.white,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: Color.fromARGB(255, 239, 239, 239),
      shadowColor: Colors.black,
    ),
    iconTheme: const IconThemeData(
      color: Colors.black,
    ),
    scaffoldBackgroundColor: const Color(0xFFEAF3EF),
    appBarTheme: const AppBarTheme(
      color: Color.fromARGB(255, 222, 226, 236),
      foregroundColor: Colors.black,
    ),
    listTileTheme: const ListTileThemeData(
      titleTextStyle: TextStyle(
        fontFamily: 'Nasalization',
        color: Colors.black,
      ),
    ),
    primaryColor: const Color.fromARGB(255, 240, 244, 255),
    dividerColor: const Color.fromARGB(255, 7, 76, 41),
    buttonTheme: ButtonThemeData(
      buttonColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color.fromARGB(255, 7, 76, 41),
      ).copyWith(surface: Colors.white),
    ),
    textTheme: TextTheme(
      bodySmall: const TextStyle(
        fontFamily: 'Nasalization',
        color: Colors.black,
      ),
      bodyMedium: GoogleFonts.montserrat(
        color: Colors.black,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: const TextStyle(
        fontFamily: 'Nasalization',
        color: Colors.black,
      ),
      titleSmall: const TextStyle(
        color: Colors.white70,
        fontFamily: 'Nasalization',
      ),
      titleMedium: const TextStyle(
        color: Colors.white,
        fontFamily: 'Nasalization',
      ),
      titleLarge: const TextStyle(
        fontFamily: 'Nasalization',
        color: Colors.white,
      ),
      headlineSmall: GoogleFonts.montserrat(
        color: Colors.black,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: const TextStyle(
        fontFamily: 'Nasalization',
        color: Colors.black,
        fontSize: 22,
      ),
      headlineLarge: const TextStyle(
        fontFamily: 'Nasalization',
        color: Colors.black,
        fontSize: 35,
      ),
      labelMedium: GoogleFonts.montserrat(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
    ),
    primaryTextTheme: TextTheme(
      bodyMedium: const TextStyle(
        color: Color(0xFF337554),
        fontWeight: FontWeight.bold,
        fontSize: 15,
      ),
      headlineSmall: const TextStyle(
        fontFamily: 'KamikazeGradient',
        fontSize: 45,
        color: Color(0xFF337554),
      ),
      headlineLarge: const TextStyle(
        fontFamily: 'KamikazeGradient',
        fontSize: 80,
        color: Color(0xFF337554),
      ),
      headlineMedium: TextStyle(
        color: const Color.fromARGB(255, 18, 164, 197),
        fontSize: 45,
        fontFamily: 'Frau',
        fontWeight: FontWeight.w500,
        shadows: getShadows(color: Colors.white),
      ),
      labelMedium: GoogleFonts.montserrat(
        color: Colors.black,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: GoogleFonts.montserrat(
        color: Colors.black,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        shadows: getShadows(color: Colors.white, blurRadius: 5.0),
      ),
    ),
    outlinedButtonTheme: const OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(
          Color.fromARGB(255, 125, 24, 192),
        ),
      ),
    ),
    elevatedButtonTheme: const ElevatedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(
          Color.fromARGB(255, 125, 24, 192),
        ),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      actionTextColor: Colors.black,
    ),
  );

  final ThemeData _defaultDark = ThemeData.dark(
    useMaterial3: true,
  ).copyWith(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.tealAccent).copyWith(
      surface: Colors.black,
      primary: Colors.teal,
      onPrimary: Colors.tealAccent,
      secondary: Colors.purple,
      onSecondary: Colors.purpleAccent,
      tertiary: Colors.lime,
      onTertiary: Colors.limeAccent,
      outline: Colors.white,
      onSurface: Colors.white12,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
    ),
    iconTheme: const IconThemeData(
      color: Colors.white,
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: Colors.black,
      shadowColor: Colors.tealAccent,
    ),
    appBarTheme: const AppBarTheme(
      color: Color.fromARGB(255, 20, 20, 20),
      foregroundColor: Colors.white,
    ),
    listTileTheme: const ListTileThemeData(
      titleTextStyle: TextStyle(
        fontFamily: 'Nasalization',
        color: Colors.white,
      ),
    ),
    primaryColor: Colors.teal,
    textTheme: const TextTheme(
      bodySmall: TextStyle(
        fontFamily: 'Nasalization',
        color: Colors.white,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Nasalization',
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Nasalization',
        color: Colors.white,
      ),
      titleSmall: TextStyle(
        color: Colors.white70,
        fontFamily: 'Nasalization',
      ),
      titleMedium: TextStyle(
        color: Colors.white,
        fontFamily: 'Nasalization',
      ),
      labelMedium: TextStyle(
        fontFamily: 'Nasalization',
        color: Colors.white,
        fontSize: 14,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Nasalization',
        color: Colors.white,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'Nasalization',
        color: Colors.white,
        fontSize: 15,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Nasalization',
        color: Colors.white,
        fontSize: 22,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'Nasalization',
        color: Colors.white,
        fontSize: 35,
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      actionTextColor: Colors.white,
    ),
    primaryTextTheme: TextTheme(
      bodyMedium: const TextStyle(
        color: Colors.tealAccent,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
      labelMedium: const TextStyle(
        fontFamily: 'Nasalization',
        color: Colors.black,
        fontSize: 14,
      ),
      headlineSmall: const TextStyle(
        fontFamily: 'KamikazeGradient',
        fontSize: 45,
        color: Colors.tealAccent,
      ),
      headlineMedium: TextStyle(
        color: const Color.fromARGB(255, 68, 189, 255),
        fontSize: 45,
        fontFamily: 'Frau',
        shadows: getShadows(),
      ),
      headlineLarge: const TextStyle(
        fontFamily: 'KamikazeGradient',
        fontSize: 80,
        color: Colors.tealAccent,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Nasalization',
        color: Colors.white,
        fontSize: 15,
        shadows: getShadows(blurRadius: 5),
      ),
    ),
    outlinedButtonTheme: const OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(
          Color.fromARGB(255, 9, 143, 129),
        ),
      ),
    ),
    elevatedButtonTheme: const ElevatedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(
          Color.fromARGB(255, 9, 143, 129),
        ),
      ),
    ),
  );

  ThemeData appThemeData(ThemeDataType type) {
    switch (type) {
      case ThemeDataType.classic:
        return _default;
      case ThemeDataType.humani:
        return _default.copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 46, 196, 182),
          ).copyWith(
            surface: const Color.fromARGB(255, 240, 244, 255),
            primary: const Color.fromARGB(255, 83, 90, 185),
            onPrimary: const Color.fromARGB(255, 121, 127, 209),
            secondary: const Color.fromARGB(255, 189, 80, 144),
            onSecondary: const Color.fromARGB(255, 218, 121, 178),
            tertiary: const Color.fromARGB(255, 119, 151, 50),
            onTertiary: const Color.fromARGB(255, 150, 186, 74),
            onSurface: Colors.white,
          ),
          outlinedButtonTheme: const OutlinedButtonThemeData(
            style: ButtonStyle(
              foregroundColor: WidgetStatePropertyAll(
                Color.fromARGB(255, 74, 24, 192),
              ),
            ),
          ),
          elevatedButtonTheme: const ElevatedButtonThemeData(
            style: ButtonStyle(
              foregroundColor: WidgetStatePropertyAll(
                Color.fromARGB(255, 74, 24, 192),
              ),
            ),
          ),
        );
      case ThemeDataType.neoDark:
        return _defaultDark;
      case ThemeDataType.monochrome:
        return _defaultDark.copyWith(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey).copyWith(
            surface: Colors.black,
            primary: const Color.fromARGB(250, 67, 116, 146),
            onPrimary: const Color.fromARGB(76, 15, 163, 255),
            secondary: const Color.fromARGB(255, 203, 109, 238),
            onSecondary: const Color.fromARGB(76, 255, 102, 133),
            tertiary: Colors.white,
            onTertiary: Colors.white30,
            onSurface: Colors.white10,
          ),
          primaryColor: Colors.grey,
          outlinedButtonTheme: const OutlinedButtonThemeData(
            style: ButtonStyle(
              foregroundColor: WidgetStatePropertyAll(
                Color.fromARGB(255, 131, 145, 143),
              ),
            ),
          ),
          elevatedButtonTheme: const ElevatedButtonThemeData(
            style: ButtonStyle(
              foregroundColor: WidgetStatePropertyAll(
                Color.fromARGB(255, 121, 130, 129),
              ),
            ),
          ),
          primaryTextTheme: TextTheme(
            bodyMedium: const TextStyle(
              color: Color.fromARGB(248, 101, 178, 227),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            labelMedium: const TextStyle(
              fontFamily: 'Nasalization',
              color: Colors.black,
              fontSize: 14,
            ),
            headlineSmall: const TextStyle(
              fontFamily: 'KamikazeGradient',
              fontSize: 45,
              color: Color.fromARGB(248, 101, 178, 227),
            ),
            headlineLarge: const TextStyle(
              fontFamily: 'KamikazeGradient',
              fontSize: 80,
              color: Color.fromARGB(248, 101, 178, 227),
            ),
            headlineMedium: TextStyle(
              color: const Color.fromARGB(255, 68, 189, 255),
              fontSize: 45,
              fontFamily: 'Frau',
              shadows: getShadows(),
            ),
          ),
        );
    }
  }

  void changeTheme(ThemeDataType type) {
    this.type = type;
    var box = Hive.box('theme_data');
    box.put('type', type);
    emit(type);
  }
}
