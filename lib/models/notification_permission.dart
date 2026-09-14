enum NotificationPermission {
  speedLimit(
    'speedLimitNotification',
    'speed/limit',
    'Speed limit',
    'When a vehicle exceeds its speed limit.',
  ),
  signalTampering(
    'signalTamperingNotification',
    'signal/tampering',
    'Signal tampering',
    'When interference with a tracker signal is detected.',
  ),
  batteryTampering(
    'batteryTamperingNotification',
    'battery/tampering',
    'Battery tampering',
    'When battery tampering is detected.',
  ),
  engineOn(
    'engineOnNotification',
    'engine/on',
    'Engine on',
    'When a vehicle engine starts.',
  ),
  engineOff(
    'engineOffNotification',
    'engine/off',
    'Engine off',
    'When a vehicle engine stops.',
  );

  const NotificationPermission(
    this.field,
    this.path,
    this.title,
    this.description,
  );

  final String field;
  final String path;
  final String title;
  final String description;
}
