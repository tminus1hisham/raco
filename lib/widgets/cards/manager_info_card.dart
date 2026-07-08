import 'package:atom/config/constants.dart';
import 'package:flutter/material.dart';

class ManagerInfoCard extends StatelessWidget {
  final String fullName;
  final String phoneNumber;
  final String emailAddress;
  final VoidCallback onPressed;
  final VoidCallback? onDelete;

  const ManagerInfoCard({
    super.key,
    required this.fullName,
    required this.phoneNumber,
    required this.emailAddress,
    required this.onPressed,
    this.onDelete,
  });

  String get _initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 12),
      child: Material(
        color: kWhite,
        borderRadius: BorderRadius.circular(kRadiusLG),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          splashColor: kBlue.withValues(alpha: 0.06),
          highlightColor: kBlue.withValues(alpha: 0.04),
          child: Ink(
            decoration: BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.circular(kRadiusLG),
              border: Border.all(color: kDivider),
              boxShadow: [kShadowSM],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          kBlue,
                          kBlue.withValues(alpha: 0.75),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(kRadiusMD),
                    ),
                    child: Text(
                      _initials,
                      style: const TextStyle(
                        color: kWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: kBlack,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _MetaLine(
                          icon: Icons.phone_outlined,
                          text: phoneNumber,
                        ),
                        if (emailAddress.trim().isNotEmpty) ...[
                          const SizedBox(height: 3),
                          _MetaLine(
                            icon: Icons.email_outlined,
                            text: emailAddress,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (onDelete != null)
                    _CircleIconButton(
                      icon: Icons.delete_outline,
                      color: kRed,
                      onPressed: onDelete!,
                    )
                  else
                    const Icon(
                      Icons.chevron_right,
                      color: kLightGrey,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: kGrey),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: kGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _CircleIconButton({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}
