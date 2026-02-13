import 'package:flutter/material.dart';
import 'package:loannect/api/api.dart';
import 'package:loannect/dat/Bid.dart';
import 'package:loannect/state/app_router.dart';

enum TermsType {
  BORROWER, LENDER
}

class Terms extends StatefulWidget {
  final Bid bid;
  final TermsType termsType;
  // final LoProposal proposal;
  final void Function()? onBidSealInProgress;
  final void Function(Bid)? onBidSealDone;

  const Terms({super.key, required this.termsType, required this.bid,
    this.onBidSealInProgress, this.onBidSealDone});

  @override
  State<Terms> createState() => _TermsState();
}

class _TermsState extends State<Terms> {

  late String terms;

  bool _fetchingTerms = true;
  bool _confirming = false;
  
  Terms get parent => widget;

  @override
  void initState() {
    super.initState();

    getTerms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            // if(_confirming) return;

            Navigator.pop(context);
          },
        ),
        title: const Text("Terms & Conditions"),
        actions: [
          if(_fetchingTerms) const Padding(
            padding: EdgeInsets.only(right: 6),
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2,),
            ),
          )
        ],
      ),
      body: _fetchingTerms
        ? Container()
        : SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(child: Text(terms)),
                ),
                const SizedBox(height: 20,),

                if(_confirming) const LinearProgressIndicator()
                else SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: confirmBid,
                    child: Text(
                      parent.termsType == TermsType.BORROWER
                        ? "Agree & Confirm"
                        : "Agree & Lend"
                    )
                  ),
                )
              ],
            ),
      ),
        ),
    );
  }

  Future<void> getTerms() async {
    final api = Api.getInstance();

    final termsFuture = parent.termsType == TermsType.BORROWER
      ? api.getLoTerms(parent.bid.proposal!.analytics!)
      : api.getLeTerms(parent.bid.proposal!.analytics!);

    termsFuture.then((response) {
      if(response.exists) {
        terms = response.data as String;

        setState(() {
          _fetchingTerms = false;
        });
      } else {
        context.toast(response.errorMsg);

        Navigator.pop(context);
      }
    });
  }

  void confirmBid () {
    if(_confirming) {
      return;
    }

    try {
      setState(() {
        _confirming = true;
        parent.onBidSealInProgress?.call();
      });
    } on Exception {
      //do nothing
    }

    final api = Api.getInstance();
    final confirmationFuture = parent.termsType == TermsType.BORROWER
        ? api.confirmBid(parent.bid)
        : api.initiateTransaction(parent.bid);

    confirmationFuture.then((response) {
      try {
        setState(() {
          _confirming = false;
        });
      } on Exception {
        //do nothing
      } finally {
        if (response.exists) {

          bool confirmed = response.data as bool;

          try {
            if (parent.termsType == TermsType.BORROWER) {
              if(confirmed) {
                parent.bid.seal();
              }
            }
          } on Exception {
            //do nothing
          }
        } else {
          try {
            if (mounted) {
              context.toast(response.errorMsg);
            }
          } on Exception {
            //do nothing
          }
        }

        try {
          if (response.exists) {
            Navigator.pop(context);
          }
        } on Exception {
          //do nothing
        } finally {
          try {
            if (response.exists) {
              print("calling onBidSealDone...");
              parent.onBidSealDone?.call(parent.bid);
            }
          } on Exception {
            //do nothing
          }
        }
      }
    });
  }
}
