
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:loannect/api/api.dart';
import 'package:loannect/dat/LoPreRequisites.dart';
import 'package:loannect/dat/LoProposal.dart';
import 'package:loannect/dat/data_converter.dart';
import 'package:loannect/state/app_router.dart';
import 'package:loannect/ui/custom/custom_textfield.dart';
import 'package:loannect/ui/custom/ui.dart';
import 'package:loannect/ui/lelo/lo/acknowledgment.dart';
import 'package:loannect/ui/lelo/lo/tag_adder.dart';
import 'package:provider/provider.dart';

class Preamble extends StatefulWidget {
  final int amt;
  final LoPreRequisites preRequisites;

  const Preamble(Object preRequisites, {super.key, required this.amt})
      : this.preRequisites = preRequisites as LoPreRequisites;

  @override
  State<Preamble> createState() => _PreambleState();

  String get amtStr {
    return "KSH ${DataConverter.moneyToStr(amt)}";
  }
}

class _PreambleState extends State<Preamble> {

  String _loanPurpose = '';
  String _repaymentPlan = '';

  List<String> _addedTags = [];

  int _term = 3;

  //v1 will only have mpesa. future versions will allow any payment method
  String? _paymentMethod;
  String _paymentMethodDetail = '';

  //in future versions, load this from server
  static final List<String> _SUPPORTED_PAYMENT_METHODS = ['M-PESA'];

  bool _confirmed = false;
  bool _isPreset = false;

  @override
  void initState() {
    if(parent.preRequisites.userId == null) {
      super.initState();

      //this means the user is trying to view details of a loan application that
      //was already made. it is just a preview, no intention of sending anything
      //to the server

      LoProposal preset = parent.preRequisites.preset!;

      _loanPurpose = preset.purpose;
      _addedTags = preset.tags;
      _term = preset.term;
      _repaymentPlan = preset.repaymentPlan;
      _paymentMethod = preset.destination['method'];
      _paymentMethodDetail = preset.destination['detail'];

      _confirmed = true;
      _isPreset = true;
    }
  }

  bool _sent = false;

