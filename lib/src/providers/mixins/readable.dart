import 'package:meta/meta.dart';
import 'package:rive_bloc/src/rive_bloc.dart';

@internal
mixin Readable<BindingT extends Object, ValueT extends Object?>
    on ProviderBase<BindingT, ValueT> {
  /// Get provider's binding.
  @internal
  BindingT getBinding(RiveBlocRef ref);

  /// Reads and returns this provider value.
  @internal
  ValueT read(RiveBlocRef ref);
}
