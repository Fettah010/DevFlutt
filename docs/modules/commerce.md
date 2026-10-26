# Commerce modules

Select the demo with `ftemplate create --name MyApp --org com.example --module commerce`.
The demo includes a catalog, immutable cart calculations using integer minor units, a fake
checkout adapter, and loading/empty/failure/success UI states. The default cart is in memory.

Select `commerce-persistence` to add a Drift-backed cart store; it also selects
`local-database`. The cart store is closed with the feature page lifecycle. Stored cart values
are display data, not a price source.

Checkout sends only product identifiers and quantities. The adapter's quote and order ID are
shown as authoritative; the local demo estimate is not. Checkout is not automatically retried
and no payment SDK, card collection, or payment credential storage is included. Unit and
widget tests verify calculations, request shape, error retention, and checkout states.
