# Offline data module

Select with `ftemplate create --name MyApp --org com.example --module offline-data`.

The notes reference feature uses the local Drift database for reads and writes. Refresh is
explicit; the remote snapshot freshness target is five minutes, and a failed refresh marks
that snapshot stale while leaving local notes readable. Local edits enter a durable queue
with stable operation IDs. Pending local records win same-record conflicts in this demo.
Queued writes replay only during an explicit refresh; they are not automatically retried by
the HTTP client. A failed write stays queued for a later refresh.

This is a reference policy, not background synchronization or a server-consistency promise.
The module depends on navigation, networking, and local-database (with their transitive
requirements) and adds the Android INTERNET permission through networking. Unit and widget
tests cover freshness, local persistence, offline reads, conflict handling, stable replay IDs,
and refresh states. No production backend is configured.
