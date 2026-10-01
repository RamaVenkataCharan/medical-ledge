// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unnecessary_cast

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

/// See also [appRouter].
@ProviderFor(appRouter)
final appRouterProvider = Provider.autoDispose<GoRouter>(
  (ref) => appRouter(ref as AppRouterRef),
  name: r'appRouterProvider',
);

typedef AppRouterRef = AutoDisposeProviderRef<GoRouter>;

/// See also [authState].
@ProviderFor(authState)
final authStateProvider = StreamProvider.autoDispose<AuthState>(
  (ref) => authState(ref as AuthStateRef),
  name: r'authStateProvider',
);

typedef AuthStateRef = AutoDisposeStreamProviderRef<AuthState>;
