
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loannect/api/api.dart';
import 'package:loannect/app_theme.dart' as app_theme;
import 'package:loannect/dat/UserInsights.dart';
import 'package:loannect/dat/UserProfile.dart';
import 'package:loannect/dat/data_converter.dart';
import 'package:loannect/state/app_router.dart';
import 'package:loannect/ui/custom/ui.dart';
import 'package:loannect/ui/accounts/personal_info.dart';
import 'package:loannect/ui/profile/profile_ellaborator.dart';

class Profile extends StatefulWidget {

  final int referencedTab;

  const Profile({super.key,
    required this.referencedTab
  });

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {

  final zen = Zen.fromTenets();

  UserProfile? _appUser;
  UserInsights? _userInsights;

  bool _tab1Fetching = false, _tab2Fetching = false;

  @override
  void initState() {
    super.initState();
    // appUser = AppCache.loadUser();

    _appUser = UserProfile.fromCache();
    _userInsights = UserInsights.fromCache();
    mapInsightsFromCache();
  }

  Profile get parent => widget;

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: app_theme.COLOR_PRIMARY,
      appBar: AppBar(
        // backgroundColor: app_theme.COLOR_PRIMARY,
        title: const Text("ME, MYSELF AND I"),
        titleTextStyle: GoogleFonts.bungeeShade(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.black)
      ),
      body: DefaultTabController(
        initialIndex: widget.referencedTab,
        length: 3,
        child: SafeArea(
          child: Column(
            // shrinkWrap: true,
            // padding: const EdgeInsets.all(20),
            children: [
              const Icon(Icons.self_improvement, size: 48, color: Colors.white,),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: app_theme.lightTextTheme.bodyMedium,
                  children: [
                    TextSpan(
                      text: zen.tenet1,
                      style: GoogleFonts.bungeeShade(fontSize: 18, fontWeight: FontWeight.w800, )
                    ),
                    TextSpan(text: zen.tenet2),
                    const TextSpan(text: ",  "),
                    TextSpan(
                      text: zen.tenet3,
                        style: GoogleFonts.bungeeShade(fontSize: 18, fontWeight: FontWeight.w800, )
                    ),
                    TextSpan(text: zen.tenet4),
                  ]
                ),
              ),
              const SizedBox(height: 10,),
              const TabBar(
                tabs: [
                  Tab(text: "Me"),
                  Tab(text: "Myself"),
                  Tab(text: "   I   "),
                ]
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: TabBarView(
                    children: [
                      tab1,
                      tab2,
                      tab3
                    ]
                  ),
                ),
              ),

              // const SizedBox(height: 40,),
            ],
          )
        ),
      ),
    );
  }

  Widget get tab1 {
    return ListView(
      children: [
        Text(
          "My Info",
          style: app_theme.lightTextTheme.displayMedium,
        ),

        const SizedBox(height: 10,),
        PersonalInfo1(
          editable: false,
          fullName: _appUser?.fullName ?? '',
          phone: _appUser?.phone ?? '',
          onNameChanged: (name) {},
          onPhoneChanged: (phone) {
            //todo update phone number. verify no. if user clicks update button
          },
        ),
        const SizedBox(height: 20,),
        PersonalInfo2(
          editable: false,
          dob: _appUser?.dob,
          gender: _appUser?.gender,
          email: _appUser?.email ?? '',
          onEmailChanged: (email) {
            //todo update email and verify it
          },
        ),
        const SizedBox(height: 40,),

        if(!_tab1Fetching)
          FilledButton(
            onPressed: () {
              //todo update user info (only phone and email)
            },
            child: const Text("Update My Info")
          ),

        if(_tab1Fetching)
          const LinearProgressIndicator()
      ],
    );
  }


  //todo on initState, load these values from db
  //once provided, national id can't be changed
  //address, occupation, other jobs and income can only be changed once every 30 days
  late String _nationalId;
  late String _address;
  Map<String, dynamic>? _occupationCache;
  late String _otherIncomeSources;
  Map<String, dynamic>? _incomeCache;
  late bool _wasAlreadyVerified;

  void mapInsightsFromCache() {
    _nationalId = _userInsights?.nationalId ?? '';
      //since we're loading details from cache, if it happens that there's already
      //details in the cache, it means the user was already verified, so set the flag
      //to true to disable editing of national id (and any other fields that make sense to make immutable)
      _wasAlreadyVerified = _nationalId.isNotEmpty;
    _address = _userInsights?.address ?? '';
    _occupationCache = _userInsights?.occupationDetails;
    _otherIncomeSources = _userInsights?.otherJobs ?? '';
    _incomeCache = _userInsights?.incomeDetails;
  }


  bool get nationalIdInvalid => //_nationalId.isEmpty ||
          int.tryParse(_nationalId) == null;
  bool get addressInvalid => _address.isEmpty;
  bool get occupationInvalid => _occupationCache == null;
  // bool get otherIncomeSourcesInvalid => _otherIncomeSources.isEmpty;
  bool get incomeInvalid => _incomeCache == null;
  bool get allUserInfoValid => !nationalIdInvalid && !addressInvalid && !occupationInvalid
                               && !incomeInvalid;


  Widget get tab2 {

    return ListView(
      children: [
        if(!_wasAlreadyVerified)
          const Column(  // only show if the user isn't verified
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline),
              Text("Please complete this section",),
            ],
          ),
        Text("Verify Myself", style: app_theme.lightTextTheme.displayMedium,),
        const SizedBox(height: 10,),
        CustomTextField(
          locked: _wasAlreadyVerified,
          hint: "National ID No. (for verification)",
          text: _nationalId,
          prefix: const Icon(Icons.badge_outlined),
          suffix: nationalIdInvalid ? FORM_ERROR_ICON : null,
          inputType: TextInputType.number,
          onTextChanged: (idStr) {
            //not editable, after ID has been set:
            //must provide ID no. (verify) before being allowed to get or provide loans
            _nationalId = idStr;
          },
        ),
        const SizedBox(height: 20,),
        Text("Permanent Residence", style: app_theme.lightTextTheme.displayMedium,),
        const Text("Where do you currently live?"),
        const SizedBox(height: 10,),
        CustomTextField(
          hint: "Address, Area, City, County/State & Country",
          text: _address,
          prefix: const Icon(Icons.home_outlined),
          suffix: addressInvalid ? FORM_ERROR_ICON : null,
          inputType: TextInputType.streetAddress,
          onTextChanged: (addressStr) {
            _address = addressStr;
          },
        ),
        const SizedBox(height: 20,),
        Text("My Work & Income", style: app_theme.lightTextTheme.displayMedium,),
        const SizedBox(height: 10,),
        CustomTextField(
          locked: true,
          hint: "Main occupation?",
          text: () {
            if(_occupationCache != null) {
              String jobType = _occupationCache!['job_type'];

              if (jobType == 'Unemployed' || jobType == 'Retired') {
                return jobType;
              } else {
                return "${_occupationCache!['job']} ($jobType: ${_occupationCache!['industry']})";
              }
            } else {
              return "";
            }
          }(),
          prefix: const Icon(Icons.construction_outlined),
          suffix: occupationInvalid ? FORM_ERROR_ICON : null,
          onTextChanged: (_) {},
          onFocused: () {
            showProfileElaborator(
              Ellaboration.OCCUPATION,
              _occupationCache,
              onPopResult: (result) {
                setState(() {
                  _occupationCache = result;
                });
              }
            );
          },
          //not editable. on click to go another screen and
          //ask user about education level, type of job(full-time, part-time, gig, business owner, student, unemployed etc
          //ask user about industry they work in, amount of time worked, whether job is temporary or permanent
        ),
        const SizedBox(height: 20,),
        const Text("Write as comma-separated list (leave empty if no others)"),
        const SizedBox(height: 10,),
        CustomTextField(
          hint: "Other sources of income",
          text: _otherIncomeSources,
          prefix: const Icon(Icons.playlist_add_outlined),
          // suffix: otherIncomeSourcesInvalid ? ERROR_ICON : null,
          onTextChanged: (otherSources) {
            _otherIncomeSources = otherSources;
          },
        ),
        const SizedBox(height: 20,),
        CustomTextField(
          locked: true,
          hint: "Total Monthly Income (KSH)",
          text: _incomeCache != null ? DataConverter.moneyToStr(_incomeCache!['income']) : '',
          prefix: const Icon(Icons.payments_outlined),
          suffix: incomeInvalid ? FORM_ERROR_ICON: null,
          onTextChanged: (_) {},
          onFocused: () {
            //not editable, on click:
            //ask user about income and expenditure
            //ask about whether their pay changes from month to the next (eh, maybe v2+). unnecessary-ish
            showProfileElaborator(
              Ellaboration.INCOME,
              _incomeCache,
              onPopResult: (result) {
                setState(() {
                  _incomeCache = result;
                });
              }
            );
          },
        ),
        const SizedBox(height: 40,),

        if(!_tab2Fetching)
          FilledButton(
            onPressed: verifyAndUpdateUserInfo,
            child: const Text("Verify & Submit")
          ),
        if(_tab2Fetching)
          const LinearProgressIndicator()
      ],
    );
  }

  Widget get tab3 {
    return SingleChildScrollView(
      child: Center(
        child: SizedBox(
          width: double.infinity,
          height: 500,
          child: Card(
            margin: const EdgeInsets.only(left: 36, right: 36, top: 36),
            elevation: 36,
            color: app_theme.COLOR_PRIMARY,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.spa_outlined, size: 58, color: Colors.white),
                      Icon(Icons.self_improvement, size: 100, color: Colors.white,),
                      Icon(Icons.yard_outlined, size: 58, color: Colors.white,),
                    ],
                  ),
                  Text(
                    "${zen.clause1},\n"
                    "${zen.clause2}",
                    textAlign: TextAlign.center,
                    style: app_theme.darkTextTheme.displaySmall,
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  void showProfileElaborator(
    Ellaboration ellaboration,
    Map<String, dynamic>? extra,
    {required Function(Map<String, dynamic>) onPopResult}
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) {
          return ProfileElaborator(
            title: () {
              switch(ellaboration) {
                case Ellaboration.OCCUPATION:
                  return "Main Occupation";
                case Ellaboration.INCOME:
                  return "Income";
              }
            }(),
            extra: extra,
            toEllaborate: ellaboration,
            onPopResult: onPopResult
          );
        }
      )
    );
  }

  void verifyAndUpdateUserInfo() {
    if(_appUser == null) {
      context.toast("An unexpected error occurred...");
      return;
    }

    if(allUserInfoValid) {
     UserInsights userInsights = UserInsights(
      _nationalId, _address, _occupationCache!, _otherIncomeSources, _incomeCache!
     );

     print("Updating user info: ${userInsights.toString()}");

     _tab2Fetching = true;
     //at this point appUser can't be null whatsoever
     Api.getInstance()
       .stampUser(_appUser!, userInsights)
       .then((response) {
         setState(() {
           _tab2Fetching = false;
         });

         if(response.exists) {
           Map result = response.data as Map;

           if(result['updated'] as bool) {
             //save new stuff in cache
             userInsights.cache();
             context.toast("Your update was sent.");

             if(parent.referencedTab == 1) {
               //someone requested a specific tab, now ship back to sender (lmao)
               context.pop();
             }
           } else {
             if(result['error_type'] == 'kyc') {
               setState(() {
                 _nationalId = '';
               });
             }
             context.toast(result['msg']);
           }
         } else {
           context.toast(response.errorMsg);
         }
     });
    }

    setState(() {});
  }
}

