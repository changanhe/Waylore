import 'package:lunar/lunar.dart';

enum FestivalArt { lantern, moon, blossom, earth, sparkle, snow, quiet }

class JournalFestival {
  final String id, name, title, wish, english;
  final FestivalArt art;
  final bool international;
  final int priority;
  const JournalFestival(
    this.id,
    this.name,
    this.title,
    this.wish,
    this.english,
    this.art, {
    this.international = false,
    this.priority = 50,
  });
}

/// Curated observances, not public-holiday/workday schedules. All calculation
/// uses the user's local calendar date, with no network or location permission.
class FestivalCalendar {
  static const chinese = <String, JournalFestival>{
    '1-1': JournalFestival(
      'spring',
      '春节',
      '新岁启封',
      '愿灯火可亲，团圆有期。\n把新一年的好故事，慢慢写进客行录。',
      'A new chapter begins',
      FestivalArt.lantern,
      priority: 100,
    ),
    '1-15': JournalFestival(
      'lantern',
      '元宵节',
      '灯月相逢',
      '愿人间灯火，照亮你的归途。\n所念皆圆，所行皆暖。',
      'Under the lantern light',
      FestivalArt.lantern,
      priority: 90,
    ),
    '2-2': JournalFestival(
      'dragon_head',
      '龙抬头',
      '春来万物新',
      '抬头见春，向前有光。\n愿新的出发，遇见新的风景。',
      'Welcome the spring',
      FestivalArt.blossom,
    ),
    '5-5': JournalFestival(
      'dragon_boat',
      '端午节',
      '一叶安康',
      '粽叶裹住夏日的清香，\n愿你岁岁安康，沿途有好风光。',
      'A wish for peace and health',
      FestivalArt.earth,
      priority: 90,
    ),
    '7-7': JournalFestival(
      'qixi',
      '七夕',
      '把心意珍藏',
      '愿所有真挚的牵挂，都有温柔的回应。\n也别忘了，好好爱今天的自己。',
      'Keep a little tenderness',
      FestivalArt.sparkle,
    ),
    '8-15': JournalFestival(
      'mid_autumn',
      '中秋节',
      '月满人间',
      '无论此刻身在何处，\n愿一轮明月，把牵挂送到你身边。',
      'May the moon bring us closer',
      FestivalArt.moon,
      priority: 95,
    ),
    '9-9': JournalFestival(
      'double_ninth',
      '重阳节',
      '秋高，念长',
      '把思念写进秋风，把问候送给牵挂的人。\n愿时光温柔，岁岁安康。',
      'Warm wishes across the miles',
      FestivalArt.blossom,
    ),
    '12-8': JournalFestival(
      'laba',
      '腊八节',
      '岁末有暖',
      '一碗热粥，一份惦念。\n愿你在寒冬里，也有暖意相伴。',
      'A little warmth in winter',
      FestivalArt.snow,
    ),
  };

