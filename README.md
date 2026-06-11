# hn — a Hacker News command-line reader

A small terminal client for Hacker News I built to learn Swift's concurrency
model. It fetches the current top stories and prints them ranked.

No dependencies, no API key (uses the public Firebase HN API).

## Run

```bash
swift run hn            # top 10
swift run hn -n 20      # top 20
swift test              # offline tests (mocked network)
```

Example:

```
 1. Show HN: I built a tiny Swift HTTP client
    142 pts · by alice · github.com
 2. The case for boring technology
    98 pts · by bob · mcfunley.com
```

## How it works

- **`HNClient`** fetches the top-story IDs, then fetches each item — the network
  calls run **concurrently** in a `withThrowingTaskGroup`, but results are
  written back by index so the printed list keeps HN's ranking.
- **`ItemCache`** is an `actor`, so the parallel fetches share a cache without
  data races.
- **`Fetcher`** is a small protocol (URLSession by default) so the client can be
  unit-tested offline with a mock — see `Tests`.
- **`Validator`** drops malformed items (no title, non-story) and checks URLs.

## Things I'd add next

- Comment threads (recursively fetch `kids`).
- A `--new` / `--best` flag for the other feeds.
- Simple on-disk caching with a TTL.
