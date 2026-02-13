import 'package:flutter/material.dart';
import 'package:loannect/api/api.dart';
import 'package:loannect/app_theme.dart';
import 'package:loannect/dat/Bid.dart';
import 'package:loannect/state/app_router.dart';
import 'package:loannect/state/state_man.dart';
import 'package:loannect/ui/custom/custom_textfield.dart';
import 'package:provider/provider.dart';


class SendTransactionPage extends StatefulWidget {
  final Bid pendingTransaction;

  const SendTransactionPage(this.pendingTransaction, {super.key});

  @override
  State<SendTransactionPage> createState() => _SendTransactionPageState();
}

class _SendTransactionPageState extends State<SendTransactionPage> {

  Bid get pendingTransaction => widget.pendingTransaction;

  final String _paymentMethod = 'M-PESA';  // will have more in future versions
  String _paymentMethodDetail = '';
  bool get _paymentMethodDetailInvalid => _paymentMethodDetail.isEmpty || int.tryParse(_paymentMethodDetail) == null;

  bool _fetching = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: COLOR_PRIMARY,
      appBar: AppBar(
        title: const Text("Lend Money"),
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
                      "Borrower",
                      style: theme.textTheme.displayMedium,
                    ),
                    // const SizedBox(height: 10,),
                    Text(
                      pendingTransaction.proposal!.userProfile!['user_name'],
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
                    Text("Method: ${pendingTransaction.proposal!.destination['method']}", style: darkTextTheme.displaySmall,),
                    Text("Send To: ${pendingTransaction.proposal!.destination['detail']}", style: darkTextTheme.displaySmall,),

                    const SizedBox(height: 40,),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Icon(Icons.info_outline)
                    ),
                    Text("You decided to lend to this borrower ${pendingTransaction.closeTimeAgo}"),
                    Text(
                      "Instructions",
                      style: theme.textTheme.displayMedium,
                    ),
                    Text(
                      "1. Go to the M-PESA menu on your device\n"
                      "2. Send the loan amount directly to the borrower using the Payment Details above\n"
                      "3. After sending the full amount, click the button below to confirm completion of the transaction",
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
                        builder: (_) {
                          return AlertDialog(
                            title: const Text("Completed Transaction?"),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text("No")
                              ),
                              TextButton(
                                onPressed: () {
                                  if(_paymentMethodDetailInvalid) {
                                    context.toast("Invalid M-PESA Number");
                                  } else {
                                    confirmTransactionSent({
                                      "method": _paymentMethod,
                                      "detail": _paymentMethodDetail
                                    });
                                  }

                                  Navigator.pop(context);
                                },
                                child: const Text("Done")
                              )
                            ],
                            content: SingleChildScrollView(
                              child: Column(
                                children: [
                                  Text("I confirm that I have completed the transaction of KSH ${pendingTransaction.proposal!.amountStr}",
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                  const SizedBox(height: 20,),
                                  const Text("Enter M-PESA Number that you sent the money from",),
                                  const SizedBox(height: 6,),
                                  CustomTextField(
                                    hint: "M-PESA Number: 07...",
                                    inputType: TextInputType.number,
                                    onTextChanged: (mpesaNumber) {
                                      _paymentMethodDetail = mpesaNumber;
                                    },
                                  ),
                                ],
                              ),
                            )
                          );
                        }
                      );
                    },
                    icon: const Icon(Icons.price_check_outlined),
                    label: const Text("I have sent the money in full")
                  ),
                  const SizedBox(height: 10),

                  TextButton.icon(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateColor.resolveWith((states) => Colors.black.withOpacity(0.1))
                    ),
                    onPressed: () {
                      //todo cancel lend request that was already accepted
                    },
                    label: const Text("Cancel this transaction"),
                    icon: const Icon(Icons.not_interested_outlined)
                  )
                ],
              )
            ],
          ),
        ),
      )
    );
  }

  void confirmTransactionSent (Map source) {
    setState(() {
      _fetching = true;
    });

    Api.getInstance()
      .confirmTransactionSent(pendingTransaction, source)
      .then((response) {
        setState(() {
          _fetching = false;
        });

        if(response.exists) {
          Provider.of<StateMan>(context, listen: false)
            .notifyTransactionSentOrCancelled();
        } else {
          context.toast(response.errorMsg);
        }
    });
  }
}