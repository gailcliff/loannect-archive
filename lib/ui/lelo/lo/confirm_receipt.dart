import 'package:flutter/material.dart';
import 'package:loannect/api/api.dart';
import 'package:loannect/app_theme.dart';
import 'package:loannect/dat/Bid.dart';
import 'package:loannect/state/app_router.dart';
import 'package:loannect/state/state_man.dart';
import 'package:provider/provider.dart';


class ConfirmReceipt extends StatefulWidget {
  final Bid pendingTransaction;

  const ConfirmReceipt(this.pendingTransaction, {super.key});

  @override
  State<ConfirmReceipt> createState() => _ConfirmReceiptState();
}

class _ConfirmReceiptState extends State<ConfirmReceipt> {

  Bid get pendingTransaction => widget.pendingTransaction;

  bool _fetching = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: COLOR_PRIMARY,
      appBar: AppBar(
        title: const Text("Loan Received"),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: ListView(
                  children: [
                    Text(
                      "Loan sent by Lender",
                      style: theme.textTheme.displayMedium,
                    ),
                    // const SizedBox(height: 10,),
                    Text(
                      pendingTransaction.bidderInfo!['user_name'],
                      style: darkTextTheme.displaySmall,
                    ),


                    const SizedBox(height: 20,),
                    Text(
                      "Loan Amount",
                      style: theme.textTheme.displayMedium,
                    ),
                    // const SizedBox(height: 10,),
                    Text("KSH ${pendingTransaction.proposal!.amountStr}", style: darkTextTheme.displaySmall,),

                    const SizedBox(height: 20,),
                    Text(
                      "Payment Details",
                      style: theme.textTheme.displayMedium,
                    ),
                    // const SizedBox(height: 10,),
                    Text("Sent to you through: ${pendingTransaction.source!['method']}", style: darkTextTheme.displaySmall,),
                    Text("From: ${pendingTransaction.source!['detail']}", style: darkTextTheme.displaySmall,),

                    const SizedBox(height: 40,),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Icon(Icons.info_outline)
                    ),
                    Text("The lender sent you the money ${pendingTransaction.closeTimeAgo} to your "
                        "${pendingTransaction.proposal!.destination['method']} "
                        "(${pendingTransaction.proposal!.destination['detail']})"),
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
                              content: Text("I confirm that I received the transaction of KSH ${pendingTransaction.proposal!.amountStr}"),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    confirmReceipt();
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
                      // icon: const Icon(Icons.not_interested_outlined)
                    )
                  ],
                )
            ],
          ),
        ),
      )
    );
  }

  void confirmReceipt () {
    setState(() {
      _fetching = true;
    });

    Api.getInstance()
      .confirmTransactionReceipt(pendingTransaction)
      .then((response) {
        setState(() {
          _fetching = false;
        });

        if(response.exists) {
          Provider.of<StateMan>(context, listen: false)
            .notifyTransactionReceiptAcknowledged();
        } else {
          context.toast(response.errorMsg);
        }
    });
  }
}
