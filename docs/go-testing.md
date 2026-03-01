# Go Testing (YOLO)

## Framework: Ginkgo v2 + Gomega

## Suite File (required per package)

```go
// pkg/mypackage/mypackage_suite_test.go
package mypackage_test

import (
    "testing"
    "time"
    . "github.com/onsi/ginkgo/v2"
    . "github.com/onsi/gomega"
    "github.com/onsi/gomega/format"
)

//go:generate go run -mod=mod github.com/maxbrunsfeld/counterfeiter/v6 -generate
func TestSuite(t *testing.T) {
    time.Local = time.UTC
    format.TruncatedDiff = false
    RegisterFailHandler(Fail)
    RunSpecs(t, "Test Suite")
}
```

**Every** `*_suite_test.go` gets the `//go:generate` line — even if the package has no interfaces yet.

Always check if a `*_suite_test.go` already exists before creating one.

---

## Test Structure: Arrange → Act → Assert

```go
var _ = Describe("MyService", func() {
    var (
        ctx     context.Context
        err     error
        svc     MyService
        mockDep *mocks.Dep
    )

    BeforeEach(func() {
        ctx = context.Background()
        mockDep = &mocks.Dep{}
        svc = NewMyService(mockDep)
    })

    JustBeforeEach(func() {
        err = svc.Do(ctx, "input")
    })

    It("returns no error", func() {
        Expect(err).To(BeNil())
    })

    Context("dep returns error", func() {
        BeforeEach(func() {
            mockDep.CallReturns(errors.New("boom"))
        })
        It("returns error", func() {
            Expect(err).NotTo(BeNil())
        })
    })
})
```

**Rules:**
- Package: `mypackage_test` (external test package)
- `BeforeEach` = arrange, `JustBeforeEach` = act, `It` = assert
- Fresh state in every `BeforeEach` — no shared mutable state
- Test both success and error paths

---

## Counterfeiter Mocks

**NEVER write mocks by hand.** Always use counterfeiter.

### Two things per package:

1. **One `//go:generate`** in `*_suite_test.go` (already there if you follow the suite file pattern above)
2. **One `//counterfeiter:generate`** on each interface in the package's source files

### Step 1: Add annotation to interface (source file, NOT test file)

```go
// pkg/mypackage/mypackage.go
package mypackage

//counterfeiter:generate -o ../../mocks/my-dep.go --fake-name MyDep . MyDep
type MyDep interface {
    Call(ctx context.Context, input string) (string, error)
}
```

The `//go:generate` in the suite file triggers counterfeiter, which scans the package for `//counterfeiter:generate` annotations.

**Important:**
- `-o` path is relative to the file containing the annotation
- Count `../` from the interface file to `mocks/` directory (e.g., `pkg/foo/` → `../../mocks/`)
- `--fake-name` sets the generated struct name
- Generated files go into the project-root `mocks/` directory
- Multiple interfaces in one package = multiple `//counterfeiter:generate` lines, one `//go:generate`

### Step 2: Generate mocks

```bash
make generate   # or: go generate -mod=mod ./...
```

### Step 3: Use in tests

```go
import "<module>/mocks"

mockDep = &mocks.MyDep{}

// Stub return values
mockDep.CallReturns("result", nil)
mockDep.CallReturnsOnCall(0, "first", nil)
mockDep.CallReturnsOnCall(1, "second", errors.New("boom"))

// Stub with custom implementation
mockDep.CallStub = func(ctx context.Context, input string) (string, error) {
    return "custom-" + input, nil
}

// Verify call count
Expect(mockDep.CallCallCount()).To(Equal(1))

// Verify call arguments
actualCtx, actualInput := mockDep.CallArgsForCall(0)
Expect(actualCtx).To(Equal(ctx))
Expect(actualInput).To(Equal("expected-input"))
```

---

## Real Example: Op Test with Mock Storage

