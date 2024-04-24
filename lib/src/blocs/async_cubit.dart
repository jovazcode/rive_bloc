import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import 'package:rive_bloc/src/rive_bloc.dart';

/// {@template async_cubit}
/// Streamlined `Cubit` for managing asynchronous single-value states.
///
/// The [state] of [AsyncCubit] is expected to be initialized asynchronously.
///
/// This [Cubit] as any RiveBloc `Bloc`/`Cubit` is intended to be used
/// through a [RiveBlocProviderBase] which will automatically make its
/// [state] value computed once, on the first access to the
/// [RiveBlocProviderBase], via the [build] method, and will return its
/// current [state] value on subsequent accesses.
///
/// So, if you want to expose a single-value that should be computed only once,
/// just implement a [AsyncCubit] and override the [build] method so you
/// can return the computed value you want to expose.
///
/// The [build] method will be called only when the [RiveBlocProviderBase]
/// is first `read` or `watched`.
///
/// Also, the [AsyncCubit] as any [RiverCubit] has the 'extra' capacity to
/// `read` other providers from any method through the [ref] parameter. So
/// you can access their values and `call` their methods from any part of
/// [AsyncCubit].
///
/// ***IMPORTANT***: While it is absolutely safe to use both
/// [RiveBlocRef.read] and [RiveBlocRef.watch] inside the [build] method,
/// to combine multiple providers, from other methods it is only supported to
/// use [RiveBlocRef.read].
///
/// The interesting part of this is that if a Bloc/Cubit dependency changes
/// (when using [RiveBlocRef.watch]), then [build] will be re-executed
/// accordingly, so the [state] will be recomputed and updated, and the
/// instance of the [AsyncCubit] will remain the same between the executions
/// of the [build].
///
/// {@endtemplate}
class AsyncCubit<ValueT extends Object?> extends RiverCubit<AsyncValue<ValueT>>
    with Computable<AsyncValue<ValueT>>
    implements RiveBlocBase<AsyncValue<ValueT>> {
  /// {@macro async_cubit}
  AsyncCubit(this._asyncFn) : super(AsyncValue<ValueT>.loading);

  final FutureOr<ValueT> Function(
    RiveBlocRef ref,
    Args args,
  ) _asyncFn;

  /// Obtains the [Future] associated with the `async` function
  /// of this [AsyncCubit].
  Future<ValueT> get future async => await _asyncFn(ref, args ?? const Args());

  @override
  @internal
  Future<AsyncValue<ValueT>> build(RiveBlocRef ref, Args? args) async {
    // Emit loading state.
    emit(AsyncValue<ValueT>.loading());

    // Run the async function and emit the result.
    final newState = await AsyncValue.guard(
      () async => await _asyncFn(ref, args ?? const Args()),
    );
    emit(newState);

    // Return the new state.
    return newState;
  }

  @override
  String toString() {
    return 'AsyncCubit<$ValueT> { state: $state }';
  }
}
