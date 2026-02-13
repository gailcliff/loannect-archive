import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loannect/dat/data_converter.dart';
import 'package:loannect/state/app_router.dart';
import 'package:loannect/state/fin_manager.dart';
import 'package:loannect/state/state_man.dart';
import 'package:loannect/ui/fin/instalments_detail.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:loannect/app_theme.dart';


//todo include last paid date

class Finances extends StatefulWidget {
  const Finances({super.key});

  @override
  State<Finances> createState() => _FinancesState();
}

class _FinancesState extends State<Finances> {

  FinManager get financeManager => Provider.of<FinManager>(context, listen: false);

  Future<void> fetchFinances () async {
    if(financeManager.discovering) return;

    financeManager.fetchFinances()
      .then((fetched) {
        if(!fetched) {
          context.toast("Please check your internet connection and try again...");
        }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: fetchFinances,
      child: Consumer<FinManager>(
        builder: (context, FinManager manager, child) {
          if(manager.discovering) {
            return const Center(
              // height: 100,
              // alignment: Alignment.bottomCenter,
              child: CircularProgressIndicator(),
            );
          }

          if(manager.dataIsNull) {
            //if the fetch wasn't successful or it returned an empty list
            //reuse code for both conditions to give user appropriate update.
            //if cache is null it means fetch wasn't successful
            return ListView(
              children: [
                const SizedBox(height: 100,),
                const Icon(
                  Icons.cloud_off,
                  size: 54,
                  color: Colors.grey,
                ),
                const SizedBox(height: 20,),
                Text(
                  "Failed to load.\n\nPlease check your internet connection and swipe down to refresh...",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
                )
              ],
            );
          }
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              if(!manager.hasNeitherLoansNorLendOuts)
                Text(
                  "Pull to refresh",
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                  textAlign: TextAlign.end
                ),

              Text("My Current Loan", style: theme.textTheme.displayLarge,),

              if(!manager.hasLoans)
                ...[
                  const SizedBox(height: 20,),
                  Text(
                    "You currently don't have any loans.\nDo you want to apply for one?\n\n",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),

                  FilledButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateColor.resolveWith((states) => Colors.blue.withOpacity(0.25)),
                      foregroundColor: MaterialStateColor.resolveWith((states) => Colors.blue),
                    ),
                    onPressed: () {
                      Provider.of<StateMan>(context, listen: false).toggleHomeTab(1, leLoTab: 0);
                    },
                    child: const Text("Request a Loan")
                  )
                ]
              else ...[
                const SizedBox(height: 10,),
                _currentLoanLayout
              ],

              const SizedBox(height: 20),
              Text("My Current Lend-Outs", style: theme.textTheme.displayLarge,),

              if(!manager.hasLendOuts)
                ...[
                  const SizedBox(height: 20,),
                  Text(
                    "You currently haven't lent money to borrowers.\nDo you want to lend?\n\n",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),

                  FilledButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateColor.resolveWith((states) => Colors.green.withOpacity(0.25)),
                        foregroundColor: MaterialStateColor.resolveWith((states) => Colors.green),
                      ),
                      onPressed: () {
                        Provider.of<StateMan>(context, listen: false).toggleHomeTab(1, leLoTab: 1);
                      },
                      child: const Text("Lend Money")
                  )
                ]
              else ...[
                const SizedBox(height: 10,),
                _currentLendOutsLayout
              ],
              // const SizedBox(height: 20),
              // Text("Transaction History", style: theme.textTheme.displayLarge,)
            ],
          );
        },
      ),
    );
  }

  Widget get _currentLoanLayout {
    final currentLoan = financeManager.userCurrentLoans![0];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
                          style: theme.textTheme.headlineMedium?.copyWith(color: Colors.grey.shade700)
                        ),
                        TextSpan(
                          text: "KSH ${DataConverter.moneyToStr(currentLoan.totalPaid)}",
                          style: theme.textTheme.displaySmall
                        )
                      ]
                    )
                  ),
                  if(currentLoan.hasDefaults)
                  //means the user has defaulted
                    ...[
                      const Icon(Icons.warning_sharp, color: Colors.red, size: 18,),
                      Text(
                        "You have defaulted on payment",
                        style: theme.textTheme.bodySmall?.copyWith(backgroundColor: Colors.red, color: Colors.white),
                      ),
                    ],
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "\nDEBT LEFT\n",
                          style: theme.textTheme.headlineMedium?.copyWith(color: Colors.grey.shade700)
                        ),
                        TextSpan(
                          text: "KSH ${DataConverter.moneyToStr(currentLoan.totalDebt)}\n",
                          style: theme.textTheme.displaySmall
                        )
                      ]
                    )
                  ),
                  if(currentLoan.loanDeadlinePassed)
                    const Icon(Icons.warning_sharp, color: Colors.red,),
                  Text(
                    currentLoan.loanDeadlinePassed ? "LOAN OVERDUE" : "NEXT PAYMENT DUE",
                    style: theme.textTheme.headlineMedium?.copyWith(color: currentLoan.loanDeadlinePassed ? Colors.red : Colors.grey.shade700)
                  ),
                  Text(
                    "${DateFormat.yMMMEd().format(currentLoan.nextInstalmentDueDate)}\n"
                      "at ${currentLoan.nextInstalmentDueTime.format(context)}",
                    style: theme.textTheme.bodyLarge
                  ),
                  Text("(${currentLoan.nextInstalmentDueStr})", style: TextStyle(color: Colors.grey.shade700),)

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
                  percent: currentLoan.fractionComplete,
                  center: Text(
                    "${currentLoan.percentComplete} %",
                    style: theme.textTheme.headlineLarge,
                  ),
                  header: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      "My Payment Progress",
                      style: theme.textTheme.bodyLarge?.copyWith(color: Colors.blue),
                    ),
                  ),
                  footer: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Column(
                      children: [
                        Text("Instalments Paid: ${currentLoan.instalments.length}", style: const TextStyle(fontWeight: FontWeight.bold),),

                        if(currentLoan.numConfirmedInstalments < currentLoan.numInstalments)
                          Text(
                            "Pending confirmation: ${currentLoan.numUnconfirmedInstalments}",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                          ),

                        if(currentLoan.instalments.isNotEmpty)
                          FilledButton(
                            style: ButtonStyle(
                              backgroundColor: MaterialStateColor.resolveWith((states) => Colors.blue.withOpacity(0.25)),
                              foregroundColor: MaterialStateColor.resolveWith((states) => Colors.blue),
                            ),
                            onPressed: () {
                              viewInstalments(currentLoan.instalments);
                            },
                            child: const Text("View Instalments"),
                          ),
                      ],
                    ),
                  ),
                  circularStrokeCap: CircularStrokeCap.butt,
                  progressColor: Colors.blueAccent,
                  backgroundColor: Colors.red.withOpacity(0.5),
                  animationDuration: 2000,
                  curve: Curves.easeInOutCirc,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20,),
        Text(
          "Loan Info",
          style: theme.textTheme.headlineLarge,
        ),
        // const SizedBox(height: 4,),
        Card(
          color: Colors.white,
          margin: const EdgeInsets.all(2),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Loan Amount: ", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("KSH ${currentLoan.proposal.amountStr}")
                  ]
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total Repayment: ", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("KSH ${currentLoan.paybackStr}")
                  ]
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Weekly Payment: ", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("KSH ${currentLoan.weeklyInstalmentStr}")
                  ]
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Repayment Term: ", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(currentLoan.proposal.termStr)
                  ]
                ),

                const SizedBox(height: 6,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Loan Purpose: ", style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        currentLoan.proposal.purpose,
                        style: TextStyle(color: Colors.grey.shade700),
                        textAlign: TextAlign.end,
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      )
                    )
                  ]
                ),

                const SizedBox(height: 10,),
                const Divider(),
                const SizedBox(height: 6,),

                Text(
                  "Loan Received on: ${DateFormat.yMMMEd().format(currentLoan.initiatedOn!)} "
                    "at ${
                    TimeOfDay(
                      hour: currentLoan.initiatedOn!.hour,
                      minute: currentLoan.initiatedOn!.minute
                    ).format(context)} "
                      "(${currentLoan.initiatedTimeAgo})",
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700,)// fontStyle: FontStyle.italic),
                ),
                Text(
                  "Payment to be completed by: ${
                    DateFormat.yMMMEd().format(currentLoan.initiatedOn!
                      .add(Duration(days: currentLoan.proposal.term * 4 * 7))
                    )} "
                    "at ${
                    TimeOfDay(
                      hour: currentLoan.initiatedOn!.hour,
                      minute: currentLoan.initiatedOn!.minute
                  ).format(context)}",
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700,)// fontStyle: FontStyle.italic),
                )
              ],
            ),
          ),
        ),
        const SizedBox(height: 10,),
        Text(
          "Lender",
          style: theme.textTheme.headlineLarge,
        ),
        const SizedBox(height: 4,),
        const Divider(),
        const SizedBox(height: 4,),
        Row(
          children: [
            const Icon(Icons.perm_identity_outlined),
            Text("Name: ", style: theme.textTheme.bodyLarge,),
            Text(currentLoan.bid.bidderInfo!['user_name'])
          ],
        ),
        Row(
          children: [
            const Icon(Icons.emoji_flags_outlined),
            Text("Country: ", style: theme.textTheme.bodyLarge,),
            Text(currentLoan.bid.bidderInfo!['country'])
          ],
        ),
      ],
    );
  }


  Widget get _currentLendOutsLayout {
    return ListView.separated(
      primary: false,
      shrinkWrap: true,
      itemCount: financeManager.userCurrentLendOuts!.length,
      itemBuilder: (context, pos) {
        final currentLendOut = financeManager.userCurrentLendOuts![pos];

        return Ink(
          color: Colors.white,
          child: InkWell(
            child: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 10, right: 10),
              child: Row(
                children: [
                  Container(width: 3, height: 400, color: currentLendOut.proposal.decorColor,),
                  const SizedBox(width: 10,),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Loan: KSH ${currentLendOut.proposal.amountStr}", style: theme.textTheme.displayMedium,),
                        const SizedBox(height: 6,),
                        Container(
                          decoration: BoxDecoration(
                            color: currentLendOut.proposal.decorColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10)
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.generating_tokens_outlined, color: currentLendOut.proposal.decorColor,),
                                  const SizedBox(width: 4,),
                                  Text(
                                    "Total Repayment",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                  Expanded(
                                      child: Text("KSH ${currentLendOut.paybackStr}", textAlign: TextAlign.end,)
                                  )
                                ],
                              ),
                              const SizedBox(height: 4,),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.filter_7_outlined, color: currentLendOut.proposal.decorColor,),
                                  const SizedBox(width: 4,),
                                  Text(
                                    "Weekly Payment",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                  Expanded(
                                      child: Text("KSH ${currentLendOut.weeklyInstalmentStr}", textAlign: TextAlign.end,)
                                  )
                                ],
                              ),
                              const SizedBox(height: 4,),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.calendar_month_outlined, color: currentLendOut.proposal.decorColor,),
                                  const SizedBox(width: 4,),
                                  Text(
                                    "Repayment Term",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                  Expanded(
                                      child: Text(currentLendOut.proposal.termStr, textAlign: TextAlign.end,)
                                  )
                                ],
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.show_chart_outlined, color: currentLendOut.proposal.decorColor,),
                                  const SizedBox(width: 4,),
                                  Text(
                                    "Interest",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                  Expanded(
                                      child: Text("KSH ${currentLendOut.interestStr}", textAlign: TextAlign.end,)
                                  )
                                ],
                              ),
                              const SizedBox(height: 10,),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.perm_identity_outlined, color: currentLendOut.proposal.decorColor,),
                                  const SizedBox(width: 4,),
                                  Text(
                                    "Lent To",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                  Expanded(
                                      child: Text(currentLendOut.proposal.userProfile!['user_name'], textAlign: TextAlign.end,)
                                  )
                                ],
                              ),

                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.schedule_outlined, color: currentLendOut.proposal.decorColor,),
                                  const SizedBox(width: 4,),
                                  Text(
                                    "Lent On",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                  Expanded(
                                    child: Text("${DateFormat.yMMMEd().format(currentLendOut.initiatedOn!)} "
                                        "at ${
                                        TimeOfDay(
                                            hour: currentLendOut.initiatedOn!.hour,
                                            minute: currentLendOut.initiatedOn!.minute
                                        ).format(context)} \n"
                                        "(${currentLendOut.initiatedTimeAgo})",
                                      // style: TextStyle(color: Colors.grey.shade700),
                                      textAlign: TextAlign.end,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.quiz_outlined, color: currentLendOut.proposal.decorColor,),
                                  const SizedBox(width: 4,),
                                  Text(
                                    "Loan For",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                  // const Spacer(),
                                  Expanded(
                                      child: Text(
                                        currentLendOut.proposal.purpose,
                                        textAlign: TextAlign.end,
                                        style: TextStyle(color: Colors.grey.shade700),
                                      )
                                  )
                                ],
                              ),
                              const SizedBox(height: 10,),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.account_balance_wallet_outlined, color: currentLendOut.proposal.decorColor,),
                                  const SizedBox(width: 4,),
                                  Text(
                                    "Get Repaid Via",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                  // const Spacer(),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          "${currentLendOut.bid.source!['method']}\n"
                                          "(${currentLendOut.bid.source!['detail']})",
                                          textAlign: TextAlign.end,
                                        ),
                                        InkWell(
                                          onTap: () {
                                            //todo change source
                                          },
                                          child: const Text(
                                            "Change",
                                            style: TextStyle(decoration: TextDecoration.underline, fontWeight: FontWeight.bold),
                                          ),
                                        )
                                      ]
                                    )
                                  )
                                ],
                              ),

                            ],
                          ),
                        ),
                        // const Divider(),
                        const SizedBox(height: 20,),

                        Row(
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
                                          style: theme.textTheme.headlineMedium?.copyWith(color: Colors.grey.shade700)
                                        ),
                                        TextSpan(
                                          text: "KSH ${DataConverter.moneyToStr(currentLendOut.totalPaid)}",
                                          style: theme.textTheme.displaySmall
                                        )
                                      ]
                                    )
                                  ),
                                  // if(currentLendOut.hasDefaults) //todo should i show or not
                                  // //means the user has defaulted
                                  //   ...[
                                  //     const Icon(Icons.warning_sharp, color: Colors.red, size: 18,),
                                  //     Text(
                                  //       "Borrower has defaulted on payment",
                                  //       style: theme.textTheme.bodySmall?.copyWith(backgroundColor: Colors.red, color: Colors.white),
                                  //     ),
                                  //   ],
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: "\nDEBT LEFT\n",
                                          style: theme.textTheme.headlineMedium?.copyWith(color: Colors.grey.shade700)
                                        ),
                                        TextSpan(
                                          text: "KSH ${DataConverter.moneyToStr(currentLendOut.totalDebt)}\n",
                                          style: theme.textTheme.displaySmall
                                        )
                                      ]
                                    )
                                  ),

                                  if(currentLendOut.loanDeadlinePassed)
                                    const Icon(Icons.warning_sharp, color: Colors.red,),
                                  Text(
                                    currentLendOut.loanDeadlinePassed ? "LOAN OVERDUE" : "NEXT PAYMENT DUE",
                                    style: theme.textTheme.headlineMedium?.copyWith(
                                      color: currentLendOut.loanDeadlinePassed ? Colors.red : Colors.grey.shade700
                                    )
                                  ),
                                  Text(
                                    "${DateFormat.yMMMEd().format(currentLendOut.nextInstalmentDueDate)}\n"
                                    "at ${currentLendOut.nextInstalmentDueTime.format(context)}",
                                    style: theme.textTheme.bodyLarge
                                  ),
                                  Text("(${currentLendOut.nextInstalmentDueStr})", style: TextStyle(color: Colors.grey.shade700),)

                                  // todo show next instalment debt and no of defaults
                                ],
                              )
                            ),
                            Expanded(
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: CircularPercentIndicator(
                                  radius: 70.0,
                                  lineWidth: 28.0,
                                  animation: true,
                                  percent: currentLendOut.fractionComplete,
                                  center: Text(
                                    "${currentLendOut.percentComplete} %",
                                    style: theme.textTheme.headlineMedium,
                                  ),
                                  header: Padding(
                                    padding: const EdgeInsets.only(bottom: 6.0),
                                    child: Text(
                                      "Repayment Progress",
                                      style: theme.textTheme.bodyLarge?.copyWith(color: Colors.green),
                                    ),
                                  ),
                                  footer: Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Column(
                                      children: [
                                        Text("Instalments Paid: ${currentLendOut.instalments.length}", style: const TextStyle(fontWeight: FontWeight.bold),),
                                        if(currentLendOut.instalments.isNotEmpty)
                                          FilledButton(
                                            style: ButtonStyle(
                                              backgroundColor: MaterialStateColor.resolveWith((states) => Colors.green.withOpacity(0.25)),
                                              foregroundColor: MaterialStateColor.resolveWith((states) => Colors.green),
                                            ),
                                            onPressed: () {
                                              viewInstalments(currentLendOut.instalments);
                                            },
                                            child: const Text("View Instalments"),
                                          ),
                                      ],
                                    ),
                                  ),
                                  circularStrokeCap: CircularStrokeCap.butt,
                                  progressColor: Colors.green,
                                  backgroundColor: Colors.red.withOpacity(0.5),
                                  animationDuration: 2000,
                                  curve: Curves.easeInOutCirc,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              )
            ),
          ),
        );
      },
      separatorBuilder: (context, pos) => const Divider(),
    );
  }

  void viewInstalments(final instalments) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) {
          return InstalmentsDetail(instalments: instalments);
      })
    );
  }
}
