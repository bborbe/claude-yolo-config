# Go CQRS Command-Result Pattern

Send command via Kafka, get result automatically. Library: `github.com/bborbe/cqrs`.

## Core Flow

```
Producer                              Controller
1. NewCommand(op, initiator, id, ev)  3. CommandObjectExecutor.HandleCommand()
2. SendCommandObject() → cmd topic    4. WrapCommandObjectExecutorTxs auto-sends result
                                         → result topic
5. ResultProvider.ResultFor(ctx, cmd)
6. result.Success → done
```

## Kafka Topics (auto-derived from SchemaID)

```go
schemaID := cdb.SchemaID{Group: "core", Kind: "backtest", Version: "v1"}
// → core-backtest-v1-command-{branch}   commands in
// → core-backtest-v1-event-{branch}     state changes
// → core-backtest-v1-result-{branch}    command results (auto)
// → core-backtest-v1-history-{branch}   audit log
```

## Sending a Command

```go
command := commandCreator.NewCommand(operation, initiator, "", event)
commandObjectSender.SendCommandObject(ctx, cdb.CommandObject{
    Command:  command,
    SchemaID: schemaID,
})
```

## Result Sending (Automatic)

`RunCommandConsumerTx` wraps executors with `WrapCommandObjectExecutorTxs`.
No manual result sending. Success/failure published to result topic automatically.

```go
// Controller setup — result wrapping is built-in:
cdb.RunCommandConsumerTx(saramaClientProvider, syncProducer, db,
    schemaID, batchSize, branch, false, 24*time.Hour,
    run.NewTrigger(), commandObjectExecutors)
```

## Waiting for Result

### In-Process (same service)

```go
provider := cdb.NewResultChannelProviderForRequestID()
// Wire as ResultBroadcaster in result consumer
// Wire as ResultProvider where commands are sent

ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
defer cancel()
result, err := provider.ResultFor(ctx, command)
// result.Success, result.Message, result.RequestID
```

### Cross-Process (separate service)

Consume result topic, match on `RequestID`:
```go
topic := schemaID.ResultTopic(branch)
// Filter messages where result.RequestID == command.RequestID
```

## Result Struct

```go
type Result struct {
    Success   bool
    RequestID RequestID
    Message   string
    Initiator iam.Initiator
    Operation CommandOperation
    ID        string
}
```

## Rules

- Never consume event topic to wait for command results — use result topic
- `RunCommandConsumerTx` wraps executors automatically — don't wrap manually
- `ErrCommandObjectSkipped` skips silently (no result sent)
- `SendResultEnabled() == false` + no error → no result sent
- Context timeout → `ResultFor()` returns `Success: false`

## Checklist

- [ ] Command has RequestID for correlation
- [ ] Controller uses `RunCommandConsumerTx` (auto-wraps)
- [ ] Consumer reads result topic, not event topic
- [ ] Timeout via context, not manual timer
