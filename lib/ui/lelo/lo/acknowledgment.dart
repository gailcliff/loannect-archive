
import 'package:flutter/material.dart';
import 'package:loannect/app_theme.dart';
import 'package:loannect/state/state_man.dart';
import 'package:provider/provider.dart';

class Acknowledgment extends StatelessWidget {
  const Acknowledgment({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: COLOR_PRIMARY,
      padding: const EdgeInsets.all(36),
      alignment: Alignment.center,
      child: SizedBox(
        height: 420,
        width: double.infinity,
        child: Card(
          color: COLOR_PRIMARY,
          elevation: 36,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.price_check_outlined, size: 54,),
                Text(
                  "Your application was successfully sent!",
                  style: theme.textTheme.displaySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10,),
                const Text("Lenders on Loannect will be able to see your loan application and lend you the money. You "
                    "will receive update notifications in real-time.", textAlign: TextAlign.center,),
                const SizedBox(height: 40,),
                FilledButton.icon(
                  onPressed: () {
                    final stateMan = Provider.of<StateMan>(context, listen: false);
                    stateMan.toggleHomeTab(0);
                  },
                  label: const Text("Go To Updates"),
                  icon: const Icon(Icons.currency_exchange_outlined),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
