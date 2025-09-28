#!/usr/bin/env python3
import json, sys
from urllib.request import Request, urlopen

BASE = 'http://127.0.0.1:7777'

def get(path):
    with urlopen(BASE + path) as r:
        return json.loads(r.read().decode())

def post(path, payload):
    req = Request(BASE + path, data=json.dumps(payload).encode('utf-8'), headers={'Content-Type': 'application/json'})
    with urlopen(req) as r:
        return json.loads(r.read().decode())

def main():
    caps = get('/v1/capabilities')
    print('Capabilities:', json.dumps(caps, indent=2))
    res = post('/v1/tasks/run', { 'task': 'system.validate', 'params': {} })
    print('Run:', json.dumps(res, indent=2))

if __name__ == '__main__':
    main()

