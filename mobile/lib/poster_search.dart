import 'i18n.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'poster_crop.dart';

class PosterResult {
  final String title, image, source, url;
  final String preview;
  final List<String> aliases;
  const PosterResult(
    this.title,
    this.image,
    this.source,
    this.url, {
    String? preview,
    this.aliases = const [],
  }) : preview = preview ?? image;
}

class PosterReport {
  final List<PosterResult> results;
  final Map<String, String> failures;
  const PosterReport(this.results, this.failures);
}

class PosterSearch {
  static final _cache = <String, PosterReport>{};
  static final _cachedAt = <String, DateTime>{};
  static const agent =
      'Kexinglu/1.0 (https://github.com/changanhe1205-afk/kexinglu)';
  static String normalized(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[\s·:：\-—_()（）]'), '');
  static bool matches(String title, String query) =>
      normalized(query).isNotEmpty &&
      normalized(title).contains(normalized(query));
  static bool isScreenWork(String title, String description, String filename) {
    if (RegExp(
      r'soundtrack|disambiguation|novel|小说|小說|消歧|原声|原聲',
      caseSensitive: false,
    ).hasMatch('$title $description')) {
      return false;
    }
    if (RegExp(
      r'(film director|actor|actress|导演|導演|演員|演员|歌手)[.。]?$',
      caseSensitive: false,
    ).hasMatch(description.trim())) {
      return false;
    }
    return RegExp(
      r'\bfilm\b|television series|tv series|电视剧|電視劇|电影|電影|影集|劇集|剧集|海报|海報|poster',
      caseSensitive: false,
    ).hasMatch('$title $description $filename');
  }

  static List<PosterResult> wikiResults(
    Map<String, dynamic> data,
    String language,
  ) {
    if (data['error'] != null) throw const FormatException('百科搜索暂不可用');
    final pages = ((data['query'] ?? {})['pages'] ?? {}) as Map;
    final sorted = pages.values.toList()
      ..sort(
        (a, b) => (a['index'] as int? ?? 0).compareTo(b['index'] as int? ?? 0),
      );
    final result = <PosterResult>[];
    for (final page in sorted) {
      final thumb = page['thumbnail'];
      final description =
          ((page['terms'] as Map?)?['description'] as List? ?? []).join(' ');
      if (thumb is! Map ||
          thumb['source'] is! String ||
          !isScreenWork(
            '${page['title']}',
            description,
            '${page['pageimage'] ?? ''}',
          )) {
        continue;
      }
      result.add(
        PosterResult(
          page['title'],
          thumb['source'],
          'Wikipedia',
          Uri.https(
            '$language.wikipedia.org',
            '/wiki/${page['title']}',
          ).toString(),
        ),
      );
    }
    return result;
  }

  static String entities(String s) => s
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>');
  static List<PosterResult> baiduResults(String html, String query, Uri url) {
    final meta = <String, String>{};
    for (final tag in RegExp(
      r'<meta\b[^>]*>',
      caseSensitive: false,
    ).allMatches(html)) {
      final attrs = <String, String>{};
      for (final attr in RegExp(
        r"""([\w:-]+)\s*=\s*["']([^"']*)["']""",
      ).allMatches(tag.group(0)!)) {
        attrs[attr.group(1)!.toLowerCase()] = entities(attr.group(2)!);
      }
      final key = attrs['property'] ?? attrs['name'];
      if (key != null && attrs['content'] != null) {
        meta[key.toLowerCase()] = attrs['content']!;
      }
    }
    final title = (meta['og:title'] ?? query).replaceAll('_百度百科', '');
    final description = meta['description'] ?? meta['og:description'] ?? '';
    final image = meta['og:image'] ?? meta['image'];
    if (image == null ||
        !matches(title, query) ||
        !isScreenWork(title, description, '')) {
      return [];
    }
    final imageUri = url.resolve(image);
    if (imageUri.scheme != 'https') return [];
    return [PosterResult(title, imageUri.toString(), '百度百科', url.toString())];
  }

  static String httpsImage(dynamic value) {
    if (value is! String) return '';
    final uri = Uri.tryParse(value.startsWith('//') ? 'https:$value' : value);
    if (uri == null ||
        uri.host.isEmpty ||
        !['http', 'https'].contains(uri.scheme)) {
      return '';
    }
    return uri.replace(scheme: 'https').toString();
  }

  static List<PosterResult> doubanResults(dynamic data, String query) {
    if (data is! List) throw const FormatException('豆瓣响应格式不正确');
    final found = <PosterResult>[];
    for (final row in data.whereType<Map>()) {
      final title = '${row['title'] ?? ''}',
          alias = '${row['sub_title'] ?? ''}';
      if (row['type'] != 'movie' ||
          !(matches(title, query) || matches(alias, query))) {
        continue;
      }
      final preview = httpsImage(row['img']);
      final url = httpsImage(row['url']);
      if (preview.isEmpty || Uri.tryParse(url)?.host != 'movie.douban.com') {
        continue;
      }
      final image = Uri.parse(preview).host.endsWith('.doubanio.com')
          ? preview.replaceFirst('/s_ratio_poster/', '/r/')
          : preview;
      final year = '${row['year'] ?? ''}';
      found.add(
        PosterResult(
          '$title${year.isEmpty ? '' : ' · $year'}',
          image,
          '豆瓣',
          url,
          preview: preview,
          aliases: [alias],
        ),
      );
    }
    return found;
  }

  static List<PosterResult> bangumiResults(dynamic data, String query) {
    if (data is! Map) throw const FormatException('Bangumi响应格式不正确');
    final found = <PosterResult>[];
    for (final row in (data['list'] as List? ?? []).whereType<Map>()) {
      if (row['type'] != 2) continue;
      final cn = '${row['name_cn'] ?? ''}', name = '${row['name'] ?? ''}';
      if (!matches(cn, query) && !matches(name, query)) continue;
      final imgs = row['images'];
      if (imgs is! Map) continue;
      final image = httpsImage(imgs['large'] ?? imgs['common']);
      final preview = httpsImage(
        imgs['medium'] ?? imgs['common'] ?? imgs['large'],
      );
      if (image.isEmpty) continue;
      found.add(
        PosterResult(
          cn.isEmpty ? name : cn,
          image,
          'Bangumi',
          'https://bgm.tv/subject/${row['id']}',
          aliases: [cn, name],
          preview: preview.isEmpty ? image : preview,
        ),
      );
    }
    return found;
  }

  static List<PosterResult> tvmazeResults(dynamic data, String query) {
    if (data is! List) throw const FormatException('TVmaze响应格式不正确');
    final found = <PosterResult>[];
    for (final row in data.whereType<Map>()) {
      final show = row['show'];
      if (show is! Map) continue;
      final title = show['name'];
      final imgs = show['image'];
      if (title is! String || imgs is! Map || !matches(title, query)) continue;
      final image = httpsImage(imgs['original'] ?? imgs['medium']);
      if (image.isEmpty) continue;
      final preview = httpsImage(imgs['medium']);
      final year = '${show['premiered'] ?? ''}'.split('-').first;
      found.add(
        PosterResult(
          '$title${year.isEmpty ? '' : ' · $year'}',
          image,
          'TVmaze · CC BY-SA',
          httpsImage(show['url']),
          preview: preview.isEmpty ? image : preview,
        ),
      );
    }
    return found;
  }

  static String failure(Object error) {
    if (error is TimeoutException || error is SocketException) {
      return '连接超时或网络不可达';
    }
    if (error is HandshakeException) return '安全连接失败';
    if (error is HttpException) return error.message;
    return '搜索响应暂不可用';
  }

  static Future<PosterReport> search(
    String query, {
    bool refresh = false,
    void Function(PosterReport)? onUpdate,
  }) async {
    query = query.trim();
    final key = query.toLowerCase();
    if (key.isEmpty) return const PosterReport([], {});
    if (!refresh &&
        _cache.containsKey(key) &&
        DateTime.now().difference(_cachedAt[key]!) <
            const Duration(minutes: 2)) {
      return _cache[key]!;
    }
    final results = <PosterResult>[];
    final failures = <String, String>{};
    PosterReport snapshot() {
      final sorted = <String, PosterResult>{for (final r in results) r.image: r}
          .values
          .toList();
      int rank(PosterResult r) {
        final base = r.title.split(RegExp(r'\s*[（(]| · ')).first;
        return [
              base,
              ...r.aliases,
            ].any((v) => normalized(v) == normalized(query))
            ? 0
            : 1;
      }

      sorted.sort((a, b) {
        final relevance = rank(a).compareTo(rank(b));
        if (relevance != 0) return relevance;
        return (b.image != b.preview ? 1 : 0).compareTo(
          a.image != a.preview ? 1 : 0,
        );
      });
      return PosterReport(
        List.unmodifiable(sorted.take(24)),
        Map.unmodifiable(failures),
      );
    }

    Future<void> source(
      String name,
      Future<List<PosterResult>> Function() run,
    ) async {
      try {
        results.addAll(await run());
      } catch (e) {
        failures[name] = failure(e);
      }
      onUpdate?.call(snapshot());
    }

    final chinese = RegExp(r'[\u3400-\u9fff]').hasMatch(query);
    final language = chinese ? 'zh' : 'en';
    await Future.wait([
      source('豆瓣', () async {
        final uri = Uri.https('movie.douban.com', '/j/subject_suggest', {
          'q': query,
        });
        return doubanResults(
          jsonDecode(utf8.decode(await fetch(uri, 2 * 1024 * 1024))),
          query,
        );
      }),
      source('Bangumi', () async {
        final uri = Uri.https('api.bgm.tv', '/search/subject/$query', {
          'type': '2',
          'responseGroup': 'large',
          'max_results': '10',
        });
        return bangumiResults(
          jsonDecode(utf8.decode(await fetch(uri, 2 * 1024 * 1024))),
          query,
        );
      }),
      if (chinese)
        source('百度百科', () async {
          final uri = Uri.https('baike.baidu.com', '/item/$query');
          final raw = await fetch(uri, 3 * 1024 * 1024);
          final found = baiduResults(utf8.decode(raw), query, uri);
          if (found.isEmpty) {
            throw const HttpException('该公开页面未提供可自动提取的影视海报，可打开百科查找');
          }
          return found;
        }),
      source('Wikipedia', () async {
        final uri = Uri.https('$language.wikipedia.org', '/w/api.php', {
          'action': 'query',
          'format': 'json',
          'generator': 'search',
          'gsrsearch': query.replaceAll('"', ''),
          'gsrlimit': '8',
          'prop': 'pageimages|pageterms',
          'wbptterms': 'description',
          'piprop': 'thumbnail|name',
          'pilicense': 'any',
          'pithumbsize': '1200',
        });
        return wikiResults(
          jsonDecode(utf8.decode(await fetch(uri, 2 * 1024 * 1024))),
          language,
        );
      }),
      source('TVmaze', () async {
        final raw = await fetch(
          Uri.https('api.tvmaze.com', '/search/shows', {'q': query}),
          2 * 1024 * 1024,
        );
        return tvmazeResults(jsonDecode(utf8.decode(raw)), query);
      }),
    ]);
    final report = snapshot();
    // Brief partial caching avoids repeated requests while typing. Explicit retry always bypasses it.
    if (report.results.isNotEmpty) {
      if (_cache.length >= 40) {
        final first = _cache.keys.first;
        _cache.remove(first);
        _cachedAt.remove(first);
      }
      _cache[key] = report;
      _cachedAt[key] = DateTime.now();
    }
    return report;
  }

  static Map<String, String> headers(String sourceUrl) => {
    HttpHeaders.userAgentHeader: agent,
    if ([
      'baike.baidu.com',
      'movie.douban.com',
      'm.douban.com',
    ].contains(Uri.tryParse(sourceUrl)?.host))
      HttpHeaders.refererHeader: sourceUrl,
  };
  static Future<List<int>> fetch(
    Uri uri,
    int limit, {
    String sourceUrl = '',
  }) async {
    if (uri.scheme != 'https') throw const FormatException('需要 HTTPS 图片');
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      return await (() async {
        final request = await client.getUrl(uri);
        headers(sourceUrl).forEach(request.headers.set);
        final response = await request.close();
        if (response.statusCode != 200) {
          throw HttpException(
            response.statusCode == 403
                ? '来源拒绝自动访问（403）'
                : '来源响应 ${response.statusCode}',
          );
        }
        if (response.contentLength > limit) throw const FormatException('响应过大');
        if (response.redirects.any(
          (r) => r.location.scheme.isNotEmpty && r.location.scheme != 'https',
        )) {
          throw const FormatException('不安全的重定向');
        }
        final bytes = <int>[];
        await for (final part in response) {
          bytes.addAll(part);
          if (bytes.length > limit) throw const FormatException('响应过大');
        }
        return bytes;
      })().timeout(const Duration(seconds: 8));
    } finally {
      client.close(force: true);
    }
  }

