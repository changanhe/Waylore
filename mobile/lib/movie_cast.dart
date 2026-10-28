import 'dart:convert';

import 'poster_search.dart';

class MovieCast {
  static List<String> parse(String html) {
    final names = <String>[];
    for (final tag in RegExp(
      r'''<a\b[^>]*rel\s*=\s*["\']v:starring["\'][^>]*>([\s\S]*?)</a>''',
      caseSensitive: false,
    ).allMatches(html)) {
      final name = PosterSearch.entities(
        tag.group(1)!.replaceAll(RegExp(r'<[^>]+>'), ''),
      ).trim();
      if (name.isNotEmpty && !names.contains(name)) names.add(name);
      if (names.length == 3) break;
    }
    return names;
  }

  static Future<List<String>> lookup(
    String title, {
    PosterResult? selected,
  }) async {
    PosterResult? work = selected;
    if (work == null || Uri.tryParse(work.url)?.host != 'movie.douban.com') {
      final uri = Uri.https('movie.douban.com', '/j/subject_suggest', {
        'q': title,
      });
      final data = jsonDecode(
        utf8.decode(await PosterSearch.fetch(uri, 2 * 1024 * 1024)),
      );
      final results = PosterSearch.doubanResults(data, title)
          .where(
            (r) =>
                PosterSearch.normalized(r.title.split(' · ').first) ==
                    PosterSearch.normalized(title) ||
                r.aliases.any(
                  (a) =>
                      PosterSearch.normalized(a) ==
                      PosterSearch.normalized(title),
                ),
          )
          .toList();
      // Ambiguous names require selecting a particular poster first.
      if (results.length != 1) return [];
      work = results.single;
    }
    final uri = Uri.parse(work.url);
    if (uri.host != 'movie.douban.com' ||
        !RegExp(r'^/subject/\d+/?$').hasMatch(uri.path)) {
      return [];
    }
    final id = uri.pathSegments[1];
    try {
      final details = jsonDecode(
        utf8.decode(
          await PosterSearch.fetch(
            Uri.https('m.douban.com', '/rexxar/api/v2/movie/$id'),
            3 * 1024 * 1024,
            sourceUrl: 'https://m.douban.com/',
          ),
        ),
      );
      final names = fromDetails(details);
      if (names.isNotEmpty) return names;
    } catch (_) {
      // Public detail pages remain a fallback if the structured source fails.
    }
    return parse(
      utf8.decode(
        await PosterSearch.fetch(uri, 3 * 1024 * 1024, sourceUrl: work.url),
      ),
    );
  }

  static List<String> fromDetails(dynamic details) {
    if (details is! Map || details['actors'] is! List) return [];
    final names = <String>[];
    for (final actor in details['actors']) {
      if (actor is! Map || actor['name'] is! String) continue;
      final name = (actor['name'] as String).trim();
      if (name.isNotEmpty && !names.contains(name)) names.add(name);
      if (names.length == 3) break;
    }
    return names;
  }
}
