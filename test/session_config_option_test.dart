import 'dart:convert';

import 'package:acp_dart/acp_dart.dart';
import 'package:test/test.dart';

Map<String, dynamic> _roundTrip(Map<String, dynamic> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, dynamic>;

void main() {
  group('SessionConfigOption', () {
    test('reads a boolean option and writes it back', () {
      final option = SessionConfigOption.fromJson({
        'id': 'thinking',
        'name': 'Thinking',
        'category': 'thought_level',
        'type': 'boolean',
        'currentValue': true,
      });

      expect(
        option,
        isA<BooleanSessionConfigOption>()
            .having((option) => option.id, 'id', 'thinking')
            .having((option) => option.category, 'category', 'thought_level')
            .having((option) => option.currentValue, 'currentValue', true),
      );
      expect(
        SessionConfigOption.fromJson(_roundTrip(option.toJson())),
        isA<BooleanSessionConfigOption>().having(
          (option) => option.currentValue,
          'currentValue',
          true,
        ),
      );
    });

    test('reads an option without a type as a select', () {
      final option = SessionConfigOption.fromJson({
        'id': 'mode',
        'name': 'Mode',
        'currentValue': 'code',
        'options': [
          {'value': 'code', 'name': 'Code'},
        ],
      });

      expect(
        option,
        isA<SelectSessionConfigOption>().having(
          (option) => option.currentValue,
          'currentValue',
          'code',
        ),
      );
    });

    test('reads an option of an unknown type as unknown', () {
      final json = {
        'id': 'temperature',
        'name': 'Temperature',
        'type': 'slider',
        'currentValue': 0.5,
      };
      final option = SessionConfigOption.fromJson(json);

      expect(
        option,
        isA<UnknownSessionConfigOption>()
            .having((option) => option.id, 'id', 'temperature')
            .having((option) => option.name, 'name', 'Temperature'),
      );
      expect(option.toJson(), json);
    });

    for (final (kind, json) in [
      (
        'a boolean with a string value',
        {
          'id': 'thinking',
          'name': 'Thinking',
          'type': 'boolean',
          'currentValue': 'true',
        },
      ),
      (
        'a select without options',
        {'id': 'mode', 'name': 'Mode', 'type': 'select', 'currentValue': 'a'},
      ),
      (
        'a select with malformed options',
        {
          'id': 'mode',
          'name': 'Mode',
          'type': 'select',
          'currentValue': 'a',
          'options': [
            {'unexpected': true},
          ],
        },
      ),
      (
        'an option without a name',
        {'id': 'thinking', 'type': 'boolean', 'currentValue': true},
      ),
    ]) {
      test('reads $kind as unknown', () {
        expect(
          SessionConfigOption.fromJson(json),
          isA<UnknownSessionConfigOption>(),
        );
      });
    }

    test('a malformed option does not fail the response it came in', () {
      final response = NewSessionResponse.fromJson({
        'sessionId': 'session-1',
        'configOptions': [
          {
            'id': 'thinking',
            'name': 'Thinking',
            'type': 'boolean',
            'currentValue': 'yes',
          },
          {
            'id': 'fast',
            'name': 'Fast',
            'type': 'boolean',
            'currentValue': false,
          },
        ],
      });

      expect(response.configOptions, [
        isA<UnknownSessionConfigOption>(),
        isA<BooleanSessionConfigOption>(),
      ]);
    });

    test('copyWith changes only the current value', () {
      const option = BooleanSessionConfigOption(
        id: 'thinking',
        name: 'Thinking',
        description: 'Think first',
        currentValue: false,
      );

      expect(
        option.copyWith(currentValue: true),
        isA<BooleanSessionConfigOption>()
            .having((option) => option.currentValue, 'currentValue', true)
            .having(
              (option) => option.description,
              'description',
              'Think first',
            ),
      );
    });
  });

  group('SetSessionConfigOptionRequest', () {
    test('sends a select value as its id', () {
      final request = SetSessionConfigOptionRequest(
        sessionId: 'session-1',
        configId: 'mode',
        value: const SessionConfigSelectValue('code'),
      );

      expect(request.toJson(), {
        'sessionId': 'session-1',
        'configId': 'mode',
        'value': 'code',
      });
      expect(
        SetSessionConfigOptionRequest.fromJson(
          _roundTrip(request.toJson()),
        ).value,
        const SessionConfigSelectValue('code'),
      );
    });

    test('sends a boolean value as a bool', () {
      final request = SetSessionConfigOptionRequest(
        sessionId: 'session-1',
        configId: 'thinking',
        value: const SessionConfigBooleanValue(true),
      );

      expect(request.toJson(), {
        'sessionId': 'session-1',
        'configId': 'thinking',
        'type': 'boolean',
        'value': true,
      });
      expect(
        SetSessionConfigOptionRequest.fromJson(
          _roundTrip(request.toJson()),
        ).value,
        const SessionConfigBooleanValue(true),
      );
    });
  });
}
