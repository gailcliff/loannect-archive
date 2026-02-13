
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:loannect/api/api.dart';
import 'package:loannect/app_theme.dart' as app_theme;
import 'package:loannect/dat/LoPreRequisites.dart';
import 'package:loannect/dat/UserProfile.dart';
import 'package:loannect/dat/data_converter.dart';
import 'package:loannect/state/app_router.dart';
import 'package:loannect/state/state_man.dart';
import 'package:provider/provider.dart';


class LeLo extends StatefulWidget {

  static List<String>? LO_TAGS;

  const LeLo({super.key});

  @override
  State<LeLo> createState() => _LeLoState();
}

class _LeLoState extends State<LeLo> {

  String _moneyStr = "";

  bool _fetching = false;


  @override
  Widget build(mainContext) {

    return DefaultTabController(
      initialIndex: 0,
      length: 2,
      child: Consumer<StateMan>(
        builder: (context, manager, child) {
          int tab = manager.leLoTab;
          final decorColor = tab == 0 ? Colors.blue : Colors.green;

          Future.delayed(
            Duration.zero,
            () {
              DefaultTabController.of(context).animateTo(tab);
          });

          return ListView(
            primary: true,
            children: [
              const SizedBox(height: 10,),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Card(
                      surfaceTintColor: Colors.black,
                      color: Colors.black,
                      child: ListTile(
                        title: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.receipt_long_outlined, color: Colors.white,),
                            SizedBox(height: 10,),
                            Text("My Transactions", style: TextStyle(color: Colors.white),),
                          ],
                        ),
                        subtitle: const Text("View lent money, loans, and repayments", style: TextStyle(color: Colors.white),),
                        // trailing: const Icon(Icons.navigate_next, color: Colors.white,),
                        contentPadding: const EdgeInsets.only(left: 8),
                        onTap: () {
                          //todo show transaction history
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10,),
                  Expanded(
                    child: Card(
                      child: ListTile(
                        title: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.bolt_outlined, color: Colors.blue,),
                            Text("Repay my Loan"),
                          ],
                        ),
                        subtitle: const Text("Pay instalments of a loan to clear my debt"),
                        // trailing: const Icon(Icons.navigate_next, color: Colors.white,),
                        contentPadding: const EdgeInsets.only(left: 8),
                        onTap: () {
                          context.goTo("repay_lo");
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30,),
              Text("Loan & Lend", style: app_theme.lightTextTheme.displayLarge,),
              TabBar(
                indicatorColor: app_theme.COLOR_PRIMARY,
                labelColor: app_theme.COLOR_PRIMARY,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: "Loan"),
                  Tab(text: "Lend"),
                ],
                onTap: (int tab) {
                  manager.toggleLeLoTab(tab);
                },
              ),
              if(_moneyStr.isNotEmpty) Divider(color: decorColor.shade200),
              if(_moneyStr.isNotEmpty)
                Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Text(
                      "KSH ${DataConverter.moneyToStr(int.tryParse(_moneyStr) ?? 0)}",
                      textAlign: TextAlign.center,
                      style: app_theme.lightTextTheme.displaySmall?.copyWith(color: decorColor),
                    )
                ),
              Builder(
                builder: (context) {
                  final gridKids = List<String>.generate(12, (index) => (index == 10 ? 0 : index + 1).toString(), growable: false);

                  return GridView.builder(
                    primary: false,
                    itemCount: gridKids.length,
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                      mainAxisExtent: 88
                    ),
                    itemBuilder: (context, pos) {
                      final gridKid =
                      pos == 9
                        ? const Icon(Icons.replay)
                        : (
                        pos == 11
                          ? const Icon(Icons.backspace_outlined)
                          : Text(
                            gridKids[pos],
                            style: app_theme.darkTextTheme.displayMedium?.copyWith(color: decorColor)
                          )
                      );

                      var borderRadius = BorderRadius.zero;

                      switch(pos) {
                        case 0:
                          borderRadius = const BorderRadius.only(topLeft: Radius.circular(20));
                          break;
                        case 2:
                          borderRadius = const BorderRadius.only(topRight: Radius.circular(20));
                          break;
                        case 9:
                          borderRadius = const BorderRadius.only(bottomLeft: Radius.circular(20));
                          break;
                        case 11:
                          borderRadius = const BorderRadius.only(bottomRight: Radius.circular(20));
                          break;
                        default: break;
                      }

                      return FilledButton(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateColor.resolveWith((states) => decorColor.withOpacity(0.25)),
                          // backgroundColor: MaterialStateColor.resolveWith((states) => decorColor.shade100),
                          shape: MaterialStateProperty.resolveWith((states) {
                            return RoundedRectangleBorder(
                                borderRadius: borderRadius
                            );
                          })
                        ),
                        onPressed: () {
                          if(pos == 10 && _moneyStr.isEmpty) return;

                          setState(() {
                            if(pos == 9) {
                              _moneyStr = '';
                            } else if(pos == 11) {
                              _moneyStr = _moneyStr.substring(0, _moneyStr.length - 1);
                            } else {
                              _moneyStr = _moneyStr + gridKids[pos];
                            }
                          });
                        },
                        child: gridKid
                      );
                      // return Ink(
                      //     color: _tab == 0 ? gridColor.withOpacity(0.2) : gridColor.withOpacity(0.2),
                      //     child: InkWell(
                      //       splashColor: gridColor,
                      //       child: Center(
                      //           child: gridKid
                      //       ),
                      //       onTap: () {
                      //         //todo update amounts
                      //       },
                      //     )
                      // );
                    }
                  );
                },
              ),
              const SizedBox(height: 10,),