  static const fixed = <String, JournalFestival>{
    '1-1': JournalFestival(
      'new_year',
      '元旦',
      '你好，新一年',
      '愿新的日子，有期待，有远方。\n也有值得认真收藏的小小日常。',
      'Hello, new year',
      FestivalArt.sparkle,
      priority: 90,
    ),
    '2-14': JournalFestival(
      'valentine',
      '情人节',
      '让爱有迹可循',
      '愿真心被珍惜，温柔有归处。\n把今天的心意，留成一页回忆。',
      'Love in the little things',
      FestivalArt.blossom,
      international: true,
    ),
    '3-8': JournalFestival(
      'women',
      '国际妇女节',
      '自在生长，自有光芒',
      '愿每一种选择都被尊重，\n每一份热爱，都有自由生长的空间。',
      'Respect every voice',
      FestivalArt.blossom,
      international: true,
    ),
    '3-20': JournalFestival(
      'happiness',
      '国际幸福日',
      '把小小幸福收好',
      '一顿好饭，一阵晚风，一次相逢。\n愿今天的你，拥有自己的幸福刻度。',
      'Happiness lives in small moments',
      FestivalArt.sparkle,
      international: true,
    ),
    '3-22': JournalFestival(
      'water',
      '世界水日',
      '珍惜每一滴清澈',
      '愿走过的山川长清，\n让珍惜成为日常的小小习惯。',
      'Every drop matters',
      FestivalArt.earth,
      international: true,
    ),
    '4-22': JournalFestival(
      'earth',
      '世界地球日',
      '与世界，温柔相处',
      '少留一点足迹，多留一份美好。\n愿每次出发，都珍惜脚下这颗星球。',
      'Our one beautiful home',
      FestivalArt.earth,
      international: true,
    ),
    '4-23': JournalFestival(
      'book',
      '世界读书日',
      '翻开一页，走向远方',
      '书里有未曾走过的路，\n也有帮我们读懂生活的光。',
      'A page can open a world',
      FestivalArt.sparkle,
      international: true,
    ),
    '5-1': JournalFestival(
      'labour',
      '劳动节',
      '认真生活的人，辛苦了',
      '愿每一份付出被看见，\n忙碌之外，也留一点时间给自己。',
      'For everyone who makes a difference',
      FestivalArt.blossom,
      priority: 85,
    ),
    '5-18': JournalFestival(
      'museum',
      '国际博物馆日',
      '与时间，见一面',
      '去看一件旧物，听一段往事。\n愿每次驻足，都发现世界的厚度。',
      'Stories across time',
      FestivalArt.sparkle,
      international: true,
    ),
    '6-1': JournalFestival(
      'children',
      '儿童节',
      '愿童心，永远有光',
      '愿孩子们自在长大，\n也愿每个大人，仍保留发现快乐的眼睛。',
      'Keep a little wonder',
      FestivalArt.sparkle,
    ),
    '6-5': JournalFestival(
      'environment',
      '世界环境日',
      '把绿色，留给明天',
      '让清风、绿意和干净的河流，\n成为每一程都能遇见的风景。',
      'Small actions, a greener world',
      FestivalArt.earth,
      international: true,
    ),
    '6-8': JournalFestival(
      'oceans',
      '世界海洋日',
      '听见海的回响',
      '愿海风依旧清澈，浪花仍有生机。\n每一份珍惜，都能抵达更远的蓝。',
      'For the blue we share',
      FestivalArt.earth,
      international: true,
    ),
    '7-30': JournalFestival(
      'friendship',
      '国际友谊日',
      '有些同行，值得珍藏',
      '想起一个陪你走过一段路的人。\n愿久别仍亲切，问候不必等很久。',
      'Good company, lasting memories',
      FestivalArt.blossom,
      international: true,
    ),
    '8-12': JournalFestival(
      'youth',
      '国际青年日',
      '热爱，正当时',
      '愿好奇不被岁月带走，\n想做的事，都有勇气迈出第一步。',
      'Stay curious, keep going',
      FestivalArt.sparkle,
      international: true,
    ),
    '8-19': JournalFestival(
      'photography',
      '世界摄影日',
      '把这一刻，留住',
      '光影会流动，回忆能停留。\n愿你拍下的，不只是风景，还有心动。',
      'Keep the light you find',
      FestivalArt.sparkle,
      international: true,
    ),
    '9-10': JournalFestival(
      'teachers',
      '教师节',
      '谢谢，那些引路的光',
      '一段教诲，一生回响。\n愿每一位认真耕耘的人，被温柔以待。',
      'Thank you for lighting the way',
      FestivalArt.blossom,
    ),
    '9-21': JournalFestival(
      'peace',
      '国际和平日',
      '愿每一程，都平安',
      '愿世界少些纷争，多些理解。\n让平凡而安稳的日子，成为共同的风景。',
      'May every journey be peaceful',
      FestivalArt.quiet,
      international: true,
    ),
    '9-27': JournalFestival(
      'tourism',
      '世界旅游日',
      '世界很大，慢慢去看',
      '去遇见不同的风景，也尊重不同的生活。\n愿每一程，都有值得带回的故事。',
      'Travel with curiosity and care',
      FestivalArt.earth,
      international: true,
      priority: 70,
    ),
    '10-1': JournalFestival(
      'national',
      '国庆节',
      '山河锦绣，步履从容',
      '愿山河安宁，生活明朗。\n出发看风景，也把平安带回家。',
      'Beautiful places, peaceful days',
      FestivalArt.lantern,
      priority: 95,
    ),
    '10-4': JournalFestival(
      'animals',
      '世界动物日',
      '给万物，多一点温柔',
      '愿每一个小小生命，\n都能在这颗星球上找到安稳的角落。',
      'A kinder world for every life',
      FestivalArt.earth,
      international: true,
    ),
    '10-10': JournalFestival(
      'mental_health',
      '世界精神卫生日',
      '今天，也照顾好自己',
      '不必每时每刻都表现得很好。\n累了就歇一歇，你的感受值得被认真对待。',
      'Make room for yourself',
      FestivalArt.quiet,
      international: true,
    ),
    '10-16': JournalFestival(
      'food',
      '世界粮食日',
      '珍惜，一餐一饭',
      '记住一餐的滋味，也记得食物的来处。\n愿每个人，都能安心吃好一顿饭。',
      'Every meal matters',
      FestivalArt.earth,
      international: true,
    ),
    '10-31': JournalFestival(
      'halloween',
      '万圣夜',
      '今晚，收集一点奇妙',
      '把平凡的夜晚，装进一点想象。\n愿今天有小惊喜，也有甜甜的心情。',
      'A little magic tonight',
      FestivalArt.sparkle,
      international: true,
    ),
    '11-13': JournalFestival(
      'kindness',
      '世界善意日',
      '把善意，轻轻传递',
      '一句谢谢，一次体谅，一个微笑。\n愿你的温柔，也被世界温柔接住。',
      'Kindness goes a long way',
      FestivalArt.blossom,
      international: true,
    ),
    '12-5': JournalFestival(
      'volunteers',
      '国际志愿人员日',
      '谢谢，让世界更好的人',
      '每一份微小而真诚的付出，\n都能让某个人的今天更明亮。',
      'Small acts, meaningful change',
      FestivalArt.blossom,
      international: true,
    ),
    '12-13': JournalFestival(
      'memorial',
      '国家公祭日',
      '铭记历史，珍爱和平',
      '以安静的缅怀，记住不能忘却的历史。\n愿和平长存。',
      'Remember, and cherish peace',
      FestivalArt.quiet,
      priority: 100,
    ),
    '12-24': JournalFestival(
      'christmas_eve',
      '平安夜',
      '愿今夜，平安温暖',
      '愿惦念的人安好，\n愿窗前的灯，照亮一段温暖的归途。',
      'A peaceful winter evening',
      FestivalArt.snow,
      international: true,
    ),
    '12-25': JournalFestival(
      'christmas',
      '圣诞节',
      '把温暖，送到你身边',
      '愿寒冬有暖意，平凡有惊喜。\n把一份祝福，送给此刻的你。',
      'Warm wishes for the season',
      FestivalArt.snow,
      international: true,
    ),
    '12-31': JournalFestival(
      'year_end',
      '跨年夜',
      '这一年，值得珍藏',
      '谢谢这一年认真生活的自己。\n愿下一程，仍有热爱，仍有期待。',
      'Keep the memories, welcome tomorrow',
      FestivalArt.sparkle,
    ),
  };

