import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loannect/app_theme.dart';
import 'package:loannect/state/state_man.dart';
import 'package:move_to_background/move_to_background.dart';
import 'package:provider/provider.dart';

class BonnetChecker extends StatefulWidget {
  const BonnetChecker({super.key});

  @override
  State<BonnetChecker> createState() => _BonnetCheckerState();
}

class _BonnetCheckerState extends State<BonnetChecker> {

  StateMan get stateManager => Provider.of<StateMan>(context, listen: false);

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    stateManager.notifyCheckingBonnet();
  }

  bool _fetching = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        MoveToBackground.moveTaskToBack();
        return false;
      },
      child: Scaffold(
        backgroundColor: COLOR_PRIMARY,
        body: Column(
          children: [
            Expanded(
              child: Center(
                child: _fetching
                  ? const CircularProgressIndicator()
                  : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.cloud_off,
                        size: 54,
                      ),
                      const SizedBox(height: 20,),
                      Text(
                        "Failed to load.\n\n",
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const Text("Please check your internet connection and refresh..."),
                      const SizedBox(height: 40,),
                      FilledButton(
                        onPressed: () {
                          setState(() {
                            _fetching = true;
                          });

                          stateManager.getUserUpdates()
                            .then((bool updatesFound) {
                              setState(() {
                                _fetching = false;
                              });

                              print("BonnetChecker: bonnet check result (Updates found: $updatesFound)");

                              if(updatesFound) {
                                stateManager.notifyFinishedCheckingBonnet();
                                Navigator.pop(context);
                              }
                          });
                        },
                        child: const Text("Refresh")
                      )
                    ]
                ),
              )
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text("Loannect", style: GoogleFonts.bungeeShade(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.black),),
            )
          ],
        ),
      ),
    );
  }
}
