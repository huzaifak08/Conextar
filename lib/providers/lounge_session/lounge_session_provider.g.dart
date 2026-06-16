// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lounge_session_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LoungeSession)
final loungeSessionProvider = LoungeSessionProvider._();

final class LoungeSessionProvider
    extends $NotifierProvider<LoungeSession, LoungeSessionState> {
  LoungeSessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loungeSessionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loungeSessionHash();

  @$internal
  @override
  LoungeSession create() => LoungeSession();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LoungeSessionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LoungeSessionState>(value),
    );
  }
}

String _$loungeSessionHash() => r'c891e33dabd926b8b77c0bfb944e32c95e50cd00';

abstract class _$LoungeSession extends $Notifier<LoungeSessionState> {
  LoungeSessionState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LoungeSessionState, LoungeSessionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LoungeSessionState, LoungeSessionState>,
              LoungeSessionState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
