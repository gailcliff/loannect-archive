library loannect_api;

import 'dart:io';

import 'package:http/http.dart' as http;
import 'dart:convert' as encoding;

import 'package:http/retry.dart';
import 'package:loannect/dat/Bid.dart';
import 'package:loannect/dat/Instalment.dart';
import 'package:loannect/dat/Lo.dart';
import 'package:loannect/dat/LoAppUpdate.dart';
import 'package:loannect/dat/LoPreRequisites.dart';
import 'package:loannect/dat/LoProposal.dart';
import 'package:loannect/dat/UserInsights.dart';
import 'package:loannect/dat/UserProfile.dart';

part 'api_impl.dart';

class ApiResponse {

  Object? data;
  String? _error;
  int? statusCode;

  ApiResponse([this.data, this._error, this.statusCode]);

  bool get exists => data != null;

  String get errorMsg => _error ?? "Oops! An error occurred...please try again";
}

abstract class Api {

  // static const URL = '192.168.8.125';
  static const URL = '10.203.215.52';
  static const PORT = 8000;

  static const GET = 'GET';
  static const POST = 'POST';
  static const PUT = 'PUT';

  const Api._();

  static final Api _api = _ApiImpl();

  factory Api.getInstance() => _api;

  Future<ApiResponse> registerUser(UserProfile user);

  Future<ApiResponse> getLoPreRequisites(UserProfile user, int amount, {required bool getTags});

  Future<ApiResponse> proposeLo(int userId, LoProposal proposal);

  Future<ApiResponse> discoverProposals({required List<int> history});

  Future<ApiResponse> stampUser(UserProfile user, UserInsights userInsights);

  Future<ApiResponse> getBorrowerAnalytics(LoProposal proposal);

  Future<ApiResponse> acceptLendRequest(Bid bid);

  Future<ApiResponse> getUnsealedBids(UserProfile bidder);

  Future<ApiResponse> getLendRequestUpdates(UserProfile borrower);

  Future<ApiResponse> confirmBid(Bid bid);

  Future<ApiResponse> getLoTerms(Map repaymentInfo);

  Future<ApiResponse> getLeTerms(Map repaymentInfo);

  Future<ApiResponse> initiateTransaction(Bid bid);

  Future<ApiResponse> getPendingTransaction(UserProfile user, {required String type});

  Future<ApiResponse> userIsExpectingReceipt(UserProfile user);

  Future<ApiResponse> confirmTransactionSent(Bid bid, Map source);

  Future<ApiResponse> confirmTransactionReceipt(Bid bid);

  Future<ApiResponse> getUserCurrentLoan(UserProfile user);

  Future<ApiResponse> getUserCurrentLendOuts(UserProfile user);

  Future<ApiResponse> payInstalment(Lo lo, int amount, Map source);

  Future<ApiResponse> checkIfUserIsOwed(UserProfile user);

  Future<ApiResponse> confirmInstalmentReceipt(Instalment instalment);

  Future<void> destroy();
}