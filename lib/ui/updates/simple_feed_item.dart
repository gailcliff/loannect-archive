
import 'package:flutter/material.dart';
import 'package:loannect/dat/LoProposal.dart';
import 'package:loannect/state/app_router.dart';
import 'package:loannect/state/proposal_manager.dart';
import 'package:provider/provider.dart';


class SimpleFeedItem extends StatefulWidget {
  final LoProposal loProposal;

  const SimpleFeedItem({super.key, required this.loProposal});

  @override
  State<SimpleFeedItem> createState() => _SimpleFeedItemState();
}

class _SimpleFeedItemState extends State<SimpleFeedItem> {

  late bool _bookmarked;

  late LoProposal _proposal;

  bool _fetching = false;

  @override
  void initState() {
    super.initState();

    _proposal = parent.loProposal;
    _bookmarked = _proposal.bookmarked;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Ink(
      color: Colors.white,
      child: InkWell(
        splashColor: _proposal.decorColor.withOpacity(0.2),
        onTap: loadAnalytics,
        child: Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 10, right: 10),
          child: Row(
            children: [
              Container(width: 2, height: 70, color: _proposal.decorColor,),
              const SizedBox(width: 10,),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "KSH ${_proposal.amountStr}",
                          style: theme.textTheme.headlineLarge,
                          ),
                        Text(
                          "Term: ${_proposal.term} ${_proposal.term == 1 ? 'month' : 'months'}",
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700)
                        ),
                      ],
                    ),

                    const SizedBox(height: 6,),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.perm_identity_outlined, color: _proposal.decorColor,),
                                  // const SizedBox(width: 2,),
                                  Text(_proposal.userProfile!['user_name'], maxLines: 1, overflow: TextOverflow.ellipsis,)
                                ],
                              ),
                              RichText(
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                text: TextSpan(
                                  text: "Loan for: ",
                                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                  children: [
                                    TextSpan(
                                      text: _proposal.purpose,
                                      style: theme.textTheme.bodyMedium
                                    ),
                                  ]
                                ),
                              ),
                              Text(
                                _proposal.tagsStr,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ),

                        if(_fetching)
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: _proposal.decorColor,),
                          ),

                        if(!_fetching)
                          IconButton(
                            onPressed: null,
                            icon: Icon(_bookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: _proposal.decorColor,),
                          ),
                      ],
                    ),

                    const SizedBox(height: 6,),

                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "Requested: ${_proposal.timeAgoProposed}",
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
      )
    );
  }

  Future<void> loadAnalytics() async {

    if(_fetching || _proposalManager.individualItemFetching) {
      //do nothing if already fetching (impatient user)
      return;
    }

    //if analytics were already loaded, show them
    if(_proposal.analytics != null) {
      context.goTo("updates_detail", extra: _proposal);
      return;
    }

    setState(() {
      _fetching = true;
      _proposalManager.notifyIndividualItemFetching();
    });

    _proposal.loadAnalytics()
      .then((response) {
        setState(() {
          _fetching = false;
          _proposalManager.notifyIndividualItemCompletedFetch();
        });

        if(response.exists) {
          context.goTo('updates_detail', extra: _proposal);
        } else {
          context.toast(response.errorMsg);
        }
    });
  }

  SimpleFeedItem get parent => widget;

  ProposalManager get _proposalManager => Provider.of<ProposalManager>(context, listen: false);
}
//todo implement bookmarking