import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

TextStyle titleBold(double size, {Color? color}) =>
    GoogleFonts.montserrat(fontSize: size, fontWeight: FontWeight.w700, color: color ?? offWhite);

TextStyle titleSemi(double size, {Color? color}) =>
    GoogleFonts.montserrat(fontSize: size, fontWeight: FontWeight.w600, color: color ?? offWhite);

TextStyle bodyText(double size, {Color? color, FontWeight? weight}) => GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight ?? FontWeight.w400,
      color: color ?? offWhite,
    );
