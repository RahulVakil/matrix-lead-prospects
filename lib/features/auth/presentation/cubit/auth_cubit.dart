import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/services/mock/mock_data_generators.dart';

class AuthState extends Equatable {
  final UserModel? currentUser;
  final bool isLoggedIn;

  const AuthState({this.currentUser, this.isLoggedIn = false});

  @override
  List<Object?> get props => [currentUser?.id, isLoggedIn];
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthState());

  void login(UserRole role) {
    UserModel user;
    switch (role) {
      case UserRole.rm:
        user = MockDataGenerators.defaultRm;
        break;
      case UserRole.teamLead:
        user = MockDataGenerators.teamLead;
        break;
      case UserRole.admin:
        user = MockDataGenerators.admin;
        break;
      case UserRole.ib:
        user = MockDataGenerators.ibUser;
        break;
      default:
        user = MockDataGenerators.defaultRm;
    }
    emit(AuthState(currentUser: user, isLoggedIn: true));
  }

  void logout() {
    emit(const AuthState());
  }

  void switchRole(UserRole role) {
    login(role);
  }
}
