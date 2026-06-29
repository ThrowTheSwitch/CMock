CMock: Argument Validation
==========================

Much of the power of CMock comes from its ability to automatically
validate that the arguments passed to mocked functions are the
values that were expected to be passed. CMock puts a lot of effort
into guessing how the user would most like to see those values
compared, and then represented when failures are encountered.

Like Unity, CMock follows a philosophy of making its best guesses,
and then allowing the user to explicitly specify any features that
they would like to change or customize.

Quick Reference: Which Option Should I Use?
-------------------------------------------

| Situation | Recommended Option |
|-----------|-------------------|
| Built-in C types (`int`, `uint8_t`, `float`, …) | Nothing — Option 1 handles these automatically |
| Simple typedef or `#define` alias of a known type | Option 2: add a `:treat_as` entry |
| Small `enum` type | Option 2: map to `INT8`, `INT16`, or `INT` |
| Opaque handle / function pointer where only identity matters | Option 2: map to `PTR` |
| `typedef`'d fixed-size array | Option 2: `:treat_as_array` |
| Legacy `typedef void MY_VOID` | Option 2: `:treat_as_void` |
| `struct` or `union` needing field-level comparison | Option 3: custom assertion + `:unity_helper_path` |
| Pointer to a `struct` with a custom assertion | Option 2 + 3: custom assertion, then `:treat_as` the pointer |
| Type that changes meaning per test, or one-off complex logic | Option 4: Callback |
| Last resort — type is unknown and rough equality is enough | Option 1b: memcmp fallback (automatic) |

Option 1: Common Types
----------------------

First, if you're dealing with C's standard types, there is nothing
further you need to do. CMock will choose an appropriate assertion
from Unity's list of assertions and will perform the comparison and
display using that. For example, if you specify a `short`, then it's 
very likely CMock will compare using `TEST_ASSERT_EQUAL_INT16`. For
unsigned values, it assumes you'd like them displayed in hex. Are you
interested in comparing a `const char*`? That would be Unity's 
string comparison. 

What if you have some other type of pointer? If you've instructed
CMock to compare pointers, it'll use `TEST_ASSERT_EQUAL_PTR`. 
Otherwise it'll use dereference the value being pointed at and 
compare that for you. (Read more about the Array plugin for more
details on how this all works). The TYPE being pointed to follows the
same rules as the those above... so if they're common types, for example 
`unsigned char*`, then CMock will choose to compare using the 
logical assertion (in this case `TEST_ASSERT_EQUAL_HEX8`).

A quick note about floating point types: we're calling the assertions
`TEST_ASSERT_EQUAL_FLOAT` (for example), but don't worry... these 
assertions are actually checking to make sure that the values are
"incredibly close" to the desired value instead of identical. This
is because many numbers can be represented in multiple ways when
using floating point. These differences are out of the control of 
the user, for the most part. You can ready more about this in the
Unity documentation if you're interested in the details.

Option 1b: The Fallback Plan
----------------------------

So what happens when CMock doesn't recognize the type being used?
This will happen for any custom types being used. What constitutes
a custom type?

  - You've used `#define` to create an alias for a standard type
  - You've used `typedef` to create an alias for a standard type
  - You've created an `enum` type
  - You've created a `union` type
  - You've created a `struct` type
  - You're working with a function pointer

 When CMock doesn't recognize the type as a standard type, (and 
 assuming you don't have a better option specified, as any of the
 options below), it will fall back to performing a memory 
 comparison using `TEST_ASSERT_EQUAL_MEMORY`. For the most part,
 this is effective, but the reported failures are not terribly
 descriptive.

 **WARNING:** There is one important instance where this fallback method
 doesn't work at all. If the custom type is a `struct` and that 
 struct isn't packed, then it's possible you can get false failures
 when the unused bytes between fields differ. For an unpacked struct,
 it's important that you either use option 3 or 4 below, or ignore that
 particular argument (and possibly test it manually yourself).

