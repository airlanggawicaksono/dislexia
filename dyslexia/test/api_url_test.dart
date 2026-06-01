import 'package:dyslexia/src/core/api/api_url.dart';
import 'package:dyslexia/src/features/auth/presentation/bloc/token_holder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiUrl', () {
    test('default baseUrl is the compile-time constant', () {
      // Reset to a known state in case some other test left an override.
      ApiUrl.configure();
      expect(ApiUrl.baseUrl, 'https://dev.dyslexic.app/v1');
    });

    test('configure() overrides the baseUrl', () {
      ApiUrl.configure(baseUrlOverride: 'https://staging.example.test/v1');
      expect(ApiUrl.baseUrl, 'https://staging.example.test/v1');
      ApiUrl.configure(); // back to default
    });

    test('configure() ignores empty strings', () {
      ApiUrl.configure(baseUrlOverride: 'https://x.test/v1');
      ApiUrl.configure(baseUrlOverride: '');
      expect(ApiUrl.baseUrl, 'https://x.test/v1');
      ApiUrl.configure();
    });
  });

  group('TokenHolder', () {
    test('starts empty', () {
      TokenHolder.instance.clear();
      expect(TokenHolder.instance.token, isNull);
    });

    test('set() stores a non-empty token', () {
      TokenHolder.instance.set('hello');
      expect(TokenHolder.instance.token, 'hello');
    });

    test('set(null) and set("") clear the token', () {
      TokenHolder.instance.set('hello');
      TokenHolder.instance.set(null);
      expect(TokenHolder.instance.token, isNull);
      TokenHolder.instance.set('hello');
      TokenHolder.instance.set('');
      expect(TokenHolder.instance.token, isNull);
    });
  });
}
