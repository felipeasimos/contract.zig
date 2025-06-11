## Contract.zig

Simple comptime type validation for contract-based programming using anytype in zig.

### How to install

Just add contract to your `build.zig.zon`:

```
zig fetch --save git+https://github.com/felipeasimos/contract.zig.git
```

and add the import to your modules in `build.zig`:

```
const contract = b.dependency("contract", .{
    .target = target,
    .optimize = optimize,
});
lib.addImport("contract", contract.module("contract"));
```

### How to use

The folder `tests/` should be pretty explanatory, but basically it checks at compile time if an implementation type has all the functions of an interface type:

```
const Shape = struct {
    fn area() f64 {
        return 0;
    }
};

const Square = struct {
    side: f64 = 2.0,
    fn area() f64 {
        return 1;
    }
};

const ExampleConsumer = struct {
    fn func(impl: anytype) void {
        comptime contract.validate(@TypeOf(impl), Shape);
    }
};
ExampleConsumer.func(Square{});
```

If the `area` function in `Square` is removed, it will result in a compile error.