Option 2: Treat-As
------------------

CMock maintains a list of non-standard types which are basically
aliases of standard types. For example, a common shorthand for
a single-byte unsigned integer might be `u8` or `U8` or `UINT8`.
Any of these can simply be mapped to the standard
`TEST_ASSERT_EQUAL_HEX8`.

### Default Handlers

CMock ships with a built-in `:treat_as` list that already covers the
most common type aliases found in embedded C codebases. You get all
of these for free without any configuration:

| C Type              | Unity Assertion Used      |
|---------------------|---------------------------|
| `int`               | `INT`                     |
| `char`              | `INT8`                    |
| `short`             | `INT16`                   |
| `long`              | `INT`                     |
| `unsigned int`      | `HEX32`                   |
| `unsigned long`     | `HEX32`                   |
| `unsigned short`    | `HEX16`                   |
| `unsigned char`     | `HEX8`                    |
| `int8_t` / `INT8_T` / `int8` | `INT8`         |
| `int16_t` / `INT16_T` / `int16` | `INT16`     |
| `int32_t` / `INT32_T` / `int32` | `INT`       |
| `uint8_t` / `UINT8_T` / `uint8` / `UINT8` | `HEX8` |
| `uint16_t` / `UINT16_T` / `uint16` / `UINT16` | `HEX16` |
| `uint32_t` / `UINT32_T` / `uint32` / `UINT32` | `HEX32` |
| `bool` / `bool_t` / `BOOL` / `BOOL_T` | `INT`  |
| `char*`             | `STRING`                  |
| `pCHAR` / `cstring` / `CSTRING` | `STRING`   |
| `void*`             | `HEX8_ARRAY`              |
| `float` / `double`  | `FLOAT`                   |

The right-hand side of each mapping is the suffix of the Unity assertion
that will be used. `HEX8` means CMock will call `TEST_ASSERT_EQUAL_HEX8`,
for instance. Pointer variants (ending in `*`) map to the corresponding
array assertion (e.g. `HEX8*` → `TEST_ASSERT_EQUAL_HEX8_ARRAY`).

### Adding Your Own Mappings

While CMock has its own list of `:treat_as` mappings, you can
add your own pairings to this list. This works especially well for
the following types:

  - aliases of standard types using `#define` or `typedef`
  - `enum` types (works well as `INT8` or whatever size your enums are)
  - function pointers often work well as `PTR` comparisons
  - `union` types sometimes make sense to treat as the largest type...
    but this is a judgement call

Your entries **merge** with the defaults — you are only adding or
overriding specific types, not replacing the entire list. To remove
a default mapping, set its value to `nil`.

Here is a YAML configuration example:

```yaml
:cmock:
  :treat_as:
    MY_BOOL:    INT           # typedef bool MY_BOOL → compare as int
    MY_U8:      HEX8          # typedef uint8_t MY_U8 → compare as hex byte
    MY_U16:     HEX16
    MY_U32:     HEX32
    STATUS_T:   INT8          # small enum → compare as signed byte
    HANDLE_T:   PTR           # opaque pointer → compare pointer addresses
    float:      nil           # remove the default float mapping (unusual)
```

Or from Ruby:

```ruby
CMock.new(
  treat_as: {
    'MY_BOOL'  => 'INT',
    'STATUS_T' => 'INT8',
    'HANDLE_T' => 'PTR',
  }
).setup_mocks('my_module.h')
```

### Pointer Types in :treat_as

You can map pointer-to-custom-type the same way. Use a `*` suffix on
the right-hand side to indicate the comparison should use the array
variant of the assertion:

```yaml
:treat_as:
  MY_DATA_PTR: HEX8*    # compares the bytes pointed to, not the address
```

### Related Options: :treat_as_array and :treat_as_void

Two narrower variants of `:treat_as` handle specific edge cases:

**`:treat_as_array`** — for types that are themselves `typedef`'d arrays,
such as `typedef int TenIntegers[10];`. This is a hash of typedef name
to element type:

