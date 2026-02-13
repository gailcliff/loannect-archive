
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:loannect/dat/Lo.dart';
import 'package:loannect/state/fin_manager.dart';

import 'package:loannect/state/proposal_manager.dart';
import 'package:loannect/state/state_man.dart';
import 'package:loannect/ui/fin/confirm_instalment.dart';
import 'package:loannect/ui/fin/repay_lo.dart';

import 'package:loannect/ui/home.dart';
import 'package:loannect/ui/lelo/le/send_transaction.dart';
import 'package:loannect/ui/lelo/lo/confirm_receipt.dart';
import 'package:loannect/ui/lelo/lo/lo_update_viewer.dart';
import 'package:loannect/ui/lelo/lo/preamble.dart' as lo;
import 'package:loannect/ui/profile/profile.dart';
import 'package:loannect/ui/accounts/account_manager.dart';
import 'package:loannect/ui/updates/simple_feed_item_detail.dart';

import 'package:provider/provider.dart';


const _delegatedWindows = [
  'lo_preamble',
  'welcome',
  'profile',
  'updates_detail',
  'lo_updates',
  'repay_lo'
];

bool _isRouteInDelegatedWindows(String? routeName) => _delegatedWindows.contains(routeName);


extension GoRouterMiddleman on BuildContext {

  void goTo(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra
  }) {
    // switch(name) {
    //   case 'lo_preamble':
    //     Provider.of<NavMiddleman>(this, listen: false).delegateWindowRendering();
    //     break;
    //   default:
    //     break;
    // }

    if(_isRouteInDelegatedWindows(name)) {
      //this will happen if route was fired not through state changes but through
      //context.goTo
      Provider.of<StateMan>(this, listen: false).delegateWindowRendering();
    }

    goNamed(name, pathParameters: pathParameters, queryParameters: queryParameters, extra: extra);
  }

  void toast(String message) {
    try {
      final scaffold = ScaffoldMessenger.of(this);
      scaffold.clearSnackBars();
      scaffold.showSnackBar(
          SnackBar(content: Text(message, textAlign: TextAlign.center,))
      );
    } on Exception {
      //error might occur if called during build(), but eh do nothing
    }
  }
}

class AppRouter {

  late final GoRouter router;

  final StateMan stateMan;

