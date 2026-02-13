
import 'package:flutter/material.dart';
import 'package:loannect/api/api.dart';
import 'package:loannect/dat/Bid.dart';
import 'package:loannect/dat/Lo.dart';
import 'package:loannect/dat/UserProfile.dart';
import 'package:loannect/state/fin_manager.dart';
import 'package:loannect/state/proposal_manager.dart';
import 'package:loannect/ui/bonnet_checker.dart';

class StateMan extends ChangeNotifier {

  StateMan._();

  static final StateMan _stateMan = StateMan._();

  factory StateMan () => _stateMan;


  int _homeTab = 1;
  int get currentHomeTab => _homeTab;

  int _leLoTab = 0;
  int get leLoTab => _leLoTab;

  // bool _registered = false;
  // bool get isUserSignedUp => _registered;

  bool _isWindowRenderingDelegated = false;
  bool get windowRenderingWasDelegated => _isWindowRenderingDelegated;



  bool? _shouldSendTransaction;
  bool? get shouldSendTransaction => _shouldSendTransaction;
  Bid? _pendingSendTransaction;
  Bid? get pendingSendTransaction => _pendingSendTransaction;


  bool? _isUserExpectingReceipt;
  // bool? get isUserExpectingReceipt => _isUserExpectingReceipt;
  bool? _transactionWasReceived;
  bool? get transactionWasReceived => _transactionWasReceived;
  Bid? _transactionPendingReceiptConfirmation;
  Bid? get transactionPendingReceiptConfirmation => _transactionPendingReceiptConfirmation;


  bool? _isUserExpectingInstalment;
  // bool? _instalmentWasReceived;
  List<Lo>? _receivedInstalments;
  bool get hasInstalmentsToConfirm => _receivedInstalments == null
      ? false
      : (_receivedInstalments!.isNotEmpty);
  Lo? get nextInstalmentToConfirm => _receivedInstalments == null ? null : _receivedInstalments!.first;

  void notifyLendOutInstalmentsConfirmed(Lo confirmedLendOut) {
    print("Confirmed all instalments for lend out: ${confirmedLendOut.id}");
    print("Number of lend outs in the cache: ${_receivedInstalments?.length}");

    if(_receivedInstalments != null) {
      _receivedInstalments!.removeWhere((lendOut) => lendOut.id == confirmedLendOut.id);

      print("Number of lend outs left in cache: ${_receivedInstalments?.length}");

      // check if all all instalments have been confirmed. if not, continue
      // confirming
      if(_receivedInstalments!.isEmpty) {
        print("Confirmed ALL instalments of ALL lend outs.");
        // phew! all instalments in all lend outs have been confirmed
        _receivedInstalments = null;

        // don't set _isUserExpectingInstalment to false because the lender can
        // still receive instalments at any time. this is different from the case
        // of _isUserExpectingReceipt because a borrower can only expect one
        // transaction at a time. once a transaction has been received, no other
        // one can be received or expected to be received until the user makes
        // another loan application and confirms a bid, at which point
        // _isUserExpectingReceipt will be set to true and set to false once again
        // after they have confirmed receipt of loan money.

        FinManager().clearData();
        toggleHomeTab(2);
      }
    }

    // this will invoke confirmation of another lend out's instalments if there
    // still some unconfirmed left
    notifyListeners();
  }


  void toggleHomeTab(int tab, {int? leLoTab}) {
    _homeTab = tab;
    _isWindowRenderingDelegated = false;

    if(leLoTab != null) {
      _leLoTab = leLoTab;
    }

    notifyListeners();
  }

  void toggleLeLoTab (int tab) {
    _leLoTab = tab;
    notifyListeners();
  }

  void delegateWindowRendering() {
    if(!_isWindowRenderingDelegated) {
      _isWindowRenderingDelegated = true;
      notifyListeners();
    }
  }

  void revokeDelegatedWindowRendering() {
    if(_isWindowRenderingDelegated) {
      print("revoked delegated window rendering");
      _isWindowRenderingDelegated = false;
      notifyListeners();
    }
  }


