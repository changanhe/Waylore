import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kexinglu_mobile/movie_cast.dart';
import 'package:kexinglu_mobile/feedback.dart';

void main() {
  test('structured cast is ordered, deduplicated and capped', () {
    expect(
      MovieCast.fromDetails({
        'actors': [
          {'name': '甲'},
          {'name': '甲'},
          {},
          {'name': '乙'},
          {'name': '丙'},
          {'name': '丁'},
        ],
      }),
      ['甲', '乙', '丙'],
    );
    expect(MovieCast.fromDetails({'error': 'unavailable'}), isEmpty);
  });
  test(
    'cast preserves billing order, removes duplicates and limits to three',
    () {
      expect(
        MovieCast.parse("""<a rel='v:directedBy'>导演</a>
      <a rel='v:starring'>甲</a><a rel='v:starring'>甲</a>
      <a class='actor' rel='v:starring'><span>乙 &amp; 丙</span></a>
      <a rel="v:starring">丁</a><a rel='v:starring'>戊</a>"""),
        ['甲', '乙 & 丙', '丁'],
      );
      expect(MovieCast.parse('<html>验证码</html>'), isEmpty);
    },
  );
  testWidgets('feedback stays above navigation, expires and allows undo', (
    t,
  ) async {
    var undone = false;
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Stack(
              children: [
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    key: const ValueKey('nav'),
                    height: 92,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text('导航'),
                    ),
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: () => showJournalMessage(
                      context,
                      SnackBar(
                        content: const Text('已删除'),
                        action: SnackBarAction(
                          label: '撤销',
                          onPressed: () => undone = true,
                        ),
                      ),
                    ),
                    child: const Text('删除'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('删除'));
    await t.pumpAndSettle();
    expect(
      t.getRect(find.text('已删除')).bottom,
      lessThan(t.getRect(find.byKey(const ValueKey('nav'))).top),
    );
    await t.tap(find.text('撤销'));
    await t.pumpAndSettle();
    expect(undone, isTrue);
    await t.tap(find.text('删除'));
    await t.pumpAndSettle();
    await t.pump(const Duration(seconds: 3));
    await t.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
  });
}
