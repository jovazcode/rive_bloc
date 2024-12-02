import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:meta/meta.dart';

import 'package:rive_bloc/src/rive_bloc.dart';
import 'package:uuid/uuid.dart';

/// A Ref with a Provider.
///
/// Used to invalidate the Watcher (if `Computable`) when the watched provider
/// is a Bloc/Cubit and its state changes.
class ProviderRef<BlocT extends RiveBlocBase<StateT>, StateT extends Object?,
    ValueT extends Object?> extends WidgetRef {
  /// A Ref with a Provider.
  ProviderRef(
    this.ref,
    this.watcher,
    this.watcherValue,
  ) : super(ref.context, state: ref.state, provider: ref.provider);

  /// The widget ref.
  final WidgetRef ref;

  /// The provider with role of watcher.
  final RiveBlocProviderBase<BlocT, StateT, ValueT> watcher;

  /// The value of the watcher provider.
  final BlocT watcherValue;

  /// Returns the value exposed by a provider and rebuild the widget
  /// when that value changes.
  @override
  T watch<BindingT extends Object, T extends Object?>(
    Watchable<BindingT, T> provider,
  ) {
    final instance = (provider as Readable<BindingT, T>).getBinding(this);
    print('!!!DEBUG <ProviderRef> watch[$this]: instance=$instance, watcher='
        '$watcher, watcherValue=$watcherValue');

    // If the watcher value is `Computable` and the watched instance is a
    // `RiveBlocBase` then it must be recomputed anytime the watched
    // instance `state` changes.
    if (watcherValue is Computable && instance is RiveBlocBase<dynamic>) {
      ref.setListener<RiveBlocBase<dynamic>, dynamic>(
        '${watcher.uid}-${provider.uid}',
        provider: watcher,
        watcher: watcherValue,
        blocProvider: provider as RiveBlocProviderBase,
        bloc: instance,
        listener: (_) {
          try {
            // Invalidate the watcher to recompute its state.
            invalidate(watcher);
          } catch (err, stackTrace) {
            throw StateError(
              'ProviderRef.watch() cannot invalidate '
              'the watching provider ($watcher), '
              "maybe trying to look up a deactivated widget's ancestor?\n"
              'Try binding your watching provider to the root of your Flutter '
              'app with putting there the first call to '
              '`ref.read(yourWatchingProvider)`.\n\n'
              '$err\n $stackTrace',
            );
          }
        },
      );
    }

    return (provider as Readable<BindingT, T>).read(this);
  }
}

/// {@template stream_provider}
/// A [StateProvider] that creates and handles an [StreamBloc] to expose
/// [AsyncValue]s of [ValueT], recevied from a [Stream].
/// {@endtemplate}
/// {@macro provider_description}
class StreamProvider<BlocT extends StreamBloc<ValueT>, ValueT extends Object?>
    extends StateProvider<BlocT, AsyncValue<ValueT>> {
  /// {@macro provider}
  StreamProvider(
    super.createFn, {
    required super.uid,
    required super.keepAlive,
    super.original,
    super.father,
    super.args,
    super.name,
  });

  /// A constructor that creates a provider from another one.
  @internal
  StreamProvider.fromProvider(StreamProvider<BlocT, ValueT> provider)
      : super(
          provider._createFn,
          uid: provider.uid,
          keepAlive: provider.keepAlive,
          name: provider.name,
          father: provider._father,
          args: provider._args,
        );

  /// Creates an overrider provider from this one.
  @override
  StreamProvider<BlocT, ValueT> overrideWith(BlocT Function() createFn) {
    return StreamProvider<BlocT, ValueT>(
      createFn,
      uid: const Uuid().v4(),
      keepAlive: keepAlive,
      name: name,
      original: this,
      father: _father,
      args: _args,
    );
  }

  /// Creates an overrider provider from this one.
  @override
  StreamProvider<BlocT, ValueT> overrideWithValue(BlocT value) =>
      overrideWith(() => value);

  /// Get this provider's binding.
  @override
  @internal
  BlocT getBinding(RiveBlocRef ref) {
    // Set the ref
    final widgetRef = ref as WidgetRef;

    // Check overrides
    final overriderProvider = RiveBlocScope.of(widgetRef.context)
        .getProvider(uid) as ProviderBase<BlocT, BlocT>?;

    // Set
    final thisProvider = (overriderProvider ?? this)
        as RiveBlocProviderBase<BlocT, AsyncValue<ValueT>, BlocT>;

    // Check if registered
    if (!getIt.isRegistered<BlocT>(
      instanceName: thisProvider.uid,
    )) {
      if (isFamily) {
        // Family provider
        registerValue(widgetRef.state);
      } else {
        throw StateError('$this has not been created neither by '
            '`RiveBlocScope` nor `RiveBlocBuilder`.');
      }
    }

    if (isFamily) {
      final value = getIt.get<BlocT>(
        instanceName: thisProvider.uid,
      );
      return value;
    }
    return widgetRef.context.read<BlocT>();
  }

  /// Dispose provider.
  @override
  @internal
  void dispose() {
    if (isFamily) {
      getIt
          .get<BlocT>(
            instanceName: uid,
          )
          .close();
    }
    super.dispose();
  }

  /// {@macro provider_factory}
  @override
  StreamProvider<BlocT, ValueT> call(
    RiveBlocRef ref,
    Args args,
  ) {
    return ref.getFamilyProvider(
          '$uid($args)',
        ) as StreamProvider<BlocT, ValueT>? ??
        StreamProvider<BlocT, ValueT>(
          _createFn,
          uid: '$uid($args)', // Unique 'args'-based identifier
          keepAlive: true, // Keep the instance alive
          name: name == null ? null : '$name($args)',
          father: this, // Set this provider the father
          args: args,
        );
  }

  @override
  void _computeIfNeeded(
    RiveBlocRef ref,
    StreamBloc<ValueT> value,
  ) {
    value
      // Set ref
      ..ref = ref

      // Compute the state (if needed)
      ..call(ref, _args);
  }

  @override
  String toString() {
    if (name != null) {
      return name!;
    }
    return 'StreamProvider<$BlocT> { uid: $uid }';
  }
}

