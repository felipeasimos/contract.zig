const contract = @import("contract");
const std = @import("std");
const testing = std.testing;

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

test "multiple methods with same signatures" {
    const Drawable = struct {
        fn draw(self: *@This()) void {
            _ = self;
        }
        fn area(self: *@This()) f64 {
            _ = self;
            return 0;
        }
        fn perimeter(self: *@This()) f64 {
            _ = self;
            return 0;
        }
    };

    const Circle = struct {
        radius: f64 = 1.0,
        fn draw(self: *@This()) void {
            _ = self;
            // Drawing logic here
        }
        fn area(self: *@This()) f64 {
            return 3.14159 * self.radius * self.radius;
        }
        fn perimeter(self: *@This()) f64 {
            return 2 * 3.14159 * self.radius;
        }
    };

    const ExampleConsumer = struct {
        fn func(impl: anytype) void {
            comptime contract.validate(@TypeOf(impl), Drawable);
        }
    };
    ExampleConsumer.func(Circle{});
}

// Test methods with different parameter types
test "methods with various parameter types" {
    const Calculator = struct {
        fn add(a: i32, b: i32) i32 {
            return a + b;
        }
        fn multiply(a: f64, b: f64) f64 {
            return a * b;
        }
        fn concat(a: []const u8, b: []const u8, allocator: std.mem.Allocator) ![]u8 {
            _ = a;
            _ = b;
            _ = allocator;
            return error.NotImplemented;
        }
    };

    const SimpleCalculator = struct {
        fn add(a: i32, b: i32) i32 {
            return a + b;
        }
        fn multiply(a: f64, b: f64) f64 {
            return a * b;
        }
        fn concat(a: []const u8, b: []const u8, allocator: std.mem.Allocator) ![]u8 {
            return try std.fmt.allocPrint(allocator, "{s}{s}", .{ a, b });
        }
    };

    const ExampleConsumer = struct {
        fn func(impl: anytype) void {
            comptime contract.validate(@TypeOf(impl), Calculator);
        }
    };
    ExampleConsumer.func(SimpleCalculator{});
}

// Test const self parameter
test "method using const self" {
    const Reader = struct {
        fn read(self: *const @This()) []const u8 {
            _ = self;
            return "";
        }
    };

    const FileReader = struct {
        content: []const u8 = "file content",
        fn read(self: *const @This()) []const u8 {
            return self.content;
        }
    };

    const ExampleConsumer = struct {
        fn func(impl: anytype) void {
            comptime contract.validate(@TypeOf(impl), Reader);
        }
    };
    ExampleConsumer.func(FileReader{});
}

// Test methods with generic parameters
test "methods with generic/anytype parameters" {
    const Container = struct {
        fn store(self: *@This(), value: anytype) void {
            _ = self;
            _ = value;
        }
        fn process(data: anytype, callback: fn (anytype) void) void {
            callback(data);
        }
    };

    const IntContainer = struct {
        values: std.ArrayList(i32) = undefined,
        fn store(self: *@This(), value: anytype) void {
            _ = self;
            _ = value;
            // Store implementation
        }
        fn process(data: anytype, callback: fn (anytype) void) void {
            callback(data);
        }
    };

    const ExampleConsumer = struct {
        fn func(impl: anytype) void {
            comptime contract.validate(@TypeOf(impl), Container);
        }
    };
    ExampleConsumer.func(IntContainer{});
}

// Test methods with error unions
test "methods with error return types" {
    const Parser = struct {
        fn parse(self: *@This(), input: []const u8) !i32 {
            _ = self;
            _ = input;
            return error.ParseError;
        }
        fn validate(input: []const u8) !bool {
            _ = input;
            return true;
        }
    };

    const NumberParser = struct {
        fn parse(self: *@This(), input: []const u8) !i32 {
            _ = self;
            return std.fmt.parseInt(i32, input, 10);
        }
        fn validate(input: []const u8) !bool {
            _ = std.fmt.parseInt(i32, input, 10) catch return false;
            return true;
        }
    };

    const ExampleConsumer = struct {
        fn func(impl: anytype) void {
            comptime contract.validate(@TypeOf(impl), Parser);
        }
    };
    ExampleConsumer.func(NumberParser{});
}

// Test methods with optional return types
test "methods with optional return types" {
    const Finder = struct {
        fn find(self: *@This(), key: []const u8) ?[]const u8 {
            _ = self;
            _ = key;
            return null;
        }
        fn get_first() ?i32 {
            return null;
        }
    };

    const HashMap = struct {
        data: std.StringHashMap([]const u8) = undefined,
        fn find(self: *@This(), key: []const u8) ?[]const u8 {
            _ = self;
            _ = key;
            return null; // Simplified implementation
        }
        fn get_first() ?i32 {
            return 42;
        }
    };

    const ExampleConsumer = struct {
        fn func(impl: anytype) void {
            comptime contract.validate(@TypeOf(impl), Finder);
        }
    };
    ExampleConsumer.func(HashMap{});
}

