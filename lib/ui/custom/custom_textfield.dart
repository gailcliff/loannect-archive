
import 'package:flutter/material.dart';
import 'package:loannect/app_theme.dart' as app_theme;

class CustomTextField extends StatefulWidget {

  final String hint;
  final String text;
  final bool? locked;
  final Widget? prefix;
  final Widget? suffix;
  final double padding;
  final Color? decorColor;
  final Color? fillColor;
  final void Function(String text)? onTextChanged;
  final void Function()? onFocused;
  final TextInputType inputType;
  final bool multiline;
  final int? maxChars;
  final bool hideCharCount;

  const CustomTextField({Key? key,
    required this.hint,
    this.text = '',
    this.locked,
    this.prefix,
    this.suffix,
    this.padding = 10,
    this.fillColor = Colors.white,
    this.decorColor = app_theme.COLOR_SECONDARY,
    this.onTextChanged,
    this.onFocused,
    this.inputType = TextInputType.text,
    this.multiline = false,
    this.maxChars,
    this.hideCharCount = false
  }) : super(key: key);

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {

  TextEditingController? _textFieldController;

  @override
  void initState() {
    // if(parent.onTextChanged != null) {
    //   _textFieldController = TextEditingController();
    //   _textFieldController?.text = parent.text;
    //   _textFieldController?.addListener(() {
    //     parent.onTextChanged!(_textFieldController!.text, _textFieldController);
    //   });
    // }
    super.initState();
  }

  @override
  void dispose() {
    if(_textFieldController != null) _textFieldController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if(_textFieldController != null) _textFieldController?.dispose();

    // this was removed from initState because the text wasn't refreshing
    // if set on the TextField manually.
    //  i.e like passing in the text: CustomTextField(text: 'text_here'...)
    // putting it inside initState means it won't refresh during rebuilds
    // initiated through setState.
    // putting it inside build ensures that text will be re-rendered when
    // setState is called.

    if(parent.onTextChanged != null) {
      _textFieldController = TextEditingController();
      _textFieldController?.text = parent.text;
      _textFieldController?.addListener(() {
        parent.onTextChanged!(_textFieldController!.text.trim());
      });
    }

    return Column(
      children: <Widget>[
        TextField(
          readOnly: parent.locked ?? false,
          keyboardType: parent.inputType,
          obscureText: (parent.inputType == TextInputType.visiblePassword) ? true : false,
          cursorColor: parent.decorColor,
          maxLines: (parent.multiline) ? 3 : 1,
          maxLength: parent.maxChars,
          // style: const TextStyle(overflow: TextOverflow.ellipsis),
          decoration: InputDecoration(
            prefixIcon: parent.prefix,
            suffixIcon: parent.suffix,
            counterText: parent.hideCharCount ? "" : null,

            contentPadding: EdgeInsets.all(parent.padding),

            labelText: parent.hint,
            labelStyle: TextStyle(color: Colors.grey.shade700),

            filled: true,
            fillColor: parent.fillColor,

            border: const OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25)
              )
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: parent.decorColor ?? Colors.black, width: 1),
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25)
              )
            ),
          ),
          onTap: parent.onFocused,
          controller: _textFieldController,
        ),
        Divider(
          height: 1.0,
          color: parent.decorColor,
        )
      ]
    );
  }

  CustomTextField get parent => widget;
}