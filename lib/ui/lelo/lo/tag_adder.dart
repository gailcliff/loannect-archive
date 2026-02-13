
import 'package:flutter/material.dart';
import 'package:loannect/state/app_router.dart';
import 'package:loannect/ui/custom/custom_textfield.dart';
import 'package:loannect/ui/lelo/le_lo.dart';
import 'package:provider/provider.dart';


class TagAdderRepo extends ChangeNotifier {
  
  List<String> _tags = LeLo.LO_TAGS!;

  List<String> addedTags;

  TagAdderRepo({required this.addedTags});

  
  void onTagEdited(String tag) {
    if(tag.isEmpty) {
      _tags = LeLo.LO_TAGS!;
    } else {
      _tags = LeLo.LO_TAGS!.where((loTag) => loTag.toLowerCase().contains(tag.toLowerCase())).toList();
    }

    notifyListeners();
  }


  void onTagsStateChanged(String tag, BuildContext context, [bool autoRemove=true]) {
    if(addedTags.contains(tag)) {
      if(autoRemove) {
        addedTags.remove(tag);

        notifyListeners();
      }
    } else {
      if(addedTags.length < 5) {
        addedTags.add(tag);
      } else {
        context.toast("The maximum is 5 tags");
      }

      notifyListeners();
    }
  }

  void setAllAddedTags (List<String> tags) {
    addedTags = tags;
    notifyListeners();
  }

  int get addedTagsCount => addedTags.length;

  bool get attainedAddedTagsThreshold => addedTagsCount >= 5;
  
  List<String> get tags => _tags;
}

class TagAdder extends StatefulWidget {

  const TagAdder({super.key});

  @override
  State<TagAdder> createState() => _TagAdderState();
}

class _TagAdderState extends State<TagAdder> with ChangeNotifier{

  TagAdder get parent => widget;

  String? _editedTag;

  TagAdderRepo get _tagAdderRepo => Provider.of<TagAdderRepo>(context, listen: false);

  late ScrollController tagsScrollController;

  @override
  void initState() {
    super.initState();

    tagsScrollController = ScrollController();
  }

  @override
  void dispose() {
    try {
      tagsScrollController.dispose();
    } on Exception {
      //do nothing
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Add Tags"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: closeAndReturnTags,
        ),
        actions: [
          TextButton(
            onPressed: closeAndReturnTags,
            child: const Text("OK")
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    text: "Add tags for this loan ",
                    style: Theme.of(context).textTheme.bodyMedium,
                    children: const [
                      TextSpan(
                          text: "(from most to least important)",
                          style: TextStyle(fontStyle: FontStyle.italic)
                      )
                    ]
                  ),
                ),
                const SizedBox(height: 10,),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        hint: "Start typing and then add",
                        maxChars: 26,
                        hideCharCount: true,
                        onTextChanged: (tag) {
                          if(tag.isNotEmpty) {
                            _editedTag = tag;
                            _tagAdderRepo.onTagEdited(tag);
                          } else {
                            resetEditing();
                          }
                        },
                        prefix: IconButton(
                          onPressed: resetEditing,
                          icon: const Icon(Icons.replay),
                        ),
                        suffix: IconButton(
                          onPressed: () {
                            if(_editedTag != null) {
                              bool shouldScroll = !_tagAdderRepo.addedTags.contains(_editedTag);

                              _tagAdderRepo.onTagsStateChanged(_editedTag!, context, false);

                              if(shouldScroll) {
                                scrollTagsToEnd();
                              }

                              resetEditing();
                            }
                          },
                          icon: const Icon(Icons.add_circle)
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // const SizedBox(height: 20,),
          Expanded(
            child: Consumer<TagAdderRepo>(
              builder: (context, TagAdderRepo repo, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      controller: tagsScrollController,
                      padding: const EdgeInsets.only(left: 10, right: 10),
                      scrollDirection: Axis.horizontal,
                      child: Wrap(
                        spacing: 10,
                        children: [
                          for(String tag in repo.addedTags)
                            Chip(
                              label: Text(tag),
                              onDeleted: () {
                                repo.onTagsStateChanged(tag, context);
                              },
                            )
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 10,),
                      child: Text("OR, select from the list below then press OK above...", style: TextStyle(color: Colors.grey.shade700),),
                    ),
                    Expanded(
                      child: ListView.separated(
                        itemCount: repo.tags.length,
                        itemBuilder: (context, pos) {
                          String tag = repo.tags[pos];

                          return ListTile(
                            // tileColor: Colors.white,
                            selectedColor: Colors.blue,
                            selected: repo.addedTags.contains(tag),
                            title: Text(tag),
                            onTap: () {
                              bool shouldScroll = !repo.addedTags.contains(tag);

                              repo.onTagsStateChanged(tag, context);

                              if(shouldScroll) {
                                scrollTagsToEnd();
                              }
                            },
                          );
                        },
                        separatorBuilder: (_, __) => const Divider(),
                      ),
                    ),
                  ],
                );
              },
            ),
          )
        ],
      ),
    );
  }

  void resetEditing() {
    _editedTag = '';
    setState(() {});
    _tagAdderRepo.onTagEdited('');
  }

  void scrollTagsToEnd() {
    try {
      tagsScrollController.animateTo(
        tagsScrollController.position.maxScrollExtent + 300,
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    } on Exception {
      //do nothing
    }
  }

  void closeAndReturnTags () {
    // dispose();
    try {
      Navigator.pop(context, _tagAdderRepo.addedTags);
      dispose();
    } on Exception {
      //do nothing
    }
  }
}
