
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:loannect/api/api.dart';
import 'package:loannect/dat/Bid.dart';
import 'package:loannect/dat/LoProposal.dart';
import 'package:loannect/app_theme.dart' as app_theme;
import 'package:loannect/dat/UserProfile.dart';
import 'package:loannect/dat/data_converter.dart';
import 'package:loannect/state/app_router.dart';
import 'package:loannect/state/proposal_manager.dart';
import 'package:loannect/state/state_man.dart';
import 'package:loannect/ui/accounts/account_manager.dart';
import 'package:loannect/ui/lelo/terms.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class SimpleFeedItemDetail extends StatefulWidget {

  final LoProposal loProposal;
  final Bid? bid;

  SimpleFeedItemDetail(Object detail, {super.key})
      : loProposal = detail is Bid ? detail.proposal! : detail as LoProposal,
      bid = detail is Bid ? detail : null;


  bool get proposalAccepted => bid != null;


  @override
  State<SimpleFeedItemDetail> createState() => _SimpleFeedItemDetailState();
}
class _SimpleFeedItemDetailState extends State<SimpleFeedItemDetail>{
  SimpleFeedItemDetail get parent => widget;

  late LoProposal _loProposal;
  //todo add bid if request was accepted

  late String _borrowerName;
  late String _borrowerCountry;
  late int _borrowerForDays;
  late DateTime _borrowerSince;
  late Map _borrowerOccupation;
  late Map _analytics;

  late bool _bookmarked;


  late ScrollController _scrollController;

  ProposalManager get _proposalManager => Provider.of<ProposalManager>(context, listen: false);

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();

    _loProposal = parent.loProposal;
    Map userProfile = _loProposal.userProfile!;

    _borrowerName = userProfile['user_name'];
    _borrowerCountry = userProfile['country'];
    _borrowerForDays = userProfile['since'];
    _borrowerSince = DateTime.fromMillisecondsSinceEpoch(_borrowerForDays);

    Map userInfo = userProfile['info'];
    _borrowerOccupation = userInfo['occupation'];

    _analytics = _loProposal.analytics!;

    _bookmarked = _loProposal.bookmarked;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _rated = false;
  double _rating = 0;


