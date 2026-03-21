import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

TextStyle syneBold(double size, {Color? color}) =>
    GoogleFonts.syne(fontSize: size, fontWeight: FontWeight.w700, color: color ?? offWhite);

TextStyle syneSemi(double size, {Color? color}) =>
    GoogleFonts.syne(fontSize: size, fontWeight: FontWeight.w600, color: color ?? offWhite);

TextStyle dmSans(double size, {Color? color, FontWeight? weight}) => GoogleFonts.dmSans(
      fontSize: size,
      fontWeight: weight ?? FontWeight.w400,
      color: color ?? offWhite,
    );
