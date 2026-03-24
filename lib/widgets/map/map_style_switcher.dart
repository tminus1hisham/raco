import 'package:atom/config/app_theme.dart';
import 'package:atom/config/constants.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapStyleSwitcherButton extends StatelessWidget {
  final MapboxMap? mapboxMap;
  final String currentStyleUri;
  final ValueChanged<String> onStyleChanged;

  const MapStyleSwitcherButton({
    super.key,
    required this.mapboxMap,
    required this.currentStyleUri,
    required this.onStyleChanged,
  });

  static const _styles = [
    ('Streets', MapboxStyles.MAPBOX_STREETS, Icons.map_outlined),
    ('Satellite', MapboxStyles.SATELLITE, Icons.satellite_alt_outlined),
    ('Sat+Streets', MapboxStyles.SATELLITE_STREETS, Icons.layers_outlined),
    ('Light', MapboxStyles.LIGHT, Icons.light_mode_outlined),
    ('Dark', MapboxStyles.DARK, Icons.dark_mode_outlined),
  ];

  void _show(BuildContext context) {
    final col = context.col;
    showModalBottomSheet(
      context: context,
      backgroundColor: col.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Map Style',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: col.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _styles.map((entry) {
                final (label, uri, icon) = entry;
                final isActive = currentStyleUri == uri;
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    mapboxMap?.loadStyleURI(uri);
                    onStyleChanged(uri);
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isActive
                              ? kBlue.withValues(alpha: 0.12)
                              : col.inputFill,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isActive ? kBlue : col.border,
                            width: isActive ? 2 : 1,
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: isActive ? kBlue : col.textSecondary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          color: isActive ? kBlue : col.textSecondary,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      shadowColor: Colors.black.withValues(alpha: 0.2),
      child: InkWell(
        onTap: () => _show(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: col.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.layers_outlined, color: col.textPrimary, size: 22),
        ),
      ),
    );
  }
}
