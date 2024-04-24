import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import 'package:rive_bloc/src/rive_bloc.dart';

/// {@template value_cubit}
/// Streamlined `Cubit` for managing single-value states.
///
/// The [state] of [ValueCubit] is expected to be initialized synchronously.
///
/// This [Cubit] as any RiveBloc `Bloc`/`Cubit` is intended to be used
/// through a [RiveBlocProviderBase] which will automatically make its
/// [state] value computed once, on the first access to the
/// [RiveBlocProviderBase], via the [build] method, and will return its
/// current [state] value on subsequent accesses.
///
/// So, if you want to expose a single-value that should be computed only once,
/// just implement a [ValueCubit] and override the [build] method so you
/// can return the computed value you want to expose.
///
/// The [build] method will be called only when the [RiveBlocProviderBase]
/// is first `read` or `watched`.
///
/// Also, the [ValueCubit] as any [RiverCubit] has the 'extra' capacity to
/// `read` other providers from any method through the [ref] parameter. So
/// you can access their values and `call` their methods from any part of
/// [ValueCubit].
///
/// ***IMPORTANT***: While it is absolutely safe to use both
/// [RiveBlocRef.read] and [RiveBlocRef.watch] inside the [build] method,
/// to combine multiple providers, from other methods it is only supported to
/// use [RiveBlocRef.read].
///
/// The interesting part of this is that if a Bloc/Cubit dependency changes
/// (when using [RiveBlocRef.watch]), then [build] will be re-executed
/// accordingly, so the [state] will be recomputed and updated, and the
/// instance of the [ValueCubit] will remain the same between the executions
/// of the [build].
///
/// Look at the following example where the filtered tasks list is
/// automatically computed and cached each time the `taskListFilter` or
/// the `taskListProvider` changes:
///
/// ```dart
/// final tasksProvider = RiveBlocProvider.state(()
///                         => FilteredTasksCubit());
///
/// class FilteredTasksCubit extends ValueCubit<List<Task>> {
///   FilteredTasksCubit() : super(() => []);
///
///   @override
///   List<Task> build(RiveBlocRef ref, Args? args) {
///     final filter = ref.watch(taskListFilter);
///     final tasks = ref.watch(taskListProvider);
///
///     switch (filter) {
///       case TaskListFilter.completed:
///         return todos.where((task) => task.completed).toList();
///       case TaskListFilter.active:
///         return todos.where((task) => !task.completed).toList();
///       case TaskListFilter.all:
///         return tasks;
///     }
///   }
/// }
/// ```
///
/// Also, don't forget that [ValueCubit], as any [Cubit], can [emit] new
/// values at any time in any method you need.
///
/// ```dart
/// final taskListProvider = RiveBlocProvider.state(() => TaskListCubit());
///
/// class TaskListCubit extends ValueCubit<List<Task>> {
///   TaskListCubit() : super(() => []);
///
///   void addTask(Task task) => emit(
///         [...state, task],
///       );
///   void removeTask(Task task) => emit(
///         state.where((t) => t != task).toList(),
///       );
/// }
/// ```
///
/// Moreover, this [Cubit] allows you to set new [state] values at any time
/// from the outside, through the [state] setter method. Useful for simple
/// cases where you don't need any method to compute the new [state] value,
/// but just set it. For example:
///
/// ```dart
/// ref.read(taskListFilter).state = TaskListFilter.all;
/// ```
///
/// {@endtemplate}
class ValueCubit<T extends Object?> extends RiverCubit<T>
    with Computable<T>
    implements RiveBlocBase<T> {
  /// {@macro value_cubit}
  ValueCubit(
    T initialState, {
    FutureOr<T> Function(
      RiveBlocRef ref,
      Args args,
    )? build,
  })  : _valueFn = build,
        super(() => initialState);

  final FutureOr<T> Function(
    RiveBlocRef ref,
    Args args,
  )? _valueFn;

  /// Obtains the [Future] associated with the `build` function
  /// of this [ValueCubit].
  Future<T> get future async => await build(ref, args ?? const Args());

  /// {@macro computable.build}
  @visibleForOverriding
  @override
  FutureOr<T> build(RiveBlocRef ref, Args? args) {
    if (_valueFn == null) return state;
    return _valueFn!(ref, args ?? const Args());
  }

  /// You can set the [state] value at any time from outside!
  @nonVirtual
  set state(T value) => emit(value);

  @override
  String toString() {
    return 'ValueCubit<$T> { state: $state }';
  }
}
