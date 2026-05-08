import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vacapp/features/auth/data/repositories/auth_repository.dart';
import 'package:vacapp/features/auth/domain/entitites/user.dart';
import 'package:vacapp/features/auth/presentation/blocs/auth_event.dart';
import 'package:vacapp/features/auth/presentation/blocs/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(InitialAuthState()) {
    on<LoginEvent>(_onLogin);
    on<RegisterCompanyEvent>(_onRegisterCompany);
    on<RegisterRancherEvent>(_onRegisterRancher);
    on<RegisterBuyerEvent>(_onRegisterBuyer);
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(LoadingAuthState());
    try {
      final User user =
          await authRepository.login(email: event.email, password: event.password);
      emit(SuccessLoginState(user: user));
    } catch (e) {
      emit(FailureState(errorMessage: e.toString()));
    }
  }

  Future<void> _onRegisterCompany(
      RegisterCompanyEvent event, Emitter<AuthState> emit) async {
    emit(LoadingAuthState());
    try {
      final User user = await authRepository.registerCompany(
        fullName: event.fullName,
        email: event.email,
        password: event.password,
        phone: event.phone,
      );
      emit(SuccessRegisterState(user: user));
    } catch (e) {
      emit(FailureState(errorMessage: e.toString()));
    }
  }

  Future<void> _onRegisterRancher(
      RegisterRancherEvent event, Emitter<AuthState> emit) async {
    emit(LoadingAuthState());
    try {
      final User user = await authRepository.registerRancher(
        fullName: event.fullName,
        email: event.email,
        password: event.password,
        phone: event.phone,
      );
      emit(SuccessRegisterState(user: user));
    } catch (e) {
      emit(FailureState(errorMessage: e.toString()));
    }
  }

  Future<void> _onRegisterBuyer(
      RegisterBuyerEvent event, Emitter<AuthState> emit) async {
    emit(LoadingAuthState());
    try {
      final User user = await authRepository.registerBuyer(
        fullName: event.fullName,
        email: event.email,
        password: event.password,
        phone: event.phone,
      );
      emit(SuccessRegisterState(user: user));
    } catch (e) {
      emit(FailureState(errorMessage: e.toString()));
    }
  }
}
