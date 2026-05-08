import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vacapp/features/marketplace/data/repositories/marketplace_repository.dart';
import 'package:vacapp/features/marketplace/presentation/blocs/marketplace_event.dart';
import 'package:vacapp/features/marketplace/presentation/blocs/marketplace_state.dart';

class MarketplaceBloc extends Bloc<MarketplaceEvent, MarketplaceState> {
  final MarketplaceRepository _repository;

  MarketplaceBloc(this._repository) : super(MarketplaceInitial()) {
    on<LoadPublicationsEvent>(_onLoad);
    on<LoadMyPublicationsEvent>(_onLoadMine);
    on<PublishBovineEvent>(_onPublish);
    on<RequestPurchaseEvent>(_onRequestPurchase);
    on<CancelPublicationEvent>(_onCancel);
  }

  Future<void> _onLoad(
      LoadPublicationsEvent event, Emitter<MarketplaceState> emit) async {
    emit(MarketplaceLoading());
    try {
      final pubs = await _repository.getPublished();
      emit(PublicationsLoaded(pubs));
    } catch (e) {
      emit(MarketplaceError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLoadMine(
      LoadMyPublicationsEvent event, Emitter<MarketplaceState> emit) async {
    emit(MarketplaceLoading());
    try {
      final pubs = await _repository.getMine();
      emit(PublicationsLoaded(pubs));
    } catch (e) {
      emit(MarketplaceError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onPublish(
      PublishBovineEvent event, Emitter<MarketplaceState> emit) async {
    emit(MarketplaceLoading());
    try {
      await _repository.publish(event.body);
      emit(const MarketplaceOperationSuccess('Bovino publicado exitosamente'));
      add(LoadMyPublicationsEvent());
    } catch (e) {
      emit(MarketplaceError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onRequestPurchase(
      RequestPurchaseEvent event, Emitter<MarketplaceState> emit) async {
    emit(MarketplaceLoading());
    try {
      await _repository.requestPurchase(event.publicationId, {
        'publicationId': event.publicationId,
        'buyerId': event.buyerId,
        if (event.message != null) 'message': event.message,
      });
      emit(const MarketplaceOperationSuccess('Solicitud de compra enviada'));
      add(LoadPublicationsEvent());
    } catch (e) {
      emit(MarketplaceError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCancel(
      CancelPublicationEvent event, Emitter<MarketplaceState> emit) async {
    emit(MarketplaceLoading());
    try {
      await _repository.cancel(event.id);
      emit(const MarketplaceOperationSuccess('Publicación cancelada'));
      add(LoadMyPublicationsEvent());
    } catch (e) {
      emit(MarketplaceError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