/// {@template async_provider}
/// A [StateProvider] that creates and handles an [AsyncCubit] to expose
/// [AsyncValue]s of [ValueT], computed asynchronously.
/// {@endtemplate}
/// {@macro provider_description}
class AsyncProvider<BlocT extends AsyncCubit<ValueT>, ValueT extends Object?>
    extends StateProvider<BlocT, AsyncValue<ValueT>> {
  /// {@macro provider}
  AsyncProvider(
    super.createFn, {
    required super.uid,
    required super.keepAlive,
    super.original,
    super.father,
    super.args,
    super.name,
  });

  /// A constructor that creates a provider from another one.
  @internal
  AsyncProvider.fromProvider(AsyncProvider<BlocT, ValueT> provider)
      : super(
          provider._createFn,
          uid: provider.uid,
          keepAlive: provider.keepAlive,
          name: provider.name,
          father: provider._father,
          args: provider._args,
        );

  /// Creates an overrider provider from this one.
  @override
  AsyncProvider<BlocT, ValueT> overrideWith(BlocT Function() createFn) {
    return AsyncProvider<BlocT, ValueT>(
      createFn,
      uid: const Uuid().v4(),
      keepAlive: keepAlive,
      name: name,
      original: this,
      father: _father,
      args: _args,
    );
  }

  /// Creates an overrider provider from this one.
  @override
  AsyncProvider<BlocT, ValueT> overrideWithValue(BlocT value) =>
      overrideWith(() => value);

  /// Get this provider's binding.
  @override
  @internal
  BlocT getBinding(RiveBlocRef ref) {
    // Set the ref
    final widgetRef = ref as WidgetRef;

    // Check overrides
    final overriderProvider = RiveBlocScope.of(widgetRef.context)
        .getProvider(uid) as ProviderBase<BlocT, BlocT>?;

    // Set
    final thisProvider = (overriderProvider ?? this)
        as RiveBlocProviderBase<BlocT, AsyncValue<ValueT>, BlocT>;

    // Check if registered
    if (!getIt.isRegistered<BlocT>(
      instanceName: thisProvider.uid,
    )) {
      if (isFamily) {
        // Family provider
        registerValue(widgetRef.state);
      } else {
        throw StateError('$this has not been created neither by '
            '`RiveBlocScope` nor `RiveBlocBuilder`.');
      }
    }

    if (isFamily) {
      final value = getIt.get<BlocT>(
        instanceName: thisProvider.uid,
      );
      return value;
    }
    return widgetRef.context.read<BlocT>();
  }

  /// Dispose provider.
  @override
  @internal
  void dispose() {
    if (isFamily) {
      getIt
          .get<BlocT>(
            instanceName: uid,
          )
          .close();
    }
    super.dispose();
  }

  /// {@macro provider_factory}
  @override
  AsyncProvider<BlocT, ValueT> call(
    RiveBlocRef ref,
    Args args,
  ) {
    return ref.getFamilyProvider(
          '$uid($args)',
        ) as AsyncProvider<BlocT, ValueT>? ??
        AsyncProvider<BlocT, ValueT>(
          _createFn,
          uid: '$uid($args)', // Unique 'args'-based identifier
          keepAlive: true, // Keep the instance alive
          name: name == null ? null : '$name($args)',
          father: this, // Set this provider the father
          args: args,
        );
  }

  @override
  void _computeIfNeeded(
    RiveBlocRef ref,
    AsyncCubit<ValueT> value,
  ) {
    value
      // Set ref
      ..ref = ref

      // Compute the state (if needed)
      ..call(ref, _args);
  }

  @override
  String toString() {
    if (name != null) {
      return name!;
    }
    return 'AsyncProvider<$BlocT> { uid: $uid }';
  }
}

