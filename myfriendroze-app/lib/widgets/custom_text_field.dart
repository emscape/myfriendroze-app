import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int maxLines;
  final bool enabled;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final bool enableVoice; // adds a mic icon and voice dictation

  const CustomTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.prefixIcon,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.enabled = true,
    this.autofillHints,
    this.textInputAction,
    this.enableVoice = false,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  stt.SpeechToText? _speech;
  bool _isListening = false;
  bool _speechAvailable = false;

  Future<void> _toggleListening() async {
    // Capture messenger before any awaits
    final messenger = ScaffoldMessenger.maybeOf(context);

    if (_speech == null) {
      _speech = stt.SpeechToText();
      _speechAvailable = await _speech!.initialize(
        onError: (err) => debugPrint('Speech error: $err'),
        onStatus: (status) => debugPrint('Speech status: $status'),
      );
    }

    if (!_speechAvailable) {
      messenger?.showSnackBar(
        const SnackBar(content: Text('Speech recognition not available on this device')),
      );
      return;
    }

    if (!_isListening) {
      final ok = await _speech!.listen(onResult: (res) {
        final text = res.recognizedWords;
        widget.controller.text = text;
        widget.controller.selection = TextSelection.fromPosition(
          TextPosition(offset: widget.controller.text.length),
        );
        widget.onChanged?.call(text);
      });
      if (ok) {
        if (!mounted) return;
        setState(() => _isListening = true);
      }
    } else {
      await _speech!.stop();
      if (!mounted) return;
      setState(() => _isListening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trailing = <Widget>[];
    if (widget.enableVoice && !widget.obscureText) {
      trailing.add(IconButton(
        tooltip: _isListening ? 'Stop voice input' : 'Voice input',
        icon: Icon(_isListening ? Icons.mic : Icons.mic_none,
            color: _isListening ? Colors.red : null),
        onPressed: widget.enabled ? _toggleListening : null,
      ));
    }
    if (widget.suffixIcon != null) {
      trailing.add(widget.suffixIcon!);
    }

    return TextFormField(
      controller: widget.controller,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      onChanged: widget.onChanged,
      maxLines: widget.maxLines,
      enabled: widget.enabled,
      autofillHints: widget.autofillHints,
      textInputAction: widget.textInputAction,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        suffixIcon: trailing.isEmpty
            ? null
            : Row(mainAxisSize: MainAxisSize.min, children: trailing),
        prefixIcon: widget.prefixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
