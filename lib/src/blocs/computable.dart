import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:meta/meta.dart';

import 'package:rive_bloc/src/rive_bloc.dart';

/// {@template computable}
/// A mixin that makes a Bloc/Cubit computable.
/// {@endtemplate}
/// {@template computable.build}
/// Computes a new state (or do something), only once!
///
/// This is useful when you want to expose a [state] that must be computed
/// only once, or when a "non-static" initial value must be computed.
///
/// In any case, [build] will be called when the [RiveBlocProviderBase]
/// is first `read` or `watch`. Subsequent reads will not call the function
/// again, but instead return the current [state] value.
///
/// It is safe to use [RiveBlocRef.read] or [RiveBlocRef.watch] inside
/// the [build] method to combine multiple providers.
///
/// If a dependency of this Bloc/Cubit (when using [RiveBlocRef.watch])
/// changes, then [build] will be re-executed. On the other hand,
/// the Bloc/Cubit will not be recreated. Its instance will be preserved
/// between executions of [build] and always remain the same.
///
/// If this method throws, reading this [RiveBlocProviderBase] will rethrow
/// the error.
/// {@endtemplate}
mixin Computable<T> on BlocBase<T> {
  /// Last arguments applied to the [build] state computing function.
  Args? args;

  /// Is value computed.
  /// @nodoc
  @internal
  @internal
  bool get isComputed => _computedValue != null;

  /// Last computed value.
  /// @nodoc
  @nonVirtual
  @internal
  FutureOr<T>? get computedValue => _computedValue;
  FutureOr<T>? _computedValue;

  /// Invalidates the computed state.
  /// @nodoc
  @nonVirtual
  @internal
  void invalidate(RiveBlocRef ref, {bool refresh = true}) {
    // Reset computed value.
    _computedValue = null;

    // Re-compute the state.
    //
    // TODO(jvc): Find a way to avoid calling `this` directly.
    // Direct `call(ref, args)` is unsafe, when invoked
    // from ouside the widgets tree, depending on what the
    // app compute function is supposed to do!!
    if (refresh && !isClosed && (ref as WidgetRef).context.mounted) {
      this(ref, args);
    }
  }

  /// {@macro computable.build}
  FutureOr<T> build(RiveBlocRef ref, Args? args);

  /// @macro computable_value
  /// @nodoc
  @nonVirtual
  @internal
  FutureOr<T> call(RiveBlocRef ref, [Args? args]) async {
    // Save last args for later computing use.
    this.args = args;

    // If computed, return actual state
    if (isComputed) {
      return await computedValue!;
    }

    // Compute and cache the computed result.
    _computedValue = build(ref, args);

    // Await and emit the new computed state.
    final value = await _computedValue!;
    if (!isClosed) {
      emit(value);
    }

    // Return the computed state.
    return value;
  }
}
