
import 'package:flutter/material.dart';
import 'package:loannect/api/api.dart';
import 'package:loannect/dat/Lo.dart';
import 'package:loannect/dat/UserProfile.dart';

class FinManager extends ChangeNotifier {

  FinManager._();

  static final FinManager _manager = FinManager._();

  factory FinManager() => _manager;


  bool discovering = false;
  bool get dataIsNull => userCurrentLoans == null || userCurrentLendOuts == null;
  bool get hasNeitherLoansNorLendOuts =>
      (userCurrentLoans?.isEmpty ?? true)
      && (userCurrentLendOuts?.isEmpty ?? true);

  List<Lo>? userCurrentLoans;
  List<Lo>? userCurrentLendOuts;


  Future<bool> fetchFinances ({bool onlyIfNotLoaded = false}) async {
    if(discovering) return true;
    if(onlyIfNotLoaded) {
      if(!dataIsNull) {
        return true;
      }
    }

    print("fetching finances at FinManager...");

    discovering = true;
    notifyListeners();

    bool fetchedLoan = false, fetchedLendOuts = false;

    fetchedLoan = await _fetchCurrentLoan();
    if(fetchedLoan) {
      fetchedLendOuts = await _fetchCurrentLendOuts();
    }

    discovering = false;

    notifyListeners();

    return fetchedLoan && fetchedLendOuts;
  }


  Future<bool> _fetchCurrentLoan () async {

    if(appUser == null) {
      userCurrentLoans = [];
      return true;
    }

    final currentLoan = await Api.getInstance().getUserCurrentLoan(appUser!);

    if(currentLoan.exists) {
      if(currentLoan.data is Lo) {
        userCurrentLoans = [currentLoan.data as Lo];
      } else {
        userCurrentLoans = [];
      }
    }

    // notifyListeners();

    return currentLoan.exists;
  }

  Future<bool> _fetchCurrentLendOuts () async {

    if(appUser == null) {
      userCurrentLendOuts = [];
      return true;
    }


    final currentLendOuts = await Api.getInstance().getUserCurrentLendOuts(appUser!);

    if(currentLendOuts.exists) {
      userCurrentLendOuts = currentLendOuts.data as List<Lo>;
    }

    // notifyListeners();

    return currentLendOuts.exists;
  }

  void clearData () {
    userCurrentLoans = null;
    userCurrentLendOuts = null;
    notifyListeners();
  }

  bool get hasLoans => userCurrentLoans!.isNotEmpty;

  bool get hasLendOuts => userCurrentLendOuts!.isNotEmpty;

  UserProfile? get appUser => UserProfile.fromCache();
}