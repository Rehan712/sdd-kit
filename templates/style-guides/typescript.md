# Style guide: TypeScript / JavaScript

Digest of the [Google TypeScript Style Guide](https://google.github.io/styleguide/tsguide.html)
(read 2026-11-12), for implementers and reviewers on every TypeScript stack
(`javascript`, `nextjs`, `react`, `expo-rn`, `loopback4`, `bun-monorepo`,
`aws-cdk-lambda-ts`, `firebase-rtk-codegen`). The linked page is the
authority — open it when a case is not covered here.

## Precedence

1. The project's own config and constitution: ESLint, Prettier, `tsconfig.json`, CI. Formatting (quotes, width, semicolons, wrapping) is the formatter's — the guide assumes code is auto-formatted.
2. The file you are editing — match it. Existing non-conforming code is not reformatted; a brand-new file follows the guide. A style-only change is its own task, never mixed into a behavioral one.
3. The stack overlay (`../stack-overlays/<tag>.md`) — including where a framework needs otherwise (its line names the exception).
4. This guide.

## Modules

- ES modules only: no `namespace`, no `require`, no `/// <reference>`. Split code into files, not namespaces.
- **Named exports only — no default exports**, except where a framework or tool loads the file by its default export (the overlay says which).
- Export only what is used outside the module. No `export let`: exports are final once the module has run; mutable state is read through an exported getter function.
- No container classes of static members for namespacing — export the functions and constants themselves.
- `import type {…}` (or inline `import {type Foo}`) for symbols used only as types; `export type {…} from` when re-exporting types. No `import()` in type annotations.
- Relative imports (`./foo`) within a project; keep `../` chains short. Namespace imports (`import * as ns`) for large APIs, named imports for a few well-named symbols.

## Naming

| Kind | Style |
|---|---|
| class, interface, type, enum, decorator, type parameter, TSX component | `UpperCamelCase` |
| variable, parameter, function, method, property, module alias | `lowerCamelCase` |
| module-level constant, `static readonly` constant, enum value | `CONSTANT_CASE` |

- Acronyms are words: `loadHttpUrl`, `customerId` — not `loadHTTPURL`, `customerID`.
- Descriptive names; no abbreviation an outsider would not know, no dropped letters. A short name only in a scope of ten lines or fewer.
- No `_` prefix or suffix for private members, no `I` prefix or `Interface` suffix, no `opt_` prefix, no type encoded in the name.
- `CONSTANT_CASE` only at module level. A value that can be created more than once (a function local) is `lowerCamelCase`.
- An unused trailing parameter is omitted, not renamed to `_`; `_name` only where syntax requires a binding.

## Variables, arrays, objects

- `const` by default, `let` when reassigned, never `var`. One variable per declaration; declared before use.
- Literals, never the `Array` or `Object` constructors. Sized array: `Array.from<T>({length: n})`.
- Iterate arrays with `for … of` (`.entries()` for the index); never `for … in` on an array. Object iteration goes through `Object.keys/values/entries`, or `for … in` with a `hasOwnProperty` filter.
- Spread only plain objects and arrays (never class instances) — it is a shallow copy.
- Parameter destructuring: one level, shorthand properties, defaults on the left (`{limit = 10} = {}`).
- `Map`/`Set` over index-signature objects; `Record<Keys, V>` for a known key set.

## Classes

- TypeScript `private` — never `#private` fields. Never write `public` except on a non-readonly parameter property.
- `readonly` on every property not reassigned after the constructor. Parameter properties (`constructor(private readonly db: Db) {}`) instead of hand-assigned fields; field initializers where the value does not depend on a constructor argument.
- No empty or pass-through constructor. No member that only the constructor uses.
- Never add or remove properties after construction; never touch `prototype`; no mixins.
- Getters are pure; no pass-through accessor that only hides a field.
- No `this` in static methods; call a static on the class that defines it. Prefer a module-level function to a private static method.

## Functions

- Function declarations for named functions; arrow functions for callbacks and nested functions; no `function` expressions.
- Arrow body: a block when the return value is unused, an expression only when it is used.
- Never rebind `this` (`bind`, `const self = this`) — use an arrow function. `this` only inside classes or where an explicit `this` type is declared.
- Pass callbacks as explicit arrows — `xs.map((x) => parse(x))` — not a bare function reference that may receive extra arguments.
- Rest parameters instead of `arguments`; spread instead of `.apply`. Default initializers have no side effects.
- Several optional parameters become one destructured options object. Split a function that outgrows about 40 lines.

## Control flow and errors

- Braces on every block (a one-line `if` may go without). `===`/`!==` always; `== null` only to match both `null` and `undefined`.
- Every `switch` has a `default`, last; no fall-through from a non-empty `case`.
- Throw only `Error` (or a subclass), always with `new`; the same for `Promise.reject`. Throw rather than return an error object.
- `catch (e: unknown)` and narrow before use. No empty `catch` without a comment saying why. Keep `try` blocks tight around what can throw.
- Never test "it throws" with `try { … fail() } catch {}` — use the framework's throws assertion.

## Types

- Rely on inference for trivially inferred values; annotate where it helps a reader (complex expressions, exported symbols). Return-type annotations are the author's call unless the project requires them.
- No `any` — a specific type, a generic, or `unknown` narrowed by a guard. No `{}` type: `unknown`, `Record<string, T>` or `object`.
- `interface` for object shapes; `type` aliases for unions, tuples, primitives and inferred types.
- Object literals are **annotated**, not asserted: `const foo: Foo = {…}`, never `{…} as Foo`.
- Avoid `as` and non-null `!` — prefer a runtime check; where one is needed, a comment says why it is safe. `as` syntax only (no `<T>x`); double assertions go through `unknown`.
- `T[]` for simple element types, `Array<T>` for anything more complex (`Array<string|number>`).
- A type alias never includes `|null` or `|undefined` — add it at the use site. Deal with null close to where it arises.
- Lowercase primitives (`string`, never `String`); no wrapper objects (`new String`).
- Mapped and conditional types sparingly — the simplest construct that works.
- Numbers: `Number(x)` then check for `NaN`; never unary `+`, never `parseInt` without a radix and validation. Enum values are compared explicitly, never coerced to boolean.

## Disallowed

`@ts-ignore`, `@ts-nocheck`, and `@ts-expect-error` outside tests · `const enum`
· `eval` / `new Function(string)` · `with` · `debugger` · relying on ASI ·
non-standard or proposal-stage language features · modifying built-in
prototypes · new global symbols · defining new decorators (framework-provided
ones are fine).

## Comments

- `/** JSDoc */` for what a user of the code reads, `//` for implementation notes; no `/* */` blocks, no decorative boxes.
- Document every top-level export and anything non-obvious. A comment adds information — never one that restates the name or the type; no types in JSDoc.
- Method docs start with a verb phrase ("Computes …"). `@deprecated` carries the migration path. JSDoc goes before decorators.

## Lints that carry these rules

A plan decision for a new project, never a drive-by in an existing one.
Google's own preset is [`gts`](https://github.com/google/gts) (ESLint +
Prettier + tsconfig). On an existing typescript-eslint setup, the rules that
enforce the list above: `no-var`, `prefer-const`, `eqeqeq` (`null: ignore`),
`curly`, `default-case`, `no-fallthrough`, `import/no-default-export`,
`@typescript-eslint/no-explicit-any`, `no-non-null-assertion`,
`ban-ts-comment`, `consistent-type-imports`, `consistent-type-assertions`,
`consistent-type-definitions`, `array-type` (`array-simple`), `no-namespace`,
`only-throw-error`, `naming-convention`.