  void notifyShouldSendTransaction(Bid pendingSendTransaction) {
    print("at StateMan: user should send a transaction");
    _shouldSendTransaction = true;
    _pendingSendTransaction = pendingSendTransaction;

    notifyListeners();
  }

  void notifyTransactionSentOrCancelled() {
    // user is confirming that they have sent a transaction that they were
    // supposed to send or they cancelled it
    _shouldSendTransaction = false;
    _pendingSendTransaction = null;

    // clear items and bids so that user has to reload them
    final proposalManager = ProposalManager();
    proposalManager.clearItems();
    proposalManager.clearBids();

    toggleHomeTab(0);
  }

  void notifyTransactionReceiptAcknowledged() {
    _isUserExpectingReceipt = false;
    _transactionWasReceived = false;
    _transactionPendingReceiptConfirmation = null;

    toggleHomeTab(2);
  }

  void notifyExpectingTransaction() {
    _isUserExpectingReceipt = true;

    notifyListeners();
  }

  Future<bool> getUserUpdates() async {
    if(appUser == null) return true;

    final api = Api.getInstance();


    if(_shouldSendTransaction == null) {
      print("fetching pending send transaction...");

      final pendingSend = await api.getPendingTransaction(appUser!, type: 'send');

      if(pendingSend.exists) {
        if(pendingSend.data is Bid) {
          _pendingSendTransaction = pendingSend.data as Bid;
          _shouldSendTransaction = true;
        } else {
          _shouldSendTransaction = false;
        }

        print("got user update (shouldSendTransaction: $_shouldSendTransaction)");

      } else {
        // if there was a network error, don't execute other futures. just
        // short-circuit to save time.
        return false;
      }
    }

    if((_isUserExpectingReceipt ?? true)
        // || (_transactionWasReceived == null)
    ) {
      print("fetching pending receipt transaction..."
          "(_isUserExpectingReceipt: $_isUserExpectingReceipt, _transactionWasReceived: $_transactionWasReceived)");

      //always recheck whether a transaction was received if _isUserExpectingReceipt
      //is either null or true.

      //the second condition (_transactionWasReceived == null) is just for checking
      //whether the function getUserPendingReceiptTransaction was successfully
      //executed and pendingReceipt.exists returned true. basically there's two
      //functions at play here in this specific situation and we want to reload
      //if either _isUserExpectingReceipt or _transactionWasReceived is null.
      //on second thought, the second boolean check is redundant and including it
      //causes redundant checks.

      //also reload if _isUserExpectingReceipt is true because a transaction can
      //come in at any time.

      final userExpectingReceipt = await api.userIsExpectingReceipt(appUser!);
      if (userExpectingReceipt.exists) {
        // bool isUserExpectingReceipt = userExpectingReceipt.data as bool;

        //even if _isUserExpectingReceipt is true, update its value every single
        //time on reload. _isUserExpectingReceipt is basically a bool of whether
        //a user has any bids with status as 1 (as a borrower). if right now _isUserExpectingReceipt is true
        //on my frontend as a borrower, five minutes from now it could be false if
        //the bid that i had confirmed was set to status -1 because a lender cancelled
        //the lend request. in this case, if i check the server again, _isUserExpectingReceipt
        //will be returned as false. so basically i should check the server for the latest
        //_isUserExpectingReceipt status. if a lender cancelled on me, i can confirm another
        //bid again and now _isUserExpectingReceipt becomes true because I'm manipulating
        //its value on my frontend. so if it was false earlier, no problem, i will be
        //manipulating its value on my frontend when i confirm a bid; if it's true,
        //check its latest value from server. also if user deletes loan application,
        //or confirms receipt of money, todo set _isUserExpectingReceipt to false.
        //at the point in time when the user confirms a bid, set _isUserExpectingReceipt
        //to true.

        //NOTE: if a lender cancels user's lend request that the user had confirmed
        //(meaning the bid status changed from 1 to 0), there's no way the bid status
        //of any bid will be changed externally, the borrower has the full control over this.
        //so, if the user confirms a bid anew, we'll be able to change _isUserExpectingReceipt
        //to true without making any trips to server and without worrying about
        //consistency of data across client and server.

        _isUserExpectingReceipt = userExpectingReceipt.data as bool;

        print("got user update (_isUserExpectingReceipt: $_isUserExpectingReceipt)");

        //only fetch pending receipt if the user is expecting a transaction.
        //(value was checked in server; if it was previously true a minute ago
        // it could be false right now)
        if(_isUserExpectingReceipt!) {
          bool fetchedPendingReceipt = await getUserPendingReceiptTransaction();

          if (!fetchedPendingReceipt) {
            return false;
          }
        }
      } else {
        return false;
      }
    }

    if(_isUserExpectingInstalment ?? true) {
      //todo set _isUserExpectingInstalment to true once a user has lent out money

      //recheck if user is still owed
      final userHasLendOuts = await api.checkIfUserIsOwed(appUser!);

      if(userHasLendOuts.exists) {
        _isUserExpectingInstalment = userHasLendOuts.data as bool;

        if(_isUserExpectingInstalment!) {

          final currentLendOuts = await Api.getInstance().getUserCurrentLendOuts(appUser!);

          if(currentLendOuts.exists) {
            final userCurrentLendOuts = currentLendOuts.data as List<Lo>;

            //filter only for lend outs that have unconfirmed instalments that
            //then the user has to confirm receipt. we're not concerned about
            //lend outs with zero unconfirmed instalments.
            List<Lo> lendOutsWithUnconfirmedInstalments;
            lendOutsWithUnconfirmedInstalments = userCurrentLendOuts.where(
              (lendOut) => lendOut.numUnconfirmedInstalments > 0
            ).toList();

            if(lendOutsWithUnconfirmedInstalments.isNotEmpty) {
              // only if user has lend outs with payment instalments that have not been
              // confirmed, update the value of _receivedInstalments.

              for(Lo lendOut in lendOutsWithUnconfirmedInstalments) {
                // for each lend out, only include the unconfirmed instalments
                // since they are the ones that we're concerned about. the already confirmed ones are....
                // ...already confirmed. now let's only focus on the ones that are
                // not.
                // to recap, the filtering process is two fold. first, filter out to remain
                // with lend outs with unconfirmed instalments. next, filter out confirmed
                // instalments in each of the lend outs to only remain with unconfirmed
                // instalments for every lend out.
                lendOut.instalments.removeWhere((instalment) => instalment.confirmed);
              }

              _receivedInstalments?.clear();
              _receivedInstalments = [];
              _receivedInstalments?.addAll(lendOutsWithUnconfirmedInstalments);
            }
          }
        }
      } else {
        return false;
      }
    }

    //execute other futures

    notifyListeners();

    print("finished fetching all user updates at getUserUpdates()");
    return true;
  }