// Test methods with comptime parameters
test "methods with comptime parameters" {
    const Transformer = struct {
        fn transform(self: *@This(), comptime T: type, value: T) T {
            _ = self;
            return value;
        }
        fn create(comptime T: type) T {
            return std.mem.zeroes(T);
        }
    };

    const TypeTransformer = struct {
        fn transform(self: *@This(), comptime T: type, value: T) T {
            _ = self;
            return value;
        }
        fn create(comptime T: type) T {
            return std.mem.zeroes(T);
        }
    };

    const ExampleConsumer = struct {
        fn func(impl: anytype) void {
            comptime contract.validate(@TypeOf(impl), Transformer);
        }
    };
    ExampleConsumer.func(TypeTransformer{});
}

// Test methods with struct parameters
test "methods with struct parameters" {
    const Point = struct {
        x: f64,
        y: f64,
    };

    const Geometry = struct {
        fn distance(p1: Point, p2: Point) f64 {
            const dx = p1.x - p2.x;
            const dy = p1.y - p2.y;
            return @sqrt(dx * dx + dy * dy);
        }
        fn midpoint(self: *@This(), p1: Point, p2: Point) Point {
            _ = self;
            return Point{
                .x = (p1.x + p2.x) / 2,
                .y = (p1.y + p2.y) / 2,
            };
        }
    };

    const BasicGeometry = struct {
        fn distance(p1: Point, p2: Point) f64 {
            _ = p1;
            _ = p2;
            return 0; // Simplified
        }
        fn midpoint(self: *@This(), p1: Point, p2: Point) Point {
            _ = self;
            _ = p1;
            _ = p2;
            return Point{ .x = 0, .y = 0 }; // Simplified
        }
    };

    const ExampleConsumer = struct {
        fn func(impl: anytype) void {
            comptime contract.validate(@TypeOf(impl), Geometry);
        }
    };
    ExampleConsumer.func(BasicGeometry{});
}

// Test methods with array parameters
test "methods with array and slice parameters" {
    const Processor = struct {
        fn process_array(self: *@This(), arr: [5]i32) i32 {
            _ = self;
            _ = arr;
            return 0;
        }
        fn process_slice(data: []const i32) i32 {
            _ = data;
            return 0;
        }
        fn sum_fixed(numbers: [10]f64) f64 {
            _ = numbers;
            return 0;
        }
    };

    const NumberProcessor = struct {
        fn process_array(self: *@This(), arr: [5]i32) i32 {
            _ = self;
            var sum: i32 = 0;
            for (arr) |num| sum += num;
            return sum;
        }
        fn process_slice(data: []const i32) i32 {
            var sum: i32 = 0;
            for (data) |num| sum += num;
            return sum;
        }
        fn sum_fixed(numbers: [10]f64) f64 {
            var sum: f64 = 0;
            for (numbers) |num| sum += num;
            return sum;
        }
    };

    const ExampleConsumer = struct {
        fn func(impl: anytype) void {
            comptime contract.validate(@TypeOf(impl), Processor);
        }
    };
    ExampleConsumer.func(NumberProcessor{});
}

// Test methods with function pointer parameters
test "methods with function pointer parameters" {
    const EventHandler = struct {
        fn on_event(self: *@This(), callback: *const fn (i32) void) void {
            _ = self;
            callback(42);
        }
        fn filter(data: []const i32, predicate: *const fn (i32) bool) []const i32 {
            _ = data;
            _ = predicate;
            return &[_]i32{};
        }
    };

    const SimpleEventHandler = struct {
        fn on_event(self: *@This(), callback: *const fn (i32) void) void {
            _ = self;
            callback(100);
        }
        fn filter(data: []const i32, predicate: *const fn (i32) bool) []const i32 {
            _ = data;
            _ = predicate;
            return &[_]i32{}; // Simplified implementation
        }
    };

    const ExampleConsumer = struct {
        fn func(impl: anytype) void {
            comptime contract.validate(@TypeOf(impl), EventHandler);
        }
    };
    ExampleConsumer.func(SimpleEventHandler{});
}

// Test interface with no methods (empty interface)
test "empty interface validation" {
    const EmptyInterface = struct {};

    const AnyStruct = struct {
        value: i32 = 42,
        fn some_method(self: *@This()) void {
            _ = self;
        }
    };

    const ExampleConsumer = struct {
        fn func(impl: anytype) void {
            comptime contract.validate(@TypeOf(impl), EmptyInterface);
        }
    };
    ExampleConsumer.func(AnyStruct{});
}

