CMock: Argument Validation
==========================

Much of the power of CMock comes from its ability to automatically 
validate that the arguments passed to mocked functions are the 
values that were expected to be passed. CMock puts a lot of effort
into guessing how the user would most like to see those values 
compared, and then represented when failures are encountered.

Like Unity, CMock follows a philosophy of making its best guesses,
and then allowing the user to explicity specify any features that 
they would like to change or customize.

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
a single-byte unsigned integer might be `u8` or `U8` or `UNIT8`.
Any of these can simply be mapped to the standard 
`TEST_ASSERT_EQUAL_HEX8`.

While CMock has its own list of `:treat_as` mappings, you can 
add your own pairings to this list. This works especially well for
the following types:

  - aliases of standard types using `#define` or `typedef`
  - `enum` types (works well as `INT8` or whatever size your enums are)
  - function pointers often work well as `PTR` comparisons
  - `union` types sometimes make sense to treat as the largest type... 
    but this is a judgement call

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

Once you have a function which does the main work, we *need* to create
one macro, and there are a number of other macros which are useful to
create, in order to treat our assertion just like any other Unity 
assertion.

`#define UNITY_TEST_ASSERT_EQUAL_MyType(e,a,l,m) AssertEqualMyType(e,a,l,m)`

The macro above is the one that CMock is looking for. Notice that it 
starts with `UNITY_TEST_ASSERT_EQUAL_` followed by the name of our type, 
*exactly* the way our type is named. The arguments are, in order:

  - `e` - expected value
  - `a` - actual value
  - `l` - line number to report
  - `m` - message to append at the end

If CMock finds a macro that matches this argument list and naming convention,
then it can automatically use this assertion where needed... all we need to
do now is tell CMock where to find our custom assertion.

### Informing CMock about our Assertion

In the CMock configuration file, in the `:cmock` or `:unity` sections, 
there can be an option for `unity_helper_path`. Add the location of your
new Unity helper file (file with this assertion) to this list.

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