```yaml
:cmock:
  :treat_as_array:
    TenIntegers: int
    MyBuffer:    uint8_t
```

This lets CMock treat parameters of these types the same way it would
treat a pointer-plus-count, enabling features like `ExpectWithArray`
and `ReturnArrayThruPtr`.

**`:treat_as_void`** — for legacy codebases that typedef `void` to a
custom name (e.g. `typedef void MY_VOID;`). Add such names here so
CMock knows functions returning or accepting that type are effectively
`void`:

```yaml
:cmock:
  :treat_as_void:
    - MY_VOID
    - NORETURN_T
```

Option 3: Custom Assertions for Custom Types
--------------------------------------------

CMock has the ability to use custom assertions, if you form them 
according to certain specifications. Creating a custom assertion 
can be a bit of work, But the reward is that, once you've done so,
you can use those assertions within your own tests AND CMock will
magically use them within its own mocks.

To accomplish this, we're going tackle multiple steps:

  1. Write a custom assertion function
  2. Wrap it in a `UNITY_TEST_` macro
  3. Wrap it in a `TEST_` macro
  4. Inform CMock that it exists

Let's look at each of those steps in detail:

### Creating a Custom Assertion

A custom assertion is a function which accepts a standard set of 
inputs, and then uses Unity's assertion macros to verify any details
required for the types involved. 

The inputs:

  - the `expected` value (as a `const` version of type being verified)
  - the `actual` value (also as a `const` version of the desired type)
  - the `line` this function was called from (as type `UNITY_LINE_TYPE`)
  - an optional `message` to be appended (as type `const char*`)

Inside the function, we use the *internal* versions of Unity's assertions
to validate any details that need validating.

Let's look at an example! Let's say we have the following type:

```
typedef struct MyType_t
{
    int a;
    const char* b;
} MyType;
```

In our application, the length of `b` is supposed to be specified by `a`,
and `b` is therefore allowed to have any value (including `0x00`). 

Our custom assertion might look something like this:

```
void AssertEqualMyType(const MyType expected, const MyType actual, UNITY_LINE_TYPE line, const char* message)
{
    //It's common to override the default message with our own 
    (void)message; 

    // Verify the lengths are the same, or they're clearly not matched
    UNITY_TEST_ASSERT_EQUAL_INT(expected.a, actual.a, line, "Data length mismatch");

    // Verify we're dealing with actual pointers
    UNITY_TEST_ASSERT_NOT_NULL(expected.b, line, "Expected value should not be NULL");
    UNITY_TEST_ASSERT_NOT_NULL(actual.b, line, "Actual value should not be NULL");

    // Verify the string contents
    UNITY_TEST_ASSERT_EQUAL_MEMORY(expected.b, actual.b, expected.a, line, "Data not equal");
}
```

There are a few things to note about this. First, notice we're using the 
`UNITY_TEST_ASSERT_` assertions? That's because these allow us to pass 
on the specific line number. Second, notice we override the message with our
own more helpful messages? You don't need to do this, but anything you can do
to help a developer find a bug is a good thing.

What if there isn't an assertion that is right for your needs? You can 
always do whatever operations are necessary yourself, and use `UNITY_TEST_FAIL()`
directly.

One final note: It's best to only test the things that are hard rules about
how a type is supposed to work in your system. Anything else should be left to
the test code.

For example, let's say that in our example above, there are situations where
it IS valid for the pointers to be `NULL`. Perhaps the pointers are ignored
completely when the `a` field is `0`. In that case, we could drop those 
assertions completely, or add logic to only check when necessary.

Similarly, should our assertion check that the length is positive? In this
case, it's dangerous if it's negative, because the memory check wouldn't like it.

Updating for these concerns:


