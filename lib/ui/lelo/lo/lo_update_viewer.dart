import 'package:flutter/material.dart';
import 'package:loannect/api/api.dart';
import 'package:loannect/dat/Bid.dart';
import 'package:loannect/dat/LoAppUpdate.dart';
import 'package:loannect/dat/LoPreRequisites.dart';
import 'package:loannect/dat/LoProposal.dart';
import 'package:loannect/dat/UserProfile.dart';
import 'package:loannect/state/app_router.dart';
import 'package:loannect/state/state_man.dart';
import 'package:loannect/ui/lelo/lo/preamble.dart';
import 'package:loannect/ui/lelo/terms.dart';
import 'package:provider/provider.dart';
import 'package:loannect/app_theme.dart' as app_theme;


class LoUpdateViewer extends StatefulWidget {
  const LoUpdateViewer({super.key});

  @override
  State<StatefulWidget> createState() => _LoUpdateViewerState();
}

class _LoUpdateViewerState extends State<LoUpdateViewer> {

  bool _fetching = false;
  bool _errorFetching = false;

  bool _bidConfirmationInProgress = false;

  bool _hasUpdates = false;
  LoAppUpdate? _loUpdate;

  LoProposal? get _proposal => _loUpdate?.application;

  // bool

  @override
  void initState() {
    super.initState();

    loadUpdates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Application Updates"),
        actions: [
          IconButton(
            onPressed: () {

            },
            icon: const Icon(Icons.more_vert)
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadUpdates,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: (_fetching || _errorFetching || !_hasUpdates)
            ? discoveringView
            : updatesView
        ),
      )
    );
  }

  Future<void> loadUpdates() async {
    if(appUser == null || _fetching) return;

    setState(() {
      _fetching = true;
      _errorFetching = false;
      _hasUpdates = false;
      _loUpdate = null;
    });

    Api.getInstance()
      .getLendRequestUpdates(appUser!)
      .then((response) async {
        _fetching = false;


        if(response.exists) {
          final update = response.data as LoAppUpdate;

          if(update.hasUpdates) {
            final loProposal = update.application;
            print("Got updates for loan application: ${loProposal.toString()}");

            _fetching = true;
            final analytics = await loProposal!.loadAnalytics();
            _fetching = false;

            if(analytics.exists) {

              _hasUpdates = update.hasUpdates;

              if(_hasUpdates) {
                _loUpdate = update;

                for(Bid bid in _loUpdate!.bids!) {
                  bid.proposal = loProposal;
                }
              }
            } else {
              _errorFetching = true;
            }
          }
        } else {
          _errorFetching = true;
          // context.toast(response.errorMsg);
        }

        setState(() {});
    });
  }

  Widget get discoveringView {
    return ListView(
      // child: Column(
      //   mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 100,),
          Icon(
            _fetching
              ? Icons.content_paste_search_outlined
              : (_errorFetching ? Icons.cloud_off : Icons.pending_actions_outlined),
            size: 54,
            color: Colors.grey,
          ),
          const SizedBox(height: 40,),
          Text(
            _fetching
              ? "Loading your pending loan applications..."
              : (
                _errorFetching
                ? "Failed to load.\n\nPlease check your internet connection and swipe down to refresh..."
                : "You currently don't have any pending loan applications.\n\nDo you want to apply for a loan?"
              ),
            style: TextStyle(color: Colors.grey.shade700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40,),

          if(_fetching)
            const LinearProgressIndicator(),

          if(!_fetching && !_errorFetching)
            FilledButton(
              onPressed: () {
                Provider.of<StateMan>(context, listen: false)
                  .toggleHomeTab(1, leLoTab: 0);
              },
              child: const Text("Apply for a Loan"),
            )
        ],
      // ),
    );
  }

  Widget get updatesView {
    return ListView(
      children: [
        BorrowerBubble(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const RotatedBox(
                quarterTurns: 1,
                child: Icon(Icons.payments_outlined, color: Colors.white,)
              ),
              Text("KSH ${_proposal!.amountStr}", style: app_theme.darkTextTheme.headlineMedium,),
              Text("Loan term: ${_proposal!.termStr}", style: app_theme.darkTextTheme.bodyMedium,),
            ],
          )
        ),
        BorrowerBubble(
          variation: 2,
          child: Text(
            "Loan for: ${_proposal!.purpose}",
            style: app_theme.darkTextTheme.bodyMedium,
            // textAlign: TextAlign.end,
          )
        ),
        BorrowerBubble(
          variation: 2,
          child: Text(
            "Payment method for receiving loan:\n"
                "${_proposal!.destination['method']}\n"
                "(${_proposal!.destination['detail']})",
            style: app_theme.darkTextTheme.bodyMedium,
            textAlign: TextAlign.end,
            // textAlign: TextAlign.end,
          )
        ),
        BorrowerBubble(
          variation: 3,
          pad: false,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    print("Proposal analytics at LoUpdateViewer: ${_proposal!.analytics}");

                    final preRequisites = LoPreRequisites(
                      true, true, null,
                      _proposal!.analytics!['base_rate'] as double,
                      _proposal!.tags,
                      {
                        // "${_proposal!.term}": double.parse(_proposal!.analytics!['weekly_instalment'].toString())
                        "${_proposal!.term}": (_proposal!.analytics!['weekly_instalment'] as num).toDouble()
                      },
                      _proposal
                    );

                    return Preamble(preRequisites, amt: _proposal!.amount);
                  }
                )
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                "Tap for more...",
                style: app_theme.darkTextTheme.bodySmall?.copyWith(
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white
                ),
              ),
            ),
          )
        ),
        Text(
          "Loan requested ${_proposal!.timeAgoProposed}",
          style: app_theme.lightTextTheme.bodySmall?.copyWith(color: Colors.grey.shade700, fontStyle: FontStyle.italic),
          textAlign: TextAlign.end,
        ),
        if(_loUpdate!.bids!.isEmpty) bidsPendingBubble
        else ...[
          const SizedBox(height: 10,),
          TextDivider("Loan Request Accepted"),
          const SizedBox(height: 10,),
          LenderBubble(
            child: Text(
              _loUpdate!.bids!.length > 1
                ? "Some lenders accepted your loan request. Please select one lender from "
                  "the list below and click 'Confirm' to complete the loan transaction..."
                : "A lender accepted your loan request. Click 'Confirm' below to complete the loan transaction..."
            )
          ),
          TextDivider("Confirm to Finish"),
          const SizedBox(height: 10,),

          // If any of the bids was already confirmed earlier, only show that one
          // else, show all the bids so that the user can pick one to confirm.
          // We're using a spread operator together with an anonymous function
          // that returns the bids.
          ...(
            () {
              Bid? anySealedBid = getAnySealedBid();

              List<Bid> bids = anySealedBid != null ? [anySealedBid] : _loUpdate!.bids!;

              return [
                for(Bid bid in bids)
                  LenderBubble(
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Accepted your request"),
                        Text(
                          bid.bidTimeAgo!,
                          style: app_theme.lightTextTheme.bodySmall?.copyWith(color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.perm_identity_outlined),
                            Text("Name: ", style: app_theme.lightTextTheme.bodyLarge,),
                            Text(bid.bidderInfo!['user_name'])
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.emoji_flags_outlined),
                            Text("Country: ", style: app_theme.lightTextTheme.bodyLarge,),
                            Text(bid.bidderInfo!['country'])
                          ],
                        ),
                        const SizedBox(height: 20,),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            label: Text(bid.sealed
                              ? "Confirmed!"
                              : (bid.cancelled ? "Cancelled by Lender" : "Confirm")
                            ),
                            icon: Icon(bid.cancelled ? Icons.not_interested_outlined : Icons.done_all_outlined),
                            style: ButtonStyle(
                                backgroundColor: MaterialStateColor.resolveWith((states) => Colors.black.withOpacity(0.1))
                            ),
                            onPressed: (bid.sealed || bid.cancelled) ? null : () {

                              if(_bidConfirmationInProgress) {
                                context.toast("Please wait...");
                              } else {
                                //todo accept terms and confirm bid
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    fullscreenDialog: true,
                                    builder: (context) {
                                      return Terms(
                                        termsType: TermsType.BORROWER,
                                        bid: bid,
                                        // proposal: _proposal!,
                                        onBidSealInProgress: () {
                                          _bidConfirmationInProgress = true;
                                        },
                                        onBidSealDone: (Bid bid) {
                                          _bidConfirmationInProgress = false;

                                          setState(() {});

                                          if(bid.sealed) {
                                            //only if bid was sealed successfully

                                            Provider.of<StateMan>(context, listen: false)
                                              .notifyExpectingTransaction();

                                            showDialog(
                                              context: context,
                                              builder: (context) {
                                                return AlertDialog(
                                                  title: const Text("Confirmed!"),
                                                  content: Text("The lender (${bid.bidderInfo!['user_name']}) was notified to transact to you the loan money of KSH ${_proposal!.amountStr}. "
                                                      "They will send you the money through the payment method that you provided while applying for the loan. "
                                                      "You will get a notification immediately they send you the money."),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                      },
                                                      child: const Text("OK, GOT IT")
                                                    )
                                                  ],
                                                );
                                              }
                                            );
                                          }
                                        },
                                      );
                                    })
                                );
                              }
                            },
                          ),
                        )
                      ],
                    )
                  ),

                if(anySealedBid != null)
                  BorrowerBubble(
                    child: Text("Confirmed terms and conditions", style: app_theme.darkTextTheme.bodyMedium,)
                  ),

                if (anySealedBid != null)
                  LenderBubble(
                    variation: 3,
                    child: Text("The lender (${anySealedBid.bidderInfo!['user_name']}) was notified to transact to you the loan money of KSH ${_proposal!.amountStr}. "
                      "They will send you the money through the payment method that you provided while applying for the loan. "
                      "You will get a notification immediately they send you the money.")
                  )
              ];
            }()
          ) // list of sealed bids returned from the anonymous function through spread operator
        ]
        // else todo list bids and tell user to pick one to confirm
      ],
    );
  }

  Bid? getAnySealedBid () {
    // if any of the bids in the accepted requests has been confirmed, return
    // that bid, else return null
    for(Bid bid in _loUpdate!.bids!) {
      if(bid.sealed) {
        return bid;
      }
    }

    return null;
  }

  Widget get bidsPendingBubble {
    return Column(
      children: [
        LenderBubble(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Icon(Icons.schedule_outlined, size: 18, color: Colors.grey,),
                const SizedBox(width: 6,),
                Expanded(
                  child: Text(
                    "Waiting for a lender to accept your loan request...",
                    maxLines: 2,
                    softWrap: true,
                    style: app_theme.lightTextTheme.bodyMedium,
                  ),
                ),
              ],
            )
        ),
        LenderBubble(
          variation: 3,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(Icons.notifications_active_outlined, size: 18, color: Colors.grey,),
              const SizedBox(width: 6,),
              Expanded(
                child: Text(
                  "You will receive updates here as lenders on Loannect accept your loan request",
                  maxLines: 2,
                  style: app_theme.lightTextTheme.bodyMedium,
                ),
              ),
            ],
          )
        ),
      ],
    );
  }

  Widget BorrowerBubble({required Widget child, int variation = 1, bool pad = true}) {
    /*
    variations
    1 - all rounded except bottom right
    2 - all only top left and bottom left rounded
    3 - all rounded except top right
    * */

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Ink(
              padding: pad ? const EdgeInsets.all(12.0) : null,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: variation == 1 ? const Radius.circular(20) : Radius.zero,
                  bottomLeft: const Radius.circular(20),
                  bottomRight: variation == 3 ? const Radius.circular(20) : Radius.zero
                )
              ),
              child: child
            ),
          ),
        ],
      ),
    );
  }

  Widget LenderBubble({required Widget child, int variation = 1, bool pad = true}) {
    /*
    variations
    1 - all rounded except bottom left
    2 - all only top right and bottom right rounded
    3 - all rounded except top left
    * */

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Ink(
              padding: pad ? const EdgeInsets.all(12) : null,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: variation == 1 ? const Radius.circular(20) : Radius.zero,
                  topRight: const Radius.circular(20),
                  bottomLeft: variation == 3 ? const Radius.circular(20) : Radius.zero,
                  bottomRight: const Radius.circular(20)
                )
              ),
              child: child
            ),
          ),
        ],
      ),
    );
  }

  Widget TextDivider(String text) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        const SizedBox(width: 6,),
        Text(text, style: app_theme.lightTextTheme.bodySmall?.copyWith(color: Colors.grey.shade700),),
        const SizedBox(width: 6,),
        const Expanded(child: Divider()),
      ],
    );
  }

  UserProfile? get appUser => UserProfile.fromCache();
}
