# coding: utf-8
from __future__ import print_function, unicode_literals

import platform
import time
import sys
import os

PY2 = sys.version_info[0] == 2
if PY2:
    sys.dont_write_bytecode = True
    unicode = unicode
else:
    unicode = str

WINDOWS = False
if platform.system() == "Windows":
    WINDOWS = [int(x) for x in platform.version().split(".")]

VT100 = not WINDOWS or WINDOWS >= [10, 0, 14393]
# introduced in anniversary update

ANYWIN = WINDOWS or sys.platform in ["msys"]

MACOS = platform.system() == "Darwin"


def get_unix_home():
    try:
        v = os.environ["XDG_CONFIG_HOME"]
        if not v:
            raise Exception()
        ret = os.path.normpath(v)
        os.listdir(ret)
        return ret
    except:
        pass

    try:
        v = os.path.expanduser("~/.config")
        if v.startswith("~"):
            raise Exception()
        ret = os.path.normpath(v)
        os.listdir(ret)
        return ret
    except:
        return "/tmp"


class EnvParams(object):
    def __init__(self):
        self.t0 = time.time()
        self.mod = os.path.dirname(os.path.realpath(__file__))
        if self.mod.endswith("__init__"):
            self.mod = os.path.dirname(self.mod)

        if sys.platform == "win32":
            self.cfg = os.path.normpath(os.environ["APPDATA"] + "/copyparty")
        elif sys.platform == "darwin":
            self.cfg = os.path.expanduser("~/Library/Preferences/copyparty")
        else:
            self.cfg = get_unix_home() + "/copyparty"

        self.cfg = self.cfg.replace("\\", "/")
        try:
            os.makedirs(self.cfg)
        except:
            if not os.path.isdir(self.cfg):
                raise


E = EnvParams()
