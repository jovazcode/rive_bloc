import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'package:rive_bloc/src/rive_bloc.dart';

export 'builder.dart';
export 'scope.dart';
export 'widget.dart';

/// An object that allows widgets to interact with RiverBLoC providers.
class WidgetRef implements RiveBlocRef {
  /// An object that allows widgets to interact with RiverBLoC providers.
  WidgetRef(
    this.context, {
    required this.state,
    this.provider,
  });

  /// The [BuildContext] of the widget associated to this [WidgetRef].
  @internal
  final BuildContext context;

  @internal
  // ignore: public_member_api_docs
  final RiveBlocState state;

  @internal
  // ignore: public_member_api_docs
  RiveBlocProviderBase? provider;

  /// Forces a provider to re-evaluate its state immediately, and return
  /// the created value.
  @override
  T refresh<BlocT extends RiveBlocBase<StateT>, StateT extends Object,
      T extends Object>(
    RiveBlocProviderBase<BlocT, StateT, T> provider,
  ) {
    invalidate(provider);
    return provider.read(this);
  }

  /// Invalidates the state of the provider, causing it to refresh.
  @override
  void invalidate(RiveBlocProviderBase provider) {
    final bloc = provider.getBinding(this);
    if (bloc is Computable) {
      (bloc as Computable).invalidate(this);
    }
  }

  /// Invalidates the state of the current provider, causing it to refresh.
  @override
  void invalidateSelf() => invalidate(provider!);

  /// Get a family provider.
  @override
  ProviderBase? getFamilyProvider(String uid) => state.getFamilyProvider(uid);

  /// Adds a listener to perform an operation right before the
  /// provider is destroyed.
  // ignore: avoid_setters_without_getters
  @override
  void onDispose(void Function() fn) => state.onDispose(fn);

  /// Rebuilds the widget associated to this [WidgetRef].
  @override
  void rebuild() {
    if (context.mounted) {
      // ignore: invalid_use_of_protected_member
      state.widgetState.setState(() {});
    }
  }

  /// Sets a listener to a [RiveBlocBase] instance.
  @override
  void setListener<BlocT extends RiveBlocBase<StateT>, StateT>(
    String uid, {
    required RiveBlocProviderBase provider,
    required RiveBlocBase<dynamic> watcher,
    required BlocT bloc,
    required void Function(StateT state) listener,
    dynamic Function(BlocT bloc)? listenWhen,
  }) =>
      state.setListener(
        this,
        uid,
        provider: provider,
        watcher: watcher,
        bloc: bloc,
        listener: listener,
        listenWhen: listenWhen,
      );

  /// Listen to a [RiveBlocProviderBase].
  @override
  void listen<BlocT extends RiveBlocBase<StateT>, StateT>(
    RiveBlocProviderBase<BlocT, StateT, dynamic> provider,
    void Function(BlocT bloc, StateT prevState, StateT nextState) listener, {
    dynamic Function(BlocT bloc)? listenWhen,
  }) {
    // So that `_computeIfNeeded` is called before `listenTo`.
    // Without this line, the listener could be listening to
    // a state that never gets computed/updated.
    read(provider);

    // Set listener & Subscription auto-cancellation callback.
    onDispose(
      _listenToBloc(
        bloc: provider.getBinding(this),
        listener: listener,
        listenWhen: listenWhen,
      ).cancel,
    );
  }

  StreamSubscription<StateT>
      _listenToBloc<BlocT extends RiveBlocBase<StateT>, StateT>({
    required BlocT bloc,
    required void Function(BlocT bloc, StateT prevState, StateT nextState)
        listener,
    dynamic Function(BlocT bloc)? listenWhen,
  }) {
    final prevState = bloc.state;
    final subscription = bloc.stream.listen((state) {
      if (listenWhen == null) {
        listener(bloc, prevState, state);
      }
    });
    return subscription;
  }

  /// Returns the value exposed by a provider and rebuild the widget when that
  /// value changes.
  @override
  T watch<ValueT extends Object, T extends Object?>(
    Watchable<ValueT, T> provider,
  ) =>
      provider.watch(this);

  /// Reads a provider without listening to it.
  @override
  T read<ValueT extends Object, T extends Object?>(
    Readable<ValueT, T> provider,
  ) =>
      provider.read(this);
}