```go
// pkg/ops/complete_test.go
package ops_test

import (
    "context"
    "errors"
    . "github.com/onsi/ginkgo/v2"
    . "github.com/onsi/gomega"
    "github.com/bborbe/vault-cli/mocks"
    "github.com/bborbe/vault-cli/pkg/domain"
    "github.com/bborbe/vault-cli/pkg/ops"
)

var _ = Describe("CompleteOperation", func() {
    var (
        ctx         context.Context
        err         error
        completeOp  ops.CompleteOperation
        mockStorage *mocks.Storage
        vaultPath   string
        taskName    string
        task        *domain.Task
    )

    BeforeEach(func() {
        ctx = context.Background()
        mockStorage = &mocks.Storage{}
        completeOp = ops.NewCompleteOperation(mockStorage)
        vaultPath = "/path/to/vault"
        taskName = "my-task"

        task = &domain.Task{
            Name:   taskName,
            Status: domain.TaskStatusTodo,
        }
        mockStorage.FindTaskByNameReturns(task, nil)
        mockStorage.WriteTaskReturns(nil)
    })

    JustBeforeEach(func() {
        err = completeOp.Execute(ctx, vaultPath, taskName)
    })

    Context("success", func() {
        It("returns no error", func() {
            Expect(err).To(BeNil())
        })

        It("marks task as done", func() {
            Expect(mockStorage.WriteTaskCallCount()).To(Equal(1))
            _, writtenTask := mockStorage.WriteTaskArgsForCall(0)
            Expect(writtenTask.Status).To(Equal(domain.TaskStatusDone))
        })
    })

    Context("task not found", func() {
        BeforeEach(func() {
            mockStorage.FindTaskByNameReturns(nil, errors.New("not found"))
        })
        It("returns error", func() {
            Expect(err).NotTo(BeNil())
        })
        It("does not write", func() {
            Expect(mockStorage.WriteTaskCallCount()).To(Equal(0))
        })
    })
})
```

---

## Storage Tests: Use Real Temp Files

Storage tests (reading/writing markdown) use real temp directories — not mocks:

```go
// pkg/storage/markdown_test.go
package storage_test

import (
    "context"
    "os"
    . "github.com/onsi/ginkgo/v2"
    . "github.com/onsi/gomega"
    "github.com/bborbe/vault-cli/pkg/domain"
    "github.com/bborbe/vault-cli/pkg/storage"
)

var _ = Describe("Storage", func() {
    var (
        ctx     context.Context
        tempDir string
        store   storage.Storage
    )

    BeforeEach(func() {
        ctx = context.Background()
        var err error
        tempDir, err = os.MkdirTemp("", "vault-test-*")
        Expect(err).To(BeNil())

        cfg := storage.DefaultConfig()
        cfg.VaultPath = tempDir
        store = storage.NewStorage(cfg)
    })

    AfterEach(func() {
        os.RemoveAll(tempDir)
    })

    Context("WriteTask then ReadTask", func() {
        It("round-trips correctly", func() {
            task := &domain.Task{Name: "My Task", Status: domain.TaskStatusTodo}
            Expect(store.WriteTask(ctx, task)).To(BeNil())
            result, err := store.ReadTask(ctx, tempDir, "My Task")
            Expect(err).To(BeNil())
            Expect(result.Name).To(Equal("My Task"))
            Expect(result.Status).To(Equal(domain.TaskStatusTodo))
        })
    })
})
```

---

## Shared Error Variable

Define a shared test error in the suite file — reuse across all test files in the package:

```go
// pkg/ops/ops_suite_test.go
var ErrTest = errors.New("test error")
```

---

## Coverage Requirement

**Every changed package must have ≥80% test coverage.**

Check coverage after changes:
```bash
go test -cover ./pkg/...
```

If coverage is below 80%, add tests before declaring complete.

---

## Checklist Before Submitting

- [ ] Suite file exists for every tested package (check before creating)
- [ ] Package name is `mypackage_test` (not `mypackage`)
- [ ] Mocks generated with counterfeiter — never hand-written
- [ ] Both success and error paths tested
- [ ] Edge cases tested (empty input, missing data, special characters)
- [ ] Storage tests use real temp dirs, cleaned up with `AfterEach`
- [ ] Fresh `context.Background()` in each `BeforeEach`
- [ ] `make test` passes
- [ ] Coverage ≥80% for all changed packages
