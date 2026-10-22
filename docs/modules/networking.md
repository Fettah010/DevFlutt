# networking

A typed HTTP client with timeouts, cancellation, request correlation, error mapping, and
bounded idempotent retry.

## Capabilities

- `ApiClient` — the application's HTTP contract. Features depend on it, never on the
  transport.
- `ApiResult<T>` — a sealed success/failure pair. A request never throws.
- `ApiError` — a sealed `network`, `timeout`, `cancelled`, `http`, `malformed`, or `unknown`
  failure. It carries no server text and no response body, because a body may contain
  personal data.
- `ApiRequest` — method, path, query, headers, and body.
- `ApiCancellationToken` — cancels an in-flight request.
- `RetryPolicy` — the attempt bound, the backoff, and the total time budget.
- `RetryingApiClient` — a decorator that applies the retry rules above any transport.
- `DioApiClient` — the Dio transport. It is the only file in the module that imports `dio`.
- `FakeApiClient` — a deterministic test double that never touches the network.
- `RequestIdFactory` — the correlation identifier attached to every request.

## Retry rules

- The policy is configured on the client. The generated configuration retries up to three
  times; `RetryPolicy.none` disables retrying.
- Only `GET`, `HEAD`, and `OPTIONS` are retried. `POST`, `PUT`, `PATCH`, and `DELETE` are
  never replayed automatically, because the template cannot know whether the backend
  supplies an idempotency key.
- The backoff grows exponentially and is capped at 30 seconds. The total time budget,
  backoff included, is 60 seconds.
- Exhaustion produces a typed error, never an exception.
- A cancelled request is never retried.

## Request correlation

Every request carries an `X-Request-Id`. The outermost client assigns the identifier and
passes it down, so every attempt of a retried request shares it.

## Cache

No response caching ships in this module. Caching authenticated or sensitive responses
needs a policy that states expiration, invalidation, offline behaviour, and what is safe to
persist; there is no authenticated traffic yet. See ADR-004.

## Requires

- `architecture-core`
- `logging`

## Setup

The base URL comes from the existing `API_BASE_URL` configuration key; the module adds no
configuration key. `dio` is pure Dart, so there is no Android setup and no permission.

Change the transport by replacing the `inner` client of `RetryingApiClient`. Add a feature
by giving it an `ApiClient` through its constructor.

## Limits

- The `ApiError` for a failed request carries the status code but not the response body.
  A caller that needs the body must ask for it explicitly.
- The redaction of the request path is heuristic: a path that embeds a personal identifier
  is logged as it is.

## Removal

Not applicable (modules are generation-time selections). Removing the module removes the
client, the `AppServices.apiClient` field, and the `dio` dependency.

## Tests

- A request that times out, is cancelled, or answers with an undecodable body produces the
  matching typed error.
- An idempotent request is retried until it succeeds, and a non-idempotent request is
  attempted exactly once.
- The retry loop gives up after the bounded number of attempts and within the time budget.
- A retried request reuses one correlation identifier.
