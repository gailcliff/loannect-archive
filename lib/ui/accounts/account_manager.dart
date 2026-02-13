
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loannect/api/api.dart';
import 'package:loannect/app_theme.dart' as app_theme;
import 'package:loannect/dat/UserProfile.dart';
import 'package:loannect/state/app_router.dart';
import 'package:loannect/dat/gender.dart';
import 'package:loannect/ui/accounts/personal_info.dart';


class Welcome extends StatefulWidget {
  final bool autoPop;

  const Welcome({super.key, this.autoPop = false});

  @override
  State<Welcome> createState() => _WelcomeState();
}

//todo user has to set a pin while signing up
//todo while logging in use phone number (verify), country and pin

class _WelcomeState extends State<Welcome> {

  String _fullName = '';
  String _country = 'KE';
  String _phone = '';

  bool _passedStepOne = false;

  DateTime? _dob;
  Gender? _gender;
  String _email='';

  bool get isProfile1Valid => _fullName.isNotEmpty && _phone.isNotEmpty && int.tryParse(_phone) != null;
  bool get isProfile2Valid
        => _dob != null
          && _gender != null
          && (_email.isEmpty ? true : EmailValidator.validate(_email));

  Api get api => Api.getInstance();

  bool _fetching = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: app_theme.COLOR_PRIMARY,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: app_theme.COLOR_PRIMARY,
        title: const Text("ME, MYSELF AND I"),
        titleTextStyle: GoogleFonts.bungeeShade(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.black)
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: ListView(
            // mainAxisAlignment: MainAxisAlignment.center,
            shrinkWrap: true,
            children: [
              const Icon(Icons.self_improvement, size: 52, color: Colors.white,),
              Text(
                !_passedStepOne ? "Hello there!" : "Almost there...",
                style: app_theme.lightTextTheme.displayLarge,
                textAlign: TextAlign.center,
              ),
              Text(
                _passedStepOne ? "Complete your Info" : "Start by Creating an Account",
                style: app_theme.lightTextTheme.displaySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40,),

              if (!_passedStepOne) PersonalInfo1(
                  fullName: _fullName,
                  phone: _phone,
                  onNameChanged: (text) => _fullName = text,
                  onPhoneChanged: (text) => _phone = text
              ),
              if(_passedStepOne) PersonalInfo2(
                  dob: _dob,
                  gender: _gender,
                  email: _email,
                  onDobChanged: (dob) {
                    setState(() {
                      _dob = dob;
                    });
                  },
                  onEmailChanged: (email) => _email = email,
                  onGenderChanged: (gender) {
                    setState(() {
                      _gender = gender;
                    });
                  }
              ),

              const SizedBox(height: 40,),

              if(_fetching) const LinearProgressIndicator(),
              if(!_fetching)
                FilledButton(
                  onPressed: () {
                  if(_passedStepOne) {
                    if(isProfile2Valid) {
                      _fetching = !_fetching;

                      //todo register user

                      UserProfile user = UserProfile(
                        _fullName, _country, _phone, _dob!, _gender!,
                        email: _email.isEmpty ? null : _email
                      );

                      api.registerUser(user)
                        .then((response) {
                          setState(() {
                            _fetching = !_fetching;
                          });

                          if(response.exists) {
                            int newUserId = response.data as int;

                            user.id = newUserId;

                            user.cache()
                              .then((_) {
                                context.toast("WELCOME!\nYou created an account successfully...\nAND You're now a Loannecter!");

                                if(widget.autoPop) {
                                  Navigator.pop(context);
                                } else {
                                  context.goTo(
                                    "profile",
                                    queryParameters: {"tab": "myself"}
                                  );
                                }
                            });
                          } else {
                            context.toast(response.errorMsg);
                          }
                      });
                    }

                  } else {
                    //check if info is valid
                    if(isProfile1Valid) {
                      //todo verify phone number and then proceed to the next step
                      _passedStepOne = !_passedStepOne;
                    }
                    //will not proceed if invalid(will highlight errors on ui)
                  }

                  setState(() {});
                },
                  child: Text(_passedStepOne ? "Proceed" : "Create My Free Account")
                ),

                if(!_fetching && !_passedStepOne)
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        const Expanded(child: Divider(color: Colors.black,)),
                        const SizedBox(width: 10,),
                        Text("OR", style: app_theme.darkTextTheme.bodyLarge, textAlign: TextAlign.center,),
                        const SizedBox(width: 10,),
                        const Expanded(child: Divider(color: Colors.black,)),
                      ],
                    ),
                  ),

                if(!_fetching && !_passedStepOne)
                  FilledButton(
                    onPressed: () {
                      //todo log user in (follow the login policy)
                    },
                    child: const Text("Log In")
                  )
            ],
          ),
        ),
      ),
    );
  }
}