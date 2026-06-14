// ignore_for_file: constant_identifier_names, non_constant_identifier_names

enum Environment { local, localIP, development, production, lounging }

class Endpoints {
  // 1. Set your active target environment here
  static Environment currentEnvironment = Environment.localIP;

  // 2. Computed getter to fix the environment switching bug safely
  static String get baseUrl {
    switch (currentEnvironment) {
      case Environment.local:
        return 'http://localhost:3000';
      case Environment.localIP:
        return 'http://192.168.1.15:3000';
      case Environment.development:
        // Typical AWS setup: API Gateway custom domain or ALB Subdomain
        return 'https://api-dev.contextar.theqlu.com';
      case Environment.production:
        // Production Domain pointing to CloudFront, Route 53, or an AWS Load Balancer
        return 'https://api.contextar.theqlu.com';
      case Environment.lounging:
        // Staging/Sandbox tier on an AWS App Runner or ECS instance
        return 'https://api-stage.contextar.theqlu.com';
    }
  }

  // 3. Computed getter for WebSockets (AWS API Gateway WebSocket or custom service)
  static String get socketUrl {
    switch (currentEnvironment) {
      case Environment.local:
        return 'ws://localhost:3000';
      case Environment.localIP:
        return 'ws://192.168.100.114:3000';
      case Environment.development:
        return 'wss://ws-dev.contextar.theqlu.com';
      case Environment.production:
        return 'wss://ws.contextar.theqlu.com';
      case Environment.lounging:
        return 'wss://ws-stage.contextar.theqlu.com';
    }
  }

  // FIXED: Converted to getters so changes to currentEnvironment instantly propagate to DioApiClient
  static String get BASE_URL => baseUrl;
  static String get BASE_SOCKET_URL => socketUrl;

  // Static Platform Constants & Deep Linking targets
  static const String QLU_SOCIAL = 'https://qlu.social/link/demo';
  static const String YORI_BACKEND_API_KEY =
      '9aed3916-af53-40a2-9532-73d69f49153a';
  static const String YORI_BACKEND = 'https://yori.theqlu.com';

  // AWS AI/Verification Microservice Custom Endpoints
  static const String INTRO_VERIFICATION_SERVICE_URL =
      'https://ai.contextar.theqlu.com';

  static const String Q_APP_SHARE = 'https://qlu-roundtable.app.link';
  static const String Q_APP_SHARE_RT = 'https://invite.qlu.ai';
  static const String LIVE_KIT_SFU_URL = 'http://34.131.231.97:7880';
  static const String Q_APP_PRIVACY_POLICY =
      "https://roundtable.qlu.ai/?index=0";
  static const String Q_APP_COMMUNITY_GUIDELINE =
      "https://roundtable.qlu.ai/?index=1";
}
