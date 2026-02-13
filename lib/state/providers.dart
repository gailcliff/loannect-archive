
import 'package:loannect/state/fin_manager.dart';
import 'package:loannect/state/proposal_manager.dart';
import 'package:loannect/state/state_man.dart';
import 'package:provider/provider.dart';

List<ChangeNotifierProvider> providers = [
  ChangeNotifierProvider<StateMan>(
    create: (context) => StateMan(),
  ),
  ChangeNotifierProvider<ProposalManager>(
    create: (context) => ProposalManager()
  ),
  ChangeNotifierProvider<FinManager>(
    create: (context) => FinManager()
  )
];