  static const eve = JournalFestival(
    'eve',
    '除夕',
    '灯火可亲，岁岁相守',
    '把旧岁的故事轻轻合上，\n愿新年的第一盏灯，照见团圆与希望。',
    'A warm light for the new year',
    FestivalArt.lantern,
    priority: 100,
  );
  static const qingming = JournalFestival(
    'qingming',
    '清明',
    '清明寄思',
    '把思念安放在春风里。\n愿记忆中的温暖，陪我们认真走好往后的路。',
    'In remembrance, with tenderness',
    FestivalArt.quiet,
    priority: 90,
  );
  static const winter = JournalFestival(
    'winter',
    '冬至',
    '冬至已至，暖意将归',
    '长夜之后，白昼渐长。\n愿你有热饭暖汤，也有向光而行的力量。',
    'The light begins to return',
    FestivalArt.snow,
  );
  static const spring = JournalFestival(
    'spring_begins',
    '立春',
    '从春天，重新出发',
    '万物正醒来，好事在路上。\n愿你心里有光，眼里有新的风景。',
    'A fresh beginning',
    FestivalArt.blossom,
  );
  static const mothers = JournalFestival(
    'mothers',
    '母亲节',
    '致每一份温柔的守护',
    '愿那些付出爱与照料的人，\n也被看见，被理解，被好好珍惜。',
    'For every caring heart',
    FestivalArt.blossom,
    international: true,
  );
  static const fathers = JournalFestival(
    'fathers',
    '父亲节',
    '致那些无声的守护',
    '有些关心，藏在平常的日子里。\n愿每一份守护，都有温暖的回应。',
    'For the quiet ways of caring',
    FestivalArt.earth,
    international: true,
  );
  static const thanks = JournalFestival(
    'thanksgiving',
    '感恩节（美国）',
    '把谢谢，说给生活',
    '感谢一段相伴，一次善意，一餐热饭。\n愿我们始终看得见，日子里的小小馈赠。',
    'Grateful for the little things',
    FestivalArt.blossom,
    international: true,
  );
  static const easter = JournalFestival(
    'easter',
    '复活节（西方）',
    '迎接新的希望',
    '春光里，万物重新生长。\n愿新的希望，也在你的日常里悄悄发芽。',
    'A season of renewal',
    FestivalArt.blossom,
    international: true,
  );
  static final Map<String, List<JournalFestival>> _cache = {};

