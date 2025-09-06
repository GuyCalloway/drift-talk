import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:voice_ai_app/features/voice_chat/presentation/bloc/voice_chat_bloc.dart';
import 'package:voice_ai_app/features/voice_chat/presentation/bloc/voice_chat_state.dart';
import 'package:voice_ai_app/features/voice_chat/presentation/bloc/voice_chat_event.dart';
import 'package:voice_ai_app/features/voice_chat/presentation/pages/voice_chat_page.dart';
import 'package:voice_ai_app/features/voice_chat/domain/entities/voice_message.dart';
import 'package:voice_ai_app/shared/theme/app_theme.dart';

import 'voice_chat_page_test.mocks.dart';

@GenerateMocks([VoiceChatBloc])
void main() {
  group('VoiceChatPage Widget Tests', () {
    late MockVoiceChatBloc mockVoiceChatBloc;
    late MockAudioBloc mockAudioBloc;

    setUp(() {
      mockVoiceChatBloc = MockVoiceChatBloc();
      mockAudioBloc = MockAudioBloc();

      // Setup default states
      when(mockVoiceChatBloc.state).thenReturn(const VoiceChatInitial());
      when(mockVoiceChatBloc.stream).thenAnswer((_) => Stream.empty());
      when(mockAudioBloc.state).thenReturn(const AudioInitial());
      when(mockAudioBloc.stream).thenAnswer((_) => Stream.empty());
    });

    Widget createWidgetUnderTest() {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<VoiceChatBloc>.value(value: mockVoiceChatBloc),
            BlocProvider<AudioBloc>.value(value: mockAudioBloc),
          ],
          child: const VoiceChatPage(),
        ),
      );
    }

    testWidgets('displays app bar with correct title', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Voice AI Assistant'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('shows loading indicator when state is initial', (WidgetTester tester) async {
      when(mockVoiceChatBloc.state).thenReturn(const VoiceChatInitial());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows loading indicator when state is loading', (WidgetTester tester) async {
      when(mockVoiceChatBloc.state).thenReturn(const VoiceChatLoading());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when connected with no messages', (WidgetTester tester) async {
      when(mockVoiceChatBloc.state).thenReturn(const VoiceChatConnected(
        messages: [],
        connectionStatus: ConnectionStatus.connected,
      ));

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Start a conversation'), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
    });

    testWidgets('displays messages when connected with messages', (WidgetTester tester) async {
      final testMessage = VoiceMessage(
        id: '1',
        content: 'Hello, AI!',
        type: MessageType.user,
        status: MessageStatus.sent,
        timestamp: DateTime.now(),
      );

      when(mockVoiceChatBloc.state).thenReturn(VoiceChatConnected(
        messages: [testMessage],
        connectionStatus: ConnectionStatus.connected,
      ));

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Hello, AI!'), findsOneWidget);
    });

    testWidgets('shows message input when connected', (WidgetTester tester) async {
      when(mockVoiceChatBloc.state).thenReturn(const VoiceChatConnected(
        messages: [],
        connectionStatus: ConnectionStatus.connected,
      ));

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(TextField), findsAtLeastNWidgets(1));
      expect(find.text('Type your message...'), findsOneWidget);
    });

    testWidgets('disables message input when not connected', (WidgetTester tester) async {
      when(mockVoiceChatBloc.state).thenReturn(const VoiceChatDisconnected(
        messages: [],
      ));

      await tester.pumpWidget(createWidgetUnderTest());

      final textField = tester.widget<TextField>(find.byType(TextField).first);
      expect(textField.enabled, isFalse);
    });

    testWidgets('sends message when send button is tapped', (WidgetTester tester) async {
      when(mockVoiceChatBloc.state).thenReturn(const VoiceChatConnected(
        messages: [],
        connectionStatus: ConnectionStatus.connected,
      ));

      await tester.pumpWidget(createWidgetUnderTest());

      // Enter text
      await tester.enterText(find.byType(TextField).first, 'Test message');
      await tester.pump();

      // Tap send button
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      // Verify the bloc received the event
      verify(mockVoiceChatBloc.add(
        argThat(isA<VoiceChatMessageSent>()
            .having((event) => event.message, 'message', 'Test message')),
      )).called(1);
    });

    testWidgets('shows connection status icon in app bar', (WidgetTester tester) async {
      when(mockVoiceChatBloc.state).thenReturn(const VoiceChatConnected(
        messages: [],
        connectionStatus: ConnectionStatus.connected,
      ));

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
    });

    testWidgets('shows error snackbar when VoiceChatError occurs', (WidgetTester tester) async {
      when(mockVoiceChatBloc.state).thenReturn(const VoiceChatInitial());
      when(mockVoiceChatBloc.stream).thenAnswer(
        (_) => Stream.value(const VoiceChatError(
          message: 'Connection failed',
          messages: [],
          connectionStatus: ConnectionStatus.error,
        )),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(); // Trigger the listener

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Connection failed'), findsOneWidget);
    });

    testWidgets('shows permission dialog when AudioPermissionRequired', (WidgetTester tester) async {
      when(mockVoiceChatBloc.state).thenReturn(const VoiceChatConnected(
        messages: [],
        connectionStatus: ConnectionStatus.connected,
      ));
      when(mockAudioBloc.state).thenReturn(const AudioInitial());
      when(mockAudioBloc.stream).thenAnswer(
        (_) => Stream.value(const AudioPermissionRequired()),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(); // Trigger the listener

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Microphone Permission Required'), findsOneWidget);
      expect(find.text('Grant Permission'), findsOneWidget);
    });

    testWidgets('toggles connection when connection status is tapped', (WidgetTester tester) async {
      when(mockVoiceChatBloc.state).thenReturn(const VoiceChatConnected(
        messages: [],
        connectionStatus: ConnectionStatus.connected,
      ));

      await tester.pumpWidget(createWidgetUnderTest());

      // Tap the connection status icon
      await tester.tap(find.byIcon(Icons.cloud_done));
      await tester.pump();

      // Verify disconnect was requested
      verify(mockVoiceChatBloc.add(const VoiceChatDisconnectRequested())).called(1);
    });
  });
}