import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:rive_bloc/src/rive_bloc.dart';

/// {@template riverbloc.scope}
/// A widget that creates the Dart Object values and/or Bloc/Cubit
/// of the given [providers], for a [child] widgets tree which will
/// have access to those values and instances.
///
/// All Flutter apps using RiverBLoC must contain a [RiveBlocScope] at
/// the root of the widgets tree, typically to set at least global dependency
/// injections and declare global `keepAlive` [providers].
///
/// It is done as followed:
///
/// ```dart
/// void main() {
///   runApp(
///     // Enable RiveBloc for the entire application
///     RiveBlocScope(
///       // List of providers to expose values and blocs/cubits
///       // globally to the entire application
///       providers: [
///           apiClientProvider,
///           authUserRepositoryProvider,
///           ...
///       ],
///       child: MyApp(),
///     ),
///   );
/// }
/// ```
///
/// `RiveBlocScope` is responsible for creating the [child] which will
/// have access to exposed Object values and/or Bloc/Cubit instances
/// through the standard Bloc API, for instance via
/// `BlocProvider.of<MyValueCubit>(context)`, but also through
/// [RiveBlocBuilder] widgets, as follow:
///
/// ```dart
/// RiveBlocBuilder(
///  builder: (context, ref, child) {
///     final myData1 = ref.watch(myDataProvider1);
///     final myData2 = ref.watch(myDataProvider2);
///     return ShowDataWidget(myData1, myData2);
///  },
/// );
/// ```
/// {@endtemplate}
class RiveBlocScope extends StatefulWidget {
  /// {@macro riverbloc.scope}
  const RiveBlocScope({
    required this.child,
    this.providers = const [],
    this.overrides = const [],
    this.runScoped,
    super.key,
  });

  /// The closest instance of [RiveBlocScope] that encloses the given context.
  static RiveBlocScopeState of(BuildContext context) {
    final state = context.findAncestorStateOfType<RiveBlocScopeState>();
    if (state == null) {
      throw StateError(
        'RiveBlocScope is not available. '
        'You need to add RiveBlocScope at the root of your Flutter app.',
      );
    }

    return state;
  }

  /// List of RiverBLoC ´Providers´ exposing values and blocs/cubits,
  /// to be made available within the underlying widgets tree.
  final List<ProviderBase> providers;

  /// List of RiverBLoC ´Providers´ overriding upper providers,
  /// to be made available within the underlying widgets tree.
  final List<ProviderBase> overrides;

  /// A function that runs scoped within the [RiveBlocScope] and
  /// which has access to the [BuildContext] and the [RiveBlocRef].
  final FutureOr<void> Function(
    BuildContext context,
    RiveBlocRef ref,
  )? runScoped;

  /// The part of the widget tree that can use [RiveBlocBuilder]
  /// to consume the given [providers].
  final Widget child;

  @override
  State<RiveBlocScope> createState() => RiveBlocScopeState();
}

/// The state of the [RiveBlocScope] widget.
class RiveBlocScopeState extends State<RiveBlocScope> {
  static final Map<String, ProviderBase> _finalOverrides = {};

  late Map<String, ProviderBase> _overrides = {};
  late RiveBlocState _state;

  @override
  void initState() {
    super.initState();
    _state = RiveBlocState(this);
    _overrides = {
      for (final provider in widget.overrides) provider.uid: provider,
    };
  }

  @override
  void dispose() {
    _state.dispose();
    _overrides.clear();
    super.dispose();
  }

  /// Get the [ProviderBase] instance by its [uid].
  ProviderBase? getProvider(String uid) =>
      _overrides[uid] ?? RiveBlocScopeState._finalOverrides[uid];

  /// Get the [ProviderBase] instance by its [uid].
  static ProviderBase? getFinalProvider(String uid) =>
      RiveBlocScopeState._finalOverrides[uid];

  @override
  Widget build(BuildContext context) {
    final blocProviders = widget.providers
        .map(
          (provider) {
            if (provider is! RiveBlocProviderBase) {
              provider.registerValue(_state);
              return null;
            }
            return provider;
          },
        )
        .nonNulls
        .toList();
    final blocOverrides = widget.overrides
        .map(
          (provider) {
            // Register the overrider
            if (provider is! RiveBlocProviderBase) {
              _finalOverrides[provider.original!.uid] = provider;
              provider.registerValue(_state);
              return null;
            }

            // Scoped overriders cache
            _overrides[provider.original!.uid] = provider;

            return provider;
          },
        )
        .nonNulls
        .toList();
    final blocs = [...blocProviders, ...blocOverrides];
    return blocs.isEmpty
        ? Builder(
            builder: (context) {
              widget.runScoped?.call(
                context,
                WidgetRef(context, state: _state),
              );
              return widget.child;
            },
          )
        : MultiBlocProvider(
            providers: blocs
                .map(
                  (provider) => provider.toBlocProvider(_state),
                )
                .nonNulls
                .toList(),
            child: Builder(
              builder: (context) {
                widget.runScoped?.call(
                  context,
                  WidgetRef(context, state: _state),
                );
                return widget.child;
              },
            ),
          );
  }
}
