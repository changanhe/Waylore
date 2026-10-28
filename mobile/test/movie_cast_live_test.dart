import 'package:flutter_test/flutter_test.dart';
import 'package:kexinglu_mobile/movie_cast.dart';

void main() {
  test('live Chinese titles return leading cast', () async {
    expect(await MovieCast.lookup('琅琊榜'), ['胡歌', '刘涛', '王凯']);
    expect((await MovieCast.lookup('流浪地球')).length, 3);
  }, skip: !const bool.fromEnvironment('CAST_LIVE'));
}
