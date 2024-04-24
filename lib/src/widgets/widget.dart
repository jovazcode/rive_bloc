import 'package:flutter/widgets.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:rive_bloc/src/rive_bloc.dart';

/// {@template riverbloc_widget}
/// A [StatelessWidget] that can listen to providers.
///
/// Using [RiveBlocWidget], this allows the widget tree to listen to changes on
/// provider, so that the UI automatically updates when needed.
///
/// Do not modify any state or start any http request inside [build].
///
/// As a usage example, consider:
///
/// ```dart
/// final helloWorldProvider = Provider((_) => 'Hello world');
/// ```
///
/// We can then subclass [RiveBlocWidget] to listen to `helloWorldProvider`,
/// like so:
///
/// ```dart
/// class Example extends RiveBlocWidget {
///   const Example({Key? key}): super(key: key);
///
///   @override
///   Widget build(BuildContext context, RiveBlocRef ref) {
///     final value = ref.watch(helloWorldProvider);
///     return Text(value); // Hello world
///   }
/// }
/// ```
///
/// **Note**
/// You can watch as many providers inside [build] as you want to:
///
/// ```dart
/// @override
/// Widget build(BuildContext context, RiveBlocRef ref) {
///   final value = ref.watch(someProvider);
///   final another = ref.watch(anotherProvider);
///   return Text(value); // Hello world
/// }
/// ```
/// {@endtemplate}
abstract class RiveBlocWidget extends StatefulWidget {
  /// {@macro riverbloc_widget}
  const RiveBlocWidget({
    super.key,
    this.providers = const [],
  });

  /// List of RiverBLoC ´Providers´ exposing values and blocs/cubits,
  /// to be made available within the underlying widgets tree.
  final List<ProviderBase> providers;

  @override
  State<RiveBlocWidget> createState() => _RiveBlocWidgetState();

  /// Describes the part of the user interface represented by this widget.
  Widget build(BuildContext context, RiveBlocRef ref);
}

class _RiveBlocWidgetState extends State<RiveBlocWidget> {
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
            builder: (context) => widget.build(
              context,
              WidgetRef(context, state: _state),
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
              builder: (context) => widget.build(
                context,
                WidgetRef(context, state: _state),
              ),
            ),
          );
  }
}

/// A [StatefulWidget] that can read providers.
abstract class RiveBlocStatefulWidget extends StatefulWidget {
  /// A [StatefulWidget] that can read providers.
  const RiveBlocStatefulWidget({super.key});

  @override
  // ignore: no_logic_in_create_state
  RiveBlocStatefulState createState();
}

/// A [State] that has access to a [WidgetRef] through [ref], allowing
/// it to read providers.
abstract class RiveBlocStatefulState<T extends RiveBlocStatefulWidget>
    extends State<T> {
  late RiveBlocState _state;

  @override
  void initState() {
    _state = RiveBlocState(this);
    super.initState();
  }

  /// An object that allows widgets to interact with providers.
  late RiveBlocRef ref = WidgetRef(context, state: _state);
}
