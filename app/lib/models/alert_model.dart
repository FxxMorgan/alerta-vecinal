class AlertModel {
  final String id;
  final String sender;
  final String notes;
  final DateTime timestamp;
  final bool active;

  AlertModel({
    required this.id,
    required this.sender,
    required this.notes,
    required this.timestamp,
    required this.active,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] as String? ?? 'unknown_${DateTime.now().millisecondsSinceEpoch}',
      sender: json['sender'] as String? ?? 'Vecino sin identificar',
      notes: json['notes'] as String? ?? '¡Alerta de emergencia activada!',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      active: json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender,
      'notes': notes,
      'timestamp': timestamp.toIso8601String(),
      'active': active,
    };
  }
}
