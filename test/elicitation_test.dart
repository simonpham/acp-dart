import 'package:acp_dart/acp_dart.dart';
import 'package:test/test.dart';

void main() {
  test("Claude Code's question reads with its message and choices", () {
    final request = CreateElicitationRequest.fromJson({
      'mode': 'form',
      'sessionId': 's',
      'toolCallId': 'toolu_1',
      'message': 'How should I start?',
      'requestedSchema': {
        'type': 'object',
        'properties': {
          'question_0': {
            'type': 'string',
            'title': 'Start',
            'oneOf': [
              {
                'const': 'commit',
                'title': "I'll commit first",
                'description': 'You commit, then I start.',
              },
              {'const': 'now', 'title': 'Start now'},
            ],
          },
          'question_0_custom': {
            'type': 'string',
            'title': 'Other',
            'description': 'Type your own answer.',
          },
        },
      },
    });

    expect(request.message, 'How should I start?');
    expect(request.toolCallId, 'toolu_1');
    final properties = request.schema?.properties ?? const {};
    expect(properties.keys, ['question_0', 'question_0_custom']);
    final choices = properties['question_0']?.choices ?? const [];
    expect([for (final choice in choices) choice.value], ['commit', 'now']);
    expect(choices.first.label, "I'll commit first");
    expect(choices.first.description, 'You commit, then I start.');
    expect(properties['question_0_custom']?.choices, isEmpty);
  });

  test('an earlier draft\'s schema field still reads', () {
    final request = CreateElicitationRequest.fromJson({
      'schema': {
        'properties': {
          'name': {'type': 'string'},
        },
      },
    });

    expect(request.schema?.properties.keys, ['name']);
  });

  test('enum values take their enumNames as titles', () {
    final property = ElicitationPropertySchema.fromJson({
      'type': 'string',
      'enum': ['a', 'b'],
      'enumNames': ['Alpha'],
    });

    expect(
      [for (final choice in property.choices) choice.label],
      ['Alpha', 'b'],
    );
  });

  test("a multiple choice reads its items' titled options", () {
    final property = ElicitationPropertySchema.fromJson({
      'type': 'array',
      'items': {
        'anyOf': [
          {'const': 'b', 'title': 'B'},
          {'const': 'a', 'title': 'A'},
        ],
      },
    });

    expect(
      [for (final choice in property.itemChoices) choice.label],
      ['B', 'A'],
    );
  });

  test('the request goes out with the wire names', () {
    final json = CreateElicitationRequest(
      message: 'Pick one',
      schema: ElicitationSchema(),
    ).toJson();

    expect(json['message'], 'Pick one');
    expect(json.containsKey('requestedSchema'), isTrue);
    expect(json.containsKey('schema'), isFalse);
  });
}
