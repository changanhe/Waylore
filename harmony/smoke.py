"""Non-destructive native navigation checks on a local HarmonyOS emulator.

Usage: python harmony/smoke.py --device 127.0.0.1:5555 --kind phone
Only emulator loopback targets are accepted. Does not clear app data or log in.
"""
from pathlib import Path
import argparse
import json
import re
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
HDC = Path('D:/Tools/DevEcoStudio/sdk/default/openharmony/toolchains/hdc.exe')
CLI = Path('D:/Tools/deveco-cli/node_modules/.bin/devecocli.cmd')
BUNDLE = 'com.changanhe.kexinglu'


class EmulatorCheck:
    def __init__(self, device, kind, output=None):
        if not re.fullmatch(r'127\.0\.0\.1:\d+', device):
            raise ValueError('This smoke check accepts local emulators only')
        self.device = device
        self.kind = kind
        self.output = Path(output or ROOT / 'build/harmony-verification/build2')
        self.output.mkdir(parents=True, exist_ok=True)

    def run(self, arguments):
        completed = subprocess.run([str(x) for x in arguments], capture_output=True,
                                   encoding='utf-8', errors='replace', timeout=45)
        output = completed.stdout + completed.stderr
        if completed.returncode or '[Fail]' in output:
            raise RuntimeError(output)
        return output

    def hdc(self, *arguments):
        return self.run([HDC, '-t', self.device, *arguments])

    def ui(self, command, *arguments):
        return self.run([CLI, 'ui', command, '--device', self.device, *arguments])

    def layout(self):
        for attempt in range(3):
            try:
                output = self.ui('layout', '--format', 'json')
                break
            except RuntimeError as error:
                if 'Empty dumpLayout response' not in str(error) or attempt == 2:
                    raise
                time.sleep(1)
        for match in re.finditer(r'\[', output):
            try:
                value, _ = json.JSONDecoder().raw_decode(output[match.start():])
                if isinstance(value, list) and value and isinstance(value[0], dict):
                    return value
            except json.JSONDecodeError:
                pass
        raise RuntimeError('Native UI layout was not returned')

    @staticmethod
    def flatten(nodes):
        for node in nodes:
            yield node
            yield from EmulatorCheck.flatten(node.get('children', []))

    def click(self, label, nodes=None):
        nodes = self.flatten(self.layout() if nodes is None else nodes)
        matches = [node for node in nodes if label in node.get('text', '').splitlines()
                   and node.get('clickable') and node.get('bounds')]
        if not matches:
            raise RuntimeError(f'Visible clickable element missing: {label}')
        left, top, right, bottom = matches[-1]['bounds']
        self.ui('click', str((left + right) // 2), str((top + bottom) // 2))
        time.sleep(.45)

    def screenshot(self, name):
        path = self.output / f'{self.kind}-{name}.png'
        if path.exists():
            path = path.with_name(f'{path.stem}-{time.time_ns()}{path.suffix}')
        self.ui('screenshot', '--path', str(path))
        if not path.exists() or path.stat().st_size < 1000:
            raise RuntimeError(f'Screenshot missing: {path}')
        return path.name

    def check(self):
        actual_kind = self.hdc('shell', 'param', 'get', 'const.product.devicetype').strip()
        if actual_kind != self.kind:
            raise RuntimeError(f'Expected {self.kind} system image, got {actual_kind}')
        self.hdc('shell', 'aa', 'start', '-a', 'EntryAbility', '-b', BUNDLE)
        time.sleep(1)
        tabs = [('首页', 'home'), ('旅途', 'travel'), ('票夹', 'tickets'),
                ('收藏', 'collection'), ('我的', 'profile')]
        checked = []
        for label, name in tabs:
            self.click(label)
            nodes = self.layout()
            text = '\n'.join(node.get('text', '') for node in self.flatten(nodes))
            assert '本地资料暂时未能打开' not in text
            nav = [node for node in self.flatten(nodes)
                   if node.get('type') == 'Button' and node.get('text') in dict(tabs)]
            assert len(nav) == 5, f'Navigation not accessible on {label}'
            checked.append({'page': name, 'navigation_buttons': len(nav),
                            'screenshot': self.screenshot(name)})
        bundle_info = self.hdc('shell', 'bm', 'dump', '-n', BUNDLE)
        if '"versionCode": 2' not in bundle_info:
            raise RuntimeError('Expected installed Harmony build 2')
        report = {'device_type': actual_kind, 'build': 2,
                  'system_version': self.hdc('shell', 'param', 'get', 'const.ohos.fullname').strip(),
                  'checks': checked, 'limitations': 'Emulator navigation only; no real device or real account used.'}
        path = self.output / f'{self.kind}-smoke.json'
        path.write_text(json.dumps(report, ensure_ascii=False, indent=2), 'utf-8')
        print(json.dumps(report, ensure_ascii=False))


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--device', required=True)
    parser.add_argument('--kind', required=True, choices=['phone', 'tablet'])
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    EmulatorCheck(args.device, args.kind, args.output).check()
