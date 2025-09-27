import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'glassmorphic_container.dart';

class CommanTextField extends StatefulWidget {
  final String label;
  final String hint;
  final bool obscureText;
  final TextEditingController controller;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;

  const CommanTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.validator,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<CommanTextField> createState() => _CommanTextFieldState();
}

class _CommanTextFieldState extends State<CommanTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChanged);
    _hasText = widget.controller.text.isNotEmpty;
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _onTextChanged() {
    final has = widget.controller.text.isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  @override
  Widget build(BuildContext context) {
    final height = 68.0;
    final showSmallLabel = _isFocused || _hasText;

    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: GlassmorphicContainer(
              blur: AppConstants.glassBlur,
              opacity: AppConstants.glassOpacity,
              borderRadius: BorderRadius.circular(
                AppConstants.borderRadiusXLarge,
              ),
              border: Border.all(
                color: _isFocused
                    ? AppColors.primaryOrange.withOpacity(0.9)
                    : AppColors.cardBorder,
                width: _isFocused ? 2.0 : 1.0,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  if (widget.prefixIcon != null) ...[
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            (_isFocused
                                    ? AppColors.primaryOrange
                                    : AppColors.primaryBlue)
                                .withOpacity(0.12),
                      ),
                      child: Icon(
                        widget.prefixIcon,
                        color: _isFocused
                            ? AppColors.primaryOrange
                            : AppColors.primaryBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],

                  Expanded(
                    child: TextFormField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      obscureText: widget.obscureText,
                      keyboardType: widget.keyboardType,
                      validator: widget.validator,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      cursorColor: AppColors.primaryOrange,
                      decoration: InputDecoration.collapsed(
                        hintText: widget.hint,
                        hintStyle: TextStyle(
                          color: AppColors.textLight.withOpacity(0.9),
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),

                  if (widget.suffixIcon != null) ...[
                    const SizedBox(width: 8),
                    Material(
                      color: Colors.transparent,
                      child: IconButton(
                        splashRadius: 22,
                        icon: Icon(
                          widget.suffixIcon,
                          color: _isFocused
                              ? AppColors.primaryOrange
                              : AppColors.textLight,
                          size: 22,
                        ),
                        onPressed: widget.onSuffixIconPressed,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          Positioned(
            left: widget.prefixIcon != null ? 80 : 20,
            top: showSmallLabel ? 8 : (height / 2 - 10),
            child: AnimatedDefaultTextStyle(
              duration: AppConstants.fastAnimation,
              style: TextStyle(
                color: showSmallLabel
                    ? AppColors.primaryOrange
                    : AppColors.textLight.withOpacity(0.95),
                fontSize: showSmallLabel ? 12 : 16,
                fontWeight: FontWeight.w700,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(color: Colors.transparent),
                child: Text(widget.label),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
