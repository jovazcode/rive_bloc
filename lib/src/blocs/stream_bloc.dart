import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:meta/meta.dart';
import 'package:rive_bloc/src/rive_bloc.dart';

/// {@template stream_bloc_event}
/// Base class for all [StreamBlocEvent]s which are
/// handled by the [StreamBloc].
/// {@endtemplate}
abstract class StreamBlocEvent {
  /// {@macro stream_bloc_event}
  const StreamBlocEvent();
}

/// {@template stream_bloc_start}
/// Signifies to the [StreamBloc] that the user
/// has requested to start listening to the
/// stream.
/// {@endtemplate}
final class _StreamBlocStartedEvent extends StreamBlocEvent {
  /// {@macro stream_bloc_start}
  const _StreamBlocStartedEvent();
}

/// {@template stream_bloc_data}
/// Incoming data from [StreamBloc] stream.
/// {@endtemplate}
final class _StreamBlocDataEvent<ValueT extends Object?>
    extends StreamBlocEvent {
  /// {@macro stream_bloc_data}
  const _StreamBlocDataEvent(this.value);

  /// The incoming data from the stream.
  final ValueT value;
}

/// {@template stream_bloc}
/// A `Bloc` that manages a stream of values.
///
/// [StreamBloc] is identical in behavior/usage to [AsyncCubit], modulo the fact
/// that the [state] values come from a `Stream` instead of being computed
/// in a `build` method.
///
/// The initial value of [StreamBloc] can be specified synchronously.
///
/// It can be used to express a value asynchronously loaded that can change over
/// time, such as an editable `Message` coming from a web socket:
///
/// ```dart
/// final messageProvider = RiveBlocProvider.stream(()
///   => StreamBloc<String>((ref, args) => {
///           return IOWebSocketChannel.connect('ws://echo.websocket.org').stream;
///      });
/// );
/// ```
///
/// Which the UI can then listen:
///
/// ```dart
/// Widget build(context, ref) {
///   AsyncValue<String> message = ref.watch(messageProvider).state;
///
///   return message.when(
///     loading: () => const CircularProgressIndicator(),
///     error: (err, stack) => Text('Error: $err'),
///     data: (message) {
///       return Text(message);
///     },
///   );
/// }
/// ```
///
/// This [Bloc] as any RiveBloc `Bloc`/`Cubit` is intended to be used
/// through [RiveBlocProvider] which will manage its lifecycle and
/// allow accesses to it.
///
/// Also, the [StreamBloc] as any [RiveBloc] has the 'extra' capacity to
/// `read` other providers from any method through the [ref] parameter. So
/// you can access their values and `call` their methods from any part of
/// [StreamBloc].
///
/// ***IMPORTANT***: While it is absolutely safe to use both
/// [RiveBlocRef.read] and [RiveBlocRef.watch] inside the constructor method
/// to combine multiple providers, it is only supported to use
/// [RiveBlocRef.read] from other methods and parts of the Bloc.
///
/// The interesting part of this is that if a Bloc/Cubit dependency changes
/// (when using [RiveBlocRef.watch]), then the englobing Widgets tree
/// will be rebuilt and the method inside the constructor will be re-executed,
/// whereas the instance of the [StreamBloc] will remain the same between all
/// these executions.
///
/// {@endtemplate}
class StreamBloc<ValueT extends Object?>
    extends RiveBloc<StreamBlocEvent, AsyncValue<ValueT>>
    with Computable<AsyncValue<ValueT>>
    implements RiveBlocBase<AsyncValue<ValueT>> {
  /// {@macro stream_bloc}
  StreamBloc(this._streamFn) : super(AsyncValue.loading) {
    on<_StreamBlocStartedEvent>(
      (event, emit) async {
        emit(const AsyncValue.loading());
        await emit.onEach<ValueT>(
          _stream,
          onData: (value) => add(_StreamBlocDataEvent<ValueT>(value)),
        );
      },
      transformer: restartable(),
    );

    on<_StreamBlocDataEvent<ValueT>>(
      (event, emit) => emit(AsyncValue.data(event.value)),
    );
  }

  final Stream<ValueT> Function(RiveBlocRef ref, Args args) _streamFn;

  late Stream<ValueT> _stream;

  @override
  @internal
  AsyncValue<ValueT> build(RiveBlocRef ref, Args? args) {
    _stream = _streamFn(ref, args ?? const Args());
    add(const _StreamBlocStartedEvent());
    return state;
  }

  @override
  String toString() {
    return 'BlocStream<$ValueT> { state: $state }';
  }
}
