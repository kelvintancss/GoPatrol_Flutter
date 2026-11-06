// lib/env/env.dart
import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class AppEnv {
    @EnviedField(varName: 'STAGING_API_KEY', obfuscate: true)
    static final String stagingApiKey = _AppEnv.stagingApiKey;
    
    @EnviedField(varName: 'STAGING_SECRET_KEY', obfuscate: true)
    static final String stagingSecretKey = _AppEnv.stagingSecretKey;

    @EnviedField(varName: 'PRODUCTION_API_KEY', obfuscate: true)
    static final String prodApiKey = _AppEnv.prodApiKey;

    @EnviedField(varName: 'PRODUCTION_SECRET_KEY', obfuscate: true)
    static final String prodSecretKey = _AppEnv.prodSecretKey;
}