// Test with methods that have the same name but different signatures (should fail if strict)
test "method overloading scenarios" {
    const Overloaded = struct {
        fn process(self: *@This(), value: i32) void {
            _ = self;
            _ = value;
        }
    };

    const Implementation = struct {
        fn process(self: *@This(), value: i32) void {
            _ = self;
            _ = value;
        }
    };

    const ExampleConsumer = struct {
        fn func(impl: anytype) void {
            comptime contract.validate(@TypeOf(impl), Overloaded);
        }
    };
    ExampleConsumer.func(Implementation{});
}

// Test with union parameters
test "methods with union parameters" {
    const Value = union(enum) {
        int: i32,
        float: f64,
        string: []const u8,
    };

    const Serializer = struct {
        fn serialize(self: *@This(), value: Value) []const u8 {
            _ = self;
            _ = value;
            return "";
        }
        fn deserialize(data: []const u8) Value {
            _ = data;
            return Value{ .int = 0 };
        }
    };

    const JsonSerializer = struct {
        fn serialize(self: *@This(), value: Value) []const u8 {
            _ = self;
            _ = value;
            return "{}"; // Simplified
        }
        fn deserialize(data: []const u8) Value {
            _ = data;
            return Value{ .int = 42 };
        }
    };

    const ExampleConsumer = struct {
        fn func(impl: anytype) void {
            comptime contract.validate(@TypeOf(impl), Serializer);
        }
    };
    ExampleConsumer.func(JsonSerializer{});
}

// Test with enum parameters
test "methods with enum parameters" {
    const Color = enum {
        red,
        green,
        blue,
    };

    const Painter = struct {
        fn paint(self: *@This(), color: Color) void {
            _ = self;
            _ = color;
        }
        fn mix(c1: Color, c2: Color) Color {
            _ = c1;
            _ = c2;
            return Color.red;
        }
    };

    const DigitalPainter = struct {
        fn paint(self: *@This(), color: Color) void {
            _ = self;
            _ = color;
            // Painting logic
        }
        fn mix(c1: Color, c2: Color) Color {
            _ = c1;
            _ = c2;
            return Color.green; // Simplified mixing
        }
    };

    const ExampleConsumer = struct {
        fn func(impl: anytype) void {
            comptime contract.validate(@TypeOf(impl), Painter);
        }
    };
    ExampleConsumer.func(DigitalPainter{});
}

// Test with pointer to slice parameters
test "methods with complex pointer types" {
    const DataProcessor = struct {
        fn process_data(self: *@This(), data: *[]const u8) void {
            _ = self;
            _ = data;
        }
        fn modify_slice(slice: *[]i32) void {
            _ = slice;
        }
    };

    const SimpleDataProcessor = struct {
        fn process_data(self: *@This(), data: *[]const u8) void {
            _ = self;
            _ = data;
        }
        fn modify_slice(slice: *[]i32) void {
            _ = slice;
        }
    };

    const ExampleConsumer = struct {
        fn func(impl: anytype) void {
            comptime contract.validate(@TypeOf(impl), DataProcessor);
        }
    };
    ExampleConsumer.func(SimpleDataProcessor{});
}

// Test methods with variadic parameters (if supported)
test "methods with multiple return values via struct" {
    const Result = struct {
        success: bool,
        value: i32,
    };

    const Validator = struct {
        fn check(self: *@This(), input: []const u8) Result {
            _ = self;
            _ = input;
            return Result{ .success = true, .value = 0 };
        }
    };

    const NumberValidator = struct {
        fn check(self: *@This(), input: []const u8) Result {
            _ = self;
            const value = std.fmt.parseInt(i32, input, 10) catch return Result{ .success = false, .value = 0 };
            return Result{ .success = true, .value = value };
        }
    };

    const ExampleConsumer = struct {
        fn func(impl: anytype) void {
            comptime contract.validate(@TypeOf(impl), Validator);
        }
    };
    ExampleConsumer.func(NumberValidator{});
}

// Test with self as value (not pointer)
test "method using self by value" {
    const Copyable = struct {
        value: i32 = 0,
        fn get_value(self: @This()) i32 {
            return self.value;
        }
        fn double(self: @This()) @This() {
            return @This(){ .value = self.value * 2 };
        }
    };

    const SimpleCopyable = struct {
        value: i32 = 5,
        fn get_value(self: @This()) i32 {
            return self.value;
        }
        fn double(self: @This()) @This() {
            return @This(){ .value = self.value * 2 };
        }
    };

    const ExampleConsumer = struct {
        fn func(impl: anytype) void {
            comptime contract.validate(@TypeOf(impl), Copyable);
        }
    };
    ExampleConsumer.func(SimpleCopyable{});
}
