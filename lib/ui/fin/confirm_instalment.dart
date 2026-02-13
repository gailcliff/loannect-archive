import 'package:flutter/material.dart';
import 'package:loannect/api/api.dart';
import 'package:loannect/app_theme.dart';
import 'package:loannect/dat/Instalment.dart';
import 'package:loannect/dat/Lo.dart';
import 'package:loannect/state/app_router.dart';


class ConfirmInstalment extends StatefulWidget {
  final Lo lendOutWithInstalments;
  final void Function(Lo) onConfirmationFinished;

  const ConfirmInstalment(this.lendOutWithInstalments, {super.key, required this.onConfirmationFinished});

  @override
  State<ConfirmInstalment> createState() => _ConfirmInstalmentState();
}

class _ConfirmInstalmentState extends State<ConfirmInstalment> {

  Lo get lendOut => widget.lendOutWithInstalments;
  Instalment? get nextInstalmentToConfirm => lendOut.instalments.isEmpty ? null : lendOut.instalments.first;
  bool get hasMoreToConfirm => lendOut.numInstalments > 0;
  int currentInstalmentWereAt = 1;

  void onInstalmentConfirmed() {
    try {
      print("instalment confirmed: ${nextInstalmentToConfirm?.id}");
      lendOut.instalments.removeWhere((instalment) => instalment.id == nextInstalmentToConfirm?.id);

      if (hasMoreToConfirm) {
        print("Total left to confirm: ${lendOut.numInstalments}");
        context.toast("Another instalment was received too. Please confirm");
      } else {
        print("all instalments confirmed...");

        widget.onConfirmationFinished.call(lendOut);
      }

      setState(() {
        currentInstalmentWereAt += 1;
        bgColor = bgColor == COLOR_PRIMARY ? Colors.green : COLOR_PRIMARY;
      });
    } on Exception {
      // do nothing
      print("exception occurred");
    }
  }

  bool _fetching = false;

  Color bgColor = COLOR_PRIMARY;

  @override
  Widget build(BuildContext context) {
    print("Viewing instalment: ${nextInstalmentToConfirm?.id} of lend out ${lendOut.id}");

    return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: const Text("Loan Instalment Received"),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 20.0, top: 20, right: 20),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Center(
                        child: Text(
                          " ${currentInstalmentWereAt.toString()} ",
                          style: darkTextTheme.displayLarge,
                        ),
                      ),
                    ),
                  ],
                ),

                Expanded(
                  child: ListView(
                    children: [
                      Text(
                        "Instalment Amount",
                        style: theme.textTheme.displayMedium,
                      ),
                      // const SizedBox(height: 10,),
                      Text("KSH ${nextInstalmentToConfirm?.amountStr}", style: darkTextTheme.displaySmall,),

                      const SizedBox(height: 20,),
                      Text(
                        "Payment Details",
                        style: theme.textTheme.displayMedium,
                      ),

                      // the borrower's payments details are in each instalment, since
                      // they are the ones that pay the instalment
                      Text("Sent to you through: ${nextInstalmentToConfirm?.source['method']}", style: darkTextTheme.displaySmall,),
                      Text("From: ${nextInstalmentToConfirm?.source['detail']}", style: darkTextTheme.displaySmall,),

                      const SizedBox(height: 20,),

                      Text(
                        "Paid by Borrower",
                        style: theme.textTheme.displayMedium,
                      ),
                      // const SizedBox(height: 10,),
                      Text(
                        lendOut.proposal.userProfile!['user_name'],
                        style: darkTextTheme.displaySmall,
                      ),

                      const SizedBox(height: 20,),
                      Text(
                        "You lent the Borrower",
                        style: theme.textTheme.displayMedium,
                      ),
                      // const SizedBox(height: 10,),
                      Text(
                        "KSH ${lendOut.proposal.amountStr}",
                        style: darkTextTheme.displaySmall,
                      ),

                      const SizedBox(height: 40,),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Icon(Icons.info_outline)
                      ),

                      // the lender's payment details are in their bid. any updates to their payment details
                      // are made in their bid in the db.
                      Text("The borrower sent you the money ${nextInstalmentToConfirm?.instalmentTimeAgo} to your "
                          "${lendOut.bid.source!['method']} "
                          "(${lendOut.bid.source!['detail']})"),
                      Text(
                        "Instructions",
                        style: theme.textTheme.displayMedium,
                      ),
                      Text(
                        "1. Go to your M-PESA transaction logs or messages on your device\n"
                        "2. Check for the transaction received from the Payment Details above\n"
                        "3. Click the 'Money Received' button below to confirm",
                        // "3. After sending the full amount, click the button below to confirm completion of the transaction.",
                        style: darkTextTheme.bodyLarge,
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 10,),
                if(_fetching)
                  const LinearProgressIndicator()
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text("Confirm"),
                                content: Text("I confirm that I received the transaction of KSH ${nextInstalmentToConfirm?.amountStr}"),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      confirmInstalmentReceipt();
                                    },
                                    child: const Text("Yes")
                                  )
                                ],
                              );
                            }
                          );
                        },
                        icon: const Icon(Icons.price_check_outlined),
                        label: const Text("Money Received")
                      ),
                      const SizedBox(height: 10),

                      TextButton(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateColor.resolveWith((states) => Colors.black.withOpacity(0.1))
                        ),
                        onPressed: () {
                          //todo dispute receipt
                        },
                        child: const Text("Not received"),
                      )
                    ],
                  )
              ],
            ),
          ),
        )
    );
  }

  void confirmInstalmentReceipt() {
    print("Confirming instalment: ${nextInstalmentToConfirm?.id} of lend out ${lendOut.id}");

    setState(() {
      _fetching = true;
    });

    Api.getInstance()
      .confirmInstalmentReceipt(nextInstalmentToConfirm!)
      .then((response) {
        _fetching = false; //setState will be called at onInstalmentConfirmed

        if(response.exists) {
          onInstalmentConfirmed();
        } else {
          context.toast(response.errorMsg);
        }
    });
  }
}