/// {@template state_provider}
/// A [RiveBlocProvider] that creates, handles and exposes a Bloc/Cubit.
/// {@endtemplate}
/// {@macro provider}
/// {@macro provider_description}
class StateProvider<BlocT extends RiveBlocBase<StateT>, StateT extends Object?>
    extends RiveBlocProviderBase<BlocT, StateT, BlocT>
    with Readable<BlocT, BlocT>, Watchable<BlocT, BlocT> {
  /// {@macro provider}
  StateProvider(
    super.factoryFn, {
    required super.uid,
    required super.keepAlive,
    super.name,
    super.original,
    super.father,
    super.args,
  });

  /// A constructor that creates a provider from another one.
  @internal
  StateProvider.fromProvider(StateProvider<BlocT, StateT> provider)
      : super(
          provider._createFn,
          uid: provider.uid,
          keepAlive: provider.keepAlive,
          name: provider.name,
          father: provider._father,
          args: provider._args,
        );

  /// Creates an overrider provider from this one.
  @override
  StateProvider<BlocT, StateT> overrideWith(BlocT Function() createFn) {
    return StateProvider<BlocT, StateT>(
      createFn,
      uid: const Uuid().v4(),
      keepAlive: keepAlive,
      name: name,
      original: this,
      father: _father,
      args: _args,
    );
  }

  /// Creates an overrider provider from this one.
  @override
  StateProvider<BlocT, StateT> overrideWithValue(BlocT value) =>
      overrideWith(() => value);

  /// Get this provider's binding.
  @override
  @internal
  BlocT getBinding(RiveBlocRef ref) {
    // Set the ref
    final widgetRef = ref as WidgetRef;

    // Check overrides
    final overriderProvider = RiveBlocScope.of(widgetRef.context)
        .getProvider(uid) as ProviderBase<BlocT, BlocT>?;

    // Set
    final thisProvider = (overriderProvider ?? this)
        as RiveBlocProviderBase<BlocT, StateT, BlocT>;

    // Check if registered
    if (!getIt.isRegistered<BlocT>(
      instanceName: thisProvider.uid,
    )) {
      if (isFamily) {
        // Family provider
        registerValue(widgetRef.state);
      } else {
        throw StateError('$this has not been created neither by '
            '`RiveBlocScope` nor `RiveBlocBuilder`.');
      }
    }

    if (isFamily) {
      final value = getIt.get<BlocT>(
        instanceName: thisProvider.uid,
      );
      return value;
    }
    return widgetRef.context.read<BlocT>();
  }

  /// Dispose provider.
  @override
  @internal
  void dispose() {
    if (isFamily) {
      getIt
          .get<BlocT>(
            instanceName: uid,
          )
          .close();
    }
    super.dispose();
  }

  /// Reads and returns this provider value.
  ///
  /// {@macro ref.read_description}
  @override
  @internal
  BlocT read(RiveBlocRef ref) {
    // Set the ref
    final widgetRef = ref as WidgetRef;

    // Check overrides
    final overriderProvider = RiveBlocScope.of(widgetRef.context)
        .getProvider(uid) as ProviderBase<BlocT, BlocT>?;

    // Set
    final thisProvider = (overriderProvider ?? this)
        as RiveBlocProviderBase<BlocT, StateT, BlocT>;

    if (!getIt.isRegistered<BlocT>(
      instanceName: thisProvider.uid,
    )) {
      if (isFamily) {
        // Family provider
        registerValue(widgetRef.state);
      } else {
        throw StateError('$this has not been created neither by '
            '`RiveBlocScope` nor `RiveBlocBuilder`.');
      }
    }

    // Set provider
    widgetRef.provider = thisProvider;

    // Family provider
    if (isFamily) {
      final value = getIt.get<BlocT>(
        instanceName: thisProvider.uid,
      );
      _computeIfNeeded(
        ProviderRef(widgetRef, thisProvider, value),
        value,
      );
      return value;
    }

    // Compute the state if needed
    final value = widgetRef.context.read<BlocT>();
    _computeIfNeeded(ProviderRef(widgetRef, thisProvider, value), value);
    return value;
  }

  /// Reads and returns this provider value, and listens to changes.
  ///
  /// {@macro ref.watch_description}
  @override
  @internal
  BlocT watch(RiveBlocRef ref) {
    // Set the ref
    final widgetRef = ref as WidgetRef;

    // Check overrides
    final overriderProvider = RiveBlocScope.of(widgetRef.context)
        .getProvider(uid) as ProviderBase<BlocT, BlocT>?;

    // Set
    final thisProvider = (overriderProvider ?? this)
        as RiveBlocProviderBase<BlocT, StateT, BlocT>;

    // Check if registered
    if (!getIt.isRegistered<BlocT>(
      instanceName: thisProvider.uid,
    )) {
      if (isFamily) {
        // Family provider
        registerValue(widgetRef.state);
      } else {
        throw StateError('$this has not been created neither by '
            '`RiveBlocScope` nor `RiveBlocBuilder`.');
      }
    }

    // Set the provider.
    widgetRef.provider = thisProvider;

    // If this is a `Family Provider` then we must handle here the listening
    // process so that the Widget tree is rebuilt anytime the watched
    // Bloc `state` changes (No `BlocProvider` for `Family Providers`).
    if (isFamily) {
      final value = getIt.get<BlocT>(
        instanceName: thisProvider.uid,
      );
      ref.setListener<BlocT, StateT>(
        thisProvider.uid,
        provider: thisProvider,
        watcher: value,
        blocProvider: thisProvider,
        bloc: value,
        listener: (_) {
          // Make the tree rebuild.
          ref.rebuild();
        },
      );
      _computeIfNeeded(
        ProviderRef(widgetRef, thisProvider, value),
        value,
      );
      return value;
    }

    // Compute the state if needed
    final value = widgetRef.context.watch<BlocT>();
    _computeIfNeeded(
      ProviderRef<BlocT, StateT, BlocT>(widgetRef, thisProvider, value),
      value,
    );
    return value;
  }

  /// {@macro provider_factory}
  @override
  StateProvider<BlocT, StateT> call(
    RiveBlocRef ref,
    Args args,
  ) {
    return ref.getFamilyProvider(
          '$uid($args)',
        ) as StateProvider<BlocT, StateT>? ??
        StateProvider<BlocT, StateT>(
          _createFn,
          uid: '$uid($args)', // Unique 'args'-based identifier
          keepAlive: true, // Keep the instance alive
          name: name == null ? null : '$name($args)',
          father: this, // Set this provider the father
          args: args,
        );
  }

  void _computeIfNeeded(RiveBlocRef ref, BlocT value) {
    if (value is RefHandler) {
      (value as RefHandler).ref = ref;
    }

    // Return the value if it is not computable
    if (value is! Computable) {
      return;
    }

    // Compute the state if needed
    (value as Computable).call(ref, _args);
  }

  @override
  String toString() {
    if (name != null) {
      return name!;
    }
    return 'StateProvider<$BlocT> { uid: $uid }';
  }
}

