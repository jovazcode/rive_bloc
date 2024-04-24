import 'package:flutter/widgets.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:rive_bloc/src/rive_bloc.dart';

/// [RiveBlocBuilder] function type.
///
/// See also [RiveBlocBuilder]
typedef RiveBlocBuilderFn = Widget Function(
  BuildContext context,
  RiveBlocRef ref,
  Widget? child,
);

/// {@template riverbloc_builder}
/// A widget that creates the values and/or Blocs/Cubits of the given
/// providers listed in the [providers] parameter, and allows access to
/// those values and instances to its children via [RiveBlocRef].
///
/// It automatically handles the creation, and thus the closing, for all
/// the non-`keepAlived` Bloc/Cubit instances.
///
/// By default the Object values and/or Bloc/Cubit instances are created
/// every time this widget is rebuilt in the widgets tree, so the `createFn`
/// method of each provider is called each time accordingly.
///
/// It is used as a dependency injection (DI) widget so that a single created
/// Dart Object value and/or a single created instance of a Bloc/Cubit can be
/// provided to multiple widgets within all the subtree.
///
/// If [ProviderBase.keepAlive] is `true`, the instance is a singleton
/// created only once:
/// - shared across the whole app,
/// - cached for the entire app lifeycle,
/// - disposed only when the app is closed.
///
/// So, if `keepAlive` is `true` the same instance is always returned
/// through the [RiveBlocRef] `read` and `watch` API methods.
///
/// Also, [RiveBlocBuilder] can be used to listen to [providers]
/// inside a [Widget] or to rebuild as few widgets as possible when
/// a provider updates.
///
/// ```dart
/// RiveBlocBuilder(
///  providers: [
///     myDataProvider1,
///     myDataProvider2,
///  ],
///  builder: (context, ref, child) {
///     final myData1 = ref.watch(myDataProvider1);
///     final myData2 = ref.watch(myDataProvider2);
///     return ShowDataWidget(myData1, myData2);
///  },
/// );
/// ```
/// {@endtemplate}
class RiveBlocBuilder extends StatefulWidget {
  /// {@macro riverbloc_builder}
  const RiveBlocBuilder({
    required this.builder,
    this.providers = const [],
    Widget? child,
    super.key,
  }) : _child = child;

  /// List of RiverBLoC ´Providers´ exposing values and blocs/cubits,
  /// to be made available within the underlying widgets tree.
  final List<ProviderBase> providers;

  /// Builder function for consuming [providers].
  final RiveBlocBuilderFn builder;

  final Widget? _child;

  @override
  State<RiveBlocBuilder> createState() => _RiveBlocBuilderState();
}

class _RiveBlocBuilderState extends State<RiveBlocBuilder> {
  late RiveBlocState _state;

  @override
  void initState() {
    _state = RiveBlocState(this);
    super.initState();
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

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
    return blocProviders.isEmpty
        ? Builder(
            builder: (context) => widget.builder(
              context,
              WidgetRef(context, state: _state),
              widget._child,
            ),
          )
        : MultiBlocProvider(
            providers: blocProviders
                .map(
                  (provider) => provider.toBlocProvider(_state),
                )
                .nonNulls
                .toList(),
            child: Builder(
              builder: (context) => widget.builder(
                context,
                WidgetRef(context, state: _state),
                widget._child,
              ),
            ),
          );
  }
}
