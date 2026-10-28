import 'dart:async';

import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';

class TestAudioPlatform extends JustAudioPlatform {
  int plays = 0;
  final players = <String, TestAudioPlayer>{};
  @override
  Future<AudioPlayerPlatform> init(InitRequest request) async =>
      players[request.id] = TestAudioPlayer(request.id, () => plays++);
  @override
  Future<DisposePlayerResponse> disposePlayer(
    DisposePlayerRequest request,
  ) async {
    await players.remove(request.id)?.dispose(DisposeRequest());
    return DisposePlayerResponse();
  }

  @override
  Future<DisposeAllPlayersResponse> disposeAllPlayers(
    DisposeAllPlayersRequest request,
  ) async => DisposeAllPlayersResponse();
}

class TestAudioPlayer extends AudioPlayerPlatform {
  final void Function() onPlay;
  Duration? lastSeek;
  Completer<PlayResponse>? pendingPlay;
  final events = StreamController<PlaybackEventMessage>.broadcast();
  TestAudioPlayer(super.id, this.onPlay);
  @override
  Stream<PlaybackEventMessage> get playbackEventMessageStream => events.stream;
  @override
  Future<LoadResponse> load(LoadRequest request) async {
    events.add(
      PlaybackEventMessage(
        processingState: ProcessingStateMessage.ready,
        updateTime: DateTime.now(),
        updatePosition: Duration.zero,
        bufferedPosition: const Duration(seconds: 40),
        duration: const Duration(seconds: 40),
        icyMetadata: null,
        currentIndex: 0,
        androidAudioSessionId: null,
      ),
    );
    return LoadResponse(duration: const Duration(seconds: 40));
  }

  @override
  Future<PlayResponse> play(PlayRequest request) async {
    onPlay();
    pendingPlay = Completer<PlayResponse>();
    return pendingPlay!.future;
  }

  @override
  Future<PauseResponse> pause(PauseRequest request) async {
    if (pendingPlay?.isCompleted == false) {
      pendingPlay!.complete(PlayResponse());
    }
    events.add(
      PlaybackEventMessage(
        processingState: ProcessingStateMessage.ready,
        updateTime: DateTime.now(),
        updatePosition: const Duration(seconds: 1),
        bufferedPosition: const Duration(seconds: 40),
        duration: const Duration(seconds: 40),
        icyMetadata: null,
        currentIndex: 0,
        androidAudioSessionId: null,
      ),
    );
    return PauseResponse();
  }

  @override
  Future<DisposeResponse> dispose(DisposeRequest request) async {
    await events.close();
    return DisposeResponse();
  }

  @override
  Future<SetVolumeResponse> setVolume(SetVolumeRequest request) async =>
      SetVolumeResponse();
  @override
  Future<SetSpeedResponse> setSpeed(SetSpeedRequest request) async =>
      SetSpeedResponse();
  @override
  Future<SetPitchResponse> setPitch(SetPitchRequest request) async =>
      SetPitchResponse();
  @override
  Future<SetSkipSilenceResponse> setSkipSilence(
    SetSkipSilenceRequest request,
  ) async => SetSkipSilenceResponse();
  @override
  Future<SetLoopModeResponse> setLoopMode(SetLoopModeRequest request) async =>
      SetLoopModeResponse();
  @override
  Future<SetShuffleModeResponse> setShuffleMode(
    SetShuffleModeRequest request,
  ) async => SetShuffleModeResponse();
  @override
  Future<SetAndroidAudioAttributesResponse> setAndroidAudioAttributes(
    SetAndroidAudioAttributesRequest request,
  ) async => SetAndroidAudioAttributesResponse();
  @override
  Future<SeekResponse> seek(SeekRequest request) async {
    lastSeek = request.position;
    return SeekResponse();
  }
}
