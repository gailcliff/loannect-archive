import 'package:flutter/material.dart';
import 'package:loannect/dat/Bid.dart';
import 'package:loannect/state/app_router.dart';
import 'package:loannect/state/proposal_manager.dart';
import 'package:loannect/state/state_man.dart';
import 'package:loannect/ui/lelo/terms.dart';
import 'package:provider/provider.dart';


class AcceptedRequestsList extends StatelessWidget {
  const AcceptedRequestsList({super.key});


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Requests I've Accepted", style: theme.textTheme.bodyLarge,),
            Text("Pull to refresh", style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),),
          ],
        ),
        SizedBox(
          width: double.infinity,
          height: 210,
          child: Consumer<ProposalManager>(
            builder: (context, manager, child) {
              return ListView.separated(
                padding: const EdgeInsets.all(10),
                scrollDirection: Axis.horizontal,
                itemCount: manager.pendingRequests!.length,
                itemBuilder: (context, pos) => AcceptedRequestBanner(pendingItem: manager.pendingRequests![pos],),
                separatorBuilder: (context, pos) => const SizedBox(width: 20,),
              );
            },
          ),
        ),
        const Divider(),
        const SizedBox(height: 10,),
      ],
    );
  }
}


class AcceptedRequestBanner extends StatefulWidget {
  final Bid pendingItem;

  const AcceptedRequestBanner({super.key, required this.pendingItem});

  @override
  State<StatefulWidget> createState() => _AcceptedRequestBannerState();
}

class _AcceptedRequestBannerState extends State<AcceptedRequestBanner> {

  Bid get pendingItem => widget.pendingItem;

  bool _fetching = false;

  ProposalManager get proposalManager => Provider.of<ProposalManager>(context, listen: false);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 210,
      child: Card(
        // color: Colors.green,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)
        ),
        child: InkWell(
          onTap: () {
            loadDetail(
              onLoaded: (Bid pendingItem) {
                if(pendingItem.source == null) {
                  context.goTo("updates_detail", extra: pendingItem);
                } else {
                  // if borrower has already sent the money (waiting borrower confirmation)
                  Provider.of<StateMan>(context, listen: false).toggleHomeTab(2);
                }
              }
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Row(
                  children: [
                    const Spacer(flex: 3,),
                    const RotatedBox(
                      quarterTurns: 1,
                      child: Icon(Icons.payments_outlined, color: Colors.green,),
                    ),
                    const Spacer(flex: 2,),

                    if(!_fetching) const Icon(Icons.navigate_next)
                    else const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                ),
                Text(
                  "KSH ${pendingItem.proposal!.amountStr}",
                  style: theme.textTheme.bodyLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6,),
                Text("Borrower:", textAlign: TextAlign.center, style: theme.textTheme.bodySmall,),
                Text(
                  pendingItem.proposal!.userProfile!['user_name'],
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                ),
                const SizedBox(height: 6,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      pendingItem.unsealed
                      ? Icons.schedule_outlined
                      : (
                        pendingItem.source != null
                          ? Icons.schedule_send
                          : Icons.done_all_outlined
                       ),
                      size: 18,
                      color: Colors.green,
                    ),
                    Text(
                      (pendingItem.unsealed || pendingItem.source != null)
                        ? " Waiting borrower to confirm..."
                        : " The borrower confirmed!",
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                      maxLines: 1,
                    ),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    //todo check bid status. if not 1, disable button
                    //else if clicked, confirm terms and conditions and then lend
                    //also if source != null, meaning the lender already confirmed
                    //completion of transaction from their end
                    onPressed: (pendingItem.unsealed || pendingItem.source != null)
                      ? null
                      : () {
                        loadDetail(
                          onLoaded: (Bid pendingItem) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                fullscreenDialog: true,
                                builder: (context) {
                                  return Terms(
                                    termsType: TermsType.LENDER,
                                    bid: pendingItem,
                                    onBidSealDone: (Bid bid) {
                                      bid.closeTime = DateTime.now(); // only temporary to show lender what time they
                                      // decided to lend to the borrower. doesn't affect the close time in db or
                                      // anywhere else. in future, this is reloaded from the server, but immediately
                                      // at this time, no trips will be made to server

                                      Provider.of<StateMan>(context, listen: false).notifyShouldSendTransaction(bid);
                                    },
                                  );
                                }
                              )
                            );
                          }
                        );
                    },
                    child: Text(pendingItem.source == null ? "Lend Money Now" : "Money Sent"),
                  ),
                ),
              ],
            ),
          ),
        ),
      )
    );
  }

  void loadDetail ({required void Function(Bid) onLoaded}) {
    if(_fetching || proposalManager.individualItemFetching) {
      //do nothing if already fetching (impatient user)
      return;
    }

    if(pendingItem.proposal!.analytics == null) {

      setState(() {
        _fetching = true;
        proposalManager.notifyIndividualItemFetching();
      });

      pendingItem.proposal!
        .loadAnalytics()
        .then((response) {
          setState(() {
            _fetching = false;
            proposalManager.notifyIndividualItemCompletedFetch();
          });

          if(response.exists) {
            onLoaded.call(pendingItem);
          } else {
            context.toast(response.errorMsg);
          }
      });
    } else {
      onLoaded.call(pendingItem);
    }
  }
}
//todo don't include pending accepted requests in the main updates list