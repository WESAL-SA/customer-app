/// Build flavors. Keep this list in sync with the native build configs
/// (android/app/build.gradle productFlavors and iOS schemes/xcconfigs).
enum Flavor { dev, staging, production }

extension FlavorX on Flavor {
  static Flavor fromName(String name) {
    switch (name.toLowerCase()) {
      case 'production':
      case 'prod':
        return Flavor.production;
      case 'staging':
      case 'stage':
        return Flavor.staging;
      case 'dev':
      case 'development':
      default:
        return Flavor.dev;
    }
  }

  String get label {
    switch (this) {
      case Flavor.dev:
        return 'Dev';
      case Flavor.staging:
        return 'Staging';
      case Flavor.production:
        return 'Production';
    }
  }
}
