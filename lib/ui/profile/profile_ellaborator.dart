import 'package:flutter/material.dart';
import 'package:loannect/state/app_router.dart';
import 'package:loannect/ui/custom/custom_textfield.dart';

enum Ellaboration {
  OCCUPATION,
  INCOME
}

class ProfileElaborator extends StatefulWidget {
  final String title;
  final Map<String, dynamic>? extra;
  final Ellaboration toEllaborate;
  final Function(Map<String, dynamic>) onPopResult;

  const ProfileElaborator({
    super.key,
    required this.title,
    required this.extra,
    required this.toEllaborate,
    required this.onPopResult
  });

  @override
  State<ProfileElaborator> createState() => _ProfileElaboratorState();
}

class _ProfileElaboratorState extends State<ProfileElaborator> {
  ProfileElaborator get parent => widget;

  late Map<String, dynamic> cache;

  @override
  void initState() {
    super.initState();

    cache = parent.extra ?? {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.close)
        ),
        title: Text(parent.title),
        actions: [
          TextButton(
            onPressed: validateAndPopResult,
            child: const Text("OK"),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if(parent.toEllaborate == Ellaboration.OCCUPATION)
            ...occupationWidget,

          if(parent.toEllaborate == Ellaboration.INCOME)
            ...incomeWidget,
          const SizedBox(height: 40,),
          FilledButton(
            onPressed: validateAndPopResult,
            child: const Text("Done")
          )
        ],
      ),
    );
  }

  final occupationTypes = <String>[
    "Full-time",
    "Part-time",
    "Unemployed",
    "Gig",
    "Student",
    "Business owner",
    "Self-employed",
    "Contractor",
    "Freelancer",
    "Volunteer",
    "Retired"
  ];

  List<Widget> get occupationWidget {
    return [
      CustomTextField(
        hint: "What do you do for work?",
        text: cache['job'] ?? '',
        onTextChanged: (job) {
          cache['job'] = job;
        },
      ),
      const SizedBox(height: 20,),
      Card(
        child: ListTile(
          title: const Text("Type of work"),
          subtitle: Text(cache['job_type'] ?? "Select from the menu"),
          contentPadding: const EdgeInsets.only(left: 10),
          trailing: PopupMenuButton<String>(
            surfaceTintColor: Colors.white,
            tooltip: "Type of work",
            icon: const Icon(
              Icons.arrow_drop_down_circle_outlined,
              // color: genderInvalid ? Colors.red : null,
            ),
            itemBuilder: (context) {
              return List.generate(
                occupationTypes.length,
                (index) {
                  return PopupMenuItem<String>(
                    value: occupationTypes[index],
                    child: ListTile(
                      title: Text(occupationTypes[index]),
                    )
                  );
                },
                growable: false
              );
            },
            onSelected: (occupationType) {
              cache['job_type'] = occupationType;

              if(occupationType == 'Unemployed' || occupationType == 'Retired') {
                cache['job'] = 'N/A';
                cache['industry'] = 'N/A';

                validateAndPopResult();
              } else {
                setState(() {});
              }
            },
          ),
        ),
      ),
      const SizedBox(height: 20,),
      const Text("Industry (e.g Transport, Plumbing, Beauty, Health, Catering, Factory, Education, etc)..."),
      const SizedBox(height: 10,),
      CustomTextField(
        hint: "My work is in the ________ industry",
        text: cache['industry'] ?? '',
        onTextChanged: (industry) {
          cache['industry'] = industry;
        },
      )
    ];
  }

  List<Widget> get incomeWidget {
    return [
      CustomTextField(
        hint: "Total earned before expenses",
        text: cache['income'] != null ? cache['income'].toString() : '',
        inputType: TextInputType.number,
        onTextChanged: (income) {
          cache['income'] = int.tryParse(income);
        },
      ),
      const SizedBox(height: 20,),
      const Text("Total spend (food, rent, bills, loans, utilities, household, and other expenses)"),
      const SizedBox(height: 10,),
      CustomTextField(
        hint: "Total spend estimate",
        text: cache['expenses'] != null ? cache['expenses'].toString() : '',
        inputType: TextInputType.number,
        onTextChanged: (expenses) {
          cache['expenses'] = int.tryParse(expenses);
        },
      )
    ];
  }

  void validateAndPopResult() {
    if(valid) {
      parent.onPopResult.call(cache);
      Navigator.pop(context);
    } else {
      context.toast("Info is incomplete or invalid. Please correct and try again");
    }
  }

  bool get valid {
    switch(parent.toEllaborate) {
      case Ellaboration.OCCUPATION:
        return (
          cache['job'] != null && (cache['job'] as String).isNotEmpty
          && cache['job_type'] != null && (cache['job_type'] as String).isNotEmpty
          && cache['industry'] != null && (cache['industry'] as String).isNotEmpty
        );
      case Ellaboration.INCOME:
        return (
          cache['income'] != null && cache['income'] is int
          && cache['expenses'] != null && cache['expenses'] is int
        );
      default:
        return false;
    }
  }
}
