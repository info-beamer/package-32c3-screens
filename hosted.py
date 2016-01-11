# Part of info-beamer hosted
#
# Copyright (c) 2014, Florian Wesch <fw@dividuum.de>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#     Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#
#     Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the
#     distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
# IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import os
import sys
import json
import socket
import pyinotify

types = {}

def type(fn):
    types[fn.__name__] = fn
    return fn

@type
def color(value):
    return value

@type
def string(value):
    return value

@type
def boolean(value):
    return value

@type
def select(value):
    return value

@type
def duration(value):
    return value

@type
def integer(value):
    return value

@type
def font(value):
    return value

@type
def resource(value):
    return value

class Configuration(object):
    def __init__(self):
        self._restart = False
        self._options = []
        self._config = {}
        self._parsed = {}
        self.parse_node_json(do_update=False)
        self.parse_config_json()

    def restart_on_update(self):
        print >>sys.stderr, "[hosted.py] going to restart when config is updated"
        self._restart = True

    def parse_node_json(self, do_update=True):
        with file("node.json") as f:
            self._options = json.load(f)['options']
        if do_update:
            self.update_config()

    def parse_config_json(self, do_update=True):
        with file("config.json") as f:
            self._config = json.load(f)
        if do_update:
            self.update_config()

    def update_config(self):
        if self._restart:
            print >>sys.stderr, "[hosted.py] restarting service (restart_on_update set)"
            import thread, time
            thread.interrupt_main()
            time.sleep(100)
            return

        def parse_recursive(options, config, target):
            # print 'parsing', config
            for option in options:
                if not 'name' in option:
                    continue
                if option['type'] == 'list':
                    items = []
                    for item in config[option['name']]:
                        parsed = {}
                        parse_recursive(option['items'], item, parsed)
                        items.append(parsed)
                    target[option['name']] = items
                    continue
                target[option['name']] = types[option['type']](config[option['name']])

        parsed = {}
        parse_recursive(self._options, self._config, parsed)
        print >>sys.stderr, "[hosted.py] updated config"
        self._parsed = parsed

    def __getitem__(self, key):
        return self._parsed[key]
Configuration = Configuration()

class EventHandler(pyinotify.ProcessEvent):
    def process_default(self, event):
        print >>sys.stderr, event
        basename = os.path.basename(event.pathname)
        if basename == 'node.json':
            Configuration.parse_node_json()
        elif basename == 'config.json':
            Configuration.parse_config_json()
        elif basename == 'hosted.py':
            print >>sys.stderr, "[hosted.py] restarting service since hosted.py changed"
            import thread, time
            thread.interrupt_main()
            time.sleep(100)


wm = pyinotify.WatchManager()

notifier = pyinotify.ThreadedNotifier(wm, EventHandler())
notifier.daemon = True
notifier.start()

wm.add_watch('.', pyinotify.IN_MOVED_TO)

print >>sys.stderr, "initialized hosted.py"

CONFIG = Configuration

class Node(object):
    def __init__(self, node):
        self._node = node
        self._sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

    def send_raw(self, raw):
        print >>sys.stderr, "sending %r" % (raw,)
        self._sock.sendto(raw, ('127.0.0.1', 4444))

    def send(self, data):
        self.send_raw(self._node + data)

    class Sender(object):
        def __init__(self, node, path):
            self._node = node
            self._path = path

        def __call__(self, data):
            raw = "%s:%s" % (self._path, data)
            self._node.send_raw(raw)

    def __getitem__(self, path):
        return self.Sender(self, self._node + path)

    def __call__(self, data):
        return self.Sender(self, self._node)(data)
NODE = Node(os.environ['NODE'])

class Upstream(object):
    def __init__(self):
        self._socket = None

    def ensure_connected(self):
        if self._socket:
            return False
        try:
            print >>sys.stderr, "establishing upstream connection"
            self._socket = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            self._socket.connect(os.environ['SYNCER_SOCKET'])
            return True
        except Exception, err:
            print >>sys.stderr, "cannot connect to upstream socket: %s" % (err,)

    def send_raw(self, raw):
        try:
            if self.ensure_connected():
                self._socket.send(raw)
        except Exception, err:
            print >>sys.stderr, "cannot send to upstream: %s" % (err,)
            if self._socket:
                self._socket.close()
            self._socket = None

    def send(self, **data):
        self.send_raw(json.dumps(data))
UPSTREAM = Upstream()