  bool _fetching = false;

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isPreset ? "Application Info" : (_sent ? "Application Sent!" : "Get Loan")),
      ),
      body: _sent ? const Acknowledgment() :
      SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              "My Loan Amount",
              style: theme.textTheme.displayMedium,
            ),
            const SizedBox(height: 10,),

            if(_confirmed)
              Text(parent.amtStr, style: theme.textTheme.bodyLarge,)
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        parent.amtStr,
                        style: theme.textTheme.displayLarge?.copyWith(
                          color: Colors.blue,
                          backgroundColor: Colors.blue.withOpacity(0.25),
                        ),
                      ),
                      IconButton(
                        onPressed: context.pop,
                        icon: const Icon(Icons.edit_outlined)
                      )
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20,),
            Text(
              "Purpose of Loan",
              style: theme.textTheme.displayMedium,
            ),
            const Text("What do you want to achieve with this loan?"),
            const SizedBox(height: 10,),

            if(_confirmed)
              Text(_loanPurpose, style: theme.textTheme.bodyLarge,)
            else
              CustomTextField(
                hint: "Explain in detail",
                text: _loanPurpose,
                multiline: true,
                maxChars: 1000,
                // suffix: !_confirmed ? ERROR_ICON : null,
                onTextChanged: (text) {
                  _loanPurpose = text;
                },
              ),

            const SizedBox(height: 10,),

            Builder(
              builder: (context) {
                if(_confirmed) {
                  StringBuffer tags = StringBuffer();
                  for(String addedTag in _addedTags) {
                    tags.write("#$addedTag \t");
                  }

                  return Text(tags.toString(), style: TextStyle(color: Colors.grey.shade700, fontStyle: FontStyle.italic),);
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          text: "Add tags ",
                          style: theme.textTheme.bodyMedium,
                          children: const [
                            TextSpan(
                              text: "(at least one)",
                              style: TextStyle(fontStyle: FontStyle.italic)
                            )
                          ]
                        ),
                      ),
                      Wrap(
                        spacing: 10,
                        children: [
                          if(_addedTags.length < 5)
                            FilledButton.icon(
                              label: const Text("Add tag"),
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                //add a tag. maximum is five tags, minimum is one
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    fullscreenDialog: true,
                                    builder: (context) {
                                      return ChangeNotifierProvider(
                                        create: (context) => TagAdderRepo(addedTags: _addedTags),
                                        child: const TagAdder()
                                      );
                                    }
                                )).then((addedTags) {
                                if(addedTags != null) {
                                  setState(() {
                                    _addedTags = addedTags;
                                  });
                                  }
                                });
                              }
                            ),
                            for(String tag in _addedTags)
                              Chip(
                                label: Text(tag),
                                onDeleted: () {
                                  setState(() {
                                    _addedTags.remove(tag);
                                  });
                                },
                              ),
                          ],
                        )
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 10,),
            const Divider(),
            const SizedBox(height: 20,),
            Text("Loan Duration", style: theme.textTheme.displayMedium,),
            const SizedBox(height: 10,),

            if(_confirmed)
              loanDurationSettings
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Adjust to your most comfortable time of repaying the loan in full"),
                      Center(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: _term.toString(),
                                style: theme.textTheme.displayLarge?.copyWith(
                                  color: Colors.blue,
                                )
                              ),
                              TextSpan(text: "    ${_term == 1 ? "month" : "months"}", style: theme.textTheme.bodyLarge)
                            ]
                          ),
                        ),
                      ),
                      Slider(
                        value: _term.toDouble(),
                        min: 0,
                        max: 6,
                        divisions: 6,
                        onChanged: (value) {
                          if(value >= 1) {
                            setState(() {
                              _term = value.toInt();
                            });
                          }
                        },
                      ),

                      loanDurationSettings,
                    ],
                  ),
              ),
            ),

            const SizedBox(height: 20,),
            const Divider(),
            const SizedBox(height: 10,),
            Text("Repayment Plan", style: theme.textTheme.displayMedium,),
            const Text("Through what means will you repay this loan?"),
            const SizedBox(height: 10,),

            if(_confirmed)
              Text(_repaymentPlan, style: theme.textTheme.bodyLarge,)
            else
              CustomTextField(
                hint: "Explain in detail",
                text: _repaymentPlan,
                multiline: true,
                maxChars: 1000,
                // suffix: !_confirmed ? ERROR_ICON : null,
                onTextChanged: (text) {
                  _repaymentPlan = text;
                },
              ),

            const SizedBox(height: 20,),
            Text("Payment Method", style: theme.textTheme.displayMedium,),
            const Text("How do you want to receive the loan money?"),
            const SizedBox(height: 10,),

            if(_confirmed)
              ...[
                Text(_paymentMethod!, style: theme.textTheme.bodyLarge,),
                Text(_paymentMethodDetail)
              ]
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.only(left: 10.0, right: 10, bottom: 20),
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text("Payment method"),
                        subtitle: Text(_paymentMethod ?? "Click arrow to select"),
                        contentPadding: EdgeInsets.zero,
                        trailing: PopupMenuButton<String>(
                          surfaceTintColor: Colors.white,
                          tooltip: "Choose payment method",
                          icon: Icon(
                            Icons.arrow_drop_down_circle_outlined,
                            color: _paymentMethod == null ? Colors.red : null,
                          ),
                          itemBuilder: (context) {
                            return List.generate(
                              _SUPPORTED_PAYMENT_METHODS.length,
                              (index) {
                                return PopupMenuItem<String>(
                                  value: _SUPPORTED_PAYMENT_METHODS[index],
                                  child: ListTile(
                                    title: Text(_SUPPORTED_PAYMENT_METHODS[index]),
                                  )
                              );
                              },
                              growable: false
                            );
                          },
                          onSelected: (paymentMethodName) {
                            setState(() {
                              _paymentMethod = paymentMethodName;
                            });
                          },
                        ),
                      ),
                      CustomTextField(
                        hint: _paymentMethod == "M-PESA" ? "Enter M-PESA Number: 07..." : "Enter Account Number",
                        text: _paymentMethodDetail,
                        fillColor: Colors.grey.shade200,
                        // decorColor: _paymentMethodDetail == null ? Colors.red : null,
                        onTextChanged: (accountNumber) {
                          _paymentMethodDetail = accountNumber;
                        },
                      ),
                    ],
                  ),
                ),
              ),

            if(_confirmed)
              infoSection,

            const SizedBox(height: 40,),

            if(!_isPreset && !_fetching)
              FilledButton(
                child: Text(!_confirmed ? "Proceed" : "Agree and Submit"),
                onPressed: () {
                  if(_fetching) {
                    return; //if already fetching, return
                  }

                  //validate info and confirm
                  if(_loanPurpose.isEmpty || _addedTags.isEmpty || _repaymentPlan.isEmpty
                    || _paymentMethod == null || _paymentMethodDetail.isEmpty
                    || int.tryParse(_paymentMethodDetail) == null
                  ) {
                    context.toast("Please fill in all the required info and check that it is valid");
                  } else {
                    if(!_confirmed) {
                      _confirmed = !_confirmed;
                    } else {
                      //sent lo request to server
                      _fetching = true;

                      LoProposal proposal = LoProposal(
                        parent.amt, _loanPurpose, _addedTags,
                        _term, _repaymentPlan,
                        {
                          "method": _paymentMethod,
                          "detail": _paymentMethodDetail
                        }
                      );

                      Api.getInstance()
                        .proposeLo(parent.preRequisites.userId!, proposal)
                        .then((response) {
                          setState(() {
                            _fetching = false;

                            if(response.exists) {
                              //update the ui with acknowledgment of proposal receipt
                              _sent = true;
                            } else {
                              context.toast(response.errorMsg);
                            }
                          });
                        });
                    }
                  }

                  setState(() {});
                },
              ),

            if(_confirmed && !_isPreset && !_fetching)
              TextButton(
                onPressed: () {
                  setState(() {
                    _confirmed = !_confirmed;
                  });
                },
                child: const Text("Edit")
              ),

            if(_fetching)
              const LinearProgressIndicator()
          ],
        ),
      ),
    );
  }

  Widget get loanDurationSettings {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: "Total time to pay loan: ",
            style: Theme.of(context).textTheme.bodyLarge,
            children: [
              TextSpan(
                  text: "$_term ${_term == 1 ? "month" : "months"}",
                  style: const TextStyle(fontStyle: FontStyle.italic)
              )
            ]
          ),
        ),
        RichText(
          text: TextSpan(
            text: "Daily interest rate: ",
            style: Theme.of(context).textTheme.bodyLarge,
            children: [
              TextSpan(
                  text: "${parent.preRequisites.baseRate.toString()} %",
                  style: const TextStyle(fontStyle: FontStyle.italic)
              )
            ]
          ),
        ),
        RichText(
          text: TextSpan(
            text: "Weekly repayment: ",
            style: Theme.of(context).textTheme.bodyLarge,
            children: [
              TextSpan(
                  text: "KSH ${DataConverter.moneyToStr(parent.preRequisites.instalments!["$_term"] ?? 0)}",
                  style: const TextStyle(fontStyle: FontStyle.italic)
              )
            ]
          ),
        ),
        const SizedBox(height: 10,),
        const Text("Repayments are made in small instalments every 7 days", style: TextStyle(fontStyle: FontStyle.italic),),
      ],
    );
  }

  Widget get infoSection {
    return const Column(
      children: [
        SizedBox(height: 20,),
        Divider(),
        SizedBox(height: 10,),
        Icon(Icons.tips_and_updates_outlined),
        SizedBox(height: 10,),
        Text("Loannect is a platform that connects lenders and borrowers.\n"
            "Anyone can lend or borrow on Loannect. "
            "If you request a loan, someone else just like you on this platform (a lender) lends the money to you.\n"
            "Lender earns from the interest on loans and borrowers gets access to loans at competitive interest rates!"),
        Text("Enjoy!", style: TextStyle(fontWeight: FontWeight.bold),),// style: Theme.of(context).textTheme.bodyLarge,),

        SizedBox(height: 40,),
        Text("Falsifying information on your loan application is a crime. "
          "If you are caught, you could be prosecuted and face serious penalties, including fines, imprisonment, "
          "and being banned from obtaining a loan in the future. "
          "Please be honest and accurate when providing information on your loan application. This will help us connect "
          "you to the loan that is right for you.")
      ],
    );
  }

  Preamble get parent => widget;
}