  // fetching/finished fetching flags
  bool _makingOrBreakingBid = false;


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Lend Request"),
        backgroundColor: _loProposal.decorColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          physics: const ClampingScrollPhysics(),
          controller: _scrollController,
          children: [
            Container(
              color: _loProposal.decorColor,
              padding: const EdgeInsets.all(36),
              alignment: Alignment.center,
              child: SizedBox(
                height: 350,
                width: double.infinity,
                child: Card(
                  color: _loProposal.decorColor,
                  elevation: 36,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // const Icon(Icons.payments_outlined, size: 54, color: Colors.white,),
                        const RotatedBox(
                          quarterTurns: 1,
                          child: Icon(Icons.payments_outlined, size: 54, color: Colors.white,),
                        ),
                        const SizedBox(height: 10,),
                        RichText(
                          text: TextSpan(
                            text: "KSH  ",
                            style: app_theme.darkTextTheme.headlineLarge,
                            children: [
                              TextSpan(
                                text: _loProposal.amountStr,
                                style: app_theme.darkTextTheme.displayLarge,
                              )
                            ]
                          )
                        ),
                        const SizedBox(height: 10,),
                        Text("Loan requested by:", textAlign: TextAlign.center, style: app_theme.darkTextTheme.bodyLarge,),
                        Text(
                          _borrowerName,
                          style: app_theme.darkTextTheme.headlineMedium,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _loProposal.timeAgoProposed!,
                          style: app_theme.darkTextTheme.bodySmall,
                        ),
                        const SizedBox(height: 20,),

                        if (parent.proposalAccepted) (
                          Column(
                           children: [
                             Text(
                               "You accepted request ${parent.bid!.bidTimeAgo!}",
                               style: app_theme.darkTextTheme.bodyMedium,
                             ),
                             const SizedBox(height: 6,),
                             Row(
                               mainAxisAlignment: MainAxisAlignment.center,
                               children: [
                                 Icon(
                                   parent.bid!.unsealed ? Icons.schedule_outlined : Icons.done_all_outlined,
                                   size: 18,
                                   color: Colors.white,
                                 ),
                                 Text(
                                   parent.bid!.unsealed
                                     ? " Waiting for borrower to confirm..."
                                     : " Borrower has already confirmed!",
                                   style: app_theme.darkTextTheme.bodyMedium,
                                 )
                               ],
                             ),
                             if(parent.bid!.sealed)
                               const SizedBox(height: 10,),
                             if(parent.bid!.sealed)
                               FilledButton(
                                 onPressed: () {
                                   Navigator.push(
                                     context,
                                     MaterialPageRoute(
                                       fullscreenDialog: true,
                                       builder: (context) {
                                         return Terms(
                                           termsType: TermsType.LENDER,
                                           bid: parent.bid!,
                                           onBidSealDone: (_) {
                                             Provider.of<StateMan>(context, listen: false).notifyShouldSendTransaction(parent.bid!);
                                           },
                                         );
                                       }
                                     )
                                   );
                                 },
                                 child: const Text("Lend Money Now")
                               )
                           ],
                          )
                        )
                        else if(_makingOrBreakingBid) const LinearProgressIndicator()
                        else FilledButton.icon(
                          onPressed: fullScroll,
                          label: const Text("Accept Lend Request"),
                          icon: const Icon(Icons.done_all_outlined),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10,),
            Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if(!parent.proposalAccepted)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        label: const Text("Save"),
                        style: ButtonStyle(
                            backgroundColor: MaterialStateColor.resolveWith((states) => _loProposal.decorColor.withOpacity(0.1))
                        ),
                        onPressed: () {
                          _bookmarked
                              ? _proposalManager.onProposalUnBookmarked(_loProposal)
                              : _proposalManager.onProposalBookmarked(_loProposal);

                          setState(() {
                            _bookmarked = !_bookmarked;
                          });
                        },
                        icon: Icon(_bookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: _loProposal.decorColor,),
                      ),
                    ),
                  Text(
                    "Borrower Info",
                    style: theme.textTheme.displayMedium,
                  ),
                  const SizedBox(height: 10,),
                  const Divider(),
                  const SizedBox(height: 6,),
                  Row(
                    children: [
                      Icon(Icons.perm_identity_outlined, color: _loProposal.decorColor,),
                      Text("Name: ", style: theme.textTheme.bodyLarge,),
                      Text(_borrowerName)
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.emoji_flags_outlined, color: _loProposal.decorColor,),
                      Text("Country: ", style: theme.textTheme.bodyLarge,),
                      Text(_borrowerCountry)
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.construction_outlined, color: _loProposal.decorColor,),
                      Text("Occupation: ", style: theme.textTheme.bodyLarge,),
                      // Text(_borrowerInfo['occupation']['job']),
                      Text(
                        maxLines: 2,
                        () {
                          String jobType = _borrowerOccupation['job_type'];

                          if (jobType == 'Unemployed' || jobType == 'Retired') {
                            return jobType;
                          } else {
                            return "${_borrowerOccupation['job']}";
                          }
                        }()
                      ),
                    ],
                  ),
                  if (_borrowerOccupation['job_type'] != 'Unemployed' && _borrowerOccupation['job_type'] != 'Retired')
                    Text(
                      "        Job status: ${_borrowerOccupation['job_type']}  |  Job Industry: ${_borrowerOccupation['industry']}",
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  const SizedBox(height: 6,),
                  Align(
                    alignment: Alignment.centerRight,
                    child: RichText(
                        text: TextSpan(
                            text: "Joined Loannect on ${DateFormat.yMMMMd().format(_borrowerSince)} ",
                            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700, fontSize: 12),
                            children: [
                              TextSpan(
                                  text: "(${timeago.format(_borrowerSince)})",
                                  style: const TextStyle(fontStyle: FontStyle.italic)
                              )
                            ]
                        )
                    ),
                  ),
                  const SizedBox(height: 6,),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    isThreeLine: true,
                    title: Text("Past Debts", style: theme.textTheme.bodyLarge,),
                    subtitle: const Text("Loan of KSH 4000, and 10+ others\nCurrent debt: 0"),
                    trailing: const Icon(Icons.navigate_next),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text("Lend History", style: theme.textTheme.bodyLarge,),
                    subtitle: const Text("Has lent KSH 200, and 4 others"),
                    trailing: const Icon(Icons.navigate_next),
                  ),
                  // const Divider(),

                  const SizedBox(height: 20,),
                  Text(
                    "Loan Info",
                    style: theme.textTheme.displayMedium,
                  ),

                  const SizedBox(height: 6,),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text("Loan Term (duration of full repayment)", style: theme.textTheme.bodyLarge,),
                    subtitle: RichText(
                      text: TextSpan(
                        text: "${_loProposal.term.toString()} ${_loProposal.term == 1 ? 'month' : 'months'}\n",
                        style: theme.textTheme.bodyMedium,
                        children: [
                          TextSpan(
                            text: "Loan to be repaid in instalments every 1 week (7 days)",
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700)
                          )
                        ]
                      ),
                    ),
                    isThreeLine: true
                  ),

                  Container(
                    padding: const EdgeInsets.all(10),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _loProposal.decorColor
                      )
                    ),
                    child: Column(
                      children: [
                        Text(
                          "My Potential Profit",
                          style: theme.textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 10,),
                        const Text("If I lend"),
                        Text(
                          "KSH ${_loProposal.amountStr}",
                          style: theme.textTheme.bodyLarge,
                        ),
                        const Text("and the borrower repays in full, I will earn:"),
                        const SizedBox(height: 10,),
                        Text(
                          "Interest (Profit): KSH ${DataConverter.moneyToStr(_analytics['interest'])}",
                          style: theme.textTheme.bodyLarge,
                        ),
                        Text(
                          "Interest Rate: ${_analytics['base_weekly_rate']}% weekly",
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 5),
                        const Divider(),
                        const SizedBox(height: 5),
                        Text(
                          "Weekly Repayment: KSH ${DataConverter.moneyToStr(_analytics['weekly_instalment'])}",
                          style: theme.textTheme.bodyLarge,
                        ),
                        Text(
                          "No. of instalments/weeks: ${DataConverter.moneyToStr(_analytics['num_instalments'])}",
                          // style: theme.textTheme.bodyLarge//?.copyWith(color: Colors.grey.shade700)
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Total Repayment: KSH ${DataConverter.moneyToStr(_analytics['total_payout'])}",
                          style: theme.textTheme.bodyLarge,
                        ),
                        Text("(Loan amount + Interest)", style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10,),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text("Reason for Loan", style: theme.textTheme.bodyLarge,),
                    isThreeLine: true,
                    subtitle: RichText(
                      text: TextSpan(
                        text: "${_loProposal.purpose}\n",
                        style: theme.textTheme.bodyMedium,
                        children: [
                          TextSpan(
                            text: _loProposal.tagsStr,
                            style: TextStyle(color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                          )
                        ]
                      ),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text("Borrower's Repayment Plan", style: theme.textTheme.bodyLarge,),
                    subtitle: Text(_loProposal.repaymentPlan),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text("Borrower's Payment Method", style: theme.textTheme.bodyLarge,),
                    trailing: const Icon(Icons.notification_important),
                    subtitle: RichText(
                      text: TextSpan(
                        text: "This borrower can only receive money through the payment method listed below. Please only accept this lend request if you use this payment method:\n",
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                        children: [
                          TextSpan(
                            text: _loProposal.destination['method'],
                            style: theme.textTheme.bodyLarge,
                          )
                        ]
                      ),
                    ),
                    isThreeLine: true
                  ),
                  const Divider(),
                  const SizedBox(height: 6,),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Builder(
                      builder: (context) {
                        if(_makingOrBreakingBid) return const LinearProgressIndicator();

                        if(parent.proposalAccepted) {
                          return TextButton.icon(
                            style: ButtonStyle(
                              backgroundColor: MaterialStateColor.resolveWith((states) => Colors.black.withOpacity(0.1))
                            ),
                            onPressed: () {
                              //todo cancel lend request that was already accepted
                            },
                            label: const Text("Cancel Request"),
                            icon: const Icon(Icons.not_interested_outlined)
                          );
                        } else {
                          return FilledButton.icon(
                            onPressed: () {
                              //accept lend request
                              //todo if user has signed up, accept request
                              //else user has to sign up first
                              //if user has not been verified, they have to verify
                              //(actually, on second thought, only require verification for borrowers)

                              UserProfile? appUser = UserProfile.fromCache();

                              if(appUser == null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const Welcome(autoPop: true,))
                                );
                                return;
                              }

                              if(_makingOrBreakingBid) {
                                return; // if fetching already in progress, return
                              }

                              setState(() {
                                _makingOrBreakingBid = true;
                              });


                              Bid bid = Bid.fromProposal(_loProposal);

                              Api.getInstance()
                                .acceptLendRequest(bid)
                                .then((response) {

                                  //todo make mounted checks all through the app
                                  if(!mounted) return;

                                  setState(() {
                                    _makingOrBreakingBid = false;
                                  });

                                  if(response.exists) {

                                    bool proposalAccepted = response.data as bool;

                                    if(proposalAccepted) {
                                      //todo update ui

                                      //add the proposal to the bid (we didn't at first cause
                                      //we don't want to send the whole thing to the server
                                      //(it's redundant)
                                      bid.proposal = _loProposal;

                                      //this is temporary just for immediate ui.
                                      //it has no effect. real bid time is in the server
                                      //for future db lookups
                                      bid.bidTime = DateTime.now();

                                      _proposalManager.onProposalAccepted(bid);

                                      context.toast("You have accepted the lend request!");

                                      context.pop();
                                    } else {
                                      context.toast("You had already accepted this lend request in the past. Can't accept again");
                                    }
                                  } else {
                                    context.toast("Failed to accept lend request. ${response.errorMsg}");
                                  }
                              });
                            },
                            label: const Text("Accept Lend Request"),
                            icon: const Icon(Icons.done_all_outlined),
                          );
                        }
                      },
                    )
                  ),

                  if(!_makingOrBreakingBid && !parent.proposalAccepted)
                    Wrap(
                      alignment: WrapAlignment.center,
                      // crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text("Accept", style: theme.textTheme.bodySmall,),
                        const Icon(Icons.arrow_forward_outlined, size: 18,),
                        Text("Borrower Confirms", style: theme.textTheme.bodySmall,),
                        const Icon(Icons.arrow_forward_outlined, size: 18,),
                        Text("Lend Money", style: theme.textTheme.bodySmall,),
                      ],
                    ),

                  if(_makingOrBreakingBid) const Text("Please wait..."),

                  const SizedBox(height: 20,),

                  if(!_makingOrBreakingBid && !parent.proposalAccepted)
                    Column(
                      children: [
                        Text(
                          "(Optional)\nHow likely are you to lend to this borrower?",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 6,),

                        RatingBar.builder(
                          itemSize: 36,
                          allowHalfRating: true,
                          onRatingUpdate: (double rating) {
                            setState(() {
                              _rating = rating;

                              if(!_rated) {
                                _rated = true;
                                fullScroll();
                              }

                              if(_rating <= 0) {
                                _rated = false;
                              }
                            });
                          },
                          itemBuilder: (context, index) {
                            switch (index) {
                              case 0:
                                return const Icon(
                                  Icons.sentiment_very_dissatisfied_sharp,
                                  color: Colors.redAccent,
                                );
                              case 1:
                                return const Icon(
                                  Icons.sentiment_dissatisfied_sharp,
                                  color: Colors.orange,
                                );
                              case 2:
                                return const Icon(
                                  Icons.sentiment_neutral,
                                  color: Colors.blueGrey,
                                );
                              case 3:
                                return const Icon(
                                  Icons.sentiment_satisfied_sharp,
                                  color: Colors.green,
                                );
                              case 4:
                              default:
                                return const Icon(
                                  Icons.sentiment_very_satisfied_sharp,
                                  color: Colors.blue,
                                );
                            }
                          },
                        ),

                        const SizedBox(height: 6,),

                        // todo rating does nothing in v1.
                        // if(_rating > 0)
                        //   TextButton(
                        //       style: ButtonStyle(
                        //           backgroundColor: MaterialStateColor.resolveWith((states) => Colors.black.withOpacity(0.1))
                        //       ),
                        //       onPressed: () {
                        //         //todo submit rating for analytics
                        //       },
                        //       child: const Text(
                        //         "     Submit     ",
                        //         style: TextStyle(fontSize: 12),
                        //       )
                        //   )
                      ],
                    )
                ],
              ),
            ),
          ],
        ),
      )
    );
  }

  void fullScroll() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 300,
      duration: const Duration(milliseconds: 1000),
      curve: Curves.slowMiddle,
    );
  }
}

