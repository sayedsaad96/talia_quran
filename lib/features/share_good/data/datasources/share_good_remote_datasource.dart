import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/invite_types.dart';

class ShareGoodRemoteException implements Exception {
  const ShareGoodRemoteException(this.failure);
  final ShareGoodFailure failure;
}

class ShareGoodRemoteDatasource {
  ShareGoodRemoteDatasource(this.client);
  final SupabaseClient? client;

  Future<Map<String, dynamic>> call(
    String function, [
    Map<String, dynamic>? params,
  ]) async {
    if (client == null) {
      throw const ShareGoodRemoteException(ShareGoodFailure.featureUnavailable);
    }
    try {
      final result = await client!.rpc(function, params: params);
      if (result is! Map) throw const FormatException('Invalid response');
      final data = Map<String, dynamic>.from(result);
      if (data['error'] != null) {
        throw ShareGoodRemoteException(_failure(data['error'].toString()));
      }
      return data;
    } on ShareGoodRemoteException {
      rethrow;
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST202' ||
          e.message.contains('Could not find the function')) {
        throw const ShareGoodRemoteException(
          ShareGoodFailure.featureUnavailable,
        );
      }
      throw ShareGoodRemoteException(_failure(e.message));
    } on SocketException {
      throw const ShareGoodRemoteException(ShareGoodFailure.network);
    } on http.ClientException {
      throw const ShareGoodRemoteException(ShareGoodFailure.network);
    } on TimeoutException {
      throw const ShareGoodRemoteException(ShareGoodFailure.network);
    } on HttpException {
      throw const ShareGoodRemoteException(ShareGoodFailure.network);
    } on FormatException {
      throw const ShareGoodRemoteException(ShareGoodFailure.featureUnavailable);
    }
  }
}

ShareGoodFailure _failure(String code) {
  if (code.contains('share_good_session_required')) {
    return ShareGoodFailure.authRequired;
  }
  if (code.contains('share_good_not_eligible') || code == 'not_eligible') {
    return ShareGoodFailure.notEligible;
  }
  return switch (code) {
    'expired' => ShareGoodFailure.expired,
    'rate_limited' => ShareGoodFailure.rateLimited,
    'invalid_input' ||
    'invalid_invite' ||
    'invalid' => ShareGoodFailure.invalidInvite,
    _ => ShareGoodFailure.featureUnavailable,
  };
}