/// {@template value_provider}
/// A [RiveBlocProvider] that creates and exposes a single-value
/// state Object of type [ValueT], computed once and shared.
/// {@endtemplate}
/// {@macro provider_description}
class ValueProvider<BlocT extends ValueCubit<ValueT>, ValueT extends Object?>
    extends RiveBlocProviderBase<BlocT, ValueT, ValueT>
    with Readable<BlocT, ValueT>, Watchable<BlocT, ValueT> {
  /// {@macro provider}
  ValueProvider(
    super.createFn, {
    required super.uid,
    required super.keepAlive,
    super.original,
    super.father,
    super.args,
    super.name,
  });

  /// A constructor that creates a provider from another one.
  @internal
  ValueProvider.fromProvider(ValueProvider<BlocT, ValueT> provider)
      : super(
          provider._createFn,
          uid: provider.uid,
          keepAlive: provider.keepAlive,
          name: provider.name,
          father: provider._father,
          args: provider._args,
        );

  /// Creates an overrider provider from this one.
  @override
  ValueProvider<BlocT, ValueT> overrideWith(
    BlocT Function() createFn,
  ) {
    return ValueProvider<BlocT, ValueT>(
      createFn,
      uid: const Uuid().v4(),
      keepAlive: keepAlive,
      name: name,
      original: this,
      father: _father,
      args: _args,
    );
  }

  /// Creates an overrider provider from this one.
  @override
  ValueProvider<BlocT, ValueT> overrideWithValue(BlocT value) =>
      overrideWith(() => value);

  /// Get this provider's binding.
  @override
  @internal
  BlocT getBinding(RiveBlocRef ref) {
    // Set the ref
    final widgetRef = ref as WidgetRef;

    // Check overrides
    final overriderProvider = RiveBlocScope.of(widgetRef.context)
        .getProvider(uid) as RiveBlocProviderBase<BlocT, ValueT, ValueT>?;

    // Set
    final thisProvider = overriderProvider ?? this;

    // Check if registered
    if (!getIt.isRegistered<BlocT>(
      instanceName: thisProvider.uid,
    )) {
      if (isFamily) {
        // Family provider
        registerValue(widgetRef.state);
      } else {
        throw StateError('$this has not been created neither by '
            '`RiveBlocScope` nor `RiveBlocBuilder`.');
      }
    }

    if (isFamily) {
      final value = getIt.get<BlocT>(
        instanceName: thisProvider.uid,
      );
      return value;
    }
    return widgetRef.context.read<BlocT>();
  }

  /// Dispose provider.
  @override
  @internal
  void dispose() {
    if (isFamily) {
      getIt
          .get<BlocT>(
            instanceName: uid,
          )
          .close();
    }
    super.dispose();
  }

  /// Reads and returns this provider value.
  ///
  /// {@macro ref.read_description}
  @override
  @internal
  ValueT read(RiveBlocRef ref) {
    // Set the ref
    final widgetRef = ref as WidgetRef;

    // Check overrides
    final overriderProvider = RiveBlocScope.of(widgetRef.context)
        .getProvider(uid) as RiveBlocProviderBase<BlocT, ValueT, ValueT>?;

    // Set
    final thisProvider = overriderProvider ?? this;

    if (!getIt.isRegistered<BlocT>(
      instanceName: thisProvider.uid,
    )) {
      if (isFamily) {
        // Family provider
        registerValue(widgetRef.state);
      } else {
        throw StateError('$this has not been created neither by '
            '`RiveBlocScope` nor `RiveBlocBuilder`.');
      }
    }

    // Set provider
    widgetRef.provider = thisProvider;

    // Family provider
    if (isFamily) {
      final value = getIt.get<BlocT>(
        instanceName: thisProvider.uid,
      );
      _computeIfNeeded(
        ProviderRef(widgetRef, thisProvider, value),
        value,
      );
      return value.state;
    }

    // Compute the state if needed
    final value = widgetRef.context.read<BlocT>();
    _computeIfNeeded(ProviderRef(widgetRef, thisProvider, value), value);
    return value.state;
  }

  /// Read and returns this provider value, and listen to changes.
  ///
  /// {@macro ref.watch_description}
  @override
  @internal
  ValueT watch(RiveBlocRef ref) {
    // Set the ref
    final widgetRef = ref as WidgetRef;

    // Check overrides
    final overriderProvider = RiveBlocScope.of(widgetRef.context)
        .getProvider(uid) as RiveBlocProviderBase<BlocT, ValueT, ValueT>?;

    // Set
    final thisProvider = overriderProvider ?? this;

    // Check if registered
    if (!getIt.isRegistered<BlocT>(
      instanceName: thisProvider.uid,
    )) {
      if (isFamily) {
        // Family provider
        registerValue(widgetRef.state);
      } else {
        throw StateError('$this has not been created neither by '
            '`RiveBlocScope` nor `RiveBlocBuilder`.');
      }
    }

    // Set provider
    widgetRef.provider = thisProvider;

    // If this is a `Family Provider` then we must handle here the listening
    // process so that the Widget tree is rebuilt anytime the watched
    // Bloc `state` changes (No `BlocProvider` for `Family Providers`).
    if (isFamily) {
      final value = getIt.get<BlocT>(
        instanceName: thisProvider.uid,
      );
      ref.setListener<BlocT, ValueT>(
        thisProvider.uid,
        provider: thisProvider,
        watcher: value,
        blocProvider: thisProvider,
        bloc: value,
        listener: (_) {
          // Make the tree rebuild.
          ref.rebuild();
        },
      );
      _computeIfNeeded(
        ProviderRef(widgetRef, thisProvider, value),
        value,
      );
      return value.state;
    }

    // Compute the state if needed
    final value = widgetRef.context.watch<BlocT>();
    _computeIfNeeded(
      ProviderRef(widgetRef, thisProvider, value),
      value,
    );
    return value.state;
  }

  /// {@macro provider_factory}
  @override
  ValueProvider<BlocT, ValueT> call(
    RiveBlocRef ref,
    Args args,
  ) {
    return ref.getFamilyProvider(
          '$uid($args)',
        ) as ValueProvider<BlocT, ValueT>? ??
        ValueProvider<BlocT, ValueT>(
          _createFn,
          uid: '$uid($args)', // Unique 'args'-based identifier
          keepAlive: true, // Keep the instance alive
          name: name == null ? null : '$name($args)',
          father: this, // Set this provider the father
          args: args,
        );
  }

  void _computeIfNeeded(
    RiveBlocRef ref,
    BlocT value,
  ) {
    value
      // Set ref
      ..ref = ref

      // Compute the state (if needed)
      ..call(ref, _args);
  }

  @override
  String toString() {
    if (name != null) {
      return name!;
    }
    return 'ValueProvider<$BlocT, $ValueT> { uid: $uid }';
  }
}

