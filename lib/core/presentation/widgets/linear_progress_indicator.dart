import 'package:flutter/material.dart';
import 'package:rioko_ni/core/config/app_sizes.dart';

class RiokoLinearProgressIndicator extends StatelessWidget {
  final double remaining;
  final int nominative;
  final String message;

  const RiokoLinearProgressIndicator({
    required this.remaining,
    required this.nominative,
    required this.message,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height / 2,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSizes.padding,
              horizontal: AppSizes.paddingQuadruple,
            ),
            child: LinearProgressIndicator(
              value: remaining / nominative,
            ),
          ),
        ],
      ),
    );
  }
}
