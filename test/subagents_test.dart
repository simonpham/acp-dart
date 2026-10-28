import 'dart:convert';

import 'package:acp_dart/src/schema.dart';
import 'package:acp_dart/src/session_update_converter.dart';
import 'package:test/test.dart';

/// Updates as claude-agent-acp sends them in the ACP subagents draft.
SessionUpdate _update(String json) => const SessionUpdateConverter().fromJson(
  jsonDecode(json) as Map<String, dynamic>,
);

void main() {
  group('Subagents', () {
    test('a client declares subagents as an empty object, or not at all', () {
      final declared = ClientCapabilities(
        subagents: const SubagentsCapability(),
      ).toJson();
      final plain = ClientCapabilities().toJson();

      expect(declared['subagents'], <String, dynamic>{});
      expect(plain.containsKey('subagents'), isFalse);
      expect(
        ClientCapabilities.fromJson(jsonDecode(jsonEncode(declared))).subagents,
        isNotNull,
      );
    });

    test('a subagent is announced, then changes state', () {
      final announce = _update(
        '{"sessionUpdate":"subagent_update","sessionId":"agent_n",'
        '"title":"general-purpose","description":"Fix the build",'
        '"capabilities":{"cancel":{}},"state":{"state":"running"}}',
      );
      final failed = _update(
        '{"sessionUpdate":"subagent_update","sessionId":"agent_n",'
        '"state":{"state":"idle","stopReason":"error",'
        '"error":{"code":-32603,"message":"Build broke"}}}',
      );

      expect(announce, isA<SubagentUpdate>());
      final announced = announce as SubagentUpdate;
      expect(announced.sessionId, 'agent_n');
      expect(announced.title, 'general-purpose');
      expect(announced.description, 'Fix the build');
      expect(announced.capabilities?.cancel, isTrue);
      expect(announced.state?.state, 'running');

      final ended = failed as SubagentUpdate;
      expect(ended.title, isNull);
      expect(ended.state?.stopReason, 'error');
      expect(ended.state?.error?.message, 'Build broke');
      expect(
        const SessionUpdateConverter().toJson(ended)['sessionUpdate'],
        'subagent_update',
      );
    });

    test('a message between sessions carries its content', () {
      final message = _update(
        '{"sessionUpdate":"session_message","messageId":"toolu_task:reply",'
        '"senderSessionId":"agent_1","recipientSessionId":"root",'
        '"content":[{"type":"text","text":"The parser is in x.ts."}]}',
      );

      expect(message, isA<SessionMessageUpdate>());
      final reply = message as SessionMessageUpdate;
      expect(reply.senderSessionId, 'agent_1');
      expect(reply.recipientSessionId, 'root');
      expect((reply.content.single as TextContentBlock).text, contains('x.ts'));
      expect(
        const SessionUpdateConverter().toJson(reply),
        containsPair('sessionUpdate', 'session_message'),
      );
    });
  });
}
