class MqttConfig {
  final String brokerHost;
  final int port;
  final String clientId;
  final String telemetryTopic;
  final String controlTopic;
  final String username;
  final String password;
  final bool useSecure;

  MqttConfig({
    this.brokerHost = 'adaa622b6b644c048748162b0be4ac5f.s1.eu.hivemq.cloud',
    this.port = 8883,
    String? clientId,
    this.telemetryTopic = 'skripsi/nizar/soil',
    this.controlTopic = 'skripsi/nizar/manual',
    this.username = 'nizar2209',
    this.password = 'saputra2209',
    this.useSecure = true,
  }) : clientId = clientId ?? 'FlutterApp_Nizar';

  Map<String, dynamic> toJson() {
    return {
      'brokerHost': brokerHost,
      'port': port,
      'clientId': clientId,
      'telemetryTopic': telemetryTopic,
      'controlTopic': controlTopic,
      'username': username,
      'password': password,
      'useSecure': useSecure,
    };
  }

  factory MqttConfig.fromJson(Map<String, dynamic> json) {
    return MqttConfig(
      brokerHost: json['brokerHost'] ?? 'adaa622b6b644c048748162b0be4ac5f.s1.eu.hivemq.cloud',
      port: json['port'] ?? 8883,
      clientId: json['clientId'],
      telemetryTopic: json['telemetryTopic'] ?? 'skripsi/nizar/soil',
      controlTopic: json['controlTopic'] ?? 'skripsi/nizar/manual',
      username: json['username'] ?? 'nizar2209',
      password: json['password'] ?? 'saputra2209',
      useSecure: json['useSecure'] ?? true,
    );
  }

  MqttConfig copyWith({
    String? brokerHost,
    int? port,
    String? clientId,
    String? telemetryTopic,
    String? controlTopic,
    String? username,
    String? password,
    bool? useSecure,
  }) {
    return MqttConfig(
      brokerHost: brokerHost ?? this.brokerHost,
      port: port ?? this.port,
      clientId: clientId ?? this.clientId,
      telemetryTopic: telemetryTopic ?? this.telemetryTopic,
      controlTopic: controlTopic ?? this.controlTopic,
      username: username ?? this.username,
      password: password ?? this.password,
      useSecure: useSecure ?? this.useSecure,
    );
  }
}
