<p align="center">
  <img src="https://github.com/jovazcode/rive_bloc/raw/main/screenshots/logo.png" height="300" alt="River Bloc">
</p>

# RiveBloc

<!-- [![build][build_badge]][build_link] -->
<!-- [![coverage][coverage_badge]][build_link] -->
[![pub package][pub_badge]][pub_link]
[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

[build_link]: https://github.com/jovazcode/rive_bloc/actions/workflows/main.yaml
[pub_link]: https://pub.dev/packages/rive_bloc
[build_badge]: https://github.com/jovazcode/rive_bloc/actions/workflows/main.yaml/badge.svg
[coverage_badge]: https://github.com/jovazcode/rive_bloc/raw/main/coverage_badge.svg
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[pub_badge]: https://img.shields.io/pub/v/rive_bloc.svg
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis

Built on top of the [Flutter BLoC](https://pub.dev/packages/flutter_bloc) library, **RiveBloc** is a Programming Interface Layer deeply inspired by [Riverpod](https://riverpod.dev/) that makes working with [BLoC](https://bloclibrary.dev/) less verbose and less time-consuming.

## Quick Start 🚀

The main building blocks of RiveBloc are `providers` and `builders`.

A `Provider` is a way to get access to a piece of state (an `Object` value or a `Bloc`/`Cubit` instance), while a `Builder` is a way to
use that state in the widgets tree.

`RiveBlocProvider` is the main entry point for creating providers.

***IMPORTANT***: For providers to work, you need to add `RiveBlocScope`
at the root of your Flutter applications, like this:
```dart
void main() {
  runApp(RiveBlocScope(child: MyApp()));
}
```

Providers solve the following problems:
- Providers have the flexibility of global variables, without their
downsides. They can be accessed from anywhere, while ensuring
testability and scalability,
- Providers are safe to use. It is not possible to read a value in
an uninitialized state,
- Providers can be accessed in a single line of code.

**RiveBloc** offers 5 providers, divided into two main categories:
- 1 `Final` Provider for exposing final Dart `Object` values,
- 4 `RiveBloc` Providers for exposing `Bloc`/`Cubit` dynamic `state` values.

The `FinalProvider` is created with `RiveBlocProvider.finalValue`, while the other ones are created with
`RiveBlocProvider.value`, `RiveBlocProvider.state`, `RiveBlocProvider.async` and `RiveBlocProvider.stream`.

Providers come in many variants, but they all work the same way.

The most common usage is to declare them as global variables, like this:
```dart
final myProvider = RiveBlocProvider.finalValue(() => MyValue());
final myBlocProvider = RiveBlocProvider.state(() => MyBloc());
```

Secondly, all the providers should be declared through the `RiveBlocScope`
widget (not really mandatory, but highly recommended), so that they are
for sure accessible from anywhere in the application:
```dart
RiveBlocScope(
  providers: [
    myProvider,
    myBlocProvider,
    ...
  ],
  child: MyApp(),
);
```

***IMPORTANT***: Multiple providers cannot share the same value type!!
```dart
// This, does not work:
final value1 = RiveBlocProvider.value(() => MyValueCubit(1));
final value2 = RiveBlocProvider.value(() => MyValueCubit(2));

// Do this, instead:
final value1 = RiveBlocProvider.value(() => MyValueCubit1());
final value2 = RiveBlocProvider.value(() => MyValueCubit2());
```

Once the providers are declared, you can access the values and instances
they expose, by using the `read` and `watch` methods:
```dart
RiveBlocBuilder(
  builder: (context, ref) {
    final myValue = ref.read(myProvider);
    final myBloc = ref.watch(myBlocProvider);
  },
);
```
 - `myValue` is an instance of `MyValueCubit`,
 - `myBloc` is an instance of `MyBloc`.

<!-- ---

## Continuous Integration 🤖

**RiveBloc** comes with a built-in [GitHub Actions workflow][github_actions_link] powered by [Very Good Workflows][very_good_workflows_link].

On each pull request and push, the CI `formats`, `lints`, and `tests` the code. This ensures the code remains consistent and behaves correctly as you add functionality or make changes.

The project uses [Very Good Analysis][very_good_analysis_link] for a strict set of analysis options used by **Very Good** team.

Code coverage is enforced using the [Very Good Workflows][very_good_coverage_link].

---

## Running Tests 🧪

For first time users, install the [very_good_cli][very_good_cli_link]:

```sh
dart pub global activate very_good_cli
```

To run all unit tests:

```sh
very_good test --coverage
```

To view the generated coverage report you can use [lcov](https://github.com/linux-test-project/lcov).

```sh
# Generate Coverage Report
genhtml coverage/lcov.info -o coverage/

# Open Coverage Report
open coverage/index.html
``` -->

[flutter_install_link]: https://docs.flutter.dev/get-started/install
[github_actions_link]: https://docs.github.com/en/actions/learn-github-actions
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[logo_black]: https://raw.githubusercontent.com/VGVentures/very_good_brand/main/styles/README/vgv_logo_black.png#gh-light-mode-only
[logo_white]: https://raw.githubusercontent.com/VGVentures/very_good_brand/main/styles/README/vgv_logo_white.png#gh-dark-mode-only
[mason_link]: https://github.com/felangel/mason
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
[very_good_cli_link]: https://pub.dev/packages/very_good_cli
[very_good_coverage_link]: https://github.com/marketplace/actions/very-good-coverage
[very_good_ventures_link]: https://verygood.ventures
[very_good_ventures_link_light]: https://verygood.ventures#gh-light-mode-only
[very_good_ventures_link_dark]: https://verygood.ventures#gh-dark-mode-only
[very_good_workflows_link]: https://github.com/VeryGoodOpenSource/very_good_workflows