  static Future<ui.Image> load(PosterResult poster) async {
    Object? error;
    for (final url in {poster.image, poster.preview}) {
      try {
        final bytes = await fetch(
          Uri.parse(url),
          12 * 1024 * 1024,
          sourceUrl: poster.url,
        );
        return await decodePoster(Uint8List.fromList(bytes));
      } catch (e) {
        error = e;
      }
    }
    throw error ?? const FormatException('没有可用海报');
  }

  static Future<String> save(PosterResult poster) async {
    final image = await load(poster);
    try {
      return await keepPoster(image, fill: true, offset: Offset.zero);
    } finally {
      image.dispose();
    }
  }
}

class PosterCandidates extends StatefulWidget {
  final String query;
  final void Function(String path, PosterResult poster) onSelected;
  const PosterCandidates({
    super.key,
    required this.query,
    required this.onSelected,
  });
  @override
  State<PosterCandidates> createState() => _PosterCandidatesState();
}

class _PosterCandidatesState extends State<PosterCandidates> {
  Timer? debounce;
  int generation = 0;
  bool busy = false, saving = false;
  String hint = '';
  List<PosterResult> results = [];
  Map<String, String> failures = {};
  @override
  void initState() {
    super.initState();
    schedule();
  }

  @override
  void didUpdateWidget(PosterCandidates old) {
    super.didUpdateWidget(old);
    if (old.query != widget.query) schedule();
  }