//todo lender should not be able to accept lend request twice. implement functionality of removing lend request from feed
//after it has been accepted
// implement bookmarking. DONE. future, sync in server
//todo implement borrower rating. borrower will be able to see an aggregate of how people are likely to lend to them. no effect on algo
//todo when user clicks on proposal, load debt and lend history from db. this will not be cached in redis, cause not
//all proposals will be clicked on. so it's just saving space and only caching most required info. will not be reloaded every time,
//saved temporarily on user's end
/*todo detail of debt and lend history
* - no of past debts
* - total amount of debt ever borrowed
* - when debt history is clicked, show every individual debt: date, amount, time of repayment, reason for loan
* - total money lent out
* - no of times lent
* - when lend history is clicked,
* */
//todo also load interest payment and total earnings. this won't be cached in redis cause they are subject to change at any time
//todo also when user clicks on proposal, update number of views (only visible to the borrower).
//recommendation will not be implemented in v1

//todo in future
//implement liking/okaying. affects algo positioning.
//borrower rating affects algo positioning
//no. of views also affects algo positioning

//todo refactor redundant if statements in list conditional widgets to if..else

//todo everywhere where there's an api operation, make sure request is not made more than once inadvertently,
//e.g when user clicked a button twice. add an if condition that checks if fetching is already currently in progress,
//and stop the function if so.