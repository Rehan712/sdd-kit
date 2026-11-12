# Style guide: Rust

Digest of the [Google Rust Style Guide](https://google.github.io/styleguide/rustguide.html)
(read 2026-11-12), for implementers and reviewers. That guide layers on the
official Rust Style Guide (rustfmt) and the Rust API Guidelines and follows
both wherever it does not say otherwise. The linked page is the authority —
open it when a case is not covered here.

## Precedence

1. The project's own config and constitution: `rustfmt.toml`, `clippy.toml`, `[lints]`, CI.
2. The file you are editing — match it. Never restyle lines the task does not touch; a style-only change is its own task.
3. The stack overlay (`../stack-overlays/rust.md`, `rust-aws-lambda.md`).
4. This guide.

**Library vs application code.** API-design rules bind library code (shared
crates, anything another project consumes). In application code (handlers,
binaries) they are a strong default: favour simplicity over reusability and
do not generalize early.

**Not adopted** — rules the guide tags for one codebase: Chrome's small-crate
and flat-directory layout, `chromium::import!`, no `async`/`.await`, no std
threads; Fuchsia's mutex; the per-codebase test frameworks. The overlay's
tokio, Cargo layout and `#[test]` rules stand.

## Modules and imports

- A leaf module is named after its primary item (`mod foo` in `foo.rs` for `Foo`). Non-leaf modules hold only `mod` declarations and re-exports.
- No glob imports. Allowed: `use super::*` in an inline (test) module, `use Enum::*` inside a function mostly about that enum, `pub use submodule::*` in a non-leaf module. Do not define preludes.
- One module per `use` — no `::` inside the braces: `use foo::bar::{Bar, Baz};` yes, `use foo::{Foo, bar::Bar};` no.
- Types and traits are imported and used unqualified (`Regex`, not `regex::Regex`); functions are called module-qualified (`mem::take(x)`, not `take(x)`). Ambiguous names stay qualified or are renamed (`io::Error`).
- Import a trait inside the function that uses it, unless the file uses its methods throughout.

## Ownership and signatures

- Unique ownership and borrows before `Rc`/`Arc`; reach for those when the alternative is unreasonably complex.
- `.clone()` for a real deep copy, not to dodge the borrow checker. (Cloning an `Rc`/`Arc` is expected.)
- Borrowed parameters take the flexible form: `&[T]` not `&Vec<T>`, `&str` not `&String`, `&T` not `&Box<T>`, `Option<&T>` not `&Option<T>`.
- Library code that only iterates accepts `impl IntoIterator` and returns iterators (`impl Iterator`); application code may use `&[T]` / `Vec<T>` when that is simpler. `impl Into<T>` parameters: rare in libraries, almost never in application code.
- An `enum` instead of a `bool` parameter whose meaning is not obvious at the call site.

## Errors and panics

- `Option` for an obvious failure with nothing to add; `Result` for recoverable failures the caller has to tell apart; `panic!` only for bugs and broken invariants.
- Pattern-match instead of check-then-unwrap: `if let Some(v) = opt { … }`, never `if opt.is_some() { opt.unwrap() }`.
- Where a panic is the right answer, `expect("<why this holds>")` over `unwrap()`. An `assert!` carries a context string that explains the invariant or logs the value — never one that repeats the condition.
- No `panic::catch_unwind` (defence in depth at most, never relied on). Never reach inside a poisoned mutex.

## Types and traits

- A newtype instead of a type alias when the semantics differ, the type needs its own API, the representation may change, or values are easy to mix up (`Day`, `Month`, `Year`).
- Named fields over tuples and tuple structs (single-field newtypes excepted).
- `#[derive]` whenever it can express the impl. Implement the std trait rather than a look-alike method (`impl FromStr`, not `fn from_str`); `Default` when there is a `new()` or a default state; `is_empty()` alongside `len()`.
- `Clone` on most types (not on handles to external resources); `Copy` only where the type will stay `Copy` — error types whenever possible; `PartialEq`/`PartialOrd` unless `Eq`/`Ord` is needed; `Hash + Eq` on map keys.
- A trait only for generic programming, `impl Trait`/`dyn Trait`, or an extension trait (named `…Ext`) — never just to organize code; otherwise an inherent impl. Libraries prefer generics/`impl Trait` to `dyn Trait` unless code size matters, and anticipate trait impls; application code adds them when needed.
- A `From` impl that is a primary way to construct the type also gets an inherent constructor. An all-public-fields options struct implements `Default`.
- Public API crossing a team or crate boundary: `#[non_exhaustive]` on enums and on all-public-field structs that may grow; `#[must_use]` on functions (and types) whose result must not be ignored; `const fn` only if it will stay `const`.
- Operators are overloaded only for their mathematical or logical meaning. Items marked `#[doc(hidden)]` that you do not own are private. No code runs before `main()` (no `ctor`).

## Naming

- Std-library method naming, including `as_` / `to_` / `into_` with the matching `self`. Constructors: `new()`, `new_with_foo()`, `try_new()` when fallible. Value conversions: `from_foo()` with a `From` impl.
- Accessors: `foo()`, `foo_mut()`, `set_foo(v)`, `take_foo()`, `replace_foo(v)`, `with_foo(|foo| …)`.
- Descriptive lifetime names on types; `'_` and single letters are fine locally. Generic parameters are short and hint at the main bound; `T`/`U` when unbounded.
- No abbreviation an outsider would not know; never drop letters from inside a word.

## Implementation

- Enough explicit types that a reader can tell what was inferred: annotate the binding (not a turbofish) for `.into()`, `.parse()` and long iterator chains.
- Iterator chains when short, or when the combinator carries the logic (`any`, `find`). A `for` loop when the chain is long or has side effects; never build a chain in a `for` header — bind it to a named variable first. Avoid `Iterator::for_each`.
- Matching a `#[non_exhaustive]` enum: list the variants you handle; `if let` / `let … else` when only some matter.
- `format!` / `write!` to join more than two strings or to substitute into a literal.
- Macros last: a function, type or trait first, then `macro_rules!`, then code generation, then `proc_macro`.
- No unstable features.
- `unsafe` only when safe code cannot do the job: behind a safe abstraction and away from business logic, with a `// SAFETY:` comment saying why it is correct and a written justification (benchmarks when the reason is speed).

## Formatting

- rustfmt decides. `#[rustfmt::skip]` only for deliberate manual alignment or generated code, never for taste.
- Guide settings for a new project: `max_width = 100` (the rustfmt default), and — where the toolchain's rustfmt has them; the guide lets stable-only codebases omit them — `imports_granularity = "Module"`, `hex_literal_case = "Lower"`, `format_macro_matchers = true`.

## Docs and comments

- `///` on public items and `//!` at the top of a module or crate, in Markdown; `//` for implementation notes and TODOs.
- Document the panic cases of functions that panic on malformed input, and the invariants of `unsafe` functions and traits.
- A comment says what the code does not; drop one that only restates the name. Self-explanatory enum variants need none. Docs are written by hand, not generated by macros.

## Lints that carry these rules

On by default under the overlay's `cargo clippy -- -D warnings` gate:
`borrowed_box`, `ptr_arg`, `should_implement_trait`, `wrong_self_convention`,
`new_without_default`, `len_without_is_empty`. Opt-in, as a plan decision for
a new library crate (never a drive-by in an existing one): rustc
`missing_docs`, `clippy::exhaustive_enums`.
