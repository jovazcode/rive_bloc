import 'package:bloc/bloc.dart';

import 'package:rive_bloc/src/rive_bloc.dart';

export 'async_cubit.dart';
export 'computable.dart';
export 'stream_bloc.dart';
export 'value_cubit.dart';

/// A base class for [RiveBloc] and [RiverCubit].
class RiveBlocBase<T> extends BlocBase<T> {
  /// A base class for [RiveBloc] and [RiverCubit].
  RiveBlocBase(super.state);
}

/// {@template rive_bloc}
/// A [Bloc] component with access to [RiveBlocRef].
///
/// This [Bloc] is intended to be used through a [RiveBlocProviderBase] which
/// will automatically gives it access to a [RiveBlocRef] instance.
///
/// Thus, [RiveBloc] components have the 'extra' capacity to `read` values
/// from other providers, and also `call` their methods, through the [ref]
/// parameter!!
///
/// ***IMPORTANT***: [RiveBlocRef.watch] is not intended to be called
/// from every method of [RiveBloc] components, so its use is unsupported.
///
/// {@endtemplate}
class RiveBloc<Event, State> extends Bloc<Event, State>
    with RefHandler
    implements RiveBlocBase<State> {
  /// {@macro rive_bloc}
  RiveBloc(State Function() initialState) : super(initialState());
}

/// {@template river_cubit}
/// A [Cubit] component with access to [RiveBlocRef].
///
/// This [Cubit] is intended to be used through a [RiveBlocProviderBase]
/// which will automatically gives it access to a [RiveBlocRef] instance.
///
/// Thus, [RiverCubit] components have the 'extra' capacity to `read` values
/// from other providers, and also `call` their methods, through the [ref]
/// parameter!!
///
/// ***IMPORTANT***: [RiveBlocRef.watch] is not intended to be called
/// from every method of [RiverCubit] components, so its use is unsupported.
///
/// {@endtemplate}
class RiverCubit<State extends Object?> extends Cubit<State>
    with RefHandler
    implements RiveBlocBase<State> {
  /// {@macro river_cubit}
  RiverCubit(State Function() initialState) : super(initialState());
}
