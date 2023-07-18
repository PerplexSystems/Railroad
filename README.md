# smltest

An advanced testing library and test runner for Standard ML, highly
inspired by [elm-test](https://github.com/elm-explorations/test) and
[Expecto](https://github.com/haf/expecto).

This library provides a set of composable functions for writing tests,
along with a built-in test runner.

## Quickstart

Here is a simple example of how tests can look:

```sml
val tests =
  describe "math operations"
    [ test "sum 1 + 1" (fn _ =>
        Expect.equal Int.compare 2 (1 + 1))
    ]

val _ =
    run tests
```

Check out the table of contents below for more information:

- [smltest](#smltest)
  - [Quickstart](#quickstart)
  - [Installing](#installing)
- [API Reference](#api-reference)
  - [Test](#test)
    - [concat](#concat)
    - [describe](#describe)
    - [focus](#focus)
    - [run](#run)
    - [runwithoptions](#runwithoptions)
    - [skip](#skip)
    - [test](#test-1)
  - [Expect](#expect)
    - [actual](#actual)
    - [expected](#expected)
    - [comparer](#comparer)
    - [tostring](#tostring)
    - [pass](#pass)
    - [fail](#fail)
    - [onfail](#onfail)
    - [istrue](#istrue)
    - [isfalse](#isfalse)
    - [some](#some)
    - [none](#none)
    - [equal](#equal)
    - [equalfmt](#equalfmt)
    - [notequal](#notequal)
    - [notequalfmt](#notequalfmt)
    - [atmost](#atmost)
    - [atmostfmt](#atmostfmt)
    - [atleast](#atleast)
    - [atleastfmt](#atleastfmt)
    - [less](#less)
    - [lessfmt](#lessfmt)
    - [greater](#greater)
    - [greaterfmt](#greaterfmt)

## Installing

<!-- TODO -->

# API Reference

## Test

The [`Test`](#test) module consists of functions that are involved in
creating and managing tests.

### concat

`val concat: Test list -> Test`

Concatenates a list of tests.

```sml
concat [ userTests, baggageTests ]
```

### describe

`val describe: string -> Test list -> Test`

Describes a list of tests.

```sml
describe "math operators"
  [ test "sum" (fn _ =>
      Expect.equal Int.compare 2 (1 + 1))
  , test "failing sum" (fn _ =>
      Expect.equal Int.compare 3 (2 + 3))
  ]
```

### focus

`val focus: Test -> Test`

Returns a [`Test`](#test) that causes other tests to be skipped, and
only runs the given one.

Calls to [`focus`](#focus) aren't meant to be committed to version
control. Instead, use them when you want to focus on getting a
particular subset of your tests to pass. If you use `focus`, your
entire test suite will fail, even if each of the individual tests
pass. This is to help avoid accidentally committing a `focus` to
version control.

If you you use `focus` on multiple tests, only those tests will run.
If you put a `focus` inside another `focus`, only the outermost only
will affect which tests gets run.

See also [`skip`](#skip). Note that `skip` takes precedence over
`focus`; if you use a `skip` inside a `focus`, it will still get
skipped, and if you use a `focus` inside a `skip`, it will also get
skipped.

```sml
describe "math operators"
  [ test "sum" (fn _ =>
      Expect.equal Int.compare 2 (1 + 1))
  , focus (test "this is the only test that will run" (fn _ =>
      Expect.equal Int.compare 3 (2 + 3)))
  ]
```

### run

<!-- TODO -->

### runwithoptions

<!-- TODO -->

### skip

`val skip: Test -> Test`

Returns a [`Test`](#test) that gets skipped.

Calls to [`skip`](#skip) aren't meant to be committed to version
control. Instead, use it when you want to focus on getting a
particular subset of your tests to pass. If you use `skip`, your
entire test suite will fail, even if each of the individual tests
pass. This is to help avoid accidentally committing a skip to version
control.

See also [`focus`](#focus). Note that `skip` takes precedence over
`focus`; if you use a `skip` inside a `focus`, it will still get
skipped, and if you use a `focus` inside a `skip`, it will also get
skipped.

```sml
describe "math operators"
  [ test "this test will be the only one to run" (fn _ =>
      Expect.equal Int.compare 2 (1 + 1))
  , skip (test "this test is skipped" (fn _ =>
      Expect.equal Int.compare 3 (2 + 3)))
  ]
```

### test

`val test: string -> (unit -> Expectation) -> Test`

Return a [`Test`](#test) that evaluates a single `Expectation`.

```sml
test "sum" (fn _ => Expect.equal Int.compare 2 (1 + 1))
```

## Expect

The [`Expect`](#expect) module consists of assertion functions that
describes a claim to be tested.

### actual

`type 'a actual = 'a`

Represents the actual value passed to an assertion function.

### expected

`type 'a expected = 'a`

Represents the expected value passed to an assertion function.

### comparer

`type 'a comparer = ('a expected * 'a actual) -> General.order`

Represents a function that compares the [`expected`](#expected)
against the [`actual`](#actual) value.

### tostring

`type 'a tostring = 'a -> string`

Represents a function that converts the given value to a `string`.

### pass

`val pass: Expectation`

Always passes.

```sml
test "this sum is always two" (fn _ =>
  if (1 + 1) = 2 then
    Expect.pass
  else
    Expect.fail "man, something is up...")
```

### fail

`val fail: string -> Expectation`

Always fails.

```sml
test "this sum is always two" (fn _ =>
  if (1 + 1) = 2 then
    Expect.pass
  else
    Expect.fail "man, something is up...")
```

### onfail

`val onfail: string -> Expectation -> Expectation`

If the given expectation fails, replace its failure message with a
custom one.

```sml
test "sum" (fn _ =>
  Expect.onfail 
    "this shouldn't be failing" 
    (Expect.equal Int.compare 4 (2 + 2)))
```

### istrue

`val istrue: bool actual -> Expectation`

Passes if the provided value is `true`.

```sml
Expect.istrue (2 > 1)
```

### isfalse

`val isfalse: bool actual -> Expectation`

Passes if the provided value is `false`.

```sml
Expect.istrue (2 < 1)
```

### some

`val some: 'a option actual -> Expectation`

Passes if the provided value is `SOME`.

```sml
val value = SOME 1
Expect.some value
```

### none

`val none: 'a option actual -> Expectation`

Passes if the provided value is `NONE`.

```sml
val value = NONE
Expect.none value
```

### equal

`val equal: 'a comparer -> 'a expected -> 'a actual -> Expectation`

Passes if the arguments are equal.

```sml
Expect.equal Int.compare 2 (1 + 1)
```

### equalfmt

`val equalfmt: 'a comparer -> 'a tostring -> 'a expected -> 'a actual
-> Expectation`

Passes if the arguments are equal, but receives a
[`tostring`](#tostring) that encapsulates the values on the
`Expectation`.

```sml
Expect.equalfmt Int.compare Int.toString 2 (1 + 1)
```

### notequal

`val notequal: 'a comparer -> 'a expected -> 'a actual -> Expectation`

Passes if the arguments are not equal.

```sml
Expect.notequal Int.compare 3 (1 + 1)
```

### notequalfmt

`val notequalfmt: 'a comparer -> 'a tostring -> 'a expected -> 'a
actual -> Expectation`

Passes if the arguments are not equal, but receives a
[`tostring`](#tostring) that encapsulates the values on the
`Expectation`.

```sml
Expect.equalfmt Int.compare Int.toString 2 (1 + 1)
```

### atmost

`val atmost: 'a comparer -> 'a expected -> 'a actual -> Expectation`

Passes if the provide value is less or equal than the expected value.

```sml
Expect.atmost Int.compare 3 2
Expect.atmost Int.compare 2 2
```

### atmostfmt

`val atmostfmt: 'a comparer -> 'a tostring-> 'a expected-> 'a actual->
Expectation`

Passes if the provided value is less or equal than the expeted value,
but receives a [`tostring`](#tostring) that encapsulates the values on
the `Expectation`.

```sml
Expect.atmost Int.compare Int.toString 3 2
Expect.atmost Int.compare Int.toString 2 2
```

### atleast

`val atleast: 'a comparer -> 'a expected -> 'a actual -> Expectation`

Passes if the provide value is greater or equal than the expected
value.

```sml
Expect.atmost Int.compare 3 4
Expect.atmost Int.compare 3 3
```

### atleastfmt

`val atleastfmt: 'a comparer -> 'a tostring -> 'a expected -> 'a
actual -> Expectation`

Passes if the provided value is greater or equal than the expeted
value, but receives a [`tostring`](#tostring) that encapsulates the
values on the `Expectation`.

```sml
Expect.atmost Int.compare Int.toString 3 4
Expect.atmost Int.compare Int.toString 3 3
```

### less

`val less: 'a comparer -> 'a expected -> 'a actual -> Expectation`

Passes if the provided value is less than the expected value.

```sml
Expect.notequal Int.compare 3 (1 + 1)
```

### lessfmt

`val lessfmt: 'a comparer -> 'a tostring -> 'a expected -> 'a actual
-> Expectation`

Passes if the provided value is less than the expeted value, but
receives a [`tostring`](#tostring) that encapsulates the values on the
`Expectation`.

```sml
Expect.atmost Int.compare Int.toString 3 2
```

### greater

`val greater: 'a comparer -> 'a expected -> 'a actual -> Expectation`

Passes if the provided value is greater than the expected value.

```sml
Expect.notequal Int.compare 3 4
```

### greaterfmt

`val greaterfmt: 'a comparer -> 'a tostring -> 'a expected -> 'a
actual -> Expectation`

Passes if the provided value is greater than the expeted value, but
receives a [`tostring`](#tostring) that encapsulates the values on the
`Expectation`.

```sml
Expect.atmost Int.compare Int.toString 3 4
```