```
void AssertEqualMyType(const MyType expected, const MyType actual, UNITY_LINE_TYPE line, const char* message)
{
    //It's common to override the default message with our own 
    (void)message; 

    // Verify the lengths are the same, or they're clearly not matched
    UNITY_TEST_ASSERT_EQUAL_INT(expected.a, actual.a, line, "Data length mismatch");

    // Verify the lengths are non-negative
    UNITY_TEST_ASSERT_GREATER_OR_EQUAL_INT(0, expected.a, line, "Data length must be positive");

    if (expected.a > 0)
    {
        // Verify we're dealing with actual pointers
        UNITY_TEST_ASSERT_NOT_NULL(expected.b, line, "Expected value should not be NULL");
        UNITY_TEST_ASSERT_NOT_NULL(actual.b, line, "Actual value should not be NULL");

        // Verify the string contents
        UNITY_TEST_ASSERT_EQUAL_MEMORY(expected.b, actual.b, expected.a, line, "Data not equal");
    }
}
```

### Wrapping our Assertion in Macros

Once you have a function which does the main work, we need to create
macros around it so that the assertion can be used conveniently both
by CMock and directly in test code.

The macro that CMock **requires** is the `UNITY_TEST_ASSERT_EQUAL_` form.
It starts with exactly that prefix, followed by the type name exactly as
declared, and takes four arguments:

```c
#define UNITY_TEST_ASSERT_EQUAL_MyType(e,a,l,m)  AssertEqualMyType(e,a,l,m)
```

  - `e` - expected value
  - `a` - actual value
  - `l` - line number to report (filled in automatically by CMock)
  - `m` - message to append at the end

CMock scans the helper header for macros matching this pattern and
automatically uses them when it encounters the corresponding type.

It is also useful (though optional) to add the simpler `TEST_ASSERT_EQUAL_`
form so the assertion is easy to call directly inside your own test
functions:

```c
#define TEST_ASSERT_EQUAL_MyType(e,a) \
    UNITY_TEST_ASSERT_EQUAL_MyType(e,a,__LINE__,NULL)

#define TEST_ASSERT_EQUAL_MyType_MESSAGE(e,a,m) \
    UNITY_TEST_ASSERT_EQUAL_MyType(e,a,__LINE__,m)
```

With these in place, you can write `TEST_ASSERT_EQUAL_MyType(expected, actual)`
in your tests just like any built-in Unity assertion.

### Informing CMock about our Assertion

CMock needs to know which header file(s) contain your custom assertions.
Set the `:unity_helper_path` option in your CMock configuration to point
at the helper header:

```yaml
:cmock:
  :unity_helper_path:
    - test/support/my_types_helper.h
```

Or from Ruby:

```ruby
CMock.new(unity_helper_path: ['test/support/my_types_helper.h'])
      .setup_mocks('my_module.h')
```

CMock parses each listed file, finds every `UNITY_TEST_ASSERT_EQUAL_*`
macro definition, and uses those macros automatically when it generates
mocks for parameters or return values of the matching types.

Done!

**Bonus:** Once you've created a custom assertion, you can use it
with `:treat_as`, just like any other standard type! This is 
particularly useful when there is a custom type which is a pointer
to a custom type.

For example, let's say you have these types:

```
typedef struct MY_STRUCT_T_
{
    int a;
    const char* b;
} MY_STRUCT_T;

typedef MY_STRUCT_T* MY_STRUCT_POINTER_T;
```

Also, let's assume you've created the following assertion:

```
UNITY_TEST_ASSERT_EQUAL_MY_STRUCT_T(e,a,l,m)
```

You can use `:treat_as` like so:

```
:treat_as:
  MY_STRUCT_POINTER_T: MY_STRUCT_T*
```

Option 4: Callback
------------------

Finally, You can choose to avoid the use of `_Expect` calls altogether
for challenging types, and use a `Callback` instead. The advantage is that
you can fill in whichever assertions make sense for that particular test,
instead of needing to rely on reusable assertions as used elsewhere. 
Typically, this option is also less work than option 3.
