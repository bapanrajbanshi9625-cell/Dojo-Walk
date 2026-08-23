import 'package:flutter/material.dart';

class InstaWalkSearchButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool loading;
  final String text;

  const InstaWalkSearchButton({
    super.key,
    required this.onPressed,
    required this.loading,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFE7FFFC),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF65D6C8),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: const Color(0xFF243746),
            disabledBackgroundColor: Colors.transparent,
            disabledForegroundColor:
                const Color(0xFF243746),
            shadowColor: Colors.transparent,
            elevation: 0,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                const SizedBox(
                  width: 19,
                  height: 19,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(
                      Color(0xFF243746),
                    ),
                  ),
                )
              else
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFF243746),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    color: Colors.white,
                    size: 17,
                  ),
                ),

              const SizedBox(width: 9),

              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
