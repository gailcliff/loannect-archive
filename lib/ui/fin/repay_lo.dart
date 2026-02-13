import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loannect/api/api.dart';
import 'package:loannect/app_theme.dart';
import 'package:loannect/dat/Lo.dart';
import 'package:loannect/dat/UserProfile.dart';
import 'package:loannect/dat/data_converter.dart';
import 'package:loannect/state/app_router.dart';
import 'package:loannect/state/fin_manager.dart';
import 'package:loannect/ui/custom/custom_textfield.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';

import 'package:loannect/state/state_man.dart';


class RepayLo extends StatefulWidget {
  const RepayLo({super.key});

  @override
  State<RepayLo> createState() => _RepayLoState();
}

class _RepayLoState extends State<RepayLo> {

  bool _fetching = false;
  bool _errorFetching = false;

  Lo? _userCurrentLoan;


  final String _paymentMethod = 'M-PESA';  // will have more in future versions
  String _paymentMethodDetail = '';
  int? _amountSent;

  bool get _paymentMethodDetailInvalid => _paymentMethodDetail.isEmpty || int.tryParse(_paymentMethodDetail) == null;

  bool _confirming = false;


  @override
  void initState() {
    super.initState();

    loadUpdates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Repay my Loan"),),
      backgroundColor: COLOR_PRIMARY,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: (_fetching || _errorFetching || (_userCurrentLoan == null))
            ? discoveringView
            : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: updatesView
                ),
                if(_confirming)
                  const LinearProgressIndicator()
                else if (_userCurrentLoan!.totalDebt > 0)
                  FilledButton.icon(
                    icon: const Icon(Icons.price_check_outlined),
                    label: const Text("Confirm Payment"),
                    onPressed: () {
                      // get the most recent payment method that the borrower used
                      // to pay an instalment
                      _paymentMethodDetail = _userCurrentLoan!.latestInstalment == null
                          ? ''
                          : _userCurrentLoan!.latestInstalment!.source['detail'];

                      showDialog(
                        context: context,
                        builder: (_) {
                          return AlertDialog(
                            title: const Text("Confirm Payment"),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text("No")
                              ),
                              TextButton(
                                onPressed: () {
                                  if(_amountSent == null) {
                                    context.toast("Invalid amount");
                                    return;
                                  }
                                  if(_amountSent! < _userCurrentLoan!.nextInstalment) {
                                    context.toast("Amount should be AT LEAST KSH ${_userCurrentLoan!.nextInstalmentStr}");
                                    return;
                                  }

                                  if(_paymentMethodDetailInvalid) {
                                    context.toast("Invalid M-PESA Number");
                                    return;
                                  }

                                  confirmInstalmentPaid();

                                  Navigator.pop(context);
                                },
                                child: const Text("Done")
                              )
                            ],
                            content: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomTextField(
                                    hint: "Enter amount sent",
                                    inputType: TextInputType.number,
                                    onTextChanged: (amount) {
                                      _amountSent = int.tryParse(amount);
                                    },
                                  ),
                                  Text(
                                    "At least KSH ${_userCurrentLoan!.nextInstalmentStr}",
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey.shade700
                                    ),
                                  ),
                                  const SizedBox(height: 20,),
                                  const Text("Enter M-PESA Number that you sent the money from",),
                                  const SizedBox(height: 6,),
                                  CustomTextField(
                                    hint: "M-PESA Number: 07...",
                                    text: _paymentMethodDetail,
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
                  )
              ],
            )
        ),
      )
    );
  }

  Widget get discoveringView {
    return ListView(
      children: [
        const SizedBox(height: 100,),
        Icon(
          _fetching
            ? Icons.content_paste_search_outlined
            : (_errorFetching ? Icons.cloud_off : Icons.pending_actions_outlined),
          size: 54,
        ),
        const SizedBox(height: 40,),
        Text(
          _fetching
            ? "Loading your current loans..."
            : (
            _errorFetching
              ? "Failed to load.\n\nPlease check your internet connection and refresh..."
              : "You currently don't have any loan.\n\nDo you want to apply for a loan?"
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40,),

        if(_fetching)
          const LinearProgressIndicator(),

        if(_errorFetching)
          FilledButton(
            onPressed: loadUpdates,
            child: const Text("Refresh"),
          ),

        if(!_fetching && !_errorFetching)
          FilledButton(
            onPressed: () {
              Provider.of<StateMan>(context, listen: false)
                .toggleHomeTab(1, leLoTab: 0);
            },
            child: const Text("Apply for a Loan"),
          )
      ],
      // ),
    );
  }

  Widget get updatesView {

    return ListView(
      children: [
        _progressView,

        if(_userCurrentLoan!.totalDebt > 0)
          ...[
            const SizedBox(height: 20,),
            Text("Pay an Instalment", style: theme.textTheme.displayMedium,),
            const SizedBox(height: 10,),
            RichText(
                text: TextSpan(
                    children: [
                      TextSpan(
                          text: "AMOUNT TO PAY\n",
                          style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white)
                      ),
                      TextSpan(
                          text: "KSH ${_userCurrentLoan!.nextInstalmentStr}",
                          style: theme.textTheme.displaySmall
                      )
                    ]
                )
            ),
            const SizedBox(height: 20,),
            Text(
                "PAYMENT DETAILS",
                style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white)
            ),
            // const SizedBox(height: 10,),
            Text("Method: ${_userCurrentLoan!.bid.source!['method']}", style: theme.textTheme.displaySmall,),
            Text("Send To: ${_userCurrentLoan!.bid.source!['detail']}", style: theme.textTheme.displaySmall,),

            const SizedBox(height: 20,),

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline, color: Colors.white,),
                const SizedBox(width: 6,),
                Text(
                    "INSTRUCTIONS",
                    style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white)
                ),
              ],
            ),
            const SizedBox(height: 6,),
            RichText(
              text: TextSpan(
                  children: [
                    TextSpan(
                        text: "1. Go to the M-PESA menu on your device\n2. Pay ", style: theme.textTheme.bodyMedium
                    ),
                    TextSpan(
                        text: "AT LEAST KSH ${_userCurrentLoan!.nextInstalmentStr} ",
                        style: darkTextTheme.bodyLarge
                    ),
                    TextSpan(
                        text: "directly to the lender using the Payment Details above\n",
                        style: theme.textTheme.bodyMedium
                    ),
                    TextSpan(
                        text: "No penalties for paying more to completing your loan earlier\n\n",
                        style: darkTextTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: Colors.grey.shade700)
                    ),
                    TextSpan(
                        text: "3. Click the button below to confirm the transaction",
                        style: theme.textTheme.bodyMedium
                    )
                  ]
              ),
            )
          ]
      ],
    );
  }

  Widget get _progressView {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "TOTAL PAID\n",
                      style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white)
                    ),
                    TextSpan(
                      text: "KSH ${DataConverter.moneyToStr(_userCurrentLoan!.totalPaid)}",
                      style: theme.textTheme.displaySmall
                    )
                  ]
                )
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "\nDEBT LEFT\n",
                      style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white)
                    ),
                    TextSpan(
                      text: "KSH ${DataConverter.moneyToStr(_userCurrentLoan!.totalDebt)}\n",
                      style: theme.textTheme.displaySmall
                    )
                  ]
                )
              ),
              if(_userCurrentLoan!.loanDeadlinePassed)
                const Icon(Icons.warning_sharp, color: Colors.red,),
              Text(
                _userCurrentLoan!.loanDeadlinePassed ? "LOAN OVERDUE" : "NEXT PAYMENT DUE",
                style: theme.textTheme.headlineMedium?.copyWith(color: _userCurrentLoan!.loanDeadlinePassed ? Colors.red : Colors.white)
              ),
              Text(
                "${DateFormat.yMMMEd().format(_userCurrentLoan!.nextInstalmentDueDate)}\n"
                    "at ${_userCurrentLoan!.nextInstalmentDueTime.format(context)}",
                style: theme.textTheme.bodyLarge
              ),
              Text("(${_userCurrentLoan!.nextInstalmentDueStr})", style: TextStyle(color: Colors.grey.shade700),)
            ],
          )
        ),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: CircularPercentIndicator(
              radius: 80.0,
              lineWidth: 28.0,
              animation: true,
              percent: _userCurrentLoan!.fractionComplete,
              center: Text(
                "${_userCurrentLoan!.percentComplete} %",
                style: theme.textTheme.headlineLarge,
              ),
              header: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  "My Payment Progress",
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              footer: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  children: [
                    Text("Instalments Paid: ${_userCurrentLoan!.instalments.length}", style: const TextStyle(fontWeight: FontWeight.bold),),
                    if(_userCurrentLoan!.instalments.isNotEmpty)
                      FilledButton(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateColor.resolveWith((states) => Colors.black.withOpacity(0.25)),
                          foregroundColor: MaterialStateColor.resolveWith((states) => Colors.black),
                        ),
                        onPressed: () {
                          //todo view instalments
                        },
                        child: const Text("View Instalments"),
                      ),
                  ],
                ),
              ),
              circularStrokeCap: CircularStrokeCap.butt,
              progressColor: Colors.black,
              backgroundColor: Colors.black.withOpacity(0.25),
              animationDuration: 2000,
              curve: Curves.easeInOutCirc,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> loadUpdates() async {
    if(appUser == null || _fetching) return;

    setState(() {
      _fetching = true;
      _errorFetching = false;
    });

    final currentLoan = await Api.getInstance().getUserCurrentLoan(appUser!);

    _fetching = false;

    if(currentLoan.exists) {
      if(currentLoan.data is Lo) {
        _userCurrentLoan = currentLoan.data as Lo;
      }
    } else {
      _errorFetching = true;
    }

    setState(() {});
  }

  Future<void> confirmInstalmentPaid () async {
    setState(() {
      _confirming = true;
    });

    final source = {
      "method": _paymentMethod,
      "detail": _paymentMethodDetail
    };

    Api.getInstance()
      .payInstalment(_userCurrentLoan!, _amountSent!, source)
      .then((response) {
        setState(() {
          _confirming = false;
        });

        if(response.exists) {
          context.toast("Instalment paid");

          Provider.of<FinManager>(context, listen: false).clearData();
          Provider.of<StateMan>(context, listen: false).toggleHomeTab(2);
        } else {
          context.toast(response.errorMsg);
        }
    });
  }

  UserProfile? get appUser => UserProfile.fromCache();
}
