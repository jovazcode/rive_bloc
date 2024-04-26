// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:get_it/get_it.dart';

import 'package:meta/meta.dart';

import 'package:rive_bloc/rive_bloc.dart';

import 'package:rive_bloc/src/providers/providers.dart';

import 'package:uuid/uuid.dart';

export 'blocs/blocs.dart';
export 'common.dart';
export 'providers/providers.dart';
export 'widgets/widgets.dart';

@internal
final GetIt getIt = GetIt.instance;

/// An object used by Widgets and providers to interact with providers.
abstract class RiveBlocRef {
  /// Adds a listener to perform an operation right before the
  /// provider is destroyed.
  void onDispose(void Function() fn);

  /// Forces a provider to re-evaluate its state immediately, and return
  /// the created value.
  T refresh<BlocT extends RiveBlocBase<StateT>, StateT extends Object,
      T extends Object>(
    RiveBlocProviderBase<BlocT, StateT, T> provider,
  );

  /// Invalidates the state of the provider, causing it to refresh.
  void invalidate(RiveBlocProviderBase provider);

  /// Invalidates the state of the current provider, causing it to refresh.
  void invalidateSelf();

  /// Get a family provider.
  @internal
  ProviderBase? getFamilyProvider(String uid);

  /// Rebuilds the widget associated to this [RiveBlocRef].
  /// @nodoc
  @internal
  void rebuild();

  /// Sets a listener to a [RiveBlocBase] instance.
  /// @nodoc
  @internal
  void setListener<BlocT extends RiveBlocBase<StateT>, StateT>(
    String uid, {
    required RiveBlocProviderBase provider,
    required RiveBlocBase<dynamic> watcher,
    required RiveBlocProviderBase blocProvider,
    required BlocT bloc,
    required void Function(StateT state) listener,
    dynamic Function(BlocT bloc)? listenWhen,
  });

  /// Listen to a [RiveBlocProviderBase].
  void listen<BlocT extends RiveBlocBase<StateT>, StateT>(
    RiveBlocProviderBase<BlocT, StateT, dynamic> provider,
    void Function(BlocT bloc, StateT prevState, StateT nextState) listener, {
    dynamic Function(BlocT bloc)? listenWhen,
  });

  /// {@template ref.watch}
  /// Returns the Bloc/Cubit instance exposed by the given [provider].
  /// {@endtemplate}
  ///
  /// {@template ref.watch_description}
  /// Causes a rebuild when that state of the Bloc/Cubit gets updated.
  ///
  /// The rebuild occurs only on the closest ancestor instance of
  /// [RiveBlocBuilder].
  ///
  /// Using [watch] allows supporting the scenario where we want to
  /// rebuild when one of the object we are listening to changed.
  ///
  /// ***IMPORTANT***: This method is not intended to be used from within
  /// providers constructors.
  ///
  /// {@endtemplate}
  T watch<ValueT extends Object, T extends Object?>(
    Watchable<ValueT, T> provider,
  );

  /// {@template ref.read}
  /// Returns the Dart Object value and/or Bloc/Cubit instance exposed
  /// by the given [provider].
  /// {@endtemplate}
  ///
  /// {@template ref.read_description}
  /// Useful when we only want to read the current value/state without
  /// doing anything else, or retrieving a bloc instance in order to
  /// call a method on it.
  ///
  /// ***IMPORTANT***: It is not safe to retrieve Bloc/Cubit instances
  /// with this method from within providers constructors. Only instances
  /// created upper in the widget tree can be safely retrieved with this
  /// method from within providers constructors.
  ///
  /// {@endtemplate}
  T read<ValueT extends Object, T extends Object?>(
    Readable<ValueT, T> provider,
  );
}

/// RiveBloc State.
@internal
class RiveBlocState {
  RiveBlocState(this.widgetState);

  /// Stateful widget state.
  final State widgetState;

  /// Family providers.
  final _children = <String, ProviderBase>{};

  /// Family providers.
  final Map<String, _BlocListener<RiveBlocBase<dynamic>, dynamic>> _listeners =
      {};

