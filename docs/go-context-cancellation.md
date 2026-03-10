# Context Cancellation in Loops

Non-blocking context check in loop iterations for fast shutdown.

## Core Pattern

```go
for _, item := range items {
    select {
    case <-ctx.Done():
        return errors.Wrap(ctx, ctx.Err(), "context cancelled")
    default:
    }
    if err := process(ctx, item); err != nil {
        return errors.Wrap(ctx, err, "process item")
    }
}
```

## Rules

1. Use non-blocking `select` with `default` — never bare `<-ctx.Done()`
2. Place check at **top** of loop, before work
3. Wrap error with context: `errors.Wrap(ctx, ctx.Err(), "description")`
4. Never return bare `ctx.Err()` — always wrap

## When to Apply

- Large collections
- Expensive per-item work (DB, HTTP, file I/O)
- Retry loops with backoff
- Paginated API callbacks
- Any loop with significant total runtime

## Bad

```go
// Blocks forever if context never cancels
<-ctx.Done()

// Check after work — too late
process(ctx, item)
select { case <-ctx.Done(): ... }

// Missing context in error
return ctx.Err()
```

## Testing

```go
It("stops early when context cancelled", func() {
    ctx, cancel := context.WithCancel(ctx)
    go func() {
        time.Sleep(10 * time.Millisecond)
        cancel()
    }()
    err := processItems(ctx, items, handler)
    Expect(err).To(MatchError(context.Canceled))
})
```

## Checklist

- [ ] Every loop with >few ms runtime has context check
- [ ] Check is non-blocking (select/default)
- [ ] Check is at top of loop
- [ ] Error includes context wrapping
