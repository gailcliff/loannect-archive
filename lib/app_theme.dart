
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// const Color COLOR_SECONDARY = Color(0xFFE0AA3E);
const Color COLOR_PRIMARY = Color(0xFFD4AF37);
// const Color COLOR_PRIMARY = Color(0xFF5C5346);
const Color COLOR_SECONDARY = Colors.black;


final TextTheme lightTextTheme = TextTheme(
  displayLarge: GoogleFonts.familjenGrotesk(fontSize: 32, fontWeight: FontWeight.w900),
  displayMedium: GoogleFonts.familjenGrotesk(fontSize: 28, fontWeight: FontWeight.w800),
  displaySmall: GoogleFonts.familjenGrotesk(fontSize: 26, fontWeight: FontWeight.normal),
  headlineLarge: GoogleFonts.familjenGrotesk(fontSize: 20, fontWeight: FontWeight.w800),
  headlineMedium: GoogleFonts.familjenGrotesk(fontSize: 18, fontWeight: FontWeight.w600),
  bodyLarge: GoogleFonts.familjenGrotesk(fontSize: 16, fontWeight: FontWeight.w500),
  bodyMedium: GoogleFonts.familjenGrotesk(fontWeight: FontWeight.normal),
  bodySmall: GoogleFonts.familjenGrotesk(fontWeight: FontWeight.normal, fontSize: 10),
  labelSmall: GoogleFonts.familjenGrotesk(fontSize: 12, fontWeight: FontWeight.bold),
).apply(
  displayColor: Colors.black,
  bodyColor: Colors.black,
);

final TextTheme darkTextTheme = TextTheme(
  displayLarge: GoogleFonts.familjenGrotesk(fontSize: 32, fontWeight: FontWeight.w900),
  displayMedium: GoogleFonts.familjenGrotesk(fontSize: 28, fontWeight: FontWeight.w800),
  displaySmall: GoogleFonts.familjenGrotesk(fontSize: 26, fontWeight: FontWeight.normal),
  headlineLarge: GoogleFonts.familjenGrotesk(fontSize: 20, fontWeight: FontWeight.w800),
  headlineMedium: GoogleFonts.familjenGrotesk(fontSize: 18, fontWeight: FontWeight.w600),
  bodyLarge: GoogleFonts.familjenGrotesk(fontSize: 16, fontWeight: FontWeight.w500),
  bodyMedium: GoogleFonts.familjenGrotesk(fontWeight: FontWeight.normal),
  bodySmall: GoogleFonts.familjenGrotesk(fontWeight: FontWeight.normal, fontSize: 10),
  labelSmall: GoogleFonts.familjenGrotesk(fontSize: 12, fontWeight: FontWeight.bold),
).apply(
  displayColor: Colors.white,
  bodyColor: Colors.white,
);

final theme = ThemeData(

  // colorScheme: const ColorScheme.dark(primary: Colors.black, secondary: Color(0xFFE0AA3E),),
  //   brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.grey.shade200,
    colorScheme: const ColorScheme.light(
      primary: COLOR_SECONDARY,
      secondary: COLOR_PRIMARY,
      // background: Colors.white
    ),
    iconTheme: const IconThemeData(
        color: COLOR_SECONDARY,
    ),
    textTheme: lightTextTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: COLOR_PRIMARY,
      foregroundColor: COLOR_SECONDARY,
      centerTitle: true,
      scrolledUnderElevation: 0,
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: COLOR_PRIMARY,
      selectedItemColor: COLOR_SECONDARY,
      unselectedItemColor: Colors.white,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      // backgroundColor: app_theme.COLOR_SECONDARY,
      foregroundColor: Colors.white,
      // extendedTextStyle: TextStyle(
      //   fontWeight: FontWeight.bold,
      // )
    ),
    cardTheme: const CardTheme(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      margin: EdgeInsets.all(0)
    ),
    sliderTheme: const SliderThemeData(
        activeTrackColor: COLOR_PRIMARY
    ),
    dividerTheme: DividerThemeData(
        color: Colors.grey.shade300,
        thickness: 1,
        space: 0
    ),
    filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
            foregroundColor: MaterialStateColor.resolveWith((states) => Colors.white)
        )
    )
  // filledButtonTheme:
);