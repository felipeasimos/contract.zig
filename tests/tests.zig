const contract = @import("contract");

test "method using no arguments" {
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
}

test "method using self" {
    const Shape = struct {
        fn area(self: *@This()) f64 {
            _ = self;
            return 0;
        }
    };

    const Square = struct {
        side: f64 = 2.0,
        fn area(self: *@This()) f64 {
            return self.side * self.side;
        }
    };

    const ExampleConsumer = struct {
        fn func(impl: anytype) void {
            comptime contract.validate(@TypeOf(impl), Shape);
        }
    };
    ExampleConsumer.func(Square{});
}
