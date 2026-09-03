import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/core/About/privacypolicy_screen.dart';
import 'package:BisonsTechs_app/core/About/termsofservice_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TermsAgreementRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const TermsAgreementRow({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Transform.scale(
          scale: 1.0,
          child: Checkbox(
            value: value,
            onChanged: (v) => onChanged(v ?? false),
            activeColor: kPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            side: BorderSide(color: Colors.blue.shade100, width: 1.5),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'I agree to the ',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12.5,
                    height: 1.5,
                  ),
                ),
                GestureDetector(
                  onTap: () => Get.to(() => const TermsOfServiceScreen()),
                  child: Text(
                    'Terms of Service',
                    style: TextStyle(
                      color: kPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                      height: 1.5,
                    ),
                  ),
                ),
                Text(
                  ' and ',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12.5,
                    height: 1.5,
                  ),
                ),
                GestureDetector(
                  onTap: () => Get.to(() => const PrivacyPolicyScreen()),
                  child: Text(
                    'Privacy Policy',
                    style: TextStyle(
                      color: kPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
