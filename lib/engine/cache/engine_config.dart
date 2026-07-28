class EngineConfig {
  bool enableBlockCompression;
  bool enableAutovacuum;
  bool enableAuditLogging;
  bool enableDataMasking;
  bool enableCostBasedOptimizer;
  bool enableTlsEncryption;

  EngineConfig({
    required this.enableBlockCompression,
    required this.enableAutovacuum,
    required this.enableAuditLogging,
    required this.enableDataMasking,
    required this.enableCostBasedOptimizer,
    required this.enableTlsEncryption,
  });

  factory EngineConfig.defaultConfig() {
    return EngineConfig(
      enableBlockCompression: true,
      enableAutovacuum: true,
      enableAuditLogging: true,
      enableDataMasking: true,
      enableCostBasedOptimizer: true,
      enableTlsEncryption: false,
    );
  }

  factory EngineConfig.allDisabled() {
    return EngineConfig(
      enableBlockCompression: false,
      enableAutovacuum: false,
      enableAuditLogging: false,
      enableDataMasking: false,
      enableCostBasedOptimizer: false,
      enableTlsEncryption: false,
    );
  }
}