/// {@template provider}
/// Creates and exposes [RiveBloc]/[RiveCubit] states.
/// {@endtemplate}
/// {@template provider_description}
///
/// All the providers should be declared through the [RiveBlocScope] root
/// widget (not really mandatory, but highly recommended), so that they are
/// for sure accessible from anywhere in the application!
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
/// Providers can also be declared in the `providers` list of the
/// [RiveBlocBuilder] widget. But in this case, it is worth noting that
/// the provider is not kept alive by default, thus all the exposed Bloc/Cubit
/// instances are re-created each time the provider is first accessed under
/// a new [RiveBlocBuilder] widget declaring it in its `providers` list.
///
/// So, if you want to reuse the same instance of a Bloc/Cubit, you can
/// (1) set the `keepAlive` parameter to `true` when creating the provider
/// so that it is kept alive for the entire application lifetime,
/// or (2) use the `providers` parameter of an upper [RiveBlocBuilder] widget
/// to declare your provider so that it is kept alive for the lifetime of this
/// declaring [RiveBlocBuilder] widget, and available to the widgets
/// tree under it.
///
/// So, by default the instance of a Bloc/Cubit is disposed when the
/// [RiveBlocBuilder] declaring it is unmounted and disposed.
///
/// And if [keepAlive] is `true` the Bloc/Cubit is a singleton instance,
/// created only once:
/// - shared across the whole app,
/// - cached for the entire app lifeycle,
/// - disposed only when the app is closed.
///
/// If [keepAlive] is `true` the same instance is always returned through
/// the [RiveBlocRef] `read` and `watch` API methods.
///
/// When the exposed Bloc/Cubit is [Computable], the provider makes its
/// `state` value computed once via [Computable.build], on first access,
/// and returns its current `state` value on subsequent accesses.
///
/// ***IMPORTANT***: Multiple providers cannot share the same bloc/cubit type!!
/// ```dart
/// // This, does not work:
/// final myBloc1 = RiveBlocProvider.state(() => MyBloc(1));
/// final myBloc2 = RiveBlocProvider.state(() => MyBloc(2));
///
/// // Do this, instead:
/// final myBloc1 = RiveBlocProvider.state(() => MyBloc1());
/// final myBloc2 = RiveBlocProvider.state(() => MyBloc2());
/// ```
///
/// {@endtemplate}
abstract class RiveBlocProviderBase<
        BlocT extends RiveBlocBase<StateT>,
        StateT extends Object?,
        ValueT extends Object?> extends ProviderBase<BlocT, ValueT>
    with Readable<BlocT, ValueT>, Watchable<BlocT, ValueT> {
  /// {@macro provider}
  RiveBlocProviderBase(
    super.createFn, {
    required super.uid,
    required super.keepAlive,
    super.name,
    super.original,
    super.father,
    super.args,
  });

  /// A constructor that creates a provider from another one.
  @internal
  RiveBlocProviderBase.fromProvider(
    RiveBlocProviderBase<BlocT, StateT, ValueT> provider,
  ) : super(
          provider._createFn,
          uid: provider.uid,
          keepAlive: provider.keepAlive,
          name: provider.name,
          father: provider._father,
          args: provider._args,
        );

  /// Creates a new [BlocProvider] out of this RiverBLoC `Provider`.
  @internal
  BlocProvider<BlocT> toBlocProvider(RiveBlocState state) {
    // Register the BLoC/Cubit instance in GetIt.
    registerValue(state);

    // Returns the BlocProvider
    return keepAlive
        ? BlocProvider.value(
            // Won't dispose the instance when the provider is unmounted.
            value: getIt.get<BlocT>(instanceName: uid),
          )
        : BlocProvider(
            // Will dispose the instance when the provider is unmounted.
            create: (_) => getIt.get<BlocT>(instanceName: uid),
          );
  }

  @override
  @internal
  // ignore: public_member_api_docs
  ValueT read(RiveBlocRef ref);

  @override
  @internal
  // ignore: public_member_api_docs
  ValueT watch(RiveBlocRef ref);

  /// {@template provider_factory}
  /// Creates a provider that builds its value from external parameters.
  /// {@endtemplate}
  RiveBlocProviderBase<BlocT, StateT, ValueT> call(
    RiveBlocRef ref,
    Args args,
  );
}