  /// Miscellaneous disposing functions.
  final List<FutureOr<void> Function()> _disposeFnList = [];

  /// Dispose the state.
  void dispose() {
    // Invoke miscellaneous disposing functions.
    for (final fn in _disposeFnList) {
      fn();
    }
    _disposeFnList.clear();

    // Dispose the listeners.
    for (final listener in _listeners.values) {
      listener._unsubscribe();
    }
    _listeners.clear();

    // Dispose the family providers.
    for (final child in _children.values) {
      child.dispose();
    }
  }

  /// Adds a listener to perform an operation right before the
  /// provider is destroyed.
  // ignore: avoid_setters_without_getters
  void onDispose(void Function() fn) => _disposeFnList.add(fn);

  /// Register a child provider.
  void registerFamilyProvider(
    ProviderBase child,
  ) =>
      _children[child.uid] = child;

  /// Get a family provider.
  ProviderBase? getFamilyProvider(String uid) => _children[uid];

  void setListener<BlocT extends RiveBlocBase<StateT>, StateT>(
    RiveBlocRef ref,
    String uid, {
    required RiveBlocProviderBase provider,
    required RiveBlocBase<dynamic> watcher,
    required RiveBlocProviderBase blocProvider,
    required BlocT bloc,
    required void Function(StateT state) listener,
    dynamic Function(BlocT bloc)? listenWhen,
  }) {
    if (_listeners[uid] != null) {
      _listeners[uid]!._unsubscribe();
      _listeners.remove(uid);
    }
    _listeners[uid] = _BlocListener<BlocT, StateT>(
      ref,
      provider,
      watcher,
      blocProvider,
      bloc,
      listener,
      listenWhen: listenWhen,
    );
  }
}

class _BlocListener<BlocT extends RiveBlocBase<StateT>, StateT> {
  _BlocListener(
    this._ref,
    this._provider,
    this._watcher,
    this._blocProvider,
    this._bloc,
    void Function(StateT state) listener, {
    dynamic Function(BlocT bloc)? listenWhen,
  }) {
    _subscribe(listener, listenWhen);
  }
  final RiveBlocRef _ref;
  final RiveBlocProviderBase _provider;
  final RiveBlocBase<dynamic> _watcher;
  final RiveBlocProviderBase _blocProvider;
  final BlocT _bloc;

  dynamic _lastConditionValue;
  StreamSubscription<dynamic>? _subscription;

  void _subscribe(
    void Function(StateT state) listener,
    dynamic Function(BlocT bloc)? listenWhen,
  ) {
    if (!_provider.isFamily && _watcher is Computable) {
      _blocProvider.addWatcher(_watcher as Computable);
    }

    // Subscribe to the bloc.
    _lastConditionValue = listenWhen?.call(_bloc);
    _subscription = _bloc.stream.listen(
      (state) {
        final conditionValue = listenWhen?.call(_bloc);
        if (conditionValue is bool) {
          if (conditionValue == false) {
            return;
          }
          if (conditionValue == true && _lastConditionValue == true) {
            return;
          }
        } else if (listenWhen != null &&
            conditionValue == _lastConditionValue) {
          return;
        }

        // Call the listener and unsubscribe.
        _unsubscribe();
        listener.call(state);
      },
      onDone: _unsubscribe,
      cancelOnError: true,
    );
  }

  void _unsubscribe() {
    // Cancel the subscription.
    _subscription?.cancel();
    _subscription = null;

    // Invalidate computed watcher if `Computable` and not Family Provider:
    // We cannot dispose non-Family `sub-listeners` (`watch` within a `build`
    // functions) without invalidating their computed values!!! Otherwise,
    // computed values would remain the same and no new listener would be
    // created (cause `build` is not called again) so that values would
    // never be updated anymore.
    if (!_provider.isFamily && _watcher is Computable) {
      _blocProvider.removeWatcher(_watcher as Computable);
      (_watcher as Computable).invalidate(_ref, refresh: false);
    }
  }
}