  @override
  void dispose() {
    generation++;
    debounce?.cancel();
    super.dispose();
  }

  void schedule({bool refresh = false}) {
    debounce?.cancel();
    final serial = ++generation;
    results = [];
    failures = {};
    hint = '';
    busy = widget.query.trim().isNotEmpty;
    if (!busy) return;
    debounce = Timer(const Duration(milliseconds: 550), () async {
      final report = await PosterSearch.search(
        widget.query,
        refresh: refresh,
        onUpdate: (p) {
          if (mounted && generation == serial) {
            setState(() {
              results = p.results;
              failures = p.failures;
            });
          }
        },
      );
      if (!mounted || serial != generation) return;
      setState(() {
        results = report.results;
        failures = report.failures;
        busy = false;
        if (results.isEmpty) hint = '暂未找到海报，可试试完整片名、原文名，或从相册导入。';
      });
    });
  }

  Future<void> select(PosterResult poster) async {
    if (saving) return;
    final serial = generation;
    setState(() {
      saving = true;
      hint = '正在获取清晰海报…';
    });
    ui.Image? image;
    try {
      image = await PosterSearch.load(poster);
      if (!mounted || serial != generation) return;
      final choice = await showModalBottomSheet<PosterCropChoice>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => PosterCropSheet(image: image!, title: poster.title),
      );
      if (choice == null || !mounted || serial != generation) {
        if (mounted) setState(() => hint = '');
        return;
      }
      setState(() => hint = '正在保存封面…');
      final path = await keepPoster(
        image,
        fill: choice.fill,
        offset: choice.offset,
        zoom: choice.zoom,
      );
      if (mounted && serial == generation) {
        widget.onSelected(path, poster);
        setState(() => hint = '封面已更新');
      }
    } catch (e) {
      if (mounted && serial == generation) {
        setState(() => hint = '海报导入失败：${PosterSearch.failure(e)}');
      }
    } finally {
      image?.dispose();
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 19,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: LocalText(
                  '发现影片海报',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              AnimatedSwitcher(
                duration: Duration(milliseconds: reduced ? 0 : 180),
                child: busy || saving
                    ? const SizedBox(
                        key: ValueKey('poster-busy'),
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        key: const ValueKey('poster-retry'),
                        tooltip: '重新查找',
                        onPressed: widget.query.trim().isEmpty
                            ? null
                            : () => setState(() => schedule(refresh: true)),
                        icon: const Icon(Icons.refresh_rounded, size: 19),
                      ),
              ),
            ],
          ),
          const LocalText(
            '多来源查找 · 原图优先 · 导入前可裁剪',
            style: TextStyle(fontSize: 11),
          ),
          if (hint.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(tr(hint), style: const TextStyle(fontSize: 12)),
            ),
          if (results.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 238,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: results.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final p = results[i];
                  return SizedBox(
                    key: ValueKey(p.image),
                    width: 112,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Material(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: saving ? null : () => select(p),
                            child: Image.network(
                              p.preview,
                              headers: PosterSearch.headers(p.url),
                              width: 112,
                              height: 168,
                              fit: BoxFit.cover,
                              cacheWidth: 336,
                              frameBuilder: (c, child, frame, sync) =>
                                  AnimatedOpacity(
                                    opacity: frame == null ? 0 : 1,
                                    duration: Duration(
                                      milliseconds: reduced || sync ? 0 : 200,
                                    ),
                                    child: child,
                                  ),
                              errorBuilder: (_, _, _) => const SizedBox(
                                width: 112,
                                height: 168,
                                child: Center(
                                  child: Icon(Icons.image_outlined),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          p.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11),
                        ),
                        InkWell(
                          onTap: () => launchUrl(
                            Uri.parse(p.url),
                            mode: LaunchMode.externalApplication,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              p.source,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.primary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
          if (!busy && failures.isNotEmpty)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              dense: true,
              title: const LocalText(
                '部分来源暂不可用',
                style: TextStyle(fontSize: 11),
              ),
              children: [
                for (final row in failures.entries)
                  ListTile(
                    dense: true,
                    title: Text(row.key),
                    subtitle: Text(row.value),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
