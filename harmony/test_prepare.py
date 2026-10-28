"""Regression checks for upgrades in the isolated Harmony workspace."""
from pathlib import Path
import json
import tempfile
import unittest

from prepare import sync_native, native_build_output


class PrepareTests(unittest.TestCase):
    def test_rebuild_refreshes_native_entry_without_replacing_private_signing(self):
        with tempfile.TemporaryDirectory() as directory:
            workspace = Path(directory)
            sync_native(workspace, {'version': '1.0.0', 'build': 2})
            profile = workspace / 'ohos/build-profile.json5'
            private_profile = '{"local_signing": "test-marker-not-a-key"}'
            profile.write_text(private_profile, 'utf-8')
            data = workspace / 'local-test-record.json'
            data.write_text('{"title":"保留的测试记录"}', 'utf-8')
            entry = workspace / 'ohos/entry/src/main/ets/entryability/EntryAbility.ets'
            entry.write_text('stale generated workspace', 'utf-8')
            sync_native(workspace, {'version': '1.0.0', 'build': 3})
            self.assertEqual(profile.read_text('utf-8'), private_profile)
            self.assertIn('GeneratedPluginRegistrant.registerWith', entry.read_text('utf-8'))
            self.assertIn('保留的测试记录', data.read_text('utf-8'))
            manifest = json.loads((workspace / 'ohos/AppScope/app.json5').read_text('utf-8'))
            self.assertEqual(manifest['app']['versionCode'], 3)
            self.assertEqual(manifest['app']['versionName'], '1.0.0')
            self.assertEqual(manifest['app']['bundleName'], 'com.changanhe.kexinglu')

    def test_cache_output_filter_does_not_ignore_plugin_source_changes(self):
        self.assertTrue(native_build_output('plugin/ohos/build/output.hap'))
        self.assertTrue(native_build_output('plugin/ohos/oh_modules/package/generated.ets'))
        self.assertFalse(native_build_output('plugin/ohos/src/main/ets/Plugin.ets'))
        self.assertFalse(native_build_output('plugin/lib/plugin.dart'))


if __name__ == '__main__':
    unittest.main()