/// Ref Handler.
mixin RefHandler {
  late RiveBlocRef? _ref;

  /// The [RiveBlocRef] currently tight to this [RiveBlocBase].
  RiveBlocRef get ref => _ref!;

  @internal
  set ref(RiveBlocRef value) {
    _ref = value;
  }
}

/// {@template rive_bloc_provider}
/// A simple way to handle dependency injection and state management in
/// Flutter using the BLoC pattern, with an API strongly inspired by Riverpod.
///
/// The main building blocks of RiveBloc are `providers` and `builders`.
///
/// A `Provider` is a way to get access to a piece of state (an Object value
/// or a Bloc/Cubit instance), while a [RiveBlocBuilder] is a way to
/// use that state in the widgets tree.
///
/// [RiveBlocProvider] is the main entry point for creating providers.
///
/// ***IMPORTANT***: For providers to work, you need to add [RiveBlocScope]
/// at the root of your Flutter applications, like this:
/// ```dart
/// void main() {
///   runApp(RiveBlocScope(child: MyApp()));
/// }
/// ```
///
/// Providers solve the following problems:
/// - Providers have the flexibility of global variables, without their
/// downsides. They can be accessed from anywhere, while ensuring
/// testability and scalability,
/// - Providers are safe to use. It is not possible to read a value in
/// an uninitialized state,
/// - Providers can be accessed in a single line of code.
///
/// RiveBloc providers are divided into two main categories:
/// - [FinalProvider] for exposing final Dart [Object] values,
/// - [StateProvider], [ValueProvider], and [AsyncProvider] for exposing
///   [Bloc] and [Cubit] based states.
///
/// The RiveBloc [FinalProvider] is created with
/// [RiveBlocProvider.finalValue], and [RiveBlocProviderBase] is created with
/// [RiveBlocProvider.state], [RiveBlocProvider.value] and
/// [RiveBlocProvider.async].
///
/// Providers come in many variants, but they all work the same way.
///
/// The most common usage is to declare them as global variables, like this:
/// ```dart
/// final myProvider = RiveBlocProvider.finalValue(() => MyValue());
/// final myBlocProvider = RiveBlocProvider.state(() => MyBloc());
/// ```
///
/// Secondly, all the providers should be declared through the [RiveBlocScope]
/// widget (not really mandatory, but highly recommended), so that they are
/// for sure accessible from anywhere in the application:
/// ```dart
/// RiveBlocScope(
///   providers: [
///     myProvider,
///     myBlocProvider,
///     ...
///   ],
///   child: MyApp(),
/// );
/// ```
///
/// ***IMPORTANT***: Multiple providers cannot share the same value type!!
/// ```dart
/// // This, does not work:
/// final value1 = RiveBlocProvider.value(() => MyValueCubit(1));
/// final value2 = RiveBlocProvider.value(() => MyValueCubit(2));
///
/// // Do this, instead:
/// final value1 = RiveBlocProvider.value(() => MyValueCubit1());
/// final value2 = RiveBlocProvider.value(() => MyValueCubit2());
/// ```
///
/// Once the providers are declared, you can access the values and instances
/// they expose, by using the `read` and `watch` methods:
/// ```dart
/// RiveBlocBuilder(
///   builder: (context, ref) {
///     final myValue = ref.read(myProvider);
///     final myBloc = ref.watch(myBlocProvider);
///   },
/// );
/// ```
///  - `myValue` is an instance of `MyValueCubit`,
///  - `myBloc` is an instance of `MyBloc`.
///
/// ***IMPORTANT***: Providers can also be declared in the `providers` list of
/// the [RiveBlocBuilder] widget. But in this case, it is worth noting that
/// the provider is not kept alive by default, thus all the exposed Object
/// values and Bloc/Cubit instances are re-created each time the provider
/// is first accessed under a new [RiveBlocBuilder] widget declaring it in
/// its `providers` list.
///
/// So, if you want to reuse the same instance of a Bloc/Cubit or keep the same
/// value of an Object alive, you can (1) set the `keepAlive` parameter to
/// `true` when creating the provider so that it is kept alive for the entire
/// application lifetime, or (2) use the `providers` parameter of an upper
/// [RiveBlocBuilder] widget to declare your provider so that it is kept
/// alive for the lifetime of the declaring [RiveBlocBuilder] widget, and
/// available to the widgets tree under it.
///
/// `RiveBlocRef` is the class that provides the `read` and `watch` methods
/// to access the values exposed by the providers.
///
/// So, providers can be accessed in any part of the application where
/// the [RiveBlocRef] object along with its `read` and `watch` methods
/// are accessible and available:
/// - Under a [RiveBlocBuilder] widget,
/// - Through providers `create` and `build` methods,
/// - Inside any method of a `RiveBlocBase` class ([ValueCubit]),....
///
/// ***IMPORTANT***: [RiveBlocRef.watch] is not intended to be called
/// from every method of [RiveBlocBase] components!! its use is only
/// supported in the `build` method of [Computable] components and
/// under the [RiveBlocWidget], [RiveBlocStatefulWidget] and
/// [RiveBlocBuilder] widgets.
///
/// {@endtemplate}
abstract class RiveBlocProvider<BlocT extends RiveBlocBase<StateT>,
    StateT extends Object?, ValueT extends Object?> {
  /// Creates a new provider that exposes a Dart Object value.
  /// @macro value_provider_description
  static FinalProvider<T> finalValue<T extends Object>(
    T Function() createFn, {
    String? name,
    bool keepAlive = false,
  }) {
    // Create the provider.
    final provider = FinalProvider<T>(
      createFn,
      uid: const Uuid().v4(),
      name: name,
      keepAlive: keepAlive,
    );

    // Check invalid value type.
    if (provider is FinalProvider<BlocBase>) {
      throw StateError(
        'RiveBlocProvider.finalValue() cannot be used with Blocs/Cubits, '
        'use RiveBlocProvider.value() instead.',
      );
    }

    return provider;
  }

  /// Creates a new [RiveBlocProviderBase] that exposes a
  /// [RiveBloc]/[RiverCubit].
  /// @macro provider_description
  static StateProvider<BlocT, StateT>
      state<BlocT extends RiveBlocBase<StateT>, StateT extends Object>(
    BlocT Function() createFn, {
    String? name,
    bool keepAlive = false,
  }) =>
          StateProvider<BlocT, StateT>(
            createFn,
            uid: const Uuid().v4(),
            name: name,
            keepAlive: keepAlive,
          );

  /// Creates a new [AsyncProvider] that exposes a [AsyncCubit].
  /// @macro provider_description
  static AsyncProvider<BlocT, T>
      async<BlocT extends AsyncCubit<T>, T extends Object?>(
    BlocT Function() createFn, {
    String? name,
    bool keepAlive = false,
  }) =>
          AsyncProvider<BlocT, T>(
            createFn,
            uid: const Uuid().v4(),
            name: name,
            keepAlive: keepAlive,
          );

  /// Creates a new [StreamProvider] that exposes a [StreamBloc].
  /// @macro provider_description
  static StreamProvider<BlocT, T>
      stream<BlocT extends StreamBloc<T>, T extends Object?>(
    BlocT Function() createFn, {
    String? name,
    bool keepAlive = false,
  }) =>
          StreamProvider<BlocT, T>(
            createFn,
            uid: const Uuid().v4(),
            name: name,
            keepAlive: keepAlive,
          );

  /// Creates a new [ValueProvider] that exposes a [T].
  /// @macro provider_description
  static ValueProvider<BlocT, T>
      value<BlocT extends ValueCubit<T>, T extends Object?>(
    BlocT Function() createFn, {
    String? name,
    bool keepAlive = false,
  }) =>
          ValueProvider<BlocT, T>(
            createFn,
            uid: const Uuid().v4(),
            name: name,
            keepAlive: keepAlive,
          );

  /// The internal provider delegate.
  RiveBlocProviderBase<BlocT, StateT, ValueT> get delegate;

  /// When the `Bloc`/`Cubit` exposed by this provider is [Computable],
  /// this method makes its state computed with the given [args].
  RiveBlocProviderBase<BlocT, StateT, ValueT> call(Args args);
}