  static String dayKey(DateTime date) =>
      '${date.year}-${date.month}-${date.day}';

  static List<JournalFestival> on(DateTime input, {bool international = true}) {
    final date = input.toLocal();
    final key = dayKey(date);
    final all = _cache.putIfAbsent(key, () => _calculate(date));
    if (_cache.length > 80) _cache.remove(_cache.keys.first);
    return List.unmodifiable(
      all.where((e) => international || !e.international),
    );
  }

  static List<JournalFestival> _calculate(DateTime date) {
    final events = <JournalFestival>[];
    final solar = fixed['${date.month}-${date.day}'];
    if (solar != null) events.add(solar);
    if (date.year >= 1901 && date.year <= 2100) {
      final lunar = Lunar.fromDate(
        DateTime(date.year, date.month, date.day, 12),
      );
      // Negative month means a leap lunar month: do not duplicate festivals.
      final traditional = chinese['${lunar.getMonth()}-${lunar.getDay()}'];
      if (traditional != null) events.add(traditional);
      final tomorrow = Lunar.fromDate(
        DateTime(date.year, date.month, date.day + 1, 12),
      );
      if (tomorrow.getMonth() == 1 && tomorrow.getDay() == 1) events.add(eve);
      final term = lunar.getJieQi();
      if (term == '清明') events.add(qingming);
      if (term == '冬至') events.add(winter);
      if (term == '立春') events.add(spring);
    }
    final week = (date.day - 1) ~/ 7 + 1;
    if (date.weekday == DateTime.sunday && date.month == 5 && week == 2) {
      events.add(mothers);
    }
    if (date.weekday == DateTime.sunday && date.month == 6 && week == 3) {
      events.add(fathers);
    }
    if (date.weekday == DateTime.thursday && date.month == 11 && week == 4) {
      events.add(thanks);
    }
    if (date.month == 3 || date.month == 4) {
      final e = easterDate(date.year);
      if (e.month == date.month && e.day == date.day) events.add(easter);
    }
    events.sort(
      (a, b) => b.priority != a.priority
          ? b.priority.compareTo(a.priority)
          : a.id.compareTo(b.id),
    );
    return List.unmodifiable(events);
  }

