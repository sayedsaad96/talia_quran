import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/identity/account_data_barrier.dart';
import '../../../../core/identity/record_owner_provider.dart';
import '../../domain/entities/kids_encouragement.dart';
import '../../domain/repositories/kids_encouragement_repository.dart';

final class ParentEncouragementComposerState extends Equatable {
  const ParentEncouragementComposerState({
    this.message = KidsEncouragementMessage.proud,
    this.sticker = KidsEncouragementSticker.starReward,
    this.isSending = false,
    this.sent = false,
    this.failed = false,
    this.quotaReached = false,
  });
  final KidsEncouragementMessage message;
  final KidsEncouragementSticker sticker;
  final bool isSending;
  final bool sent;
  final bool failed;
  final bool quotaReached;

  ParentEncouragementComposerState copyWith({
    KidsEncouragementMessage? message,
    KidsEncouragementSticker? sticker,
    bool? isSending,
    bool? sent,
    bool? failed,
    bool? quotaReached,
  }) => ParentEncouragementComposerState(
    message: message ?? this.message,
    sticker: sticker ?? this.sticker,
    isSending: isSending ?? this.isSending,
    sent: sent ?? this.sent,
    failed: failed ?? this.failed,
    quotaReached: quotaReached ?? this.quotaReached,
  );

  @override
  List<Object?> get props => [
    message,
    sticker,
    isSending,
    sent,
    failed,
    quotaReached,
  ];
}

final class ParentEncouragementComposerCubit
    extends Cubit<ParentEncouragementComposerState> {
  ParentEncouragementComposerCubit({
    required this._repository,
    required this._barrier,
    required this._owner,
    required Stream<void> accountChanges,
    required this._newRequestId,
    bool Function(Object error)? isQuotaError,
  }) : _isQuotaError = isQuotaError ?? _defaultQuotaError,
       super(const ParentEncouragementComposerState()) {
    _changes = accountChanges.listen((_) => _clearForAccountChange());
  }

  final KidsEncouragementRepository _repository;
  final AccountDataBarrier _barrier;
  final RecordOwnerProvider _owner;
  final String Function() _newRequestId;
  final bool Function(Object error) _isQuotaError;
  String? _retryPayload;
  String? _retryRequestId;
  late final StreamSubscription<void> _changes;
  int _generation = 0;

  void selectMessage(KidsEncouragementMessage value) {
    if (state.isSending || state.message == value) return;
    _clearRetry();
    emit(
      state.copyWith(
        message: value,
        sent: false,
        failed: false,
        quotaReached: false,
      ),
    );
  }

  void selectSticker(KidsEncouragementSticker value) {
    if (state.isSending || state.sticker == value) return;
    _clearRetry();
    emit(
      state.copyWith(
        sticker: value,
        sent: false,
        failed: false,
        quotaReached: false,
      ),
    );
  }

  Future<void> send(String childUserId) => _send(childUserId);
  Future<void> retry(String childUserId) => _send(childUserId);

  Future<void> _send(String childUserId) async {
    if (state.isSending || childUserId.isEmpty) return;
    _SendContext? context;
    try {
      context = _beginSend(childUserId);
      final result = await _repository.send(
        childUserId: childUserId,
        message: state.message,
        sticker: state.sticker,
        clientRequestId: context.requestId,
      );
      _completeSend(context, result);
    } catch (error) {
      if (error is AccountDataUnavailableException) return;
      if (context != null && !_isCurrent(context)) {
        return;
      }
      _handleFailure(error, childUserId);
    }
  }

  _SendContext _beginSend(String childUserId) {
    final ownerId = _owner.currentOwnerId;
    final lease = _barrier.capture()..checkOwner(ownerId);
    final payloadKey = _payloadKey(childUserId);
    final requestId = _retryPayload == payloadKey
        ? _retryRequestId!
        : _newRequestId();
    _retryPayload = payloadKey;
    _retryRequestId = requestId;
    emit(
      state.copyWith(
        isSending: true,
        sent: false,
        failed: false,
        quotaReached: false,
      ),
    );
    return _SendContext(++_generation, ownerId, lease, requestId);
  }

  void _completeSend(_SendContext context, KidsEncouragementSendResult result) {
    if (!_isCurrent(context)) return;
    _clearRetry();
    emit(
      state.copyWith(
        isSending: false,
        sent: result is KidsEncouragementSendSuccess,
        failed: false,
      ),
    );
  }

  void _handleFailure(Object error, String childUserId) {
    if (isClosed) return;
    final key = _payloadKey(childUserId);
    _retryPayload = key;
    _retryRequestId ??= _newRequestId();
    emit(
      state.copyWith(
        isSending: false,
        failed: true,
        quotaReached: _isQuotaError(error),
      ),
    );
  }

  void _clearRetry() {
    _retryPayload = null;
    _retryRequestId = null;
  }

  String _payloadKey(String childUserId) =>
      '$childUserId\u0000${state.message.serverKey}\u0000${state.sticker.serverKey}';

  bool _isCurrent(_SendContext context) {
    try {
      context.lease.checkOwner(context.ownerId);
      return context.request == _generation &&
          _owner.currentOwnerId == context.ownerId &&
          !isClosed;
    } on AccountDataUnavailableException {
      return false;
    }
  }

  void _clearForAccountChange() {
    _generation++;
    _clearRetry();
    if (!isClosed) emit(const ParentEncouragementComposerState());
  }

  static bool _defaultQuotaError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('rate_limited') ||
        message.contains('encouragement daily limit reached');
  }

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}

final class _SendContext {
  const _SendContext(this.request, this.ownerId, this.lease, this.requestId);

  final int request;
  final String ownerId;
  final AccountDataLease lease;
  final String requestId;
}
