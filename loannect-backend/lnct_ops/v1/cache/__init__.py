import redis

# cache = redis.Redis(host="192.168.8.132", port=6379, decode_responses=True)
cache = redis.Redis(host="10.203.149.76", port=6379, decode_responses=True)

_TAG_GREEN_FLAG = "lnct_cache_active"


def cache_primitive(key: str | int, value: str | int | float):
    cache.set(key, value)


def cache_map(key: str | int, value: dict):
    cache.hset(key, mapping=value)


def get_primitive(key: str | int):
    return cache.get(key)


def get_map(key: str | int):
    return cache.hgetall(key)


def cache_status_is_green_flag() -> bool:
    print("checking cache status...")
    green_flag = get_primitive(_TAG_GREEN_FLAG) is not None
    print("cache status:", "locked and loaded" if green_flag else "red flag")
    return green_flag


def green_flag_the_cache():
    if not cache_status_is_green_flag():
        print("green flagging the cache...")
        cache_primitive(_TAG_GREEN_FLAG, 1)
    else:
        # cache that was saved is still present in redis
        print("cache is active; returned green flag")
