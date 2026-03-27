import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:atom/config/app_theme.dart';
import 'package:atom/config/constants.dart';

class ShimmerCard extends StatelessWidget {
  final double height;
  final double width;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;

  const ShimmerCard({
    super.key,
    this.height = 100,
    this.width = double.infinity,
    this.margin,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? context.col.surface : Colors.grey[300]!;
    final highlightColor = isDark ? context.col.border : Colors.grey[100]!;

    return Container(
      width: width,
      height: height,
      margin: margin,
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: borderRadius ?? BorderRadius.circular(kRadiusMD),
          ),
        ),
      ),
    );
  }
}

class ShimmerList extends StatelessWidget {
  final int itemCount;
  final double cardHeight;

  const ShimmerList({super.key, this.itemCount = 6, this.cardHeight = 110});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return ShimmerCard(
          height: cardHeight,
          margin: const EdgeInsets.only(bottom: 12),
        );
      },
    );
  }
}
