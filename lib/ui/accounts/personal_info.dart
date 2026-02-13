
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:loannect/ui/custom/ui.dart';
import 'package:loannect/dat/gender.dart';

class PersonalInfo1 extends StatefulWidget {
  final String fullName;
  final String phone;
  final bool editable;
  //add country in future version

  final Function(String)? onNameChanged;
  final Function(String)? onPhoneChanged;

  const PersonalInfo1({
    super.key,
    this.fullName='',
    this.phone='',
    this.editable=true,
    this.onNameChanged,
    this.onPhoneChanged
  });

  @override
  State<PersonalInfo1> createState() => _PersonalInfo1State();
}

class _PersonalInfo1State extends State<PersonalInfo1> {
  PersonalInfo1 get parent => widget;

  bool get nameInvalid => parent.fullName.isEmpty;
  bool get phoneInvalid => parent.phone.isEmpty || int.tryParse(parent.phone) == null;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomTextField(
            locked: !parent.editable,
            text: parent.fullName,
            decorColor: nameInvalid ? Colors.red : null,
            hint: "Full name",
            onTextChanged: parent.onNameChanged,
            prefix: const Icon(Icons.perm_identity_outlined),
            suffix: nameInvalid ? FORM_ERROR_ICON : null
        ),
        const Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 15,),
              Text("  Your name exactly as it appears in your ID",
                  style: TextStyle(fontSize: 12)
              )
            ]
        ),
        const SizedBox(height: 20,),
        CustomTextField(
          locked: true,
          hint: "Country",
          prefix: const Icon(Icons.emoji_flags_outlined),
          text: "Kenya",
          onFocused: () => notifyCountryAvailability(context),
          onTextChanged: (_) {},
        ),
        const SizedBox(height: 20,),
        const Divider(height: 0.5, color: Colors.white54,),
        const SizedBox(height: 10,),
        Row(
          children: [
            const Text("+254", style: TextStyle(fontWeight: FontWeight.bold),),
            const SizedBox(width: 5,),
            Expanded(
              child: CustomTextField(
                hint: "Phone number",
                text: parent.phone,
                inputType: TextInputType.number,
                onTextChanged: parent.onPhoneChanged,
                decorColor: phoneInvalid ? Colors.red : null,
                suffix: phoneInvalid ? FORM_ERROR_ICON : null,
              ),
            )
          ],
        ),
      ],
    );
  }

  void notifyCountryAvailability (BuildContext context) {
    //todo tell user only available in Kenya. Add their email to waitlist to get notified once available

    showDialog(
      context: context,
      builder: (context) {
        String waitlistCountry = '';
        return AlertDialog(
          title: const Text("Availability"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                const Text("Currently, we're only available in Kenya. If you're not in Kenya, please add your email to our waitlist "
                    "so that we can notify you immediately we launch in your country!"),
                const SizedBox(height: 20,),
                CustomTextField(
                  hint: "Country",
                  onTextChanged: (text) {

                  },
                ),
                const SizedBox(height: 10,),
                CustomTextField(
                  hint: "Email",
                  onTextChanged: (text) {

                  },
                )
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: context.pop,
                child: const Text("No, I'm in Kenya")
            ),
            TextButton(
                onPressed: () {

                },
                child: const Text("Waitlist")
            ),
          ],
        );
      }
    );
  }
}

class PersonalInfo2 extends StatefulWidget {
  final DateTime? dob;
  final Gender? gender;
  final String email;

  final bool editable;

  final Function(DateTime)? onDobChanged;
  final Function(String)? onEmailChanged;
  final Function(Gender)? onGenderChanged;

  const PersonalInfo2({
    super.key,
    this.dob,
    this.gender,
    this.email = '',
    this.editable = true,
    this.onDobChanged,
    this.onEmailChanged,
    this.onGenderChanged
  });

  @override
  State<StatefulWidget> createState() => _PersonalInfo2State();
}

class _PersonalInfo2State extends State<PersonalInfo2>{

  PersonalInfo2 get parent => widget;

  bool get dobInvalid => parent.dob == null;
  bool get genderInvalid => parent.gender == null;
  bool get emailInvalid => (parent.email.isEmpty ? false : !EmailValidator.validate(parent.email));

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomTextField(
          hint: "Date of Birth",
          text: parent.dob != null ? DateFormat.yMMMMd().format(parent.dob!) : '',
          locked: true,
          onTextChanged: (_) { },
          prefix: const Icon(Icons.calendar_month_outlined),
          suffix: dobInvalid ? FORM_ERROR_ICON : null,
          decorColor: dobInvalid ? Colors.red : null,
          onFocused: !parent.editable ? null : () async {
            final dob = await showDatePicker(
              context: context,
              initialDate: parent.dob ?? DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now()
            );

            if(dob != null) {
              parent.onDobChanged?.call(dob);
            }
          },
        ),
        const SizedBox(height: 10,),
        Card(
          child: ListTile(
            title: const Text("Gender"),
            subtitle: Text(parent.gender == null ? "Select your gender identity" : parent.gender!.name),
            contentPadding: const EdgeInsets.only(left: 10),
            trailing: !parent.editable ? null : PopupMenuButton<Gender>(
              surfaceTintColor: Colors.white,
              tooltip: "Gender",
              icon: Icon(
                Icons.arrow_drop_down_circle_outlined,
                color: genderInvalid ? Colors.red : null,
              ),
              itemBuilder: (context) {
                return List.generate(
                  3,
                    (index) {
                    return PopupMenuItem(
                      value: Gender.values[index],
                      child: ListTile(
                        title: Text(Gender.values[index].name),
                      )
                    );
                  },
                growable: false
                );
              },
              onSelected: (gender) {
                parent.onGenderChanged?.call(gender);
              },
            ),
          ),
        ),
        const SizedBox(height: 20,),
        const Divider(height: 0.5, color: Colors.white54,),
        const SizedBox(height: 10,),
        CustomTextField(
          hint: "Email (Optional, but recommended)",
          text: parent.email,
          inputType: TextInputType.emailAddress,
          onTextChanged: parent.onEmailChanged,
          decorColor: emailInvalid ? Colors.red : null,
          prefix: const Icon(Icons.email_outlined),
          suffix: emailInvalid ? FORM_ERROR_ICON : null,
        ),
      ],
    );
  }
}

