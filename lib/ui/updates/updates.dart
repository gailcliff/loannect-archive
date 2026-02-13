
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:loannect/state/app_router.dart';
import 'package:loannect/state/proposal_manager.dart';
import 'package:loannect/ui/updates/accepted_requests.dart';
import 'package:loannect/ui/updates/simple_feed_item.dart';
import 'package:provider/provider.dart';

//todo important: the updates page will be visible even users who haven't signed up
//but if user wants to accept a lend request, they have to sign up first. good for
//dangling the meat above the dog (playing fetch)

class Updates extends StatefulWidget {
  const Updates({super.key});

  @override
  State<Updates> createState() => _UpdatesState();
}

class _UpdatesState extends State<Updates> {

  ProposalManager get manager => Provider.of<ProposalManager>(context, listen: false);

  late ScrollController scrollController;

  @override
  void initState() {
    super.initState();

    scrollController = ScrollController();
    scrollController.addListener(() {
      if((scrollController.offset == scrollController.position.maxScrollExtent)
          && (!scrollController.position.outOfRange)) {
        print("bottom of screen");

        // print("proposal items: ${manager.proposalItems}");
        if (!manager.proposalsCacheEmpty) {
          //only fetch if the user was scrolling a list that wasn't empty
          //i.e if the list is null or has no items, we don't fetch when the user
          //scrolls the list (this will be fired when the user pulls down to refresh)

          discover(true); //reload the list with a progress indicator that replaces the list
        }
      }
    });
  }

  Future<void> discover([bool subtle = false]) async {
    manager
      .discoverProposals(subtle)
      .then((bool discovered) {
        if(mounted) {
          if(!discovered) {
            context.toast("Please check your internet connection and try again...");
          } else {
            //fetch was successful
          }
        }
    });
  }

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () async {
        //don't refresh if already currently refreshing
        if(!manager.discovering && !manager.discoveringSubtly) {
          // refresh items and load anew
          manager.clearItems();
          discover();
        }
      },
      child: Consumer<ProposalManager>(
        builder: (context, ProposalManager manager, child) {
          return ListView(
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            // primary: true,
            children: [
              const SizedBox(height: 10,),
              Card(
                surfaceTintColor: Colors.black,
                color: Colors.black,
                child: ListTile(
                  title: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("My Loan Applications", style: TextStyle(color: Colors.white)),
                      //todo if there are updates, show green unread icon and arrow icon should also be green to pop
                      //updates means
                      // Icon(Icons.mark_chat_unread_outlined, color: Colors.greenAccent, size: 20,)
                    ],
                  ),
                  subtitle: const Text("View status updates of my pending loan applications", style: TextStyle(color: Colors.white),),
                  trailing: const Icon(Icons.navigate_next, color: Colors.white,),
                  contentPadding: const EdgeInsets.only(left: 12, right: 8),
                  onTap: () {
                    //todo show transaction history
                    context.goTo("lo_updates");
                  },
                ),
              ),
              const SizedBox(height: 30,),
              Text("Lend Requests", style: theme.textTheme.displayLarge,),
              const SizedBox(height: 10,),

              if(!manager.discovering && !manager.pendingRequestsEmpty) const AcceptedRequestsList(),

              Builder(
                builder: (context) {
                  if(manager.discovering) {
                    return Container(
                      height: 100,
                      alignment: Alignment.bottomCenter,
                      child: const CircularProgressIndicator(),
                    );
                  }
                  if(manager.proposalsCacheIsNull || manager.proposalsCacheEmpty) {
                    //if the fetch wasn't successful or it returned an empty list
                    //reuse code for both conditions to give user appropriate update.
                    //if cache is null it means fetch wasn't successful
                    return Column(
                      children: [
                        const SizedBox(height: 100,),
                        Icon(
                          manager.proposalsCacheIsNull ? Icons.cloud_off : Icons.person_search_outlined,
                          size: 54,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 20,),
                        Text(
                          manager.proposalsCacheIsNull
                            ? "Failed to load.\n\nPlease check your internet connection and swipe down to refresh..."
                            : "The search didn't find lend requests from borrowers for you at the moment.\n\n"
                              "Please swipe down to refresh or check again later...",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade700),
                        )
                      ],
                    );
                  }

                  //if we have some results, now return a listview
                  return ListView.separated(
                    primary: false,
                    shrinkWrap: true,
                    itemCount: manager.proposalItems!.length,
                    separatorBuilder: (context, pos) => const Divider(),
                    itemBuilder: (context, pos) {
                      final item = manager.proposalItems![pos];

                      return SimpleFeedItem(
                        key: UniqueKey(),
                        loProposal: item
                      );
                    }
                  );
                },
              ),
              if(!manager.proposalsCacheEmpty && manager.discoveringSubtly)
                //if the listview already contains items and the user scrolled the list
                //more to load more items, return a progress indicator that appears
                //below the listview rather than replace the listview
                Container(
                  height: 48,
                  // width: 10,
                  alignment: Alignment.bottomCenter,
                  child: const CircularProgressIndicator(),
                ),

              if(!manager.proposalsCacheEmpty && !manager.discoveringSubtly && !manager.discovering)
                //if there are already items in the list and no fetching is currently
                //taking place, tell show the user a hint to swipe up for more
                //since there are potentially more items to see
                Column(
                  children: [
                    const SizedBox(height: 6,),
                    Text("Swipe up for more", textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),),
                  ],
                ),
            ],
          );
        }
      )
    );
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}
