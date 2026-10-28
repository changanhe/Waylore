"""Prepare an isolated HarmonyOS workspace from the maintained mobile sources.

Requires Python + PyYAML. Does not modify the Android dependency graph, user data,
or signing configuration. Community plugins are pinned by commit, never HEAD.
"""
from pathlib import Path
import argparse
import json
import re
import shutil
import subprocess
import tarfile
import yaml

ROOT = Path(__file__).resolve().parents[1]
HERE = ROOT / 'harmony'


def replace_once(text, old, new):
    if text.count(old) != 1:
        raise RuntimeError(f'Mobile source changed; review Harmony adapter: {old}')
    return text.replace(old, new, 1)


def native_build_output(path):
    parts = Path(path).parts
    if 'ohos' not in parts:
        return False
    native = parts[parts.index('ohos') + 1:]
    return bool(native) and (
        native[0] in {'oh_modules', '.hvigor', 'build', '.cxx'}
        or native[-1] in {'BuildProfile.ets', 'oh-package-lock.json5'}
    )


def sync_native(workspace, release):
    """Update maintained native files while retaining local signing and data."""
    if not (workspace / 'ohos').exists():
        shutil.copytree(HERE / 'ohos', workspace / 'ohos')
    for relative in ['AppScope/app.json5', 'entry/src/main/module.json5',
                     'entry/src/main/ets/entryability/EntryAbility.ets']:
        shutil.copyfile(HERE / 'ohos' / relative, workspace / 'ohos' / relative)
    app_manifest = workspace / 'ohos/AppScope/app.json5'
    app_source = app_manifest.read_text('utf-8')
    app_source = re.sub(r'("versionCode"\s*:\s*)\d+', lambda m: m[1] + str(release['build']), app_source)
    app_source = re.sub(r'("versionName"\s*:\s*)"[^"]+"', lambda m: m[1] + json.dumps(release['version']), app_source)
    app_manifest.write_text(app_source, 'utf-8')


