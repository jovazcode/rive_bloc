## 0.0.1
Initial Version of the library.

## 0.0.2

* A list of watchers is maintained within watched providers.
* When a Provider is invalidated, we firstly invalidate it watchers.
* Added state setter to AsyncCubit.

## 0.0.3
* Added StreamProvider.

## 0.0.4
* Fix bug in Computable mixin when T is nullable
* Update stream_bloc documentation
* Rename RiverCubit to RiveCubit across the codebase
* Update state method signature to remove unnecessary type constraint
* Update RiveCubit constructor parameter name for clarity
* Update foregroundColor property to use WidgetStateProperty in Toolbar
* Bump flutter_bloc dependency version to 9.0.0
* Bump very_good_analysis from 5.1.0 to 6.0.0
* Bump get_it to 8.0.0
* Discard automatic loading state emission in AsyncCubit internal build