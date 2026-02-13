
import 'package:flutter/material.dart';
import 'package:loannect/api/api.dart';
import 'package:loannect/dat/Bid.dart';
import 'package:loannect/dat/LoProposal.dart';
import 'package:loannect/dat/UserProfile.dart';


class ProposalManager extends ChangeNotifier {

  ProposalManager._();

  static final ProposalManager _proposalManager = ProposalManager._();

  factory ProposalManager() => _proposalManager;


  List<LoProposal>? proposalItems;
  List<Bid>? pendingRequests;

  int? get numUnsealedBids => pendingRequests == null ? null : pendingRequests!.length;
  // if null load, if zero don't reload, if >0 reload. ie only ignore reload if == 0


  bool discovering = false; // progress indicator replaces listview
  bool discoveringSubtly = false; // progress indicator appears below listview

  Future<bool> discoverProposals([bool subtle = false]) async {
    if(discovering || discoveringSubtly) {
      //don't fetch if already currently fetching
      print("haha not gonna fetch");
      return true;
    }

    if(!proposalsCacheEmpty) {
      //if there are already items in the list, don't replace the listview with a
      //progress indicator when reloading
      subtle = true;
    }

    // discovering = subtle ? false : true;
    discoveringSubtly = subtle;
    discovering = !discoveringSubtly;

    notifyListeners();

    // load accepted requests before loading proposals
    // always reload accepted requests when tab is changed (only with prefs condition that user has bids)
    //ok, we don't always have to reload every time. there's a ui hint for user to swipe down to refresh
    //plus user will receive notification

    bool foundBids = await getAnyUnsealedBids();

    //wait until proposals are loaded
    final discoveredProposals = await Api.getInstance().discoverProposals(history: history);

    //change state from loading to loaded since fetch is complete
    discovering = false;
    discoveringSubtly = false;

    if (discoveredProposals.exists) {
      proposalItems ??= [];

      //will add different types of items
      /*
      * one is just a regular LoProposal item
      * another could be a horizontal list view of bookmarked items. nah, actually, bookmarked items are placed on top of the list
      *   - when bookmarked, an item will be saved to sharedpreferences and reloaded
      *   - everytime. put it in history too so that it's not fetched from the server
      *
      * another could be a horizontal list of recommended proposals (not implemented in v1)
      * another could be a horizontal list of requests that user has accepted and pending confirmation
      *   - this will be fetched from the server and placed on top of the list
      * */

      for(LoProposal loProposal in (discoveredProposals.data as List<LoProposal>)) {
        // if(loProposal.userId! != appUser?.id) {
          loProposal.listPos = proposalItems!.length;
          proposalItems!.add(loProposal);
        // }
      }

      // proposalItems?.addAll(
      //     (discoveredProposals.data as List<LoProposal>)
      //      // don't show the user's own lend requests in the feed. you don't want a situation where a user
      //      // accepts their own lend request and lends money to themselves (might build credit score fraudulently).
      //     // .where((LoProposal proposal) => proposal.userId! != appUser?.id) //todo
      // );
    }

    notifyListeners();


    //only return true if both api requests were successful
    return discoveredProposals.exists && foundBids;
  }

  Future<bool> getAnyUnsealedBids () async {
    // only get unsealed bids if user has signed up and user has accepted any lend requests

    if(appUser == null) return true;

    if(numUnsealedBids == 0) return true;

    //only load if numUnsealedBids is null or if numUnsealedBids > 0
    //in other words, only load if pendingRequests is null or if pendingRequests.length > 0
    print("fetching unsealed bids...");
    final unsealedBids = await Api.getInstance().getUnsealedBids(appUser!);

    if(unsealedBids.exists) {
      pendingRequests?.clear(); //remove all items from pendingRequests
      pendingRequests ??= [];

      //if there's no bids, pendingRequests will be initialized to any empty list
      //whose length is 0 and this will prevent redundant reloading. if user
      //accepts any lend request, then an item will be added to pendingRequests,
      //and this will invoke reloading of bids from db if the user refreshes
      //the list or scrolls down.
      pendingRequests?.addAll(unsealedBids.data as List<Bid>);

      notifyListeners();

      return true;
    } else {
      return false;
    }
  }

  void onProposalAccepted(Bid bid) {
    // first remove the accepted proposal from the main proposal list and then
    // add the bid to pending requests

    // proposalItems can't be empty at this point
    // proposalItems!.removeWhere((LoProposal item) => item.proposalId == bid.proposal!.proposalId);
    proposalItems!.removeAt(bid.proposal!.listPos);

    pendingRequests ??= [];
    pendingRequests?.insert(0, bid);

    notifyListeners();
  }

  void onProposalBookmarked(LoProposal loProposal) {
    proposalItems!.removeAt(loProposal.listPos);

    loProposal.bookmark();
    proposalItems!.insert(0, loProposal);
    _resetListPositions(); // list positions have changed, so shift property accordingly

    notifyListeners();
  }

  void onProposalUnBookmarked(LoProposal loProposal) {
    proposalItems!.removeAt(loProposal.listPos);

    loProposal.unBookmark();
    proposalItems!.insert(loProposal.listPos, loProposal);

    notifyListeners();
  }

  void _resetListPositions () {
    for(int c = 0; c < proposalItems!.length; c++) {
      proposalItems![c].listPos = c;
    }
  }

  void clearBids() {
    pendingRequests?.clear();
    pendingRequests = null;

    // //ignore any fetches that were already occurring
    // discovering = false;
    // discoveringSubtly = false;
    // _individualItemFetching = false;

    notifyListeners();
  }

  void clearItems() {
    //reset the list if the user wants a fresh one
    proposalItems?.clear();
    proposalItems = null;

    // ignore any fetches that were already in progress
    discovering = false;
    discoveringSubtly = false;
    _individualItemFetching = false;

    notifyListeners();
  }

  bool get proposalsCacheIsNull => proposalItems == null;

  bool get proposalsCacheEmpty => proposalItems == null ? true : proposalItems!.isEmpty;


  bool get pendingRequestsEmpty => pendingRequests == null ? true : pendingRequests!.isEmpty;


  List<int> get history {
    // history encompasses all proposals that user has already accessed from the
    // server.
    // first iterate through items in main list of proposals, and then iterate
    // through the accepted requests, which also have proposals (but these are
    // not in the main list cause they have been accepted already. and we don't
    // want a situation where the user accepts the same proposal twice).

    var foo = <int>{};

    for (LoProposal item in (proposalItems ?? [])) {
      foo.add(item.proposalId!);
    }

    for (Bid acceptedItem in (pendingRequests ?? [])) {
      foo.add(acceptedItem.proposal!.proposalId!);
    }

    return foo.toList();
  }


  bool _individualItemFetching = false;

  void notifyIndividualItemFetching () {
    _individualItemFetching = true;
  }

  void notifyIndividualItemCompletedFetch () {
    _individualItemFetching = false;
  }

  bool get individualItemFetching => _individualItemFetching;


  UserProfile? get appUser => UserProfile.fromCache();
}
