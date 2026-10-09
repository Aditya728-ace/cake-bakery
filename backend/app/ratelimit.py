"""Tiny in-memory brute-force guard for login/register.
Per worker process, which is fine for a single-owner site; swap for Redis if you ever scale out."""
import time
from collections import defaultdict, deque
from fastapi import HTTPException, Request

WINDOW = 15 * 60
MAX_FAILS = 10
_fails: dict[str, deque] = defaultdict(deque)


def _key(request: Request) -> str:
    return request.client.host if request.client else "unknown"


def _prune(q: deque):
    cutoff = time.time() - WINDOW
    while q and q[0] < cutoff:
        q.popleft()


def guard(request: Request):
    q = _fails[_key(request)]
    _prune(q)
    if len(q) >= MAX_FAILS:
        raise HTTPException(429, "Too many attempts. Please wait 15 minutes and try again.")


def record_failure(request: Request):
    _fails[_key(request)].append(time.time())


def reset(request: Request | None = None):
    if request is None:
        _fails.clear()
    else:
        _fails.pop(_key(request), None)
