
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loannect/app_theme.dart';
import 'package:loannect/dat/UserProfile.dart';
import 'package:loannect/state/app_router.dart';
import 'package:loannect/state/state_man.dart';
import 'package:loannect/ui/fin/fin.dart';
import 'package:loannect/ui/lelo/le_lo.dart';
import 'package:loannect/ui/updates/updates.dart';
import 'package:provider/provider.dart';

class Home extends StatefulWidget {

  final int homeTab;

  const Home({super.key, required this.homeTab});

  @override
  State<Home> createState() => _HomeState();
}


class _HomeState extends State<Home> with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    print("app initialized");

    WidgetsBinding.instance.addObserver(this);

    //todo check for any updates, e.g receipt of funds etc
    getUserUpdates();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("Changed lifecycle state: $state");

    if(state == AppLifecycleState.resumed) {
      //todo check for any updates, e.g receipt of funds etc
      //todo fetch unsealed bids (also do this in app router)
      //todo check if there is status update for pending loan applications

      getUserUpdates();
    }
  }

  @override
  void dispose() {
    print("disposing home...");
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  void getUserUpdates () {
    if(!stateManager.checkingTheBonnet) {
      print("at getUserUpdates: checking user updates...");

      stateManager.getUserUpdates()
        .then((bool updatesFound) {
          if (!updatesFound) {
            stateManager.checkTheBonnet(context);
          }
      });
    } else {
      print("already checking the bonnet. skipping getUserUpdates...");
    }
  }


  get pages => const [
    Updates(),
    LeLo(),
    Finances()
  ];

  StateMan get stateManager => Provider.of<StateMan>(context, listen: false);

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      // backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: Colors.white,
        centerTitle: false,
        title: const Text("Go Getter"),
        titleTextStyle: GoogleFonts.bungeeShade(fontSize: 28, fontWeight: FontWeight.w800, color: COLOR_PRIMARY),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FilledButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateColor.resolveWith((states) => COLOR_PRIMARY.withOpacity(0.25)),
                shape: MaterialStateProperty.resolveWith((states) {
                  return RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)
                  );
                })
              ),
              child: const Column(
                children: [
                  Icon(Icons.self_improvement, color: COLOR_PRIMARY,),
                  Text("Me", style: TextStyle(color: COLOR_PRIMARY),)
                ]
              ),
              onPressed: () {
                //go to either login or profile page
                UserProfile.isUserRegistered
                  ? context.goTo("profile")
                  : context.goTo("welcome");
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          // BottomNavigationBarItem(icon: Icon(Icons.published_with_changes_outlined), label: "Updates"),
          BottomNavigationBarItem(icon: Icon(Icons.currency_exchange_outlined), label: "Updates"),
          // BottomNavigationBarItem(icon: Icon(Icons.account_balance_outlined), label: "Lend & Loan"),
          BottomNavigationBarItem(
            icon: RotatedBox(
              quarterTurns: 1,
              child: Icon(Icons.payments_outlined),
            ),
            label: "Loan & Lend"
          ),
          BottomNavigationBarItem(icon: Icon(Icons.assessment_outlined), label: "My Finances"),
          // BottomNavigationBarItem(icon: Icon(Icons.self_improvement), label: "Me, Myself & I"),
        ],
        currentIndex: parent.homeTab,
        onTap: (tab) {
          stateManager.toggleHomeTab(tab);
        },
      ),
      // floatingActionButton: FloatingActionButton(
      //   child: const Icon(Icons.add),
      //   onPressed: () {
      //
      //   },
      // ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: IndexedStack(
          index: parent.homeTab,
          children: pages,
        ),
      ),
    );
  }

  Home get parent => widget;
}