class Zen {

  final String fullTenet;
  final String tenet1, tenet2, tenet3, tenet4;

  Zen(this.fullTenet, this.tenet1, this.tenet2, this.tenet3, this.tenet4);

  factory Zen.fromTenets() {
    String zen = getZen();

    final tokens = zen.split(", ");

    String token1 = tokens[0].substring(0, 1);
    String token2 = tokens[0].substring(1);
    String token3 = tokens[1].substring(0, 1);
    String token4 = tokens[1].substring(1);

    return Zen(zen, token1, token2, token3, token4);
  }

  String get clause1 => "$tenet1 $tenet2";
  String get clause2 => "$tenet3 $tenet4";

  static const _zenDen = [
    "I am present, I embrace the moment",
    "I let go, I find inner peace",
    "I breathe deeply, I let stress dissolve",
    "I seek simplicity, I find contentment",
    "I trust the journey, I surrender control",
    "I cherish stillness, I discover clarity",
    "I embrace imperfection, I nurture growth",
    "I practice gratitude, I cultivate abundance",
    "I release attachments, I invite freedom",
    "I live mindfully, I savor each experience",
    "I flow with life, I adapt gracefully",
    "I find balance, I harmonize within",
    "I am compassionate, I spread kindness",
    "I listen deeply, I understand profoundly",
    "I connect with nature, I connect with myself",
    "I choose love, I let go of fear",
    "I quiet the mind, I awaken the soul",
    "I accept what is, I embrace what comes",
    "I celebrate the journey, not just the destination",
    "I appreciate silence, I find inner wisdom",
    "I focus inward, I find outer peace",
    "I discover my essence, I express my truth",
    "I am gentle with myself, I heal with love",
    "I celebrate simplicity, I release complexity",
    "I nurture patience, I cultivate serenity",
    "I radiate positivity, I inspire others",
    "I let thoughts flow, I observe without judgment",
    "I embrace change, I embrace growth",
    "I find strength in vulnerability, I embrace authenticity",
    "I live with intention, I create with purpose",
    "I practice forgiveness, I release burdens",
    "I find joy in the present, I let go of the past",
    "I trust my intuition, I follow my heart",
    "I surrender to the unknown, I embrace uncertainty",
    "I discover inner stillness, I find outer peace",
    "I breathe in peace, I exhale tranquility",
    "I embrace solitude, I nurture self-discovery",
    "I cultivate gratitude, I transform my perspective",
    "I simplify my life, I amplify my happiness",
    "I release judgment, I embrace acceptance",
    "I am gentle with others, I am gentle with myself",
    "I find beauty in simplicity, I find peace in chaos",
    "I embrace the cycles of life, I embrace change",
    "I seek harmony, I align with the universe",
    "I practice self-care, I nourish my soul",
    "I let go of expectations, I embrace the present",
    "I embrace the unknown, I trust the process",
    "I cultivate compassion, I uplift others",
    "I focus on what matters, I let go of distractions",
    "I find stillness within, I create ripples of peace",
    "I release resistance, I flow with life",
    "I live authentically, I honor my truth",
    "I practice mindfulness, I cultivate awareness",
    "I am patient, I let life unfold naturally",
    "I nurture self-love, I radiate love to others",
    "I quiet the mind, I let the soul speak",
    "I connect with my breath, I find inner calm",
    "I celebrate impermanence, I embrace the moment",
    "I simplify my thoughts, I quiet the mind",
    "I choose peace over conflict, I choose love over fear",
    "I find grounding in nature, I find grounding within",
    "I release the past, I embrace the now",
    "I accept myself fully, I embrace my uniqueness",
    "I find strength in surrender, I find freedom in letting go",
    "I am kind to myself, I am kind to others",
    "I celebrate small victories, I find joy in every step",
    "I practice self-reflection, I foster personal growth",
    "I listen to my intuition, it holds the answers",
    "I am grateful for what is, I welcome what will be",
    "I cultivate mindfulness, I live in the present moment",
    "I find peace within chaos, I let stillness guide me",
    "I let go of control, I trust the universe's plan",
    "I radiate love and light, I am a beacon of positivity",
    "I find harmony within, I radiate harmony without",
    "I release worries, I embrace peace of mind",
    "I embrace the journey, I trust my path",
    "I surrender to the flow, I embrace the unfolding",
    "I cultivate patience, I allow life to blossom",
    "I choose simplicity, I simplify my soul",
    "I embrace the beauty of now, I release attachments to outcomes",
    "I nurture my inner garden, I let love bloom",
    "I quiet the mind, I awaken the soul's whispers",
    "I connect with my breath, I find serenity within",
    "I celebrate the present moment, it is all I truly have",
    "I practice self-compassion, I forgive myself with love",
    "I embrace the lessons, I release the pain",
    "I breathe in peace, I exhale gratitude",
    "I find clarity in silence, I find answers within",
    "I let go of resistance, I surrender to what is",
    "I trust the timing of my life, I have faith in the journey"
  ];

  static String getZen() {
    final random = Random();
    return _zenDen[random.nextInt(_zenDen.length)];
  }
}