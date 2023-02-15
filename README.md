# Low

A scripting language with simple, elegant runtime type-checking.

# Simple Type-Checking

You can use `is` or `isnt` to check if a value matches a type at runtime.
Types are also values.

You can also explicitely write the argument types:

```rs
// The type being a string means the type name must be that string.
fn F(x: "Int") {
  return x + 1;
}

F("Not an int") // We get an error on this line at runtime, because the type-check of Argument #1 failed.
```

There are also a lot of pre-defined variables for common types, like `int` and `number`. There are also helpers like `listOf`, which will check if the value is a list with every element passing the passed in type.

Example:

```rs
// You can also type your return values! If the returned value doesn't match, the crash happens at the function definition!
fn Average(nums: listOf(number)): double {
  var x = 0;

  foreach(var num in nums) {
    x = x + num
  }

  return x / nums.length;
}

print(Average([50, 30])) // Prints 40
print(Average(["string"])) // Raises an exception on this line due to type-check failing
```

# Documentation

Docs are a WIP right now.
