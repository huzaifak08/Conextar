// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'roundtable_participant_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RoundtableParticipantNotifier)
final roundtableParticipantProvider = RoundtableParticipantNotifierFamily._();

final class RoundtableParticipantNotifierProvider
    extends
        $AsyncNotifierProvider<
          RoundtableParticipantNotifier,
          List<RoundtableParticipantModel>
        > {
  RoundtableParticipantNotifierProvider._({
    required RoundtableParticipantNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'roundtableParticipantProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$roundtableParticipantNotifierHash();

  @override
  String toString() {
    return r'roundtableParticipantProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  RoundtableParticipantNotifier create() => RoundtableParticipantNotifier();

  @override
  bool operator ==(Object other) {
    return other is RoundtableParticipantNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$roundtableParticipantNotifierHash() =>
    r'0fb9b2a51d08e888d3b8f4e5366ec62a3db7ce49';

final class RoundtableParticipantNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          RoundtableParticipantNotifier,
          AsyncValue<List<RoundtableParticipantModel>>,
          List<RoundtableParticipantModel>,
          FutureOr<List<RoundtableParticipantModel>>,
          String
        > {
  RoundtableParticipantNotifierFamily._()
    : super(
        retry: null,
        name: r'roundtableParticipantProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RoundtableParticipantNotifierProvider call(String roundtableId) =>
      RoundtableParticipantNotifierProvider._(
        argument: roundtableId,
        from: this,
      );

  @override
  String toString() => r'roundtableParticipantProvider';
}

abstract class _$RoundtableParticipantNotifier
    extends $AsyncNotifier<List<RoundtableParticipantModel>> {
  late final _$args = ref.$arg as String;
  String get roundtableId => _$args;

  FutureOr<List<RoundtableParticipantModel>> build(String roundtableId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<RoundtableParticipantModel>>,
              List<RoundtableParticipantModel>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<RoundtableParticipantModel>>,
                List<RoundtableParticipantModel>
              >,
              AsyncValue<List<RoundtableParticipantModel>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
