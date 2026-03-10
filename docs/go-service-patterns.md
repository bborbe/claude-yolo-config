# Service Implementation Patterns

Provider vs Registry, interface design, and package organization.

## Provider vs Registry

**Static Provider** — fixed set, compile-time, fast (switch):
```go
func (p *provider) Get(ctx context.Context, t OrderType) (Processor, error) {
    switch t {
    case MarketOrder:
        return NewMarketProcessor(p.deps...), nil
    case LimitOrder:
        return NewLimitProcessor(p.deps...), nil
    default:
        return nil, errors.Errorf(ctx, "unknown type: %s", t)
    }
}
```

**Dynamic Registry** — extensible, runtime, plugin-like:
```go
type Registry struct { processors map[string]Creator }
func (r *Registry) Register(name string, c Creator) { r.processors[name] = c }
```

**Decision**: <10 fixed types → Provider. Extensible/plugins → Registry.

## Interface Design

```go
// Always: public interface + private struct + constructor returns interface
type OrderService interface {
    Process(ctx context.Context, order Order) error
}

type orderService struct {
    repository OrderRepository
    validator  OrderValidator
}

func NewOrderService(repo OrderRepository, val OrderValidator) OrderService {
    return &orderService{repository: repo, validator: val}
}
```

## Package Structure

```
pkg/
├── user/
│   ├── user.go          # interface
│   ├── user-type.go     # domain types
│   ├── provider.go      # provider impl
│   ├── admin.go         # individual impl
│   └── regular.go
```

## Rules

1. **Public interface, private struct** — never expose implementation
2. **Constructor injection** — all deps in constructor, not method params
3. **Domain naming** — `Processor`, `Validator`, `Repository` (not `Manager`, `Handler`, `Util`)
4. **Single-purpose packages** — singular nouns (`user/`, not `users/`)
5. **Flat structure** — no deep nesting (`pkg/user/`, not `pkg/handlers/users/processors/`)
6. **Separate types from logic** — `OrderType` (enum) vs `OrderProcessor` (behavior)

## Bad

```go
// Public struct
type OrderService struct { DB *sql.DB }

// Context object anti-pattern
func (s *service) Process(ctx context.Context, deps ServiceContext) {}

// God interface
type UserService interface {
    Create(); Update(); Delete(); SendEmail(); ProcessPayment(); GenerateReport()
}

// Manager/Util anti-pattern
type UserManager struct {}
package utils
```

## Checklist

- [ ] Public interface + private implementation
- [ ] Constructor injection (no context objects)
- [ ] Domain-appropriate naming
- [ ] Single-purpose, flat packages
- [ ] Types separated from business logic
