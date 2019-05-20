import codecs
import json
import os
import select
import sys
import traceback


class iocontext:

    def __init__(self):
        self.stdout = sys.stdout

    def __enter__(self):
        sys.stdout = sys.stderr
        return self

    def __exit__(self, *args):
        sys.stdout = self.stdout


def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)


def print_result(result):
    try:
        print(json.dumps(result))
    except TypeError:
        print(result)


def run():
    global_context = {}
    try:
        if sys.stdin in select.select([sys.stdin], [], [], 0)[0]:
            ip = sys.stdin.read()
            global_context['param'] = json.loads(ip) if (len(ip) > 0) else {"payload":""}
        else:
            global_context['param'] = {"payload": ""}

        with codecs.open(os.path.abspath('__main__.py'), 'r', 'utf-8') as m:
            code = m.read()

        with iocontext():
            fn = compile(code, filename='__main__.py', mode='exec')
            exec(fn, global_context)
            exec('fun = main(param)', global_context)

        result = global_context['fun']
        print_result(result)
    except Exception as e:
        trace = traceback.format_exc()
        msg = json.dumps({"error": str(e), "traceback": str(trace)})
        eprint(msg)
        print(msg)


if __name__ == '__main__':
    run()
