"""Launch the new Flutter Windows package with an isolated temporary database."""
import argparse
import os
from pathlib import Path
import sqlite3
import subprocess
import tempfile
import time


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--exe', type=Path, required=True)
    args = parser.parse_args()
    executable = args.exe.resolve()
    with tempfile.TemporaryDirectory(prefix='waylore-windows-smoke-') as temporary:
        environment = dict(os.environ, WAYLORE_DATA_DIR=temporary)
        log = Path('build/windows-smoke.log')
        log.parent.mkdir(parents=True, exist_ok=True)
        with log.open('w', encoding='utf-8') as stream:
            process = subprocess.Popen([str(executable)], cwd=executable.parent,
                env=environment, stdout=stream, stderr=subprocess.STDOUT)
            try:
                database = Path(temporary) / 'kexinglu-mobile.db'
                deadline = time.monotonic() + 45
                while time.monotonic() < deadline:
                    if process.poll() is not None:
                        raise RuntimeError('Windows app exited before opening its database')
                    if database.is_file():
                        try:
                            with sqlite3.connect(f'file:{database.as_posix()}?mode=ro', uri=True) as connection:
                                tables = {r[0] for r in connection.execute("SELECT name FROM sqlite_master WHERE type='table'")}
                            if {'entries', 'settings'} <= tables:
                                time.sleep(3)
                                if process.poll() is not None:
                                    raise RuntimeError('Windows app exited after initialization')
                                print('PASS: Windows release initialized its own SQLite database and stayed running.')
                                return
                        except sqlite3.Error:
                            pass
                    time.sleep(.5)
                raise RuntimeError('Windows app did not initialize within 45 seconds')
            finally:
                if process.poll() is None:
                    process.terminate()
                    try:
                        process.wait(timeout=10)
                    except subprocess.TimeoutExpired:
                        process.kill()
                        process.wait()


if __name__ == '__main__':
    main()
