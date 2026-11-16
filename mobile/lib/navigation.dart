import 'package:flutter/material.dart';

import 'motion.dart';

/// O'tish turlari
enum NavTransition {
  standard,
  fade,
  sharedAxis,
  slideUp,
}

/// FitHayot 360 markazlashtirilgan navigatsiya yordamchisi.
/// Barcha ekran o'tishlari ushbu klass orqali amalga oshiriladi.
/// `reduceMotion` faol bo'lsa, o'tishlar animatsiyasiz (bir lahzada) ishlaydi.
abstract final class AppNav {
  /// Standart o'tish (MaterialPageRoute)
  static Future<T?> push<T>(BuildContext context, Widget page) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  /// Fade o'tish (Auth oqimi, ma'lumot ekranlari) - 250 ms
  static Future<T?> pushFade<T>(BuildContext context, Widget page) {
    if (reduceMotion(context)) {
      return push<T>(context, page);
    }
    return Navigator.of(context).push<T>(
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curve = CurvedAnimation(parent: animation, curve: Curves.easeOut);
          return FadeTransition(opacity: curve, child: child);
        },
      ),
    );
  }

  /// Shared Axis (gorizontal surilish) - batafsil ekranlar (Mashq, Dastur, Retsept) - 340 ms
  static Future<T?> pushSharedAxis<T>(BuildContext context, Widget page) {
    if (reduceMotion(context)) {
      return push<T>(context, page);
    }
    return Navigator.of(context).push<T>(
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: const Duration(milliseconds: 340),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(parent: animation, curve: kCurve);
          final slide = Tween<Offset>(begin: const Offset(0.20, 0), end: Offset.zero).animate(curved);
          final fade = Tween<double>(begin: 0.0, end: 1.0).animate(curved);

          return SlideTransition(
            position: slide,
            child: FadeTransition(opacity: fade, child: child),
          );
        },
      ),
    );
  }

  /// Slide Up (modal oqimlar: Seans, Pleyer, Seans yakuni, Maslahatchi, Premium) - 360 ms
  static Future<T?> pushSlideUp<T>(BuildContext context, Widget page) {
    if (reduceMotion(context)) {
      return push<T>(context, page);
    }
    return Navigator.of(context).push<T>(
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: const Duration(milliseconds: 360),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(parent: animation, curve: kCurve);
          final slide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(curved);
          final fade = Tween<double>(begin: 0.0, end: 1.0).animate(curved);

          return SlideTransition(
            position: slide,
            child: FadeTransition(opacity: fade, child: child),
          );
        },
      ),
    );
  }

  /// O'tish turiga ko'ra push qilish
  static Future<T?> pushWith<T>(
    BuildContext context,
    Widget page, {
    NavTransition transition = NavTransition.sharedAxis,
  }) {
    return switch (transition) {
      NavTransition.standard => push<T>(context, page),
      NavTransition.fade => pushFade<T>(context, page),
      NavTransition.sharedAxis => pushSharedAxis<T>(context, page),
      NavTransition.slideUp => pushSlideUp<T>(context, page),
    };
  }

  /// Sahifani ochib, orqaga qaytganda yangilash (await push + onReturn)
  static Future<T?> pushAndRefresh<T>(
    BuildContext context,
    Widget page, {
    Future<void> Function()? onReturn,
    NavTransition transition = NavTransition.sharedAxis,
  }) async {
    final result = await pushWith<T>(context, page, transition: transition);
    if (onReturn != null) {
      await onReturn();
    }
    return result;
  }

  /// Orqaga qaytish
  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.of(context).pop<T>(result);
  }
}