/// {@template final_value_provider}
/// A `Provider` that exposes a final Dart [Object] value.
/// {@endtemplate}
/// {@template value_provider_description}
///
/// All the providers should be declared through the [RiveBlocScope] widget
/// (not really mandatory, but highly recommended), so that they are for sure
/// accessible from anywhere in the application:
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
/// By default the value is created every time the provider is read, so the
/// `createFn` method is a factory method called each time accordingly.
///
/// A new instance will be created and returned by `createFn` on each access
/// to the provider.
///
/// If [keepAlive] is `true` the value is a singleton, created only once,
/// then cached; its `createFn` is called only the first time the provider
/// is read or watched, and the same value is returned every time the
/// provider is read.
///
/// ***IMPORTANT***: To avoid memory leaks, don't forget to dispose instances
/// when no longer needed!!
/// {@endtemplate}
class FinalProvider<T extends Object> extends ProviderBase<T, T>
    with Readable<T, T> {
  /// {@macro value_provider}
  FinalProvider(
    super.createFn, {
    required super.uid,
    required super.keepAlive,
    super.name,
    super.original,
    super.father,
    super.args,
  });

  /// A constructor that creates a provider from another one.
  @internal
  FinalProvider.fromProvider(FinalProvider<T> provider)
      : super(
          provider._createFn,
          uid: provider.uid,
          keepAlive: provider.keepAlive,
          name: provider.name,
          father: provider._father,
          args: provider._args,
        );

  /// Creates an overrider provider from this one.
  @override
  FinalProvider<T> overrideWith(T Function() createFn) {
    return FinalProvider<T>(
      createFn,
      uid: const Uuid().v4(),
      keepAlive: keepAlive,
      name: name,
      original: this,
      father: _father,
      args: _args,
    );
  }

  /// Creates an overrider provider from this one.
  @override
  FinalProvider<T> overrideWithValue(T value) => overrideWith(() => value);

  /// Get this provider's binding.
  @override
  @internal
  T getBinding(RiveBlocRef ref) {
    // Set the ref
    final widgetRef = ref as WidgetRef;

    // Check if overriden
    final overriderProvider = RiveBlocScope.of(widgetRef.context)
        .getProvider(uid) as FinalProvider<T>?;
    final thisProvider = overriderProvider ?? this;

    // Done
    return thisProvider.value;
  }

  /// Dispose provider.
  @override
  @internal
  void dispose() {
    super.dispose();
  }

  /// {@template riverbloc.provider.value}
  /// Creates and returns the Dart [Object] exposed by this provider.
  ///
  /// By default the value is created every time this provider
  /// is read, so the [_createFn] method is called each time accordingly.
  ///
  /// If [keepAlive] is `true` the value is a singleton, created
  /// only once and cached, its [_createFn] is called only the
  /// first time the provider is read or watched, and the same value is
  /// returned every time the provider is read.
  ///
  /// ***IMPORTANT***: To avoid memory leaks, this method should only be
  /// called when `keepAlive` is `true`. Otherwise, don't forget to dispose
  /// instances when no longer needed!!
  /// {@endtemplate}
  T get value {
    // Check if registered
    if (!getIt.isRegistered<T>(instanceName: uid)) {
      throw StateError('$this ($T) has not been enabled neither by '
          '`RiveBlocScope` nor `RiveBlocBuilder`.');
    }

    // Check overrides
    final overriderProvider =
        RiveBlocScopeState.getFinalProvider(uid) as FinalProvider<T>?;

    // Set
    final thisProvider = overriderProvider ?? this;

    return getIt.get<T>(instanceName: thisProvider.uid);
  }

  /// Reads and returns this provider value.
  ///
  /// Calling this method is equivalent to calling:
  /// ```dart
  /// myProvider.value;
  /// ```
  @override
  @internal
  T read(RiveBlocRef ref) {
    // Set the ref
    final widgetRef = ref as WidgetRef;

    // Check overrides
    final overriderProvider = RiveBlocScope.of(widgetRef.context)
        .getProvider(uid) as FinalProvider<T>?;

    // Done
    return overriderProvider?.value ?? this.value;
  }

  @override
  String toString() {
    if (name != null) {
      return name!;
    }
    return 'FinalProvider<$T> { uid: $uid }';
  }
}