  Future<bool> getUserPendingReceiptTransaction() async {
    //this method only gets run if a user is expecting a transaction from a lender

    final txPendingReceiptConf = await Api.getInstance().getPendingTransaction(appUser!, type: 'receipt');

    if(txPendingReceiptConf.exists) {
      if(txPendingReceiptConf.data is Bid) {
        _transactionPendingReceiptConfirmation = txPendingReceiptConf.data as Bid;
        _transactionWasReceived = true;

        print("got user update: user has received a transaction..."
            "(_isUserExpectingReceipt: $_isUserExpectingReceipt, _transactionWasReceived: $_transactionWasReceived)");
      } else {
        print("got user update: user hasn't received any transaction but is expecting one: (_isUserExpectingReceipt: $_isUserExpectingReceipt, "
            "_transactionWasReceived: $_transactionWasReceived)");
        _transactionWasReceived = false;
      }

      return true;
    }

    return false;
  }

  bool _isCheckingTheBonnet = false;
  bool get checkingTheBonnet => _isCheckingTheBonnet;

  void notifyCheckingBonnet () {
    _isCheckingTheBonnet = true;
  }
  void notifyFinishedCheckingBonnet () {
    _isCheckingTheBonnet = false;
  }

  void checkTheBonnet(BuildContext context) {
    if(_isCheckingTheBonnet) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: 'bonnet_checker'),
        builder: (context) => const BonnetChecker()
      )
    );
  }

  UserProfile? get appUser => UserProfile.fromCache();
}
//todo transaction notifications also trigger getUserUpdates