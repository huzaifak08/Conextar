import 'package:conextar/models/user_model.dart';

class SofaSlotModel {
  final int sofaIndex;
  final UserModel? user;

  SofaSlotModel({required this.sofaIndex, this.user});

  factory SofaSlotModel.fromMap(Map<String, dynamic> map) {
    return SofaSlotModel(
      sofaIndex: map['sofaIndex'] as int? ?? 0,
      user: map['user'] != null
          ? UserModel.fromMap(map['user'] as Map<String, dynamic>)
          : null,
    );
  }
}

class LoungeStateModel {
  final List<UserModel> waitingArea;
  final List<SofaSlotModel> sofas;

  LoungeStateModel({required this.waitingArea, required this.sofas});

  factory LoungeStateModel.fromMap(Map<String, dynamic> map) {
    return LoungeStateModel(
      waitingArea: map['waitingArea'] != null
          ? List<UserModel>.from(
              (map['waitingArea'] as List).map(
                (x) => UserModel.fromMap(x as Map<String, dynamic>),
              ),
            )
          : [],
      sofas: map['sofas'] != null
          ? List<SofaSlotModel>.from(
              (map['sofas'] as List).map(
                (x) => SofaSlotModel.fromMap(x as Map<String, dynamic>),
              ),
            )
          : [],
    );
  }
}
