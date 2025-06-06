const std = @import("std");

fn getFunctionSignatureString(comptime FuncType: type) []const u8 {
    const func_info = @typeInfo(FuncType);

    if (func_info != .@"fn") {
        @compileError("Expected function type, got: " ++ @typeName(FuncType));
    }

    const fn_info = func_info.@"fn";

    // Start with calling convention if not default
    comptime var signature: []const u8 = "";
    if (fn_info.calling_convention != .Unspecified) {
        signature = signature ++ @tagName(fn_info.calling_convention) ++ " ";
    }

    signature = signature ++ "fn(";

    // Add parameters with more detail
    inline for (fn_info.params, 0..) |param, i| {
        if (i > 0) {
            signature = signature ++ ", ";
        }

        // Add parameter with potential modifiers
        if (param.is_generic) {
            signature = signature ++ "anytype";
        } else if (param.type) |param_type| {
            signature = signature ++ @typeName(param_type);
        } else {
            signature = signature ++ "?";
        }

        if (param.is_noalias) {
            signature = signature ++ " noalias";
        }
    }

    signature = signature ++ ")";

    // Add return type
    if (fn_info.return_type) |return_type| {
        if (return_type != void) {
            signature = signature ++ " " ++ @typeName(return_type);
        }
    } else {
        signature = signature ++ " anytype";
    }

    // Add error information
    if (fn_info.is_generic) {
        signature = signature ++ " (generic)";
    }

    return signature;
}

fn selfChildTypeMatch(comptime ParamAType: type, comptime A: type, comptime ParamBType: type, comptime B: type) bool {
    if (ParamAType == A and ParamBType == B) {
        return true;
    }
    const param_a_info = @typeInfo(ParamAType);
    const param_b_info = @typeInfo(ParamBType);

    const param_a_tag = std.meta.activeTag(param_a_info);
    const param_b_tag = std.meta.activeTag(param_b_info);
    if (param_a_tag != param_b_tag) {
        return false;
    }

    const param_a_tag_name = @tagName(param_a_tag);
    const param_a_tag_data = @field(param_a_info, param_a_tag_name);
    if (@TypeOf(param_a_tag_data) != void) {
        if (@hasField(@TypeOf(param_a_tag_data), "child")) {
            const param_a_child = param_a_tag_data.child;
            const param_b_child = @field(param_b_info, param_a_tag_name).child;
            return selfChildTypeMatch(param_a_child, A, param_b_child, B);
        }
        if (@hasField(@TypeOf(param_a_tag_data), "payload")) {
            const param_a_child = param_a_tag_data.payload;
            const param_b_child = @field(param_b_info, param_a_tag_name).payload;
            return selfChildTypeMatch(param_a_child, A, param_b_child, B);
        }
    } else {
        return true;
    }
    return false;
}

fn validateFunction(comptime Impl: type, comptime Inter: type, comptime fn_name: []const u8) void {
    const inter_fn_info = @typeInfo(@TypeOf(@field(Inter, fn_name))).@"fn";
    const impl_fn_info = @typeInfo(@TypeOf(@field(Impl, fn_name))).@"fn";

    if (impl_fn_info.return_type != inter_fn_info.return_type) {
        if (impl_fn_info.return_type == null or inter_fn_info.return_type == null) {
            @compileError("Return types don't match");
        }
        if (!selfChildTypeMatch(impl_fn_info.return_type.?, Impl, inter_fn_info.return_type.?, Inter)) {
            @compileError("Return types don't match");
        }
    }
    if (impl_fn_info.is_var_args != inter_fn_info.is_var_args) {
        @compileError("Function signature doesn't match");
    }

    for (inter_fn_info.params, 0..) |param, i| {
        const impl_param = impl_fn_info.params[i];
        const type_match = impl_param.type == param.type;
        const self_match = impl_param.is_generic or param.is_generic or impl_param.type == param.type or selfChildTypeMatch(impl_param.type.?, Impl, param.type.?, Inter);
        if (!type_match and !self_match) {
            @compileError("Function signature doesn't match");
        }
    }
}

fn validateDeclarations(comptime Impl: type, comptime Inter: type) void {
    const impl_info = @typeInfo(Impl);
    const inter_info = @typeInfo(Inter);
    const impl_tag = std.meta.activeTag(impl_info);
    const active_tag_name = @tagName(impl_tag);
    const active_tag_data = @field(impl_info, active_tag_name);

    if (@hasField(@TypeOf(active_tag_data), "decls")) {
        const inter_decls = @field(inter_info, active_tag_name).decls;
        for (inter_decls) |decl| {
            const fn_name = decl.name;
            const inter_fn = @field(Inter, fn_name);
            const inter_fn_type = @TypeOf(inter_fn);
            const inter_fn_type_info = @typeInfo(inter_fn_type);
            if (inter_fn_type_info != .@"fn") {
                continue;
            }
            if (!@hasDecl(Impl, fn_name)) {
                const error_message = std.fmt.comptimePrint("Missing implementation of {s}", .{getFunctionSignatureString(inter_fn_type)});
                @compileError(error_message);
            }
            validateFunction(Impl, Inter, fn_name);
        }
        return;
    }
}

pub fn validate(comptime Impl: type, comptime Inter: type) void {
    if (!@inComptime()) {
        @compileError("This function should only be called in comptime");
    }
    const impl_info = @typeInfo(Impl);
    const inter_info = @typeInfo(Inter);

    const impl_tag = std.meta.activeTag(impl_info);
    const inter_tag = std.meta.activeTag(inter_info);
    if (impl_tag != inter_tag) {
        @compileError("Implementation type doesn't match interface");
    }

    const active_tag_name = @tagName(impl_tag);
    const active_tag_data = @field(impl_info, active_tag_name);
    if (@TypeOf(active_tag_data) != void) {
        if (@hasField(@TypeOf(active_tag_data), "child")) {
            const impl_child = active_tag_data.child;
            const inter_child = @field(inter_info, active_tag_name).child;
            validate(impl_child, inter_child);
            return;
        }
        if (@hasField(@TypeOf(active_tag_data), "payload")) {
            const impl_child = active_tag_data.payload;
            const inter_child = @field(inter_info, active_tag_name).payload;
            validate(impl_child, inter_child);
            return;
        }
    }

    validateDeclarations(Impl, Inter);
}
