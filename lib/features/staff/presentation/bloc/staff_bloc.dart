import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vacapp/features/staff/data/models/staff_dto.dart';
import 'package:vacapp/features/staff/data/repositories/staff_repository.dart';
import 'package:vacapp/features/staff/presentation/bloc/staff_event.dart';
import 'package:vacapp/features/staff/presentation/bloc/staff_state.dart';
import 'package:flutter/foundation.dart';

class StaffBloc extends Bloc<StaffEvent, StaffState> {
  final StaffRepository _staffRepository;

  StaffBloc(this._staffRepository) : super(StaffInitial()) {
    on<LoadStaffs>(_onLoadStaffs);
    on<CreateStaff>(_onCreateStaff);
    on<UpdateStaff>(_onUpdateStaff);
    on<DeleteStaff>(_onDeleteStaff);
    on<LoadStaffById>(_onLoadStaffById);
    on<LoadStaffsByCampaign>(_onLoadStaffsByCampaign);
    on<LoadStaffsByEmployeeStatus>(_onLoadStaffsByEmployeeStatus);
    on<SearchStaffByName>(_onSearchStaffByName);
  }

  Future<void> _onLoadStaffs(LoadStaffs event, Emitter<StaffState> emit) async {
    try {
      emit(StaffLoading());
      final staffs = await _staffRepository.getAllStaffs();
      emit(StaffLoaded(staffs: staffs));
    } catch (e) {
      emit(StaffError(message: 'Error al cargar staffs: $e'));
    }
  }

  Future<void> _onCreateStaff(CreateStaff event, Emitter<StaffState> emit) async {
    try {
      emit(StaffCreating());
      
      debugPrint('🔄 Creating staff with:');
      debugPrint('  - name: ${event.name}');
      debugPrint('  - employeeStatus: ${event.employeeStatus}');
      debugPrint('  - campaignId: ${event.campaignId}');
      
      final newStaff = StaffDto(
        id: 0, // El backend asignará el ID
        name: event.name,
        employeeStatus: event.employeeStatus,
        campaignId: event.campaignId,
      );

      final createdStaff = await _staffRepository.createStaff(newStaff);
      debugPrint('✅ Staff created successfully: ${createdStaff.id}');
      
      emit(StaffOperationSuccess(message: 'Personal creado exitosamente'));
      
      // Recargar la lista
      add(LoadStaffs());
    } catch (e) {
      debugPrint('❌ Error creating staff: $e');
      String errorMessage = 'Error al crear el personal';
      
      if (e.toString().contains('FormatException')) {
        errorMessage = 'Error de formato en la respuesta del servidor';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'Error de conexión con el servidor';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Tiempo de espera agotado';
      } else if (e.toString().contains('Exception:')) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      }
      
      emit(StaffError(message: errorMessage));
    }
  }

  Future<void> _onUpdateStaff(UpdateStaff event, Emitter<StaffState> emit) async {
    try {
      emit(StaffUpdating());
      await _staffRepository.updateStaff(event.id, event.staff);
      emit(StaffOperationSuccess(message: 'Staff actualizado exitosamente'));
      
      // Recargar la lista
      add(LoadStaffs());
    } catch (e) {
      emit(StaffError(message: 'Error al actualizar staff: $e'));
    }
  }

  Future<void> _onDeleteStaff(DeleteStaff event, Emitter<StaffState> emit) async {
    try {
      emit(StaffDeleting());
      await _staffRepository.deleteStaff(event.id);
      emit(StaffOperationSuccess(message: 'Staff eliminado exitosamente'));
      
      // Recargar la lista
      add(LoadStaffs());
    } catch (e) {
      emit(StaffError(message: 'Error al eliminar staff: $e'));
    }
  }

  Future<void> _onLoadStaffById(LoadStaffById event, Emitter<StaffState> emit) async {
    try {
      emit(StaffLoading());
      final staff = await _staffRepository.getStaffById(event.id);
      emit(StaffDetailLoaded(staff: staff));
    } catch (e) {
      emit(StaffError(message: 'Error al cargar staff: $e'));
    }
  }

  Future<void> _onLoadStaffsByCampaign(LoadStaffsByCampaign event, Emitter<StaffState> emit) async {
    try {
      emit(StaffLoading());
      final staffs = await _staffRepository.getStaffByCampaignId(event.campaignId);
      emit(StaffLoaded(staffs: staffs));
    } catch (e) {
      emit(StaffError(message: 'Error al cargar staffs por campaña: $e'));
    }
  }

  Future<void> _onLoadStaffsByEmployeeStatus(LoadStaffsByEmployeeStatus event, Emitter<StaffState> emit) async {
    try {
      emit(StaffLoading());
      final staffs = await _staffRepository.getStaffByEmployeeStatus(event.employeeStatus);
      emit(StaffLoaded(staffs: staffs));
    } catch (e) {
      emit(StaffError(message: 'Error al cargar staffs por estado: $e'));
    }
  }

  Future<void> _onSearchStaffByName(SearchStaffByName event, Emitter<StaffState> emit) async {
    try {
      emit(StaffLoading());
      final staffs = await _staffRepository.getStaffByName(event.name);
      emit(StaffLoaded(staffs: staffs));
    } catch (e) {
      emit(StaffError(message: 'Error al buscar staff: $e'));
    }
  }
}