  /// Gregorian Easter (Western churches), not an all-country public holiday.
  static DateTime easterDate(int year) {
    final a = year % 19, b = year ~/ 100, c = year % 100;
    final d = b ~/ 4, e = b % 4, f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3, h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4, k = c % 4, l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    return DateTime(
      year,
      (h + l - 7 * m + 114) ~/ 31,
      (h + l - 7 * m + 114) % 31 + 1,
    );
  }

  static List<JournalFestival> get examples => [
    eve,
    chinese['1-1']!,
    chinese['1-15']!,
    chinese['5-5']!,
    chinese['8-15']!,
    qingming,
    fixed['1-1']!,
    fixed['3-8']!,
    fixed['4-22']!,
    fixed['9-27']!,
    fixed['10-1']!,
    fixed['12-25']!,
    ...fixed.values.where(
      (e) => ![
        'new_year',
        'women',
        'earth',
        'tourism',
        'national',
        'christmas',
      ].contains(e.id),
    ),
    mothers,
    fathers,
    thanks,
    easter,
    winter,
    ...chinese.values.where(
      (e) => !['spring', 'lantern', 'dragon_boat', 'mid_autumn'].contains(e.id),
    ),
  ];

  static String dailyWish(DateTime date) {
    const wishes = [
      '今天出门时，留意一下路边的树。也许已经换了颜色。',
      '如果经过一家想去的店，记下它的名字，下次不必再找。',
      '给今天拍一张照片，不一定要有特别的理由。',
      '一段旅程里，临时改变的路线往往也值得记录。',
      '吃到喜欢的东西，记下店名和位置。以后的你会用得上。',
      '找一张很久以前的照片，看看当时的自己去了哪里。',
      '今天有没有一件小事，让你想讲给朋友听？',
      '有空就走一条不同的路，熟悉的城市也会有新发现。',
      '想不起来写什么时，可以从今天的天气开始。',
      '留下一张车票，也就留下了一次出发的时间。',
      '不必把每一天都安排满。空着的半天，也可以过得很好。',
      '如果今天看到好看的天空，停一会儿再走。',
      '把旅途中听到的一句话写下来，哪怕只是随口的招呼。',
      '一杯热饮、一张靠窗的座位，都可以成为今天的记录。',
      '翻翻上一次旅行的手账，或许会想起漏写的小事。',
      '记录不必完整。只留下一句话，也比忘记好。',
      '给下次出行留一个小愿望：一条街、一座山，或一顿早饭。',
      '走累了就坐一会儿。休息也是旅程的一部分。',
      '把喜欢的照片放进手账，再写下照片之外的故事。',
      '今天可以试着记下一个声音：鸟鸣、雨声，或车站的广播。',
      '回到熟悉的地方，也可以重新拍一张照片。',
      '看过的电影、吃过的饭，都是这一段生活的线索。',
      '给今天选一首音乐，过些时候再听，或许还能想起此刻。',
      '不赶时间的时候，看看车窗外的风景。',
      '有些小地方，地图上很普通，走过之后就不一样了。',
      '把想去的地方写下来。计划可以慢慢做。',
      '记下一次愉快的相遇，也记下当时的地点。',
      '旧照片不一定要修得很完美。它原来的样子也很好。',
      '如果今天待在家里，可以记录窗外的光。',
      '写完这一页，记得给自己留一点休息的时间。',
    ];
    final ordinal = DateTime.utc(
      date.year,
      date.month,
      date.day,
    ).difference(DateTime.utc(2020)).inDays;
    return wishes[ordinal % wishes.length];
  }
}
