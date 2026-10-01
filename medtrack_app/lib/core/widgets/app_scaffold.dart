import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

/// AppScaffold — every screen must use this instead of bare Scaffold.
/// Handles SafeArea (top + bottom), keyboard insets, consistent background.
/// This is a hard rule from the spec to prevent content hiding under status/nav bars.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.extendBodyBehindAppBar = false,
    this.extendBody = false,
    this.safeAreaTop = true,
    this.safeAreaBottom = true,
    this.padding,
    this.statusBarStyle,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Widget? bottomSheet;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final bool extendBodyBehindAppBar;
  final bool extendBody;
  final bool safeAreaTop;
  final bool safeAreaBottom;
  final EdgeInsetsGeometry? padding;
  final SystemUiOverlayStyle? statusBarStyle;

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ?? AppColors.background;
    Widget bodyWidget = body;

    if (padding != null) {
      bodyWidget = Padding(padding: padding!, child: bodyWidget);
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: statusBarStyle ??
          const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
      child: Scaffold(
        backgroundColor: effectiveBg,
        appBar: appBar,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        bottomNavigationBar: bottomNavigationBar,
        bottomSheet: bottomSheet,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        extendBody: extendBody,
        body: SafeArea(
          top: safeAreaTop,
          bottom: safeAreaBottom,
          child: bodyWidget,
        ),
      ),
    );
  }
}