/// Base Provider.
class ProviderBase<BindingT extends Object, ValueT extends Object?> {
  /// Base Provider
  ProviderBase(
    this._createFn, {
    required this.uid,
    required this.keepAlive,
    ProviderBase<BindingT, ValueT>? father,
    this.original,
    Args? args,
    this.name,
  })  : _father = father,
        _args = args;

  /// A constructor that creates a provider from another one.
  @internal
  ProviderBase.fromProvider(ProviderBase<BindingT, ValueT> provider)
      : this(
          provider._createFn,
          uid: provider.uid,
          father: provider._father,
          args: provider._args,
          keepAlive: provider.keepAlive,
          name: provider.name,
        );

  /// Creates an overrider provider from this one.
  ProviderBase<BindingT, ValueT> overrideWith(BindingT Function() createFn) {
    return ProviderBase<BindingT, ValueT>(
      createFn,
      uid: uid,
      keepAlive: keepAlive,
      name: name,
      father: _father,
      args: _args,
    );
  }

  /// Creates an overrider provider from this one.
  ProviderBase<BindingT, ValueT> overrideWithValue(BindingT value) =>
      overrideWith(() => value);

  /// The factory method that creates the value exposed by this provider.
  final BindingT Function() _createFn;

  /// The unique identifier of this provider.
  final String uid;