def prepare(cache):
    workspace = ROOT / 'build/harmony-app'
    workspace.mkdir(parents=True, exist_ok=True)
    lock = json.loads((HERE / 'toolchain.lock.json').read_text('utf-8'))
    release = json.loads((HERE / 'release.json').read_text('utf-8'))
    if not re.fullmatch(r'\d+\.\d+\.\d+', release['version']) or not isinstance(release['build'], int) or release['build'] < 1:
        raise ValueError('Harmony release.json must contain a semantic version and positive build number')
    working_cache = ROOT / 'build/hp'
    working_cache.mkdir(parents=True, exist_ok=True)
    for name, spec in lock.items():
        if name == 'flutter':
            continue
        checkout = cache / name
        if not checkout.exists():
            checkout.mkdir(parents=True)
            subprocess.run(['git', 'init', str(checkout)], check=True)
            subprocess.run(['git', '-C', str(checkout), 'remote', 'add', 'origin', spec['url']], check=True)
            subprocess.run(['git', '-C', str(checkout), 'fetch', '--depth', '1', 'origin', spec['commit']], check=True)
            subprocess.run(['git', '-C', str(checkout), 'checkout', '--detach', 'FETCH_HEAD'], check=True)
        actual = subprocess.check_output(['git', '-C', str(checkout), 'rev-parse', 'HEAD'], text=True).strip()
        status = subprocess.check_output(['git', '-C', str(checkout), 'status', '--porcelain'], text=True)
        dirty = [line for line in status.splitlines() if line and not native_build_output(line[3:])]
        if actual != spec['commit'] or dirty:
            raise RuntimeError(f'{checkout}: expected clean pinned dependency; use a fresh cache directory')
        # Hvigor rewrites even tracked BuildProfile/lock files. Build from a Git
        # archive of the pinned commit so neither cache changes nor stale native
        # outputs become source inputs, and subsequent builds stay repeatable.
        archive = working_cache / f'{name}.tar'
        selected = {
            'packages-image': ['packages/image_picker'],
            'packages-url': ['packages/url_launcher'],
            'packages-path': ['packages/path_provider'],
            'packages-prefs': ['packages/shared_preferences'],
            'share': ['packages/share_plus'],
        }.get(name, [])
        subprocess.run(['git', '-C', str(checkout), 'archive', '--format=tar',
                        f'--output={archive}', spec['commit'], *selected], check=True)
        destination = working_cache / name
        destination.mkdir(parents=True, exist_ok=True)
        with tarfile.open(archive) as bundle:
            bundle.extractall(destination, filter='data')
        archive.unlink()

    cache = working_cache

    for name in ['lib', 'assets', 'test']:
        shutil.copytree(ROOT / 'mobile' / name, workspace / name, dirs_exist_ok=True)
    # Native project stays editable for local DevEco signing. Never replace it on rebuild.
    # Refresh maintained native entry points without touching the local signing
    # profile, keys, SDK paths or generated plugin registration.
    sync_native(workspace, release)
    shutil.copyfile(ROOT / 'mobile/analysis_options.yaml', workspace / 'analysis_options.yaml')

    packages = {}
    def add(repo, paths):
        for rel in paths:
            path = cache / repo / rel
            manifest = yaml.safe_load((path / 'pubspec.yaml').read_text('utf-8'))
            packages[manifest['name']] = {'path': path.as_posix()}
    for repo, family in [('packages-image','image_picker'), ('packages-url','url_launcher'),
                         ('packages-path','path_provider'), ('packages-prefs','shared_preferences')]:
        add(repo, [f'packages/{family}/{family}', f'packages/{family}/{family}_ohos'])
    for family in ['geolocator', 'geocoding']:
        add(family, [p.parent.relative_to(cache/family).as_posix()
                     for p in (cache/family).glob('*/pubspec.yaml')])
    add('sqflite', ['sqflite', 'sqflite_ohos'])
    add('links', ['app_links', 'app_links_platform_interface', 'app_links_web', 'app_links_linux'])
    add('share', ['packages/share_plus/share_plus', 'packages/share_plus/share_plus_platform_interface'])
    add('file_picker', ['.'])
    add('secure', ['flutter_secure_storage_ohos', 'flutter_secure_storage_platform_interface'])
    # Upstream 14.0.2 names the implementation flutter_geolocator_ohos but
    # its default_package still says geolocator_ohos. Fix only our build copy.
    fixed = ROOT / 'build/harmony-plugin-patches/geolocator'
    shutil.copytree(cache / 'geolocator/geolocator', fixed, dirs_exist_ok=True)
    manifest = yaml.safe_load((fixed / 'pubspec.yaml').read_text('utf-8'))
    manifest['flutter']['plugin']['platforms']['ohos']['default_package'] = 'flutter_geolocator_ohos'
    (fixed / 'pubspec.yaml').write_text(yaml.safe_dump(manifest, sort_keys=False), 'utf-8')
    packages['geolocator'] = {'path': fixed.as_posix()}
    spec = yaml.safe_load((ROOT / 'mobile/pubspec.yaml').read_text('utf-8'))
    spec['environment']['sdk'] = '>=3.11.0 <4.0.0'
    spec['version'] = f"{release['version']}+{release['build']}"
    spec['dependencies'].pop('file_picker')
    spec['dependencies'].pop('flutter_secure_storage')
    for name in ['file_picker_ohos', 'flutter_secure_storage_ohos', 'flutter_geolocator_ohos', 'geocoding_ohos']:
        spec['dependencies'][name] = packages[name]
    spec['dependency_overrides'] = packages
    (workspace / 'pubspec.yaml').write_text(yaml.safe_dump(spec, allow_unicode=True, sort_keys=False), 'utf-8')

    backup = workspace / 'lib/backup.dart'
    content = replace_once(backup.read_text('utf-8'), "package:file_picker/file_picker.dart", "package:file_picker_ohos/file_picker_ohos.dart")
    content = replace_once(content, 'FilePicker.pickFile(', 'FilePicker.platform.pickFiles(')
    content = replace_once(content, 'final file = result;', 'final file = result.xFiles.single;')
    content = replace_once(content, '(await file.length() ?? 0)', '(await file.length())')
    content = replace_once(content, 'FilePicker.saveFile(', 'FilePicker.platform.saveFile(')
    backup.write_text(content, 'utf-8')

    account = workspace / 'lib/cloud_account.dart'
    content = replace_once(account.read_text('utf-8'), 'package:flutter_secure_storage/flutter_secure_storage.dart',
                           'package:flutter_secure_storage_ohos/flutter_secure_storage_ohos.dart')
    content = replace_once(content, 'static const vault = FlutterSecureStorage();', '''static const vault = FlutterSecureStorage(ohOptions: OhosOptions(
    resetOnError: false,
    ohosKeyCipherAlgorithm: OhosKeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
    ohosStorageCipherAlgorithm: OhosStorageCipherAlgorithm.AES_GCM_NoPadding,
  ));''')
    account.write_text(content, 'utf-8')

    weather = workspace / 'lib/weather.dart'
    content = replace_once(weather.read_text('utf-8'),
        'Future<(double, double)?> _nativeLocation() async {',
        "Future<(double, double)?> _nativeLocation() async {\n    if (!Platform.isAndroid) return null;")
    weather.write_text(content, 'utf-8')

    main = workspace / 'lib/main.dart'
    content = main.read_text('utf-8')
    content = "import 'dart:io';\nimport 'package:flutter_geolocator_ohos/geolocator_ohos.dart';\nimport 'package:geocoding_ohos/geocoding_ohos.dart';\n" + content
    content = replace_once(content, 'WidgetsFlutterBinding.ensureInitialized();', '''WidgetsFlutterBinding.ensureInitialized();
  if (Platform.operatingSystem == 'ohos') {
    GeolocatorOhos.registerWith();
    GeocodingOhos.registerWith();
  }''')
    main.write_text(content, 'utf-8')
    about = workspace / 'lib/profile_pages.dart'
    about.write_text(replace_once(about.read_text('utf-8'),
                                 "'Android · 1.0.0'", "'HarmonyOS · 1.0.0'"), 'utf-8')
    interaction_test = workspace / 'test/mobile_interactions_test.dart'
    content = interaction_test.read_text('utf-8')
    if content.count("'Android · 1.0.0'") != 2:
        raise RuntimeError('Review Harmony About visibility assertions after mobile test changes')
    interaction_test.write_text(content.replace("'Android · 1.0.0'", "'HarmonyOS · 1.0.0'"), 'utf-8')
    print(f'Prepared {workspace}. Native compilation, signing and device validation are still required.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--cache', type=Path, default=ROOT/'build/harmony-dependencies')
    args = parser.parse_args()
    prepare(args.cache.resolve())