  AppRouter._() : stateMan = StateMan() {
    router = GoRouter(
      initialLocation: '/home',
      observers: [
        RouteWatcher(stateWatcher: stateMan)
      ],
      debugLogDiagnostics: true,
      refreshListenable: stateMan,
      routes: [
        GoRoute(
          name: 'home',
          path: '/home',
          builder: (context, state) {
            if(stateMan.currentHomeTab == 0 && state.location == '/home') {
              //immediately user goes to the update page, load items (only if empty)
              //if the user wants more items, they will swipe up to load more

              final proposalManager = Provider.of<ProposalManager>(context, listen: false);

              //always load pending requests
              if(!proposalManager.proposalsCacheEmpty) {
                //we don't want to reload bids twice, because bids are also reloaded below
                //when we call proposalManager.discoverProposals. so, if proposalsCache is empty,
                //reloading bids will be taken care of below when we call discoverProposals. if not
                //empty, when we switch to this tab, the method below won't be called at all, so
                //bids won't be reloaded below. they will be reloaded here: ...if(!proposalManager.proposalsCacheEmpty)...
                //we don't want double booking. in whichever case, bids are always reloaded.
                proposalManager
                  .getAnyUnsealedBids()
                  .then((bool discovered) {
                    if (!discovered) {
                      context.toast("Please check your internet connection and swipe down to refresh...");
                    }
                });
              }

              //only load proposals if empty
              if(proposalManager.proposalsCacheEmpty) {
                print("at app router, proposals cache is empty. loading proposals...");
                Future.delayed(Duration.zero, () async {
                  proposalManager.discoverProposals()
                    .then((discovered) {
                      if (!discovered) {
                        context.toast("Please check your internet connection and swipe down to refresh...");
                      }
                  });
                });
              }
            }
            else if(stateMan.currentHomeTab == 2 && state.location == '/home') {
              Future.delayed(Duration.zero, () async {
                Provider.of<FinManager>(context, listen: false)
                  .fetchFinances(
                    onlyIfNotLoaded: true
                  ).then((fetched) {
                    if(!fetched) {
                      context.toast("Please check your internet connection and swipe down to refresh...");
                    }
                });
              });
            }

            return Home(homeTab: stateMan.currentHomeTab);
          },
          routes: [
            GoRoute(
              name: 'welcome',
              path: 'welcome',
              builder: (context, state) {
                return const Welcome();
              },
            ),
            GoRoute(
              name: 'profile',
              path: 'profile',
              builder: (context, state) {
                String? tabStr = state.queryParameters['tab'];
                int tab = (tabStr == null || tabStr == 'me')
                    ? 0
                    : (tabStr == 'myself' ? 1 : 2);

                return Profile(
                    referencedTab: tab
                );
              }
            ),

            GoRoute(
              name: 'lo_preamble',
              path: 'lo/preamble/:amt',
              builder: (context, state) {
                int amount = int.parse(state.pathParameters['amt']!);
                // double? rate = double.tryParse(state.queryParameters['rate']!);
                final loPreRequisites = state.extra!;

                return lo.Preamble(loPreRequisites, amt: amount,);
              },
            ),

            GoRoute(
              name: 'updates_detail',
              path: 'updates/detail',
              builder: (context, state) {
                //this route will only be fired if a simple feed item is clicked in the updates feed
                return SimpleFeedItemDetail(state.extra!);
              }
            ),

            GoRoute(
              name: "lo_updates",
              path: "updates/lo_updates",
              builder: (context, state) {
                return const LoUpdateViewer();
              }
            ),
            GoRoute(
              name: "repay_lo",
              path: "lo/repay",
              builder: (context, state) {
                return const RepayLo();
              }
            )
          ]
        ),

        GoRoute(
          name: 'transact',
          path: '/transact',
          builder: (context, state) {
            // if this route was invoked, then stateMan.pendingSendTransaction
            // absolutely can't be null
            return SendTransactionPage(stateMan.pendingSendTransaction!);
          }
        ),
        GoRoute(
          name: 'confirm_receipt',
          path: '/confirm_receipt',
          builder: (context, state) {
            // if this route was invoked, then stateMan.pendingReceiptTransaction
            // absolutely can't be null
            return ConfirmReceipt(stateMan.transactionPendingReceiptConfirmation!);
          }
        ),
        GoRoute(
          name: 'confirm_instalment',
          path: '/confirm_instalment',
          builder: (context, state) {
            // if this route was invoked, then stateMan.nextInstalmentToConfirm
            // absolutely can't be null
            return ConfirmInstalment(
              stateMan.nextInstalmentToConfirm!,
              onConfirmationFinished: (Lo fullyConfirmedLendOut) {
                //todo remove this lend out from state and confirm the next
                //until done.

                stateMan.notifyLendOutInstalmentsConfirmed(fullyConfirmedLendOut);
              },
            );
          }
        ),
      ],
      redirect: (context, state) {
        //if user hasn't confirmed sending or receipt of funds or completion/cancellation
        //of transaction show the confirmation screen.
        //don't proceed to any other page unless the user confirms

        if(stateMan.shouldSendTransaction != null) {
          if(stateMan.shouldSendTransaction!) {
            stateMan.revokeDelegatedWindowRendering();
            return '/transact';
          }
        }

        if(stateMan.transactionWasReceived != null) {
          if(stateMan.transactionWasReceived!) {
            stateMan.revokeDelegatedWindowRendering();

            return '/confirm_receipt';
          }
        }

        // if user has instalments to confirm, meaning they received an instalment
        // from a borrower but they haven't confirmed it yet, mandate their
        // confirmation before being able to do anything else
        if(stateMan.hasInstalmentsToConfirm) {
          print("AppRouter: has more instalments to confirm");

          stateMan.revokeDelegatedWindowRendering();
          return '/confirm_instalment';
        }

        if(stateMan.windowRenderingWasDelegated) return null;

        return '/home';
      }
    );
  }

  static final AppRouter _appRouter = AppRouter._();

  factory AppRouter() => _appRouter;
}


class RouteWatcher extends NavigatorObserver {

  final StateMan stateWatcher;

  RouteWatcher({required this.stateWatcher});

  @override
  void didPush(Route route, Route? previousRoute) {
    print("Now showing route: ${route.settings.name}");
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    print("A route was popped: ${route.settings.name}");

    if(_isRouteInDelegatedWindows(route.settings.name)) {
      stateWatcher.revokeDelegatedWindowRendering();
    }
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    print("A route was removed: ${route.settings.name}");

    // if(_isRouteInDelegatedWindows(route.settings.name)) {
    //   stateWatcher.revokeDelegatedWindowRendering();
    // }
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    print("A route was replaced: ${oldRoute?.settings.name}");
  }
}