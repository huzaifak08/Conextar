// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'roundtable_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RoundtableNotifier)
final roundtableProvider = RoundtableNotifierProvider._();

final class RoundtableNotifierProvider
    extends $AsyncNotifierProvider<RoundtableNotifier, List<RoundtableModel>> {
  RoundtableNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'roundtableProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$roundtableNotifierHash();

  @$internal
  @override
  RoundtableNotifier create() => RoundtableNotifier();
}

String _$roundtableNotifierHash() =>
    r'fc2bbbb8e01ce5534d9addca9aaf981834697587';

abstract class _$RoundtableNotifier
    extends $AsyncNotifier<List<RoundtableModel>> {
  FutureOr<List<RoundtableModel>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<RoundtableModel>>, List<RoundtableModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<RoundtableModel>>,
                List<RoundtableModel>
              >,
              AsyncValue<List<RoundtableModel>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
