(* Adapted from: *)
(* - https://github.com/WebAssembly/spec/blob/main/interpreter/exec/ixx.ml, *)
(* - https://github.com/WebAssembly/spec/blob/main/interpreter/exec/fxx.ml, and *)
(* - https://github.com/WebAssembly/spec/blob/main/interpreter/exec *)

open Types

exception Num of num_type
exception TypeError of int * Num.t * num_type
exception DivideByZero
exception ConversionToInteger
exception IntegerOverflow

let of_arg f n v = try f v with Num t -> raise (TypeError (n, v, t))

module I32Op = struct
  type t = int32

  let to_value i : Num.t = I32 i

  let of_value n v : t =
    of_arg (fun v -> match v with I32 i -> i | _ -> raise (Num `I32Type)) n v

  let cmp_u x op y = op Int32.(add x min_int) Int32.(add y min_int)
  let lt_u x y = cmp_u x ( < ) y
  let le_u x y = cmp_u x ( <= ) y
  let gt_u x y = cmp_u x ( > ) y
  let ge_u x y = cmp_u x ( >= ) y

  (* let divrem_u n d = *)
  (*   if d = 0l then raise DivideByZero *)
  (*   else *)
  (*     let t = Int32.shift_right d (bitwidth - 1) in *)
  (*     let n' = Int32.(logand n (lognot t)) in *)
  (*     let q = Int32.(shift_left (div (shift_right_logical n' 1) d) 1) in *)
  (*     let r = Int32.(sub n (mul q d)) in *)
  (*     if cmp_u r ( < ) d then (q, r) else (Int32.add q 1l, Int32.sub r d) *)

  (* let div_u x y = *)
  (*   let q, _ = divrem_u x y in *)
  (*   q *)

  let shift f x y = f x Int32.(to_int (logand y 31l))
  let shl x y = shift Int32.shift_left x y
  let shr_s x y = shift Int32.shift_right x y
  let shr_u x y = shift Int32.shift_right_logical x y

  let extend_s n x =
    let shift = Int32.(to_int @@ sub 32l n) in
    Int32.(shift_right (shift_left x shift) shift)

  let unop (op : I32.unop) : Num.t -> Num.t =
    let f = match op with Clz -> assert false | Not -> Int32.lognot in
    fun v -> to_value (f (of_value 1 v))

  let binop (op : I32.binop) : Num.t -> Num.t -> Num.t =
    let f =
      match op with
      | Add -> Int32.add
      | Sub -> Int32.sub
      | Mul -> Int32.mul
      | DivS -> Int32.div
      | DivU -> Int32.unsigned_div
      | RemS -> Int32.rem
      | RemU -> Int32.unsigned_rem
      | And -> Int32.logand
      | Or -> Int32.logor
      | Xor -> Int32.logxor
      | Shl -> shl
      | ShrU -> shr_s
      | ShrS -> shr_u
      | ExtendS -> extend_s
      | ExtendU -> fun _n x -> x
      | Rotl | Rotr -> assert false
    in
    fun v1 v2 -> to_value (f (of_value 1 v1) (of_value 2 v2))

  let relop (op : I32.relop) : Num.t -> Num.t -> bool =
    let f =
      match op with
      | Eq -> ( = )
      | Ne -> ( <> )
      | LtS -> ( < )
      | LtU -> lt_u
      | LeS -> ( <= )
      | LeU -> le_u
      | GtS -> ( > )
      | GtU -> gt_u
      | GeS -> ( >= )
      | GeU -> ge_u
    in
    fun v1 v2 -> f (of_value 1 v1) (of_value 2 v2)
end

module I64Op = struct
  let to_value i : Num.t = I64 i

  let of_value n v : int64 =
    of_arg (fun v -> match v with I64 i -> i | _ -> raise (Num `I64Type)) n v

  let cmp_u x op y = op Int64.(add x min_int) Int64.(add y min_int)
  let lt_u x y = cmp_u x ( < ) y
  let le_u x y = cmp_u x ( <= ) y
  let gt_u x y = cmp_u x ( > ) y
  let ge_u x y = cmp_u x ( >= ) y

  (* let divrem_u n d = *)
  (*   if d = 0L then raise DivideByZero *)
  (*   else *)
  (*     let t = Int64.shift_right d 63 in *)
  (*     let n' = Int64.(logand n @@ lognot t) in *)
  (*     let q = Int64.(shift_left (div (shift_right_logical n' 1) d) 1) in *)
  (*     let r = Int64.(sub n (mul q d)) in *)
  (*     if cmp_u r ( < ) d then (q, r) else Int64.(add q 1L, sub r d) *)

  (* let div_u x y = *)
  (*   let q, _ = divrem_u x y in *)
  (*   q *)

  let shift f x y = f x Int64.(to_int (logand y 63L))
  let shl x y = shift Int64.shift_left x y
  let shr_s x y = shift Int64.shift_right x y
  let shr_u x y = shift Int64.shift_right_logical x y

  let extend_s n x =
    let shift = Int64.(to_int @@ sub 64L n) in
    Int64.(shift_right (shift_left x shift) shift)

  let unop (op : I64.unop) : Num.t -> Num.t =
    let f = match op with Clz -> assert false | Not -> Int64.lognot in
    fun v -> to_value (f (of_value 1 v))

  let binop (op : I64.binop) : Num.t -> Num.t -> Num.t =
    let f =
      match op with
      | Add -> Int64.add
      | Sub -> Int64.sub
      | Mul -> Int64.mul
      | DivS -> Int64.div
      | DivU -> Int64.unsigned_div
      | RemS -> Int64.rem
      | RemU -> Int64.unsigned_rem
      | And -> Int64.logand
      | Or -> Int64.logor
      | Xor -> Int64.logxor
      | Shl -> shl
      | ShrU -> shr_s
      | ShrS -> shr_u
      | ExtendS -> extend_s
      | ExtendU -> fun _n x -> x
      | Rotl | Rotr -> assert false
    in
    fun v1 v2 -> to_value (f (of_value 1 v1) (of_value 2 v2))

  let relop (op : I64.relop) : Num.t -> Num.t -> bool =
    let f =
      match op with
      | Eq -> ( = )
      | Ne -> ( <> )
      | LtS -> ( < )
      | LtU -> lt_u
      | LeS -> ( <= )
      | LeU -> le_u
      | GtS -> ( > )
      | GtU -> gt_u
      | GeS -> ( >= )
      | GeU -> ge_u
    in
    fun v1 v2 -> f (of_value 1 v1) (of_value 2 v2)
end

module F32Op = struct
  let to_value f : Num.t = F32 f

  let of_value =
    of_arg (fun v -> match v with F32 f -> f | _ -> raise (Num `F32Type))

  let of_float = Int32.bits_of_float
  let to_float = Int32.float_of_bits

  let unop (op : F32.unop) =
    let f =
      match op with
      | Neg -> Float.neg
      | Abs -> Float.abs
      | Sqrt -> Float.sqrt
      | Nearest -> Float.round
      | Ceil -> Float.ceil
      | Floor -> Float.floor
      | IsNan -> assert false
    in
    fun v -> to_value (of_float (f (to_float (of_value 1 v))))

  let binop (op : F32.binop) =
    let f =
      match op with
      | Add -> Float.add
      | Sub -> Float.sub
      | Mul -> Float.mul
      | Div -> Float.div
      | Rem -> Float.rem
      | Min -> Float.min
      | Max -> Float.max
    in
    fun v1 v2 ->
      to_value
        (of_float (f (to_float (of_value 1 v1)) (to_float (of_value 2 v2))))

  let relop (op : F32.relop) =
    let f =
      match op with
      | Eq -> ( = )
      | Ne -> ( <> )
      | Lt -> ( < )
      | Le -> ( <= )
      | Gt -> ( > )
      | Ge -> ( >= )
    in
    fun v1 v2 -> f (to_float (of_value 1 v1)) (to_float (of_value 2 v2))
end

module F64Op = struct
  let to_value f : Num.t = F64 f

  let of_value =
    of_arg (fun v -> match v with F64 f -> f | _ -> raise (Num `F64Type))

  let of_float = Int64.bits_of_float
  let to_float = Int64.float_of_bits

  let unop (op : F64.unop) =
    let f =
      match op with
      | Neg -> Float.neg
      | Abs -> Float.abs
      | Sqrt -> Float.sqrt
      | Nearest -> Float.round
      | Ceil -> Float.ceil
      | Floor -> Float.floor
      | IsNan -> assert false
    in
    fun v -> to_value (of_float (f (to_float (of_value 1 v))))

  let binop (op : F64.binop) =
    let f =
      match op with
      | Add -> Float.add
      | Sub -> Float.sub
      | Mul -> Float.mul
      | Div -> Float.mul
      | Rem -> Float.rem
      | Min -> Float.min
      | Max -> Float.max
    in
    fun v1 v2 ->
      to_value
        (of_float (f (to_float (of_value 1 v1)) (to_float (of_value 2 v2))))

  let relop (op : F64.relop) =
    let f =
      match op with
      | Eq -> ( = )
      | Ne -> ( <> )
      | Lt -> ( < )
      | Le -> ( <= )
      | Gt -> ( > )
      | Ge -> ( >= )
    in
    fun v1 v2 -> f (to_float (of_value 1 v1)) (to_float (of_value 2 v2))
end

module I32CvtOp = struct
  let trunc_f32_s (x : int32) =
    if x <> x then raise ConversionToInteger
    else
      let xf = F32Op.to_float x in
      if xf >= -.Int32.(to_float min_int) || xf < Int32.(to_float min_int) then
        raise IntegerOverflow
      else Int32.of_float xf

  let trunc_f32_u (x : int32) =
    if x <> x then raise ConversionToInteger
    else
      let xf = F32Op.to_float x in
      if xf >= -.Int32.(to_float min_int) *. 2.0 || xf <= -1.0 then
        raise IntegerOverflow
      else Int32.of_float xf

  let trunc_f64_s (x : int64) =
    if x <> x then raise ConversionToInteger
    else
      let xf = F64Op.to_float x in
      if xf >= -.Int64.(to_float min_int) || xf < Int64.(to_float min_int) then
        raise IntegerOverflow
      else Int32.of_float xf

  let trunc_f64_u (x : int64) =
    if x <> x then raise ConversionToInteger
    else
      let xf = F64Op.to_float x in
      if xf >= -.Int64.(to_float min_int) *. 2.0 || xf <= -1.0 then
        raise IntegerOverflow
      else Int32.of_float xf

  let cvtop op v : Num.t =
    let open I32 in
    match op with
    | WrapI64 -> I32 (Int64.to_int32 (I64Op.of_value 1 v))
    | TruncSF32 -> I32 (trunc_f32_s (F32Op.of_value 1 v))
    | TruncUF32 -> I32 (trunc_f32_u (F32Op.of_value 1 v))
    | TruncSF64 -> I32 (trunc_f64_s (F64Op.of_value 1 v))
    | TruncUF64 -> I32 (trunc_f64_u (F64Op.of_value 1 v))
    | ReinterpretFloat -> I32 (F32Op.of_value 1 v)
    | ExtendSI32 -> raise (TypeError (1, v, `I32Type))
    | ExtendUI32 -> raise (TypeError (1, v, `I32Type))
    | OfBool -> v (* already a num here *)
    | ToBool -> assert false
end

module I64CvtOp = struct
  let extend_i32_u (x : int32) =
    Int64.(logand (of_int32 x) 0x0000_0000_ffff_ffffL)

  let trunc_f32_s (x : int32) =
    if x <> x then raise ConversionToInteger
    else
      let xf = F32Op.to_float x in
      if xf >= -.Int64.(to_float min_int) || xf < Int64.(to_float min_int) then
        raise IntegerOverflow
      else Int64.of_float xf

  let trunc_f32_u x =
    if x <> x then raise ConversionToInteger
    else
      let xf = F32Op.to_float x in
      if xf >= -.Int64.(to_float min_int) *. 2.0 || xf <= -1.0 then
        raise IntegerOverflow
      else if xf >= -.Int64.(to_float min_int) then
        Int64.(logxor (of_float (xf -. 0x1p63)) min_int)
      else Int64.of_float xf

  let trunc_f64_s (x : int64) =
    if x <> x then raise ConversionToInteger
    else
      let xf = F64Op.to_float x in
      if xf >= -.Int64.(to_float min_int) || xf < Int64.(to_float min_int) then
        raise IntegerOverflow
      else Int64.of_float xf

  let trunc_f64_u x =
    if x <> x then raise ConversionToInteger
    else
      let xf = F64Op.to_float x in
      if xf >= -.Int64.(to_float min_int) *. 2.0 || xf <= -1.0 then
        raise IntegerOverflow
      else if xf >= -.Int64.(to_float min_int) then
        Int64.(logxor (of_float (xf -. 0x1p63)) min_int)
      else Int64.of_float xf

  let cvtop (op : I64.cvtop) v : Num.t =
    match op with
    | ExtendSI32 -> I64 (Int64.of_int32 (I32Op.of_value 1 v))
    | ExtendUI32 -> I64 (extend_i32_u (I32Op.of_value 1 v))
    | TruncSF32 -> I64 (trunc_f32_s (F32Op.of_value 1 v))
    | TruncUF32 -> I64 (trunc_f32_u (F32Op.of_value 1 v))
    | TruncSF64 -> I64 (trunc_f64_s (F64Op.of_value 1 v))
    | TruncUF64 -> I64 (trunc_f64_u (F64Op.of_value 1 v))
    | ReinterpretFloat -> I64 (F64Op.of_value 1 v)
    | WrapI64 -> raise (TypeError (1, v, `I64Type))
    | ToBool | OfBool -> assert false (* FIXME: don't like these here *)
end

module F32CvtOp = struct
  let demote_f64 x =
    let xf = F64Op.to_float x in
    if xf = xf then F32Op.of_float xf
    else
      let nan64bits = x in
      let sign_field =
        Int64.(shift_left (shift_right_logical nan64bits 63) 31)
      in
      let significand_field =
        Int64.(shift_right_logical (shift_left nan64bits 12) 41)
      in
      let fields = Int64.logor sign_field significand_field in
      Int32.logor 0x7fc0_0000l (Int64.to_int32 fields)

  let convert_i32_s x = F32Op.of_float (Int32.to_float x)

  let convert_i32_u x =
    F32Op.of_float
      Int32.(
        if x >= 0l then to_float x
        else to_float (logor (shift_right_logical x 1) (logand x 1l)) *. 2.0 )

  let convert_i64_s x =
    F32Op.of_float
      Int64.(
        if abs x < 0x10_0000_0000_0000L then to_float x
        else
          let r = if logand x 0xfffL = 0L then 0L else 1L in
          to_float (logor (shift_right x 12) r) *. 0x1p12 )

  let convert_i64_u x =
    F32Op.of_float
      Int64.(
        if I64Op.lt_u x 0x10_0000_0000_0000L then to_float x
        else
          let r = if logand x 0xfffL = 0L then 0L else 1L in
          to_float (logor (shift_right_logical x 12) r) *. 0x1p12 )

  let cvtop (op : F32.cvtop) v : Num.t =
    match op with
    | DemoteF64 -> F32 (demote_f64 (F64Op.of_value 1 v))
    | ConvertSI32 -> F32 (convert_i32_s (I32Op.of_value 1 v))
    | ConvertUI32 -> F32 (convert_i32_u (I32Op.of_value 1 v))
    | ConvertSI64 -> F32 (convert_i64_s (I64Op.of_value 1 v))
    | ConvertUI64 -> F32 (convert_i64_u (I64Op.of_value 1 v))
    | ReinterpretInt -> F32 (I32Op.of_value 1 v)
    | PromoteF32 -> raise (TypeError (1, v, `F32Type))
    | ToString | OfString -> assert false
end

module F64CvtOp = struct
  let promote_f32 x =
    let xf = F32Op.to_float x in
    if xf = xf then F64Op.of_float xf
    else
      let nan32bits = I64CvtOp.extend_i32_u x in
      let sign_field =
        Int64.(shift_left (shift_right_logical nan32bits 31) 63)
      in
      let significand_field =
        Int64.(shift_right_logical (shift_left nan32bits 41) 12)
      in
      let fields = Int64.logor sign_field significand_field in
      Int64.logor 0x7ff8_0000_0000_0000L fields

  let convert_i32_s x = F64Op.of_float (Int32.to_float x)

  (*
   * Unlike the other convert_u functions, the high half of the i32 range is
   * within the range where f32 can represent odd numbers, so we can't do the
   * shift. Instead, we can use int64 signed arithmetic.
   *)
  let convert_i32_u x =
    F64Op.of_float Int64.(to_float (logand (of_int32 x) 0x0000_0000_ffff_ffffL))

  let convert_i64_s x = F64Op.of_float (Int64.to_float x)

  (*
   * Values in the low half of the int64 range can be converted with a signed
   * conversion. The high half is beyond the range where f64 can represent odd
   * numbers, so we can shift the value right, adjust the least significant
   * bit to round correctly, do a conversion, and then scale it back up.
   *)
  let convert_i64_u (x : int64) =
    F64Op.of_float
      Int64.(
        if x >= 0L then to_float x
        else to_float (logor (shift_right_logical x 1) (logand x 1L)) *. 2.0 )

  let cvtop (op : F64.cvtop) v : Num.t =
    match op with
    | PromoteF32 -> F64 (promote_f32 (F32Op.of_value 1 v))
    | ConvertSI32 -> F64 (convert_i32_s (I32Op.of_value 1 v))
    | ConvertUI32 -> F64 (convert_i32_u (I32Op.of_value 1 v))
    | ConvertSI64 -> F64 (convert_i64_s (I64Op.of_value 1 v))
    | ConvertUI64 -> F64 (convert_i64_u (I64Op.of_value 1 v))
    | ReinterpretInt -> F64 (I64Op.of_value 1 v)
    | DemoteF64 -> raise (TypeError (1, v, `F64Type))
    | ToString | OfString -> assert false
end

(* Dispatch *)

let op i32 i64 f32 f64 = function
  | Int _ -> failwith "eval_numeric: Integer evaluations not supported"
  | Real _ -> failwith "eval_numeric: Float evaluations not supported"
  | I32 x -> i32 x
  | I64 x -> i64 x
  | F32 x -> f32 x
  | F64 x -> f64 x
  | Str _ | Bool _ -> assert false

let eval_unop = op I32Op.unop I64Op.unop F32Op.unop F64Op.unop
let eval_binop = op I32Op.binop I64Op.binop F32Op.binop F64Op.binop
let eval_relop = op I32Op.relop I64Op.relop F32Op.relop F64Op.relop
let eval_cvtop = op I32CvtOp.cvtop I64CvtOp.cvtop F32CvtOp.cvtop F64CvtOp.cvtop