              if(_fetching) const LinearProgressIndicator(),

              if(!_fetching)
                FilledButton(
                  onPressed: () {
                    int? money = int.tryParse(_moneyStr);

                    if(money != null && money >= 50) {
                      //check if user is signed up and verified
                      //if not, they have to sign up first and verify
                      //if they have, first load interest rate and then go to lo_preamble
                      // where loan request is sent to server after they fill questionnaire

                      if(UserProfile.isUserRegistered) {
                        UserProfile user = UserProfile.fromCache()!;

                        // user wants a loan
                        if(tab == 0) {
                          _fetching = true;

                          Api.getInstance()
                              .getLoPreRequisites(user, money, getTags: LeLo.LO_TAGS == null)
                              .then((response) {
                            setState(() {
                              _fetching = false;
                            });

                            if(response.exists) {
                              LoPreRequisites preRequisites = response.data as LoPreRequisites;

                              preRequisites.userId = user.id;

                              if(preRequisites.verified) {

                                if(!preRequisites.eligible) {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: const Text("Not currently eligible"),
                                        content: Text(preRequisites.info!),
                                        actions: [
                                          TextButton(
                                              onPressed: context.pop,
                                              child: const Text("Okay")
                                          )
                                        ],
                                      );
                                    }
                                  );

                                  return; //don't proceed if not eligible
                                }

                                if(preRequisites.loTags != null) {
                                  LeLo.LO_TAGS ??= preRequisites.loTags; //keep a copy of the tags, only load from server if they haven't been cached
                                }

                                context.goTo(
                                  'lo_preamble',
                                  pathParameters: {
                                    'amt': money.toString()
                                  },
                                  extra: preRequisites
                                );
                              } else {
                                //user is not verified. go the verification screen
                                context.goTo(
                                  "profile",
                                  queryParameters: {
                                    "tab": "myself"
                                  }
                                );
                              }

                            } else {
                              context.toast(response.errorMsg);
                            }
                          });
                        } else {
                          //go to the lending flow
                        }
                      } else {
                        //user is not signed up
                        context.goTo("welcome");
                      }

                      setState(() {});
                    } else {
                      //tell user to enter amount
                      context.toast("Please enter amount (minimum is 50)");
                    }
                  },
                  child: Builder(
                    builder: (context) {
                      final moneyDisplayStr = DataConverter.moneyToStr(int.tryParse(_moneyStr) ?? 0);
                      final btnText = _moneyStr.isEmpty
                          ? (tab == 1 ? "Lend Money" : "Get Loan")
                          : (tab == 1 ? "Lend KSH $moneyDisplayStr" : "Get KSH $moneyDisplayStr Loan");

                      return Text(btnText);
                    },
                  ),
                ),
              if(!_fetching && tab == 1)
                Text("OR", style: app_theme.lightTextTheme.bodyLarge,textAlign: TextAlign.center,),

              if(!_fetching)
                TextButton(
                  style: ButtonStyle(
                      backgroundColor: MaterialStateColor.resolveWith((states) => Colors.black.withOpacity(0.1))
                  ),
                  onPressed: () {
                    if(tab == 0) {
                      //todo get loan limit from server
                    } else {
                      //view loan requests feed
                      Provider.of<StateMan>(context, listen: false).toggleHomeTab(0);
                    }
                  },
                  child: Text(
                    tab == 0 ? "Check my Loan Limit" : "Browse Lend Requests",
                    style: const TextStyle(fontSize: 12),
                  )
                )
            ],
          );
        }
      )
    );
  }
}
//todo do rate limiting for loan applications. a person can't make as many loan applications as they want
//limit it to maybe 3 times in 7 days. e.g they can't just delete their pending loan application and make another
//one