import 'package:meta/meta.dart';
import 'package:rive_bloc/src/rive_bloc.dart';

@internal
mixin Watchable<BindingT extends Object, ValueT extends Object?>
    on ProviderBase<BindingT, ValueT> {
  /// Returns the BLoC/Cubit exposed by this provider.
  ///
  /// {@macro ref.watch_description}
  @internal
  ValueT watch(RiveBlocRef ref);
}
