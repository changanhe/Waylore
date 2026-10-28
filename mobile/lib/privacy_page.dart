import 'package:flutter/material.dart';

/// Bundled with the app so the policy remains readable without a browser/network.
class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  static const sections = <(String, String)>[
    (
      '本地记录与个人资料',
      '客行录是一款本地优先的旅行与生活记录应用。旅行、票根、食光、影视收藏、手帐中的文字、地点、日期与照片，以及主题、字体等偏好，默认保存在设备本地。你填写的昵称、头像、生日等资料用于展示个人页面和生日祝福；不登录也可以使用本机记录功能。\n\n应用不读取通讯录、短信或通话记录，不收集广告标识符，也不将你的记录出售或用于广告画像。',
    ),
    (
      '照片、文件与背景音乐',
      '当你主动选择照片、背景、素材或 MP3 音频时，应用读取所选文件并保存功能所需的本地副本。导入的音乐和每本手帐、每条旅行记录的配乐选择保存在本机，当前不会随云同步或记录备份一起迁移。内置音乐、素材及节日寄语可以离线使用。\n\n导出备份或分享手帐时，文件会包含你选择导出的内容；请自行选择接收方并妥善保管导出的文件。',
    ),
    (
      '可选账号与云同步',
      '账号服务由 Supabase 及你实际选择的登录服务商提供，处理邮箱、授权信息和登录会话。你发起同步时，记录与照片会经 HTTPS 传输至相应账号的云端空间；登录后编辑个人资料也可能更新账号资料，并非每次云端交互都需要再次点击同步。当前云服务可能位于境外。\n\n退出登录、删除应用或清除本机数据，不会自动删除云端副本。本机数据不会因为退出登录就被当作云端注销申请处理。',
    ),
    (
      '位置、天气与在线查询',
      '获得位置授权后，应用可读取当前或最近位置，用于显示当地天气；不在后台持续记录移动轨迹。天气查询向 Open-Meteo 发送经纬度，城市搜索发送搜索词，定位反查城市可能使用系统位置服务。拒绝位置权限后仍可手动选择城市。\n\n填写影视名称或搜索海报、主演时，作品名可能发送给豆瓣、Bangumi、百度百科、维基百科或 TVmaze，并从结果对应的图片地址加载海报。应用内置矢量地图可本地显示。',
    ),
    (
      '权限与第三方服务',
      '位置权限用于天气；照片和文件选择用于添加内容、导入音乐与备份；网络用于天气、城市搜索、影视资料、账号及同步。具体的文件选择与授权界面由设备系统提供。\n\n联网服务会接收完成请求所需的 IP 地址、查询参数及协议信息，其处理亦受各服务自身政策约束。应用启动时可能检查已配置的账号服务；天气启用后也会按功能需要刷新。关闭在线功能或断网后，核心本地记录仍可使用。',
    ),
    (
      '查看、导出与删除',
      '你可以在应用内查看、修改或删除自己的记录，并在「我的 → 数据备份」导出或导入备份。在系统设置中可撤回位置等权限。卸载、清除应用数据或设备损坏可能导致本机资料丢失，请提前备份。\n\n记录删除通过同步传播时，可能保留删除标记以处理跨设备一致性。如果需要删除云端资料、注销账号或咨询导出事项，请联系下方邮箱，我们将根据实际情况进行必要的账号归属核验。',
    ),
    (
      '未成年人、更新与联系',
      '未成年人请在监护人指导下使用，避免填写不必要的个人信息。功能或数据处理方式调整时，我们会更新本页面并注明日期。\n\n隐私问题、云端删除或账号注销申请：\nkexinglu@yeah.net\n\n请勿发送密码、验证码或私钥。',
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('隐私政策')),
    body: SelectionArea(
      child: ListView(
        key: const ValueKey('privacy-content'),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        children: [
          Text(
            '客行录 · Waylore\n更新日期：2026年10月28日',
            style: TextStyle(
              fontSize: 12,
              height: 1.8,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          for (final section in sections) ...[
            Text(
              section.$1,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              section.$2,
              style: const TextStyle(fontSize: 15, height: 1.85),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(height: 1),
            ),
          ],
        ],
      ),
    ),
  );
}