  /// The father (if any).
  final ProviderBase<BindingT, ValueT>? _father;

  /// The original overriden provider.
  final ProviderBase<BindingT, ValueT>? original;

  /// External factory parameters.
  final Args? _args;

  /// The name of this provider.
  final String? name;

  /// Whether the value exposed by this provider is kept alive.
  final bool keepAlive;

  /// Is Family Provider.
  bool get isFamily => _father != null;

  final _watchers = <Computable<dynamic>>[];

  @internal
  // ignore: public_member_api_docs
  void addWatcher(Computable<dynamic> watcher) => _watchers.add(watcher);

  @internal
  // ignore: public_member_api_docs
  void invalidateWatchers(RiveBlocRef ref) {
    for (final watcher in _watchers) {
      watcher.invalidate(ref, refresh: false);
    }
  }

  @internal
  // ignore: public_member_api_docs
  void removeWatcher(Computable<dynamic> watcher) => _watchers.remove(watcher);

  /// Registers the BLoC/Cubit instance in GetIt.
  @internal
  void registerValue(RiveBlocState state) {
    // Already registered
    if (getIt.isRegistered<BindingT>(instanceName: uid)) {
      return;
    }

    // Family provider registration
    if (isFamily) {
      state.registerFamilyProvider(this);
    }

    // Binding instance registration
    if (keepAlive) {
      getIt.registerLazySingleton(
        _createFn,
        instanceName: uid,
      );
    } else {
      getIt.registerFactory(
        _createFn,
        instanceName: uid,
      );
    }
  }

  /// Dispose provider.
  @internal
  void dispose() {
    // Dispose the instance
    if (getIt.isRegistered<BindingT>(instanceName: uid)) {
      getIt.unregister<BindingT>(instanceName: uid);
    }

    // Clear watchers
    _watchers.clear();
  }
}
