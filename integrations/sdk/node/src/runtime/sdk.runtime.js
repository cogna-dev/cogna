function _M0DTPB4Json4Null() {}
_M0DTPB4Json4Null.prototype.$tag = 0;
const _M0DTPB4Json4Null__ = new _M0DTPB4Json4Null();
function _M0DTPB4Json4True() {}
_M0DTPB4Json4True.prototype.$tag = 1;
const _M0DTPB4Json4True__ = new _M0DTPB4Json4True();
function _M0DTPB4Json5False() {}
_M0DTPB4Json5False.prototype.$tag = 2;
const _M0DTPB4Json5False__ = new _M0DTPB4Json5False();
function _M0DTPB4Json6Number(param0, param1) {
  this._0 = param0;
  this._1 = param1;
}
_M0DTPB4Json6Number.prototype.$tag = 3;
function _M0DTPB4Json6String(param0) {
  this._0 = param0;
}
_M0DTPB4Json6String.prototype.$tag = 4;
function _M0DTPB4Json5Array(param0) {
  this._0 = param0;
}
_M0DTPB4Json5Array.prototype.$tag = 5;
function _M0DTPB4Json6Object(param0) {
  this._0 = param0;
}
_M0DTPB4Json6Object.prototype.$tag = 6;
const $reinterpret_view = new DataView(new ArrayBuffer(8));
function $i64_reinterpret_f64(a) {
  $reinterpret_view.setBigUint64(0, BigInt.asUintN(64, a), false);
  return $reinterpret_view.getFloat64(0, false);
}
function _M0TPC28internal7strconv9FloatInfo(param0, param1, param2) {
  this.mantissa_bits = param0;
  this.exponent_bits = param1;
  this.bias = param2;
}
class $PanicError extends Error {}
function $panic() {
  throw new $PanicError();
}
function _M0TPB13StringBuilder(param0) {
  this.val = param0;
}
function _M0TPC16string10StringView(param0, param1, param2) {
  this.str = param0;
  this.start = param1;
  this.end = param2;
}
function $compare_int(a, b) {
  return (a >= b) - (a <= b);
}
const _M0FPB12random__seed = () => {
  if (globalThis.crypto?.getRandomValues) {
    const array = new Uint32Array(1);
    globalThis.crypto.getRandomValues(array);
    return array[0] | 0; // Convert to signed 32
  } else {
    return Math.floor(Math.random() * 0x100000000) | 0; // Fallback to Math.random
  }
};
function _M0TPB6Hasher(param0) {
  this.acc = param0;
}
const _M0FPB19int__to__string__js = (x, radix) => {
  return x.toString(radix);
};
function $bound_check(arr, index) {
  if (index < 0 || index >= arr.length) throw new Error("Index out of bounds");
}
function $unsafe_bytes_sub_string(bytes, byte_offset, byte_length) {
  const end_offset = byte_offset + byte_length;
  let buf = '';
  while (byte_offset < end_offset) {
    buf += String.fromCharCode(bytes[byte_offset] | (bytes[byte_offset + 1] << 8));
    byte_offset += 2;
  }
  return buf;
}
function $makebytes(a, b) {
  const arr = new Uint8Array(a);
  if (b !== 0) {
    arr.fill(b);
  }
  return arr;
}
function _M0TPB8MutLocalGiE(param0) {
  this.val = param0;
}
function $make_array_len_and_init(a, b) {
  const arr = new Array(a);
  arr.fill(b);
  return arr;
}
const _M0MPB7JSArray4push = (arr, val) => { arr.push(val); };
function _M0TPB8MutLocalGORPC16string10StringViewE(param0) {
  this.val = param0;
}
function _M0TPB3MapGsRPB4JsonE(param0, param1, param2, param3, param4, param5, param6) {
  this.entries = param0;
  this.size = param1;
  this.capacity = param2;
  this.capacity_mask = param3;
  this.grow_at = param4;
  this.head = param5;
  this.tail = param6;
}
function _M0TPB3MapGsbE(param0, param1, param2, param3, param4, param5, param6) {
  this.entries = param0;
  this.size = param1;
  this.capacity = param2;
  this.capacity_mask = param3;
  this.grow_at = param4;
  this.head = param5;
  this.tail = param6;
}
function _M0TPB5EntryGsbE(param0, param1, param2, param3, param4, param5) {
  this.prev = param0;
  this.next = param1;
  this.psl = param2;
  this.hash = param3;
  this.key = param4;
  this.value = param5;
}
function _M0TPB5EntryGsRPB4JsonE(param0, param1, param2, param3, param4, param5) {
  this.prev = param0;
  this.next = param1;
  this.psl = param2;
  this.hash = param3;
  this.key = param4;
  this.value = param5;
}
function _M0TPB5EntryGssE(param0, param1, param2, param3, param4, param5) {
  this.prev = param0;
  this.next = param1;
  this.psl = param2;
  this.hash = param3;
  this.key = param4;
  this.value = param5;
}
function _M0TPB8MutLocalGORPB5EntryGsRPB4JsonEE(param0) {
  this.val = param0;
}
function _M0TPC15bytes9BytesView(param0, param1, param2) {
  this.bytes = param0;
  this.start = param1;
  this.end = param2;
}
function _M0DTPC16result6ResultGUiRPC16string10StringViewbERPB7FailureE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGUiRPC16string10StringViewbERPB7FailureE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGUiRPC16string10StringViewbERPB7FailureE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGUiRPC16string10StringViewbERPB7FailureE2Ok.prototype.$tag = 1;
function _M0DTPC15error5Error60moonbitlang_2fcore_2fencoding_2futf8_2eMalformed_2eMalformed(param0) {
  this._0 = param0;
}
_M0DTPC15error5Error60moonbitlang_2fcore_2fencoding_2futf8_2eMalformed_2eMalformed.prototype.$tag = 10;
function _M0DTPC15error5Error52moonbitlang_2fcore_2fjson_2eParseError_2eInvalidChar(param0, param1) {
  this._0 = param0;
  this._1 = param1;
}
_M0DTPC15error5Error52moonbitlang_2fcore_2fjson_2eParseError_2eInvalidChar.prototype.$tag = 9;
function _M0DTPC15error5Error51moonbitlang_2fcore_2fjson_2eParseError_2eInvalidEof() {}
_M0DTPC15error5Error51moonbitlang_2fcore_2fjson_2eParseError_2eInvalidEof.prototype.$tag = 8;
const _M0DTPC15error5Error51moonbitlang_2fcore_2fjson_2eParseError_2eInvalidEof__ = new _M0DTPC15error5Error51moonbitlang_2fcore_2fjson_2eParseError_2eInvalidEof();
function _M0DTPC15error5Error54moonbitlang_2fcore_2fjson_2eParseError_2eInvalidNumber(param0, param1) {
  this._0 = param0;
  this._1 = param1;
}
_M0DTPC15error5Error54moonbitlang_2fcore_2fjson_2eParseError_2eInvalidNumber.prototype.$tag = 7;
function _M0DTPC15error5Error59moonbitlang_2fcore_2fjson_2eParseError_2eInvalidIdentEscape(param0) {
  this._0 = param0;
}
_M0DTPC15error5Error59moonbitlang_2fcore_2fjson_2eParseError_2eInvalidIdentEscape.prototype.$tag = 6;
function _M0DTPC15error5Error59moonbitlang_2fcore_2fjson_2eParseError_2eDepthLimitExceeded() {}
_M0DTPC15error5Error59moonbitlang_2fcore_2fjson_2eParseError_2eDepthLimitExceeded.prototype.$tag = 5;
const _M0DTPC15error5Error59moonbitlang_2fcore_2fjson_2eParseError_2eDepthLimitExceeded__ = new _M0DTPC15error5Error59moonbitlang_2fcore_2fjson_2eParseError_2eDepthLimitExceeded();
function _M0DTPC15error5Error48moonbitlang_2fcore_2fbuiltin_2eFailure_2eFailure(param0) {
  this._0 = param0;
}
_M0DTPC15error5Error48moonbitlang_2fcore_2fbuiltin_2eFailure_2eFailure.prototype.$tag = 4;
function _M0DTPC15error5Error40moonbitlang_2fx_2ffs_2eIOError_2eIOError(param0) {
  this._0 = param0;
}
_M0DTPC15error5Error40moonbitlang_2fx_2ffs_2eIOError_2eIOError.prototype.$tag = 3;
function _M0DTPC15error5Error65cogna_2ddev_2fcogna_2fcore_2fconfig_2eConfigError_2eFileReadError(param0, param1) {
  this._0 = param0;
  this._1 = param1;
}
_M0DTPC15error5Error65cogna_2ddev_2fcogna_2fcore_2fconfig_2eConfigError_2eFileReadError.prototype.$tag = 2;
function _M0DTPC15error5Error62cogna_2ddev_2fcogna_2fcore_2fconfig_2eConfigError_2eParseError(param0, param1) {
  this._0 = param0;
  this._1 = param1;
}
_M0DTPC15error5Error62cogna_2ddev_2fcogna_2fcore_2fconfig_2eConfigError_2eParseError.prototype.$tag = 1;
function _M0DTPC15error5Error67cogna_2ddev_2fcogna_2fcore_2fconfig_2eConfigError_2eValidationError(param0, param1) {
  this._0 = param0;
  this._1 = param1;
}
_M0DTPC15error5Error67cogna_2ddev_2fcogna_2fcore_2fconfig_2eConfigError_2eValidationError.prototype.$tag = 0;
function _M0DTPC16result6ResultGUiRPC16string10StringViewbERPC15error5ErrorE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGUiRPC16string10StringViewbERPC15error5ErrorE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGUiRPC16string10StringViewbERPC15error5ErrorE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGUiRPC16string10StringViewbERPC15error5ErrorE2Ok.prototype.$tag = 1;
function _M0DTPC16result6ResultGuRPB7FailureE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGuRPB7FailureE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGuRPB7FailureE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGuRPB7FailureE2Ok.prototype.$tag = 1;
function _M0DTPC16result6ResultGiRPB7FailureE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGiRPB7FailureE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGiRPB7FailureE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGiRPB7FailureE2Ok.prototype.$tag = 1;
function _M0DTPC16result6ResultGlRPB7FailureE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGlRPB7FailureE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGlRPB7FailureE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGlRPB7FailureE2Ok.prototype.$tag = 1;
function _M0DTPC16result6ResultGdRPB7FailureE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGdRPB7FailureE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGdRPB7FailureE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGdRPB7FailureE2Ok.prototype.$tag = 1;
function _M0DTPC16result6ResultGORPC28internal7strconv6NumberRPB7FailureE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGORPC28internal7strconv6NumberRPB7FailureE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGORPC28internal7strconv6NumberRPB7FailureE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGORPC28internal7strconv6NumberRPB7FailureE2Ok.prototype.$tag = 1;
function _M0DTPC16result6ResultGORPC28internal7strconv6NumberRPC15error5ErrorE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGORPC28internal7strconv6NumberRPC15error5ErrorE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGORPC28internal7strconv6NumberRPC15error5ErrorE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGORPC28internal7strconv6NumberRPC15error5ErrorE2Ok.prototype.$tag = 1;
function _M0TPC28internal7strconv6Number(param0, param1, param2, param3) {
  this.exponent = param0;
  this.mantissa = param1;
  this.negative = param2;
  this.many_digits = param3;
}
function _M0DTPC16result6ResultGdRPC15error5ErrorE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGdRPC15error5ErrorE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGdRPC15error5ErrorE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGdRPC15error5ErrorE2Ok.prototype.$tag = 1;
function $i64_clz(a) {
  a = BigInt.asUintN(64, a);
  if (a === 0n) return 64;
  const hi = Number(a >> 32n);
  if (hi !== 0) {
    return Math.clz32(hi);
  }
  return 32 + Math.clz32(Number(a & 0xffffffffn));
}
function _M0DTPC16result6ResultGlRPC15error5ErrorE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGlRPC15error5ErrorE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGlRPC15error5ErrorE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGlRPC15error5ErrorE2Ok.prototype.$tag = 1;
function _M0DTPC16result6ResultGiRPC15error5ErrorE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGiRPC15error5ErrorE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGiRPC15error5ErrorE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGiRPC15error5ErrorE2Ok.prototype.$tag = 1;
function _M0TPC28internal7strconv7Decimal(param0, param1, param2, param3, param4) {
  this.digits = param0;
  this.digits_num = param1;
  this.decimal_point = param2;
  this.negative = param3;
  this.truncated = param4;
}
function _M0DTPC16result6ResultGRPC28internal7strconv7DecimalRPC15error5ErrorE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRPC28internal7strconv7DecimalRPC15error5ErrorE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGRPC28internal7strconv7DecimalRPC15error5ErrorE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRPC28internal7strconv7DecimalRPC15error5ErrorE2Ok.prototype.$tag = 1;
function $f64_convert_i64_u(a) {
  return Number(a);
}
function _M0DTPC16option6OptionGdE4None() {}
_M0DTPC16option6OptionGdE4None.prototype.$tag = 0;
const _M0DTPC16option6OptionGdE4None__ = new _M0DTPC16option6OptionGdE4None();
function _M0DTPC16option6OptionGdE4Some(param0) {
  this._0 = param0;
}
_M0DTPC16option6OptionGdE4Some.prototype.$tag = 1;
function _M0TPC14json8Position(param0, param1) {
  this.line = param0;
  this.column = param1;
}
function _M0DTPC16result6ResultGRPB4JsonRPC14json10ParseErrorE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRPB4JsonRPC14json10ParseErrorE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGRPB4JsonRPC14json10ParseErrorE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRPB4JsonRPC14json10ParseErrorE2Ok.prototype.$tag = 1;
function _M0DTPC16result6ResultGuRPC14json10ParseErrorE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGuRPC14json10ParseErrorE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGuRPC14json10ParseErrorE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGuRPC14json10ParseErrorE2Ok.prototype.$tag = 1;
function _M0TPC14json12ParseContext(param0, param1, param2, param3) {
  this.offset = param0;
  this.input = param1;
  this.end_offset = param2;
  this.remaining_available_depth = param3;
}
function $f64_convert_i64(a) {
  return Number(BigInt.asIntN(64, a));
}
function _M0DTPC16result6ResultGUdORPC16string10StringViewERPC14json10ParseErrorE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGUdORPC16string10StringViewERPC14json10ParseErrorE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGUdORPC16string10StringViewERPC14json10ParseErrorE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGUdORPC16string10StringViewERPC14json10ParseErrorE2Ok.prototype.$tag = 1;
function _M0DTPC16result6ResultGiRPC14json10ParseErrorE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGiRPC14json10ParseErrorE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGiRPC14json10ParseErrorE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGiRPC14json10ParseErrorE2Ok.prototype.$tag = 1;
function _M0DTPC16result6ResultGsRPC14json10ParseErrorE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGsRPC14json10ParseErrorE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGsRPC14json10ParseErrorE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGsRPC14json10ParseErrorE2Ok.prototype.$tag = 1;
function _M0DTPC16result6ResultGRPC14json5TokenRPC14json10ParseErrorE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRPC14json5TokenRPC14json10ParseErrorE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGRPC14json5TokenRPC14json10ParseErrorE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRPC14json5TokenRPC14json10ParseErrorE2Ok.prototype.$tag = 1;
function _M0DTPC14json5Token4Null() {}
_M0DTPC14json5Token4Null.prototype.$tag = 0;
const _M0DTPC14json5Token4Null__ = new _M0DTPC14json5Token4Null();
function _M0DTPC14json5Token4True() {}
_M0DTPC14json5Token4True.prototype.$tag = 1;
const _M0DTPC14json5Token4True__ = new _M0DTPC14json5Token4True();
function _M0DTPC14json5Token5False() {}
_M0DTPC14json5Token5False.prototype.$tag = 2;
const _M0DTPC14json5Token5False__ = new _M0DTPC14json5Token5False();
function _M0DTPC14json5Token6Number(param0, param1) {
  this._0 = param0;
  this._1 = param1;
}
_M0DTPC14json5Token6Number.prototype.$tag = 3;
function _M0DTPC14json5Token6String(param0) {
  this._0 = param0;
}
_M0DTPC14json5Token6String.prototype.$tag = 4;
function _M0DTPC14json5Token6LBrace() {}
_M0DTPC14json5Token6LBrace.prototype.$tag = 5;
const _M0DTPC14json5Token6LBrace__ = new _M0DTPC14json5Token6LBrace();
function _M0DTPC14json5Token6RBrace() {}
_M0DTPC14json5Token6RBrace.prototype.$tag = 6;
const _M0DTPC14json5Token6RBrace__ = new _M0DTPC14json5Token6RBrace();
function _M0DTPC14json5Token8LBracket() {}
_M0DTPC14json5Token8LBracket.prototype.$tag = 7;
const _M0DTPC14json5Token8LBracket__ = new _M0DTPC14json5Token8LBracket();
function _M0DTPC14json5Token8RBracket() {}
_M0DTPC14json5Token8RBracket.prototype.$tag = 8;
const _M0DTPC14json5Token8RBracket__ = new _M0DTPC14json5Token8RBracket();
function _M0DTPC14json5Token5Comma() {}
_M0DTPC14json5Token5Comma.prototype.$tag = 9;
const _M0DTPC14json5Token5Comma__ = new _M0DTPC14json5Token5Comma();
function _M0TPC13ref3RefGOsE(param0) {
  this.val = param0;
}
function _M0DTPC16result6ResultGsRPC28encoding4utf89MalformedE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGsRPC28encoding4utf89MalformedE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGsRPC28encoding4utf89MalformedE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGsRPC28encoding4utf89MalformedE2Ok.prototype.$tag = 1;
function _M0TPB9ArrayViewGcE(param0, param1, param2) {
  this.buf = param0;
  this.start = param1;
  this.end = param2;
}
const _M0FP311moonbitlang1x2fs15read__file__ffi = function(path) {
   var fs = require('fs');
   try {
     const content = fs.readFileSync(path);
     globalThis.fileContent = content;
     return 0;
   } catch (error) {
     globalThis.errorMessage = error.message;
     return -1;
   }
 };
const _M0FP311moonbitlang1x2fs23get__file__content__ffi = function() {
   return globalThis.fileContent;
 };
const _M0FP311moonbitlang1x2fs24get__error__message__ffi = function() {
   return globalThis.errorMessage || '';
 };
function _M0DTPC16result6ResultGzRP311moonbitlang1x2fs7IOErrorE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGzRP311moonbitlang1x2fs7IOErrorE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGzRP311moonbitlang1x2fs7IOErrorE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGzRP311moonbitlang1x2fs7IOErrorE2Ok.prototype.$tag = 1;
function _M0DTPC16result6ResultGsRP311moonbitlang1x2fs7IOErrorE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGsRP311moonbitlang1x2fs7IOErrorE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGsRP311moonbitlang1x2fs7IOErrorE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGsRP311moonbitlang1x2fs7IOErrorE2Ok.prototype.$tag = 1;
const _M0FP311moonbitlang1x2fs17path__exists__ffi = function(path) {
  var fs = require('fs');
  return fs.existsSync(path);
 };
function _M0DTPC16result6ResultGRP411cogna_2ddev5cogna4core6config6ConfigRP411cogna_2ddev5cogna4core6config11ConfigErrorE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRP411cogna_2ddev5cogna4core6config6ConfigRP411cogna_2ddev5cogna4core6config11ConfigErrorE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGRP411cogna_2ddev5cogna4core6config6ConfigRP411cogna_2ddev5cogna4core6config11ConfigErrorE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRP411cogna_2ddev5cogna4core6config6ConfigRP411cogna_2ddev5cogna4core6config11ConfigErrorE2Ok.prototype.$tag = 1;
function _M0DTPC16result6ResultGUssERP411cogna_2ddev5cogna4core6config11ConfigErrorE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGUssERP411cogna_2ddev5cogna4core6config11ConfigErrorE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGUssERP411cogna_2ddev5cogna4core6config11ConfigErrorE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGUssERP411cogna_2ddev5cogna4core6config11ConfigErrorE2Ok.prototype.$tag = 1;
function _M0DTPC16result6ResultGbRP411cogna_2ddev5cogna4core6config11ConfigErrorE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGbRP411cogna_2ddev5cogna4core6config11ConfigErrorE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGbRP411cogna_2ddev5cogna4core6config11ConfigErrorE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGbRP411cogna_2ddev5cogna4core6config11ConfigErrorE2Ok.prototype.$tag = 1;
function _M0DTPC16result6ResultGiRP411cogna_2ddev5cogna4core6config11ConfigErrorE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGiRP411cogna_2ddev5cogna4core6config11ConfigErrorE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGiRP411cogna_2ddev5cogna4core6config11ConfigErrorE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGiRP411cogna_2ddev5cogna4core6config11ConfigErrorE2Ok.prototype.$tag = 1;
function _M0TPB8MutLocalGsE(param0) {
  this.val = param0;
}
function _M0TP411cogna_2ddev5cogna4core6config6Config(param0, param1, param2, param3, param4, param5, param6, param7, param8, param9, param10) {
  this.schema_version = param0;
  this.profile = param1;
  this.validation = param2;
  this.purl = param3;
  this.source = param4;
  this.inputs = param5;
  this.checks = param6;
  this.diff = param7;
  this.sbom = param8;
  this.cache = param9;
  this.mcp = param10;
}
function _M0TP411cogna_2ddev5cogna4core6config6Source(param0, param1) {
  this.repo = param0;
  this.source_ref = param1;
}
function _M0TP411cogna_2ddev5cogna4core6config6Inputs(param0) {
  this.include_paths = param0;
}
function _M0TP411cogna_2ddev5cogna4core6config6Checks(param0, param1) {
  this.format = param0;
  this.policy = param1;
}
function _M0TP411cogna_2ddev5cogna4core6config12DiffSettings(param0, param1) {
  this.since = param0;
  this.include_test_changes = param1;
}
function _M0TP411cogna_2ddev5cogna4core6config12SbomSettings(param0, param1, param2) {
  this.format = param0;
  this.dependency_bundles = param1;
  this.require_local_packages = param2;
}
function _M0TP411cogna_2ddev5cogna4core6config13CacheSettings(param0, param1, param2) {
  this.type_ = param0;
  this.local_store = param1;
  this.http = param2;
}
function _M0TP411cogna_2ddev5cogna4core6config18LocalCacheSettings(param0) {
  this.store_dir = param0;
}
function _M0TP411cogna_2ddev5cogna4core6config17HttpCacheSettings(param0, param1) {
  this.base_url = param0;
  this.timeout_ms = param1;
}
function _M0TP411cogna_2ddev5cogna4core6config11McpSettings(param0) {
  this.port = param0;
}
function _M0TPB8MutLocalGOsE(param0) {
  this.val = param0;
}
function _M0TPB8MutLocalGbE(param0) {
  this.val = param0;
}
function _M0DTPC16result6ResultGRP411cogna_2ddev5cogna4core6config14ResolvedConfigRP411cogna_2ddev5cogna4core6config11ConfigErrorE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRP411cogna_2ddev5cogna4core6config14ResolvedConfigRP411cogna_2ddev5cogna4core6config11ConfigErrorE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGRP411cogna_2ddev5cogna4core6config14ResolvedConfigRP411cogna_2ddev5cogna4core6config11ConfigErrorE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRP411cogna_2ddev5cogna4core6config14ResolvedConfigRP411cogna_2ddev5cogna4core6config11ConfigErrorE2Ok.prototype.$tag = 1;
function _M0TP411cogna_2ddev5cogna4core6config14ResolvedConfig(param0, param1, param2) {
  this.path = param0;
  this.root_dir = param1;
  this.config = param2;
}
function _M0TP411cogna_2ddev5cogna3sdk9generated14SourceLocation(param0, param1, param2) {
  this.uri = param0;
  this.start_line = param1;
  this.end_line = param2;
}
function _M0DTPC16option6OptionGRPB5ArrayGRP411cogna_2ddev5cogna3sdk9generated11PackageNodeEE4None() {}
_M0DTPC16option6OptionGRPB5ArrayGRP411cogna_2ddev5cogna3sdk9generated11PackageNodeEE4None.prototype.$tag = 0;
const _M0DTPC16option6OptionGRPB5ArrayGRP411cogna_2ddev5cogna3sdk9generated11PackageNodeEE4None__ = new _M0DTPC16option6OptionGRPB5ArrayGRP411cogna_2ddev5cogna3sdk9generated11PackageNodeEE4None();
function _M0DTPC16option6OptionGRPB5ArrayGRP411cogna_2ddev5cogna3sdk9generated11PackageNodeEE4Some(param0) {
  this._0 = param0;
}
_M0DTPC16option6OptionGRPB5ArrayGRP411cogna_2ddev5cogna3sdk9generated11PackageNodeEE4Some.prototype.$tag = 1;
function _M0TP411cogna_2ddev5cogna3sdk9generated11PackageNode(param0, param1, param2, param3, param4, param5) {
  this.name = param0;
  this.version = param1;
  this.ecosystem = param2;
  this.relation = param3;
  this.summary = param4;
  this.children = param5;
}
function _M0TP411cogna_2ddev5cogna3sdk9generated7Outline(param0, param1, param2, param3, param4, param5) {
  this.id = param0;
  this.symbol = param1;
  this.kind = param2;
  this.summary = param3;
  this.deprecated = param4;
  this.location = param5;
}
function _M0TP411cogna_2ddev5cogna3sdk9generated10QueryMatch(param0, param1, param2, param3, param4, param5, param6, param7) {
  this.id = param0;
  this.symbol = param1;
  this.kind = param2;
  this.signature = param3;
  this.summary = param4;
  this.docs = param5;
  this.score = param6;
  this.location = param7;
}
function _M0TP411cogna_2ddev5cogna3sdk9generated21FetchPackagesResponse(param0) {
  this.root = param0;
}
function _M0DTPC16option6OptionGRPB5ArrayGRP411cogna_2ddev5cogna3sdk9generated7OutlineEE4None() {}
_M0DTPC16option6OptionGRPB5ArrayGRP411cogna_2ddev5cogna3sdk9generated7OutlineEE4None.prototype.$tag = 0;
const _M0DTPC16option6OptionGRPB5ArrayGRP411cogna_2ddev5cogna3sdk9generated7OutlineEE4None__ = new _M0DTPC16option6OptionGRPB5ArrayGRP411cogna_2ddev5cogna3sdk9generated7OutlineEE4None();
function _M0DTPC16option6OptionGRPB5ArrayGRP411cogna_2ddev5cogna3sdk9generated7OutlineEE4Some(param0) {
  this._0 = param0;
}
_M0DTPC16option6OptionGRPB5ArrayGRP411cogna_2ddev5cogna3sdk9generated7OutlineEE4Some.prototype.$tag = 1;
function _M0TP411cogna_2ddev5cogna3sdk9generated21QueryOutlinesResponse(param0, param1) {
  this.package = param0;
  this.outlines = param1;
}
function _M0DTPC16option6OptionGRPB5ArrayGRP411cogna_2ddev5cogna3sdk9generated10QueryMatchEE4None() {}
_M0DTPC16option6OptionGRPB5ArrayGRP411cogna_2ddev5cogna3sdk9generated10QueryMatchEE4None.prototype.$tag = 0;
const _M0DTPC16option6OptionGRPB5ArrayGRP411cogna_2ddev5cogna3sdk9generated10QueryMatchEE4None__ = new _M0DTPC16option6OptionGRPB5ArrayGRP411cogna_2ddev5cogna3sdk9generated10QueryMatchEE4None();
function _M0DTPC16option6OptionGRPB5ArrayGRP411cogna_2ddev5cogna3sdk9generated10QueryMatchEE4Some(param0) {
  this._0 = param0;
}
_M0DTPC16option6OptionGRPB5ArrayGRP411cogna_2ddev5cogna3sdk9generated10QueryMatchEE4Some.prototype.$tag = 1;
function _M0TP411cogna_2ddev5cogna3sdk9generated13QueryResponse(param0, param1, param2, param3) {
  this.package = param0;
  this.mode = param1;
  this.matches = param2;
  this.cursor = param3;
}
function _M0TPB9ArrayViewGUsRPB4JsonEE(param0, param1, param2) {
  this.buf = param0;
  this.start = param1;
  this.end = param2;
}
function _M0TPB9ArrayViewGUssEE(param0, param1, param2) {
  this.buf = param0;
  this.start = param1;
  this.end = param2;
}
function _M0DTPC16result6ResultGssE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGssE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGssE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGssE2Ok.prototype.$tag = 1;
function _M0DTPC16result6ResultGRPB5ArrayGRPB4JsonEsE3Err(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRPB5ArrayGRPB4JsonEsE3Err.prototype.$tag = 0;
function _M0DTPC16result6ResultGRPB5ArrayGRPB4JsonEsE2Ok(param0) {
  this._0 = param0;
}
_M0DTPC16result6ResultGRPB5ArrayGRPB4JsonEsE2Ok.prototype.$tag = 1;
function _M0TPB9ArrayViewGUsbEE(param0, param1, param2) {
  this.buf = param0;
  this.start = param1;
  this.end = param2;
}
const _M0FP092moonbitlang_2fcore_2fbuiltin_2fStringBuilder_24as_24_40moonbitlang_2fcore_2fbuiltin_2eLogger = { method_0: _M0IPB13StringBuilderPB6Logger13write__string, method_1: _M0IP016_24default__implPB6Logger16write__substringGRPB13StringBuilderE, method_2: _M0IPB13StringBuilderPB6Logger11write__view, method_3: _M0IPB13StringBuilderPB6Logger11write__char };
const _M0MPC16string6String4trimN7_2abindS5716 = "\t\n\r ";
const _M0FPB4null = _M0DTPB4Json4Null__;
const _M0FPC16double14not__a__number = $i64_reinterpret_f64(9221120237041090561n);
const _M0FPC16double8infinity = $i64_reinterpret_f64(9218868437227405312n);
const _M0FPC16double13neg__infinity = $i64_reinterpret_f64(18442240474082181120n);
const _M0FPC28internal7strconv14base__err__str = "invalid base";
const _M0FPC28internal7strconv15range__err__str = "value out of range";
const _M0FPC28internal7strconv16syntax__err__str = "invalid syntax";
const _M0FPC28internal7strconv17min__19digit__int = 1000000000000000000n;
const _M0FPC28internal7strconv17parse__scientificN8exp__numS240 = 0n;
const _M0FPC28internal7strconv13parse__numberN11exp__numberS221 = 0n;
const _M0FPC28internal7strconv20parse__int64_2einnerN7_2abindS645 = "";
const _M0FPC28internal7strconv12double__info = new _M0TPC28internal7strconv9FloatInfo(52, 11, -1023);
const _M0FPC28internal7strconv25min__exponent__fast__path = 18446744073709551594n;
const _M0FPC28internal7strconv25max__exponent__fast__path = 22n;
const _M0FPC28internal7strconv36max__exponent__disguised__fast__path = 37n;
const _M0FPC28internal7strconv25max__mantissa__fast__path = 9007199254740992n;
const _M0FPC28internal7strconv6powtab = [1, 3, 6, 9, 13, 16, 19, 23, 26, 29, 33, 36, 39, 43, 46, 49, 53, 56, 59];
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS962 = { _0: 0, _1: "" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS963 = { _0: 1, _1: "5" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS964 = { _0: 1, _1: "25" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS965 = { _0: 1, _1: "125" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS966 = { _0: 2, _1: "625" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS967 = { _0: 2, _1: "3125" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS968 = { _0: 2, _1: "15625" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS969 = { _0: 3, _1: "78125" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS970 = { _0: 3, _1: "390625" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS971 = { _0: 3, _1: "1953125" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS972 = { _0: 4, _1: "9765625" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS973 = { _0: 4, _1: "48828125" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS974 = { _0: 4, _1: "244140625" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS975 = { _0: 4, _1: "1220703125" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS976 = { _0: 5, _1: "6103515625" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS977 = { _0: 5, _1: "30517578125" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS978 = { _0: 5, _1: "152587890625" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS979 = { _0: 6, _1: "762939453125" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS980 = { _0: 6, _1: "3814697265625" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS981 = { _0: 6, _1: "19073486328125" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS982 = { _0: 7, _1: "95367431640625" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS983 = { _0: 7, _1: "476837158203125" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS984 = { _0: 7, _1: "2384185791015625" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS985 = { _0: 7, _1: "11920928955078125" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS986 = { _0: 8, _1: "59604644775390625" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS987 = { _0: 8, _1: "298023223876953125" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS988 = { _0: 8, _1: "1490116119384765625" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS989 = { _0: 9, _1: "7450580596923828125" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS990 = { _0: 9, _1: "37252902984619140625" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS991 = { _0: 9, _1: "186264514923095703125" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS992 = { _0: 10, _1: "931322574615478515625" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS993 = { _0: 10, _1: "4656612873077392578125" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS994 = { _0: 10, _1: "23283064365386962890625" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS995 = { _0: 10, _1: "116415321826934814453125" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS996 = { _0: 11, _1: "582076609134674072265625" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS997 = { _0: 11, _1: "2910383045673370361328125" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS998 = { _0: 11, _1: "14551915228366851806640625" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS999 = { _0: 12, _1: "72759576141834259033203125" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS1000 = { _0: 12, _1: "363797880709171295166015625" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS1001 = { _0: 12, _1: "1818989403545856475830078125" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS1002 = { _0: 13, _1: "9094947017729282379150390625" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS1003 = { _0: 13, _1: "45474735088646411895751953125" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS1004 = { _0: 13, _1: "227373675443232059478759765625" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS1005 = { _0: 13, _1: "1136868377216160297393798828125" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS1006 = { _0: 14, _1: "5684341886080801486968994140625" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS1007 = { _0: 14, _1: "28421709430404007434844970703125" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS1008 = { _0: 14, _1: "142108547152020037174224853515625" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS1009 = { _0: 15, _1: "710542735760100185871124267578125" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS1010 = { _0: 15, _1: "3552713678800500929355621337890625" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS1011 = { _0: 15, _1: "17763568394002504646778106689453125" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS1012 = { _0: 16, _1: "88817841970012523233890533447265625" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS1013 = { _0: 16, _1: "444089209850062616169452667236328125" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS1014 = { _0: 16, _1: "2220446049250313080847263336181640625" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS1015 = { _0: 16, _1: "11102230246251565404236316680908203125" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS1016 = { _0: 17, _1: "55511151231257827021181583404541015625" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS1017 = { _0: 17, _1: "277555756156289135105907917022705078125" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS1018 = { _0: 17, _1: "1387778780781445675529539585113525390625" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS1019 = { _0: 18, _1: "6938893903907228377647697925567626953125" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS1020 = { _0: 18, _1: "34694469519536141888238489627838134765625" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS1021 = { _0: 18, _1: "173472347597680709441192448139190673828125" };
const _M0FPC28internal7strconv19left__shift__cheatsN5tupleS1022 = { _0: 19, _1: "867361737988403547205962240695953369140625" };
const _M0FPC28internal7strconv19left__shift__cheats = [_M0FPC28internal7strconv19left__shift__cheatsN5tupleS962, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS963, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS964, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS965, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS966, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS967, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS968, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS969, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS970, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS971, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS972, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS973, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS974, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS975, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS976, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS977, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS978, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS979, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS980, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS981, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS982, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS983, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS984, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS985, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS986, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS987, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS988, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS989, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS990, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS991, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS992, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS993, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS994, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS995, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS996, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS997, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS998, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS999, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS1000, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS1001, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS1002, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS1003, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS1004, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS1005, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS1006, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS1007, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS1008, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS1009, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS1010, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS1011, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS1012, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS1013, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS1014, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS1015, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS1016, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS1017, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS1018, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS1019, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS1020, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS1021, _M0FPC28internal7strconv19left__shift__cheatsN5tupleS1022];
const _M0FPC28internal7strconv10int__pow10 = [1n, 10n, 100n, 1000n, 10000n, 100000n, 1000000n, 10000000n, 100000000n, 1000000000n, 10000000000n, 100000000000n, 1000000000000n, 10000000000000n, 100000000000000n, 1000000000000000n];
const _M0FPC28internal7strconv5table = [1, 10, 100, 1000, 10000, 100000, 1000000, 10000000, 100000000, 1000000000, 10000000000, 100000000000, 1e+12, 1e+13, 1e+14, 1e+15, 1e+16, 1e+17, 1e+18, 1e+19, 1e+20, 1e+21, 1e+22, 0, 0, 0, 0, 0, 0, 0, 0, 0];
const _M0FPC28internal7strconv12checked__mulN6constrS1107 = 0n;
const _M0MPC14json12ParseContext16lex__number__endN7_2abindS1061 = ".";
const _M0MPC14json12ParseContext16lex__number__endN7_2abindS1062 = "e";
const _M0MPC14json12ParseContext16lex__number__endN7_2abindS1063 = "E";
const _M0FPB4seed = _M0FPB12random__seed();
const _M0FPB18brute__force__findN6constrS8126 = 0;
const _M0FPB28boyer__moore__horspool__findN6constrS8125 = 0;
function _M0FPC15abort5abortGRP411cogna_2ddev5cogna4core6config11ConfigErrorE(msg) {
  return $panic();
}
function _M0FPC15abort5abortGuE(msg) {
  $panic();
}
function _M0FPC15abort5abortGOiE(msg) {
  return $panic();
}
function _M0MPB6Logger13write__objectGsE(self, obj) {
  _M0IPC16string6StringPB4Show6output(obj, self);
}
function _M0MPC14json4Json5array(array) {
  return new _M0DTPB4Json5Array(array);
}
function _M0IPC16string6StringPB6ToJson8to__json(self) {
  return new _M0DTPB4Json6String(self);
}
function _M0FPB4rotl(x, r) {
  return x << r | (x >>> (32 - r | 0) | 0);
}
function _M0MPB6Hasher8consume4(self, input) {
  self.acc = Math.imul(_M0FPB4rotl((self.acc >>> 0) + ((Math.imul(input, -1028477379) | 0) >>> 0) | 0, 17), 668265263) | 0;
}
function _M0MPB6Hasher13combine__uint(self, value) {
  self.acc = (self.acc >>> 0) + (4 >>> 0) | 0;
  _M0MPB6Hasher8consume4(self, value);
}
function _M0MPC14byte4Byte8to__char(self) {
  return self;
}
function _M0MPB13StringBuilder11new_2einner(size_hint) {
  return new _M0TPB13StringBuilder("");
}
function _M0MPB13StringBuilder10to__string(self) {
  return self.val;
}
function _M0IPB13StringBuilderPB6Logger11write__char(self, ch) {
  self.val = `${self.val}${String.fromCodePoint(ch)}`;
}
function _M0MPC16uint166UInt1622is__leading__surrogate(self) {
  return _M0IP016_24default__implPB7Compare6op__geGkE(self, 55296) && _M0IP016_24default__implPB7Compare6op__leGkE(self, 56319);
}
function _M0MPC16uint166UInt1623is__trailing__surrogate(self) {
  return _M0IP016_24default__implPB7Compare6op__geGkE(self, 56320) && _M0IP016_24default__implPB7Compare6op__leGkE(self, 57343);
}
function _M0FPB32code__point__of__surrogate__pair(leading, trailing) {
  return (((Math.imul(leading - 55296 | 0, 1024) | 0) + trailing | 0) - 56320 | 0) + 65536 | 0;
}
function _M0MPC16uint166UInt1616unsafe__to__char(self) {
  return self;
}
function _M0MPC16string6String16unsafe__char__at(self, index) {
  const c1 = self.charCodeAt(index);
  if (_M0MPC16uint166UInt1622is__leading__surrogate(c1)) {
    const c2 = self.charCodeAt(index + 1 | 0);
    return _M0FPB32code__point__of__surrogate__pair(c1, c2);
  } else {
    return _M0MPC16uint166UInt1616unsafe__to__char(c1);
  }
}
function _M0IPC14byte4BytePB3Add3add(self, that) {
  return (self + that | 0) & 255;
}
function _M0IPC14byte4BytePB3Div3div(self, that) {
  if (that === 0) {
    $panic();
  }
  return (self / that | 0) & 255;
}
function _M0IPC14byte4BytePB3Mod3mod(self, that) {
  if (that === 0) {
    $panic();
  }
  return (self % that | 0) & 255;
}
function _M0IPC14byte4BytePB3Sub3sub(self, that) {
  return (self - that | 0) & 255;
}
function _M0MPC14byte4Byte7to__hexN14to__hex__digitS3320(i) {
  return i < 10 ? _M0MPC14byte4Byte8to__char(_M0IPC14byte4BytePB3Add3add(i, 48)) : _M0MPC14byte4Byte8to__char(_M0IPC14byte4BytePB3Sub3sub(_M0IPC14byte4BytePB3Add3add(i, 97), 10));
}
function _M0MPC14byte4Byte7to__hex(b) {
  const _self = _M0MPB13StringBuilder11new_2einner(0);
  _M0IPB13StringBuilderPB6Logger11write__char(_self, _M0MPC14byte4Byte7to__hexN14to__hex__digitS3320(_M0IPC14byte4BytePB3Div3div(b, 16)));
  _M0IPB13StringBuilderPB6Logger11write__char(_self, _M0MPC14byte4Byte7to__hexN14to__hex__digitS3320(_M0IPC14byte4BytePB3Mod3mod(b, 16)));
  return _M0MPB13StringBuilder10to__string(_self);
}
function _M0MPC16string10StringView6length(self) {
  return self.end - self.start | 0;
}
function _M0MPC16string10StringView11sub_2einner(self, start, end) {
  const str_len = self.str.length;
  let abs_end;
  if (end === undefined) {
    abs_end = self.end;
  } else {
    const _Some = end;
    const _end = _Some;
    abs_end = _end < 0 ? self.end + _end | 0 : self.start + _end | 0;
  }
  const abs_start = start < 0 ? self.end + start | 0 : self.start + start | 0;
  if (abs_start >= self.start && (abs_start <= abs_end && abs_end <= self.end)) {
    if (abs_start < str_len) {
      if (!_M0MPC16uint166UInt1623is__trailing__surrogate(self.str.charCodeAt(abs_start))) {
      } else {
        $panic();
      }
    }
    if (abs_end < str_len) {
      if (!_M0MPC16uint166UInt1623is__trailing__surrogate(self.str.charCodeAt(abs_end))) {
      } else {
        $panic();
      }
    }
    return new _M0TPC16string10StringView(self.str, abs_start, abs_end);
  } else {
    return $panic();
  }
}
function _M0MPC16string10StringView11unsafe__get(self, index) {
  return self.str.charCodeAt(self.start + index | 0);
}
function _M0MPC16string10StringView18escape__to_2einnerN14flush__segmentS3305(_env, seg, i) {
  const self = _env._1;
  const logger = _env._0;
  if (i > seg) {
    logger.method_table.method_2(logger.self, _M0MPC16string10StringView11sub_2einner(self, seg, i));
    return;
  } else {
    return;
  }
}
function _M0MPC16string10StringView18escape__to_2einner(self, logger, quote) {
  if (quote) {
    logger.method_table.method_3(logger.self, 34);
  }
  const len = _M0MPC16string10StringView6length(self);
  const _env = { _0: logger, _1: self };
  let _tmp = 0;
  let _tmp$2 = 0;
  _L: while (true) {
    const i = _tmp;
    const seg = _tmp$2;
    if (i >= len) {
      _M0MPC16string10StringView18escape__to_2einnerN14flush__segmentS3305(_env, seg, i);
      break;
    }
    const code = _M0MPC16string10StringView11unsafe__get(self, i);
    let c;
    _L$2: {
      switch (code) {
        case 34: {
          c = code;
          break _L$2;
        }
        case 92: {
          c = code;
          break _L$2;
        }
        case 10: {
          _M0MPC16string10StringView18escape__to_2einnerN14flush__segmentS3305(_env, seg, i);
          logger.method_table.method_0(logger.self, "\\n");
          _tmp = i + 1 | 0;
          _tmp$2 = i + 1 | 0;
          continue _L;
        }
        case 13: {
          _M0MPC16string10StringView18escape__to_2einnerN14flush__segmentS3305(_env, seg, i);
          logger.method_table.method_0(logger.self, "\\r");
          _tmp = i + 1 | 0;
          _tmp$2 = i + 1 | 0;
          continue _L;
        }
        case 8: {
          _M0MPC16string10StringView18escape__to_2einnerN14flush__segmentS3305(_env, seg, i);
          logger.method_table.method_0(logger.self, "\\b");
          _tmp = i + 1 | 0;
          _tmp$2 = i + 1 | 0;
          continue _L;
        }
        case 9: {
          _M0MPC16string10StringView18escape__to_2einnerN14flush__segmentS3305(_env, seg, i);
          logger.method_table.method_0(logger.self, "\\t");
          _tmp = i + 1 | 0;
          _tmp$2 = i + 1 | 0;
          continue _L;
        }
        default: {
          if (_M0IP016_24default__implPB7Compare6op__ltGkE(code, 32)) {
            _M0MPC16string10StringView18escape__to_2einnerN14flush__segmentS3305(_env, seg, i);
            logger.method_table.method_0(logger.self, "\\u{");
            logger.method_table.method_0(logger.self, _M0MPC14byte4Byte7to__hex(code & 255));
            logger.method_table.method_3(logger.self, 125);
            _tmp = i + 1 | 0;
            _tmp$2 = i + 1 | 0;
            continue _L;
          } else {
            _tmp = i + 1 | 0;
            continue _L;
          }
        }
      }
    }
    _M0MPC16string10StringView18escape__to_2einnerN14flush__segmentS3305(_env, seg, i);
    logger.method_table.method_3(logger.self, 92);
    logger.method_table.method_3(logger.self, _M0MPC16uint166UInt1616unsafe__to__char(c));
    _tmp = i + 1 | 0;
    _tmp$2 = i + 1 | 0;
    continue;
  }
  if (quote) {
    logger.method_table.method_3(logger.self, 34);
    return;
  } else {
    return;
  }
}
function _M0IPB13StringBuilderPB6Logger13write__string(self, str) {
  self.val = `${self.val}${str}`;
}
function _M0MPC16uint646UInt648to__byte(self) {
  return (Number(BigInt.asIntN(32, self)) | 0) & 255;
}
function _M0IPC16uint166UInt16PB2Eq5equal(self, that) {
  return self === that;
}
function _M0IPC16uint166UInt16PB2Eq10not__equal(self, that) {
  return self !== that;
}
function _M0IPC16uint166UInt16PB7Compare7compare(self, that) {
  return $compare_int(self, that);
}
function _M0MPC14json4Json6number(number, repr) {
  return new _M0DTPB4Json6Number(number, repr);
}
function _M0MPB6Hasher7combineGsE(self, value) {
  _M0IPC16string6StringPB4Hash13hash__combine(value, self);
}
function _M0IP016_24default__implPB2Eq10not__equalGsE(x, y) {
  return !(x === y);
}
function _M0IP016_24default__implPB2Eq10not__equalGRPC16string10StringViewE(x, y) {
  return !_M0IPC16string10StringViewPB2Eq5equal(x, y);
}
function _M0IP016_24default__implPB7Compare6op__ltGkE(x, y) {
  return _M0IPC16uint166UInt16PB7Compare7compare(x, y) < 0;
}
function _M0IP016_24default__implPB7Compare6op__leGkE(x, y) {
  return _M0IPC16uint166UInt16PB7Compare7compare(x, y) <= 0;
}
function _M0IP016_24default__implPB7Compare6op__geGkE(x, y) {
  return _M0IPC16uint166UInt16PB7Compare7compare(x, y) >= 0;
}
function _M0MPB6Hasher9avalanche(self) {
  let acc = self.acc;
  acc = acc ^ (acc >>> 15 | 0);
  acc = Math.imul(acc, -2048144777) | 0;
  acc = acc ^ (acc >>> 13 | 0);
  acc = Math.imul(acc, -1028477379) | 0;
  acc = acc ^ (acc >>> 16 | 0);
  return acc;
}
function _M0MPB6Hasher8finalize(self) {
  return _M0MPB6Hasher9avalanche(self);
}
function _M0MPB6Hasher11new_2einner(seed) {
  return new _M0TPB6Hasher((seed >>> 0) + (374761393 >>> 0) | 0);
}
function _M0MPB6Hasher3new(seed$46$opt) {
  let seed;
  if (seed$46$opt === undefined) {
    seed = _M0FPB4seed;
  } else {
    const _Some = seed$46$opt;
    seed = _Some;
  }
  return _M0MPB6Hasher11new_2einner(seed);
}
function _M0IP016_24default__implPB4Hash4hashGsE(self) {
  const h = _M0MPB6Hasher3new(undefined);
  _M0MPB6Hasher7combineGsE(h, self);
  return _M0MPB6Hasher8finalize(h);
}
function _M0MPC16string6String11sub_2einner(self, start, end) {
  const len = self.length;
  let end$2;
  if (end === undefined) {
    end$2 = len;
  } else {
    const _Some = end;
    const _end = _Some;
    end$2 = _end < 0 ? len + _end | 0 : _end;
  }
  const start$2 = start < 0 ? len + start | 0 : start;
  if (start$2 >= 0 && (start$2 <= end$2 && end$2 <= len)) {
    if (start$2 < len) {
      if (!_M0MPC16uint166UInt1623is__trailing__surrogate(self.charCodeAt(start$2))) {
      } else {
        $panic();
      }
    }
    if (end$2 < len) {
      if (!_M0MPC16uint166UInt1623is__trailing__surrogate(self.charCodeAt(end$2))) {
      } else {
        $panic();
      }
    }
    return new _M0TPC16string10StringView(self, start$2, end$2);
  } else {
    return $panic();
  }
}
function _M0IP016_24default__implPB6Logger16write__substringGRPB13StringBuilderE(self, value, start, len) {
  _M0IPB13StringBuilderPB6Logger11write__view(self, _M0MPC16string6String11sub_2einner(value, start, start + len | 0));
}
function _M0MPC16string10StringView4data(self) {
  return self.str;
}
function _M0MPC16string10StringView13start__offset(self) {
  return self.start;
}
function _M0IP016_24default__implPB4Show10to__stringGiE(self) {
  const logger = _M0MPB13StringBuilder11new_2einner(0);
  _M0IPC13int3IntPB4Show6output(self, { self: logger, method_table: _M0FP092moonbitlang_2fcore_2fbuiltin_2fStringBuilder_24as_24_40moonbitlang_2fcore_2fbuiltin_2eLogger });
  return _M0MPB13StringBuilder10to__string(logger);
}
function _M0IP016_24default__implPB4Show10to__stringGRP311moonbitlang1x2fs7IOErrorE(self) {
  const logger = _M0MPB13StringBuilder11new_2einner(0);
  _M0IP311moonbitlang1x2fs7IOErrorPB4Show6output(self, { self: logger, method_table: _M0FP092moonbitlang_2fcore_2fbuiltin_2fStringBuilder_24as_24_40moonbitlang_2fcore_2fbuiltin_2eLogger });
  return _M0MPB13StringBuilder10to__string(logger);
}
function _M0MPB4Iter4nextGUsRPB4JsonEE(self) {
  const _func = self;
  return _func();
}
function _M0MPB4Iter4nextGcE(self) {
  const _func = self;
  return _func();
}
function _M0MPC13int3Int18to__string_2einner(self, radix) {
  return _M0FPB19int__to__string__js(self, radix);
}
function _M0MPB4Iter3newGUsRPB4JsonEE(f) {
  return f;
}
function _M0MPB4Iter3newGcE(f) {
  return f;
}
function _M0MPC16string10StringView12view_2einner(self, start_offset, end_offset) {
  let end_offset$2;
  if (end_offset === undefined) {
    end_offset$2 = _M0MPC16string10StringView6length(self);
  } else {
    const _Some = end_offset;
    end_offset$2 = _Some;
  }
  return start_offset >= 0 && (start_offset <= end_offset$2 && end_offset$2 <= _M0MPC16string10StringView6length(self)) ? new _M0TPC16string10StringView(self.str, self.start + start_offset | 0, self.start + end_offset$2 | 0) : _M0FPC15abort5abortGRP411cogna_2ddev5cogna4core6config11ConfigErrorE("Invalid index for View");
}
function _M0FPB19unsafe__sub__string(_tmp, _tmp$2, _tmp$3) {
  return $unsafe_bytes_sub_string(_tmp, _tmp$2, _tmp$3);
}
function _M0MPC15bytes5Bytes29to__unchecked__string_2einner(self, offset, length) {
  const len = self.length;
  let length$2;
  if (length === undefined) {
    length$2 = len - offset | 0;
  } else {
    const _Some = length;
    length$2 = _Some;
  }
  return offset >= 0 && (length$2 >= 0 && (offset + length$2 | 0) <= len) ? _M0FPB19unsafe__sub__string(self, offset, length$2) : $panic();
}
function _M0IPC14byte4BytePB7Default7default() {
  return 0;
}
function _M0IPC16string10StringViewPB4Show10to__string(self) {
  return self.str.substring(self.start, self.end);
}
function _M0MPC16string10StringView4iter(self) {
  const start = self.start;
  const end = self.end;
  const index = new _M0TPB8MutLocalGiE(start);
  return _M0MPB4Iter3newGcE(() => {
    if (index.val < end) {
      const c1 = self.str.charCodeAt(index.val);
      if (_M0MPC16uint166UInt1622is__leading__surrogate(c1) && (index.val + 1 | 0) < self.end) {
        const c2 = self.str.charCodeAt(index.val + 1 | 0);
        if (_M0MPC16uint166UInt1623is__trailing__surrogate(c2)) {
          index.val = index.val + 2 | 0;
          return _M0FPB32code__point__of__surrogate__pair(c1, c2);
        }
      }
      index.val = index.val + 1 | 0;
      return _M0MPC16uint166UInt1616unsafe__to__char(c1);
    } else {
      return -1;
    }
  });
}
function _M0IPC16string10StringViewPB2Eq5equal(self, other) {
  const len = _M0MPC16string10StringView6length(self);
  if (len === _M0MPC16string10StringView6length(other)) {
    if (self.str === other.str && self.start === other.start) {
      return true;
    }
    let _tmp = 0;
    while (true) {
      const i = _tmp;
      if (i < len) {
        if (_M0IPC16uint166UInt16PB2Eq5equal(self.str.charCodeAt(self.start + i | 0), other.str.charCodeAt(other.start + i | 0))) {
        } else {
          return false;
        }
        _tmp = i + 1 | 0;
        continue;
      } else {
        break;
      }
    }
    return true;
  } else {
    return false;
  }
}
function _M0MPC16string6String12view_2einner(self, start_offset, end_offset) {
  let end_offset$2;
  if (end_offset === undefined) {
    end_offset$2 = self.length;
  } else {
    const _Some = end_offset;
    end_offset$2 = _Some;
  }
  return start_offset >= 0 && (start_offset <= end_offset$2 && end_offset$2 <= self.length) ? new _M0TPC16string10StringView(self, start_offset, end_offset$2) : _M0FPC15abort5abortGRP411cogna_2ddev5cogna4core6config11ConfigErrorE("Invalid index for View");
}
function _M0MPC16string6String4view(self, start_offset$46$opt, end_offset) {
  let start_offset;
  if (start_offset$46$opt === undefined) {
    start_offset = 0;
  } else {
    const _Some = start_offset$46$opt;
    start_offset = _Some;
  }
  return _M0MPC16string6String12view_2einner(self, start_offset, end_offset);
}
function _M0MPC15array9ArrayView6lengthGUsRPB4JsonEE(self) {
  return self.end - self.start | 0;
}
function _M0MPC15array9ArrayView6lengthGcE(self) {
  return self.end - self.start | 0;
}
function _M0MPC16string6String11from__array(chars) {
  const buf = _M0MPB13StringBuilder11new_2einner(Math.imul(_M0MPC15array9ArrayView6lengthGcE(chars), 4) | 0);
  const _bind = chars.end - chars.start | 0;
  let _tmp = 0;
  while (true) {
    const _ = _tmp;
    if (_ < _bind) {
      const c = chars.buf[chars.start + _ | 0];
      _M0IPB13StringBuilderPB6Logger11write__char(buf, c);
      _tmp = _ + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return _M0MPB13StringBuilder10to__string(buf);
}
function _M0MPC16string6String24char__length__eq_2einner(self, len, start_offset, end_offset) {
  let end_offset$2;
  if (end_offset === undefined) {
    end_offset$2 = self.length;
  } else {
    const _Some = end_offset;
    end_offset$2 = _Some;
  }
  let _tmp = start_offset;
  let _tmp$2 = 0;
  while (true) {
    const index = _tmp;
    const count = _tmp$2;
    if (index < end_offset$2 && count < len) {
      const c1 = self.charCodeAt(index);
      if (_M0MPC16uint166UInt1622is__leading__surrogate(c1) && (index + 1 | 0) < end_offset$2) {
        const c2 = self.charCodeAt(index + 1 | 0);
        if (_M0MPC16uint166UInt1623is__trailing__surrogate(c2)) {
          _tmp = index + 2 | 0;
          _tmp$2 = count + 1 | 0;
          continue;
        } else {
          _M0FPC15abort5abortGuE("invalid surrogate pair");
        }
      }
      _tmp = index + 1 | 0;
      _tmp$2 = count + 1 | 0;
      continue;
    } else {
      return count === len && index === end_offset$2;
    }
  }
}
function _M0MPC16string6String24char__length__ge_2einner(self, len, start_offset, end_offset) {
  let end_offset$2;
  if (end_offset === undefined) {
    end_offset$2 = self.length;
  } else {
    const _Some = end_offset;
    end_offset$2 = _Some;
  }
  let _tmp = start_offset;
  let _tmp$2 = 0;
  while (true) {
    const index = _tmp;
    const count = _tmp$2;
    if (index < end_offset$2 && count < len) {
      const c1 = self.charCodeAt(index);
      if (_M0MPC16uint166UInt1622is__leading__surrogate(c1) && (index + 1 | 0) < end_offset$2) {
        const c2 = self.charCodeAt(index + 1 | 0);
        if (_M0MPC16uint166UInt1623is__trailing__surrogate(c2)) {
          _tmp = index + 2 | 0;
          _tmp$2 = count + 1 | 0;
          continue;
        } else {
          _M0FPC15abort5abortGuE("invalid surrogate pair");
        }
      }
      _tmp = index + 1 | 0;
      _tmp$2 = count + 1 | 0;
      continue;
    } else {
      return count >= len;
    }
  }
}
function _M0MPC16string6String31offset__of__nth__char__backward(self, n, start_offset, end_offset) {
  let _tmp = end_offset;
  let _tmp$2 = 0;
  while (true) {
    const utf16_offset = _tmp;
    const char_count = _tmp$2;
    if ((utf16_offset - 1 | 0) >= start_offset && char_count < n) {
      const c = self.charCodeAt(utf16_offset - 1 | 0);
      if (_M0MPC16uint166UInt1623is__trailing__surrogate(c)) {
        _tmp = utf16_offset - 2 | 0;
        _tmp$2 = char_count + 1 | 0;
        continue;
      } else {
        _tmp = utf16_offset - 1 | 0;
        _tmp$2 = char_count + 1 | 0;
        continue;
      }
    } else {
      return char_count < n || utf16_offset < start_offset ? undefined : utf16_offset;
    }
  }
}
function _M0MPC16string6String30offset__of__nth__char__forward(self, n, start_offset, end_offset) {
  if (start_offset >= 0 && start_offset <= end_offset) {
    let _tmp = start_offset;
    let _tmp$2 = 0;
    while (true) {
      const utf16_offset = _tmp;
      const char_count = _tmp$2;
      if (utf16_offset < end_offset && char_count < n) {
        const c = self.charCodeAt(utf16_offset);
        if (_M0MPC16uint166UInt1622is__leading__surrogate(c)) {
          _tmp = utf16_offset + 2 | 0;
          _tmp$2 = char_count + 1 | 0;
          continue;
        } else {
          _tmp = utf16_offset + 1 | 0;
          _tmp$2 = char_count + 1 | 0;
          continue;
        }
      } else {
        return char_count < n || utf16_offset >= end_offset ? undefined : utf16_offset;
      }
    }
  } else {
    return _M0FPC15abort5abortGOiE("Invalid start index");
  }
}
function _M0MPC16string6String29offset__of__nth__char_2einner(self, i, start_offset, end_offset) {
  let end_offset$2;
  if (end_offset === undefined) {
    end_offset$2 = self.length;
  } else {
    const _Some = end_offset;
    end_offset$2 = _Some;
  }
  return i >= 0 ? _M0MPC16string6String30offset__of__nth__char__forward(self, i, start_offset, end_offset$2) : _M0MPC16string6String31offset__of__nth__char__backward(self, -i | 0, start_offset, end_offset$2);
}
function _M0IPB13StringBuilderPB6Logger11write__view(self, str) {
  self.val = `${self.val}${_M0IPC16string10StringViewPB4Show10to__string(str)}`;
}
function _M0FPB28boyer__moore__horspool__find(haystack, needle) {
  const haystack_len = _M0MPC16string10StringView6length(haystack);
  const needle_len = _M0MPC16string10StringView6length(needle);
  if (needle_len > 0) {
    if (haystack_len >= needle_len) {
      const skip_table = $make_array_len_and_init(256, needle_len);
      const _bind = needle_len - 1 | 0;
      let _tmp = 0;
      while (true) {
        const i = _tmp;
        if (i < _bind) {
          const _tmp$2 = _M0MPC16string10StringView11unsafe__get(needle, i) & 255;
          $bound_check(skip_table, _tmp$2);
          skip_table[_tmp$2] = (needle_len - 1 | 0) - i | 0;
          _tmp = i + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      let _tmp$2 = 0;
      while (true) {
        const i = _tmp$2;
        if (i <= (haystack_len - needle_len | 0)) {
          const _bind$2 = needle_len - 1 | 0;
          let _tmp$3 = 0;
          while (true) {
            const j = _tmp$3;
            if (j <= _bind$2) {
              if (_M0IPC16uint166UInt16PB2Eq10not__equal(_M0MPC16string10StringView11unsafe__get(haystack, i + j | 0), _M0MPC16string10StringView11unsafe__get(needle, j))) {
                break;
              }
              _tmp$3 = j + 1 | 0;
              continue;
            } else {
              return i;
            }
          }
          const _tmp$4 = _M0MPC16string10StringView11unsafe__get(haystack, (i + needle_len | 0) - 1 | 0) & 255;
          $bound_check(skip_table, _tmp$4);
          _tmp$2 = i + skip_table[_tmp$4] | 0;
          continue;
        } else {
          break;
        }
      }
      return undefined;
    } else {
      return undefined;
    }
  } else {
    return _M0FPB28boyer__moore__horspool__findN6constrS8125;
  }
}
function _M0FPB18brute__force__find(haystack, needle) {
  const haystack_len = _M0MPC16string10StringView6length(haystack);
  const needle_len = _M0MPC16string10StringView6length(needle);
  if (needle_len > 0) {
    if (haystack_len >= needle_len) {
      const needle_first = _M0MPC16string10StringView11unsafe__get(needle, 0);
      const forward_len = haystack_len - needle_len | 0;
      let _tmp = 0;
      while (true) {
        const i = _tmp;
        if (i <= forward_len) {
          if (_M0IPC16uint166UInt16PB2Eq10not__equal(_M0MPC16string10StringView11unsafe__get(haystack, i), needle_first)) {
            _tmp = i + 1 | 0;
            continue;
          }
          let _tmp$2 = 1;
          while (true) {
            const j = _tmp$2;
            if (j < needle_len) {
              if (_M0IPC16uint166UInt16PB2Eq10not__equal(_M0MPC16string10StringView11unsafe__get(haystack, i + j | 0), _M0MPC16string10StringView11unsafe__get(needle, j))) {
                break;
              }
              _tmp$2 = j + 1 | 0;
              continue;
            } else {
              return i;
            }
          }
          _tmp = i + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      return undefined;
    } else {
      return undefined;
    }
  } else {
    return _M0FPB18brute__force__findN6constrS8126;
  }
}
function _M0MPC16string10StringView4find(self, str) {
  return _M0MPC16string10StringView6length(str) <= 4 ? _M0FPB18brute__force__find(self, str) : _M0FPB28boyer__moore__horspool__find(self, str);
}
function _M0FPB33boyer__moore__horspool__rev__find(haystack, needle) {
  const haystack_len = _M0MPC16string10StringView6length(haystack);
  const needle_len = _M0MPC16string10StringView6length(needle);
  if (needle_len > 0) {
    if (haystack_len >= needle_len) {
      const skip_table = $make_array_len_and_init(256, needle_len);
      let _tmp = needle_len - 1 | 0;
      while (true) {
        const i = _tmp;
        if (i >= 1) {
          const _tmp$2 = _M0MPC16string10StringView11unsafe__get(needle, i) & 255;
          $bound_check(skip_table, _tmp$2);
          skip_table[_tmp$2] = i;
          _tmp = i - 1 | 0;
          continue;
        } else {
          break;
        }
      }
      let _tmp$2 = haystack_len - needle_len | 0;
      while (true) {
        const i = _tmp$2;
        if (i >= 0) {
          let _tmp$3 = 0;
          while (true) {
            const j = _tmp$3;
            if (j < needle_len) {
              if (_M0IPC16uint166UInt16PB2Eq10not__equal(_M0MPC16string10StringView11unsafe__get(haystack, i + j | 0), _M0MPC16string10StringView11unsafe__get(needle, j))) {
                break;
              }
              _tmp$3 = j + 1 | 0;
              continue;
            } else {
              return i;
            }
          }
          const _tmp$4 = _M0MPC16string10StringView11unsafe__get(haystack, i) & 255;
          $bound_check(skip_table, _tmp$4);
          _tmp$2 = i - skip_table[_tmp$4] | 0;
          continue;
        } else {
          break;
        }
      }
      return undefined;
    } else {
      return undefined;
    }
  } else {
    return haystack_len;
  }
}
function _M0FPB23brute__force__rev__find(haystack, needle) {
  const haystack_len = _M0MPC16string10StringView6length(haystack);
  const needle_len = _M0MPC16string10StringView6length(needle);
  if (needle_len > 0) {
    if (haystack_len >= needle_len) {
      const needle_first = _M0MPC16string10StringView11unsafe__get(needle, 0);
      let _tmp = haystack_len - needle_len | 0;
      while (true) {
        const i = _tmp;
        if (i >= 0) {
          if (_M0IPC16uint166UInt16PB2Eq10not__equal(_M0MPC16string10StringView11unsafe__get(haystack, i), needle_first)) {
            _tmp = i - 1 | 0;
            continue;
          }
          let _tmp$2 = 1;
          while (true) {
            const j = _tmp$2;
            if (j < needle_len) {
              if (_M0IPC16uint166UInt16PB2Eq10not__equal(_M0MPC16string10StringView11unsafe__get(haystack, i + j | 0), _M0MPC16string10StringView11unsafe__get(needle, j))) {
                break;
              }
              _tmp$2 = j + 1 | 0;
              continue;
            } else {
              return i;
            }
          }
          _tmp = i - 1 | 0;
          continue;
        } else {
          break;
        }
      }
      return undefined;
    } else {
      return undefined;
    }
  } else {
    return haystack_len;
  }
}
function _M0MPC16string10StringView9rev__find(self, str) {
  return _M0MPC16string10StringView6length(str) <= 4 ? _M0FPB23brute__force__rev__find(self, str) : _M0FPB33boyer__moore__horspool__rev__find(self, str);
}
function _M0MPC16string10StringView11has__suffix(self, str) {
  const _bind = _M0MPC16string10StringView9rev__find(self, str);
  if (_bind === undefined) {
    return false;
  } else {
    const _Some = _bind;
    const _i = _Some;
    return _i === (_M0MPC16string10StringView6length(self) - _M0MPC16string10StringView6length(str) | 0);
  }
}
function _M0MPC16string6String11has__suffix(self, str) {
  return _M0MPC16string10StringView11has__suffix(new _M0TPC16string10StringView(self, 0, self.length), str);
}
function _M0MPC16string10StringView11has__prefix(self, str) {
  const _bind = _M0MPC16string10StringView4find(self, str);
  if (_bind === undefined) {
    return false;
  } else {
    const _Some = _bind;
    const _i = _Some;
    return _i === 0;
  }
}
function _M0MPC16string6String11has__prefix(self, str) {
  return _M0MPC16string10StringView11has__prefix(new _M0TPC16string10StringView(self, 0, self.length), str);
}
function _M0MPC15array5Array4pushGRPB4JsonE(self, value) {
  _M0MPB7JSArray4push(self, value);
}
function _M0MPC15array5Array4pushGcE(self, value) {
  _M0MPB7JSArray4push(self, value);
}
function _M0MPC16string10StringView8contains(self, str) {
  const _bind = _M0MPC16string10StringView4find(self, str);
  return !(_bind === undefined);
}
function _M0MPC16string6String8contains(self, str) {
  return _M0MPC16string10StringView8contains(new _M0TPC16string10StringView(self, 0, self.length), str);
}
function _M0MPC16string10StringView14contains__char(self, c) {
  const len = _M0MPC16string10StringView6length(self);
  if (len > 0) {
    const c$2 = c;
    if (c$2 <= 65535) {
      let _tmp = 0;
      while (true) {
        const i = _tmp;
        if (i < len) {
          if (_M0MPC16string10StringView11unsafe__get(self, i) === c$2) {
            return true;
          }
          _tmp = i + 1 | 0;
          continue;
        } else {
          break;
        }
      }
    } else {
      if (len >= 2) {
        const adj = c$2 - 65536 | 0;
        const high = 55296 + (adj >> 10) | 0;
        const low = 56320 + (adj & 1023) | 0;
        let _tmp = 0;
        while (true) {
          const i = _tmp;
          if (i < (len - 1 | 0)) {
            if (_M0MPC16string10StringView11unsafe__get(self, i) === high) {
              if (_M0MPC16string10StringView11unsafe__get(self, i + 1 | 0) === low) {
                return true;
              }
              _tmp = i + 2 | 0;
              continue;
            }
            _tmp = i + 1 | 0;
            continue;
          } else {
            break;
          }
        }
      } else {
        return false;
      }
    }
    return false;
  } else {
    return false;
  }
}
function _M0MPC16string10StringView19trim__start_2einner(self, chars) {
  let _tmp = self;
  while (true) {
    const x = _tmp;
    if (_M0MPC16string6String24char__length__eq_2einner(x.str, 0, x.start, x.end)) {
      return x;
    } else {
      const _c = _M0MPC16string6String16unsafe__char__at(x.str, _M0MPC16string6String29offset__of__nth__char_2einner(x.str, 0, x.start, x.end));
      const _tmp$2 = x.str;
      const _bind = _M0MPC16string6String29offset__of__nth__char_2einner(x.str, 1, x.start, x.end);
      let _tmp$3;
      if (_bind === undefined) {
        _tmp$3 = x.end;
      } else {
        const _Some = _bind;
        _tmp$3 = _Some;
      }
      const _x = new _M0TPC16string10StringView(_tmp$2, _tmp$3, x.end);
      if (_M0MPC16string10StringView14contains__char(chars, _c)) {
        _tmp = _x;
        continue;
      } else {
        return x;
      }
    }
  }
}
function _M0MPC16string10StringView17trim__end_2einner(self, chars) {
  let _tmp = self;
  while (true) {
    const x = _tmp;
    if (_M0MPC16string6String24char__length__eq_2einner(x.str, 0, x.start, x.end)) {
      return x;
    } else {
      const _c = _M0MPC16string6String16unsafe__char__at(x.str, _M0MPC16string6String29offset__of__nth__char_2einner(x.str, -1, x.start, x.end));
      const _x = new _M0TPC16string10StringView(x.str, x.start, _M0MPC16string6String29offset__of__nth__char_2einner(x.str, -1, x.start, x.end));
      if (_M0MPC16string10StringView14contains__char(chars, _c)) {
        _tmp = _x;
        continue;
      } else {
        return x;
      }
    }
  }
}
function _M0MPC16string10StringView12trim_2einner(self, chars) {
  return _M0MPC16string10StringView17trim__end_2einner(_M0MPC16string10StringView19trim__start_2einner(self, chars), chars);
}
function _M0MPC16string6String12trim_2einner(self, chars) {
  return _M0MPC16string10StringView12trim_2einner(new _M0TPC16string10StringView(self, 0, self.length), chars);
}
function _M0MPC16string6String4trim(self, chars$46$opt) {
  let chars;
  if (chars$46$opt === undefined) {
    chars = new _M0TPC16string10StringView(_M0MPC16string6String4trimN7_2abindS5716, 0, _M0MPC16string6String4trimN7_2abindS5716.length);
  } else {
    const _Some = chars$46$opt;
    chars = _Some;
  }
  return _M0MPC16string6String12trim_2einner(self, chars);
}
function _M0MPC16string10StringView9is__empty(self) {
  return _M0MPC16string10StringView6length(self) === 0;
}
function _M0MPB4Iter3mapGcRPC16string10StringViewE(self, f) {
  return () => {
    const _bind = _M0MPB4Iter4nextGcE(self);
    if (_bind === -1) {
      return undefined;
    } else {
      const _Some = _bind;
      const _x = _Some;
      return f(_x);
    }
  };
}
function _M0IPC14char4CharPB4Show10to__string(self) {
  return String.fromCodePoint(self);
}
function _M0MPC16string10StringView5split(self, sep) {
  const sep_len = _M0MPC16string10StringView6length(sep);
  if (sep_len === 0) {
    return _M0MPB4Iter3mapGcRPC16string10StringViewE(_M0MPC16string10StringView4iter(self), (c) => _M0MPC16string6String12view_2einner(_M0IPC14char4CharPB4Show10to__string(c), 0, undefined));
  }
  const remaining = new _M0TPB8MutLocalGORPC16string10StringViewE(self);
  return _M0MPB4Iter3newGUsRPB4JsonEE(() => {
    const _bind = remaining.val;
    if (_bind === undefined) {
      return undefined;
    } else {
      const _Some = _bind;
      const _view = _Some;
      const _bind$2 = _M0MPC16string10StringView4find(_view, sep);
      if (_bind$2 === undefined) {
        remaining.val = undefined;
        return _view;
      } else {
        const _Some$2 = _bind$2;
        const _end = _Some$2;
        remaining.val = _M0MPC16string10StringView12view_2einner(_view, _end + sep_len | 0, undefined);
        return _M0MPC16string10StringView12view_2einner(_view, 0, _end);
      }
    }
  });
}
function _M0MPC16string6String5split(self, sep) {
  return _M0MPC16string10StringView5split(new _M0TPC16string10StringView(self, 0, self.length), sep);
}
function _M0MPB4Iter9to__arrayGRPC16string10StringViewE(self) {
  const result = [];
  while (true) {
    const _bind = _M0MPB4Iter4nextGUsRPB4JsonEE(self);
    if (_bind === undefined) {
      break;
    } else {
      const _Some = _bind;
      const _x = _Some;
      _M0MPC15array5Array4pushGRPB4JsonE(result, _x);
      continue;
    }
  }
  return result;
}
function _M0MPC16string10StringView9get__char(self, idx) {
  if (idx >= 0 && idx < _M0MPC16string10StringView6length(self)) {
    const c = _M0MPC16string10StringView11unsafe__get(self, idx);
    if (_M0MPC16uint166UInt1622is__leading__surrogate(c)) {
      if ((idx + 1 | 0) < _M0MPC16string10StringView6length(self)) {
        const next = _M0MPC16string10StringView11unsafe__get(self, idx + 1 | 0);
        return _M0MPC16uint166UInt1623is__trailing__surrogate(next) ? _M0FPB32code__point__of__surrogate__pair(c, next) : -1;
      } else {
        return -1;
      }
    } else {
      return _M0MPC16uint166UInt1623is__trailing__surrogate(c) ? -1 : _M0MPC16uint166UInt1616unsafe__to__char(c);
    }
  } else {
    return -1;
  }
}
function _M0IPC13int3IntPB4Show6output(self, logger) {
  logger.method_table.method_0(logger.self, _M0MPC13int3Int18to__string_2einner(self, 10));
}
function _M0IPC16string6StringPB4Show6output(self, logger) {
  _M0MPC16string10StringView18escape__to_2einner(new _M0TPC16string10StringView(self, 0, self.length), logger, true);
}
function _M0IPC16string6StringPB4Show10to__string(self) {
  return self;
}
function _M0MPC16result6Result11unwrap__errGRP411cogna_2ddev5cogna4core6config6ConfigRP411cogna_2ddev5cogna4core6config11ConfigErrorE(self) {
  if (self.$tag === 1) {
    return _M0FPC15abort5abortGRP411cogna_2ddev5cogna4core6config11ConfigErrorE("called `Result::unwrap_err()` on an `Ok` value");
  } else {
    const _Err = self;
    return _Err._0;
  }
}
function _M0MPC16result6Result11unwrap__errGbRP411cogna_2ddev5cogna4core6config11ConfigErrorE(self) {
  if (self.$tag === 1) {
    return _M0FPC15abort5abortGRP411cogna_2ddev5cogna4core6config11ConfigErrorE("called `Result::unwrap_err()` on an `Ok` value");
  } else {
    const _Err = self;
    return _Err._0;
  }
}
function _M0MPC16result6Result11unwrap__errGiRP411cogna_2ddev5cogna4core6config11ConfigErrorE(self) {
  if (self.$tag === 1) {
    return _M0FPC15abort5abortGRP411cogna_2ddev5cogna4core6config11ConfigErrorE("called `Result::unwrap_err()` on an `Ok` value");
  } else {
    const _Err = self;
    return _Err._0;
  }
}
function _M0MPC15array13ReadOnlyArray2atGmE(self, index) {
  $bound_check(self, index);
  return self[index];
}
function _M0MPC15array13ReadOnlyArray2atGiE(self, index) {
  $bound_check(self, index);
  return self[index];
}
function _M0MPC15array13ReadOnlyArray2atGdE(self, index) {
  $bound_check(self, index);
  return self[index];
}
function _M0MPC15array13ReadOnlyArray6lengthGiE(self) {
  return self.length;
}
function _M0MPC16option6Option6unwrapGRPB5EntryGsbEE(self) {
  if (self === undefined) {
    return $panic();
  } else {
    const _Some = self;
    return _Some;
  }
}
function _M0MPC16option6Option10unwrap__orGsE(self, default_) {
  if (self === undefined) {
    return default_;
  } else {
    const _Some = self;
    return _Some;
  }
}
function _M0MPC16option6Option10unwrap__orGcE(self, default_) {
  return self === -1 ? default_ : self;
}
function _M0MPC16option6Option3mapGRPC16string10StringViewsE(self, f) {
  if (self === undefined) {
    return undefined;
  } else {
    const _Some = self;
    const _t = _Some;
    return f(_t);
  }
}
function _M0FPB21calc__grow__threshold(capacity) {
  if (16 === 0) {
    $panic();
  }
  return (Math.imul(capacity, 13) | 0) / 16 | 0;
}
function _M0MPC13int3Int20next__power__of__two(self) {
  if (self >= 0) {
    if (self <= 1) {
      return 1;
    }
    if (self > 1073741824) {
      return 1073741824;
    }
    return (2147483647 >> (Math.clz32(self - 1 | 0) - 1 | 0)) + 1 | 0;
  } else {
    return $panic();
  }
}
function _M0MPB3Map11new_2einnerGsRPB4JsonE(capacity) {
  const capacity$2 = _M0MPC13int3Int20next__power__of__two(capacity);
  const _bind = capacity$2 - 1 | 0;
  const _bind$2 = _M0FPB21calc__grow__threshold(capacity$2);
  const _bind$3 = $make_array_len_and_init(capacity$2, undefined);
  const _bind$4 = undefined;
  return new _M0TPB3MapGsRPB4JsonE(_bind$3, 0, capacity$2, _bind, _bind$2, _bind$4, -1);
}
function _M0MPB3Map11new_2einnerGsbE(capacity) {
  const capacity$2 = _M0MPC13int3Int20next__power__of__two(capacity);
  const _bind = capacity$2 - 1 | 0;
  const _bind$2 = _M0FPB21calc__grow__threshold(capacity$2);
  const _bind$3 = $make_array_len_and_init(capacity$2, undefined);
  const _bind$4 = undefined;
  return new _M0TPB3MapGsbE(_bind$3, 0, capacity$2, _bind, _bind$2, _bind$4, -1);
}
function _M0MPB3Map20add__entry__to__tailGsbE(self, idx, entry) {
  const _bind = self.tail;
  if (_bind === -1) {
    self.head = entry;
  } else {
    const _tmp = self.entries;
    $bound_check(_tmp, _bind);
    _M0MPC16option6Option6unwrapGRPB5EntryGsbEE(_tmp[_bind]).next = entry;
  }
  self.tail = idx;
  const _tmp = self.entries;
  $bound_check(_tmp, idx);
  _tmp[idx] = entry;
  self.size = self.size + 1 | 0;
}
function _M0MPB3Map20add__entry__to__tailGsRPB4JsonE(self, idx, entry) {
  const _bind = self.tail;
  if (_bind === -1) {
    self.head = entry;
  } else {
    const _tmp = self.entries;
    $bound_check(_tmp, _bind);
    _M0MPC16option6Option6unwrapGRPB5EntryGsbEE(_tmp[_bind]).next = entry;
  }
  self.tail = idx;
  const _tmp = self.entries;
  $bound_check(_tmp, idx);
  _tmp[idx] = entry;
  self.size = self.size + 1 | 0;
}
function _M0MPB3Map10set__entryGsbE(self, entry, new_idx) {
  const _tmp = self.entries;
  $bound_check(_tmp, new_idx);
  _tmp[new_idx] = entry;
  const _bind = entry.next;
  if (_bind === undefined) {
    self.tail = new_idx;
    return;
  } else {
    const _Some = _bind;
    const _next = _Some;
    _next.prev = new_idx;
    return;
  }
}
function _M0MPB3Map10set__entryGsRPB4JsonE(self, entry, new_idx) {
  const _tmp = self.entries;
  $bound_check(_tmp, new_idx);
  _tmp[new_idx] = entry;
  const _bind = entry.next;
  if (_bind === undefined) {
    self.tail = new_idx;
    return;
  } else {
    const _Some = _bind;
    const _next = _Some;
    _next.prev = new_idx;
    return;
  }
}
function _M0MPB3Map10push__awayGsbE(self, idx, entry) {
  let _tmp = entry.psl + 1 | 0;
  let _tmp$2 = (idx + 1 | 0) & self.capacity_mask;
  let _tmp$3 = entry;
  while (true) {
    const psl = _tmp;
    const idx$2 = _tmp$2;
    const entry$2 = _tmp$3;
    const _tmp$4 = self.entries;
    $bound_check(_tmp$4, idx$2);
    const _bind = _tmp$4[idx$2];
    if (_bind === undefined) {
      entry$2.psl = psl;
      _M0MPB3Map10set__entryGsbE(self, entry$2, idx$2);
      return;
    } else {
      const _Some = _bind;
      const _curr_entry = _Some;
      if (psl > _curr_entry.psl) {
        entry$2.psl = psl;
        _M0MPB3Map10set__entryGsbE(self, entry$2, idx$2);
        _tmp = _curr_entry.psl + 1 | 0;
        _tmp$2 = (idx$2 + 1 | 0) & self.capacity_mask;
        _tmp$3 = _curr_entry;
        continue;
      } else {
        _tmp = psl + 1 | 0;
        _tmp$2 = (idx$2 + 1 | 0) & self.capacity_mask;
        continue;
      }
    }
  }
}
function _M0MPB3Map10push__awayGsRPB4JsonE(self, idx, entry) {
  let _tmp = entry.psl + 1 | 0;
  let _tmp$2 = (idx + 1 | 0) & self.capacity_mask;
  let _tmp$3 = entry;
  while (true) {
    const psl = _tmp;
    const idx$2 = _tmp$2;
    const entry$2 = _tmp$3;
    const _tmp$4 = self.entries;
    $bound_check(_tmp$4, idx$2);
    const _bind = _tmp$4[idx$2];
    if (_bind === undefined) {
      entry$2.psl = psl;
      _M0MPB3Map10set__entryGsRPB4JsonE(self, entry$2, idx$2);
      return;
    } else {
      const _Some = _bind;
      const _curr_entry = _Some;
      if (psl > _curr_entry.psl) {
        entry$2.psl = psl;
        _M0MPB3Map10set__entryGsRPB4JsonE(self, entry$2, idx$2);
        _tmp = _curr_entry.psl + 1 | 0;
        _tmp$2 = (idx$2 + 1 | 0) & self.capacity_mask;
        _tmp$3 = _curr_entry;
        continue;
      } else {
        _tmp = psl + 1 | 0;
        _tmp$2 = (idx$2 + 1 | 0) & self.capacity_mask;
        continue;
      }
    }
  }
}
function _M0MPB3Map15set__with__hashGsbE(self, key, value, hash) {
  let _tmp = 0;
  let _tmp$2 = hash & self.capacity_mask;
  while (true) {
    const psl = _tmp;
    const idx = _tmp$2;
    const _tmp$3 = self.entries;
    $bound_check(_tmp$3, idx);
    const _bind = _tmp$3[idx];
    if (_bind === undefined) {
      if (self.size >= self.grow_at) {
        _M0MPB3Map4growGsbE(self);
        _tmp = 0;
        _tmp$2 = hash & self.capacity_mask;
        continue;
      }
      const _bind$2 = self.tail;
      const _bind$3 = undefined;
      const entry = new _M0TPB5EntryGsbE(_bind$2, _bind$3, psl, hash, key, value);
      _M0MPB3Map20add__entry__to__tailGsbE(self, idx, entry);
      return undefined;
    } else {
      const _Some = _bind;
      const _curr_entry = _Some;
      if (_curr_entry.hash === hash && _curr_entry.key === key) {
        _curr_entry.value = value;
        return undefined;
      }
      if (psl > _curr_entry.psl) {
        if (self.size >= self.grow_at) {
          _M0MPB3Map4growGsbE(self);
          _tmp = 0;
          _tmp$2 = hash & self.capacity_mask;
          continue;
        }
        _M0MPB3Map10push__awayGsbE(self, idx, _curr_entry);
        const _bind$2 = self.tail;
        const _bind$3 = undefined;
        const entry = new _M0TPB5EntryGsbE(_bind$2, _bind$3, psl, hash, key, value);
        _M0MPB3Map20add__entry__to__tailGsbE(self, idx, entry);
        return undefined;
      }
      _tmp = psl + 1 | 0;
      _tmp$2 = (idx + 1 | 0) & self.capacity_mask;
      continue;
    }
  }
}
function _M0MPB3Map15set__with__hashGsRPB4JsonE(self, key, value, hash) {
  let _tmp = 0;
  let _tmp$2 = hash & self.capacity_mask;
  while (true) {
    const psl = _tmp;
    const idx = _tmp$2;
    const _tmp$3 = self.entries;
    $bound_check(_tmp$3, idx);
    const _bind = _tmp$3[idx];
    if (_bind === undefined) {
      if (self.size >= self.grow_at) {
        _M0MPB3Map4growGsRPB4JsonE(self);
        _tmp = 0;
        _tmp$2 = hash & self.capacity_mask;
        continue;
      }
      const _bind$2 = self.tail;
      const _bind$3 = undefined;
      const entry = new _M0TPB5EntryGsRPB4JsonE(_bind$2, _bind$3, psl, hash, key, value);
      _M0MPB3Map20add__entry__to__tailGsRPB4JsonE(self, idx, entry);
      return undefined;
    } else {
      const _Some = _bind;
      const _curr_entry = _Some;
      if (_curr_entry.hash === hash && _curr_entry.key === key) {
        _curr_entry.value = value;
        return undefined;
      }
      if (psl > _curr_entry.psl) {
        if (self.size >= self.grow_at) {
          _M0MPB3Map4growGsRPB4JsonE(self);
          _tmp = 0;
          _tmp$2 = hash & self.capacity_mask;
          continue;
        }
        _M0MPB3Map10push__awayGsRPB4JsonE(self, idx, _curr_entry);
        const _bind$2 = self.tail;
        const _bind$3 = undefined;
        const entry = new _M0TPB5EntryGsRPB4JsonE(_bind$2, _bind$3, psl, hash, key, value);
        _M0MPB3Map20add__entry__to__tailGsRPB4JsonE(self, idx, entry);
        return undefined;
      }
      _tmp = psl + 1 | 0;
      _tmp$2 = (idx + 1 | 0) & self.capacity_mask;
      continue;
    }
  }
}
function _M0MPB3Map15set__with__hashGssE(self, key, value, hash) {
  let _tmp = 0;
  let _tmp$2 = hash & self.capacity_mask;
  while (true) {
    const psl = _tmp;
    const idx = _tmp$2;
    const _tmp$3 = self.entries;
    $bound_check(_tmp$3, idx);
    const _bind = _tmp$3[idx];
    if (_bind === undefined) {
      if (self.size >= self.grow_at) {
        _M0MPB3Map4growGssE(self);
        _tmp = 0;
        _tmp$2 = hash & self.capacity_mask;
        continue;
      }
      const _bind$2 = self.tail;
      const _bind$3 = undefined;
      const entry = new _M0TPB5EntryGssE(_bind$2, _bind$3, psl, hash, key, value);
      _M0MPB3Map20add__entry__to__tailGsRPB4JsonE(self, idx, entry);
      return undefined;
    } else {
      const _Some = _bind;
      const _curr_entry = _Some;
      if (_curr_entry.hash === hash && _curr_entry.key === key) {
        _curr_entry.value = value;
        return undefined;
      }
      if (psl > _curr_entry.psl) {
        if (self.size >= self.grow_at) {
          _M0MPB3Map4growGssE(self);
          _tmp = 0;
          _tmp$2 = hash & self.capacity_mask;
          continue;
        }
        _M0MPB3Map10push__awayGsRPB4JsonE(self, idx, _curr_entry);
        const _bind$2 = self.tail;
        const _bind$3 = undefined;
        const entry = new _M0TPB5EntryGssE(_bind$2, _bind$3, psl, hash, key, value);
        _M0MPB3Map20add__entry__to__tailGsRPB4JsonE(self, idx, entry);
        return undefined;
      }
      _tmp = psl + 1 | 0;
      _tmp$2 = (idx + 1 | 0) & self.capacity_mask;
      continue;
    }
  }
}
function _M0MPB3Map4growGsbE(self) {
  const old_head = self.head;
  const new_capacity = self.capacity << 1;
  self.entries = $make_array_len_and_init(new_capacity, undefined);
  self.capacity = new_capacity;
  self.capacity_mask = new_capacity - 1 | 0;
  self.grow_at = _M0FPB21calc__grow__threshold(self.capacity);
  self.size = 0;
  self.head = undefined;
  self.tail = -1;
  let _tmp = old_head;
  while (true) {
    const x = _tmp;
    if (x === undefined) {
      return;
    } else {
      const _Some = x;
      const _x = _Some;
      const _next = _x.next;
      const _key = _x.key;
      const _value = _x.value;
      const _hash = _x.hash;
      _M0MPB3Map15set__with__hashGsbE(self, _key, _value, _hash);
      _tmp = _next;
      continue;
    }
  }
}
function _M0MPB3Map4growGsRPB4JsonE(self) {
  const old_head = self.head;
  const new_capacity = self.capacity << 1;
  self.entries = $make_array_len_and_init(new_capacity, undefined);
  self.capacity = new_capacity;
  self.capacity_mask = new_capacity - 1 | 0;
  self.grow_at = _M0FPB21calc__grow__threshold(self.capacity);
  self.size = 0;
  self.head = undefined;
  self.tail = -1;
  let _tmp = old_head;
  while (true) {
    const x = _tmp;
    if (x === undefined) {
      return;
    } else {
      const _Some = x;
      const _x = _Some;
      const _next = _x.next;
      const _key = _x.key;
      const _value = _x.value;
      const _hash = _x.hash;
      _M0MPB3Map15set__with__hashGsRPB4JsonE(self, _key, _value, _hash);
      _tmp = _next;
      continue;
    }
  }
}
function _M0MPB3Map4growGssE(self) {
  const old_head = self.head;
  const new_capacity = self.capacity << 1;
  self.entries = $make_array_len_and_init(new_capacity, undefined);
  self.capacity = new_capacity;
  self.capacity_mask = new_capacity - 1 | 0;
  self.grow_at = _M0FPB21calc__grow__threshold(self.capacity);
  self.size = 0;
  self.head = undefined;
  self.tail = -1;
  let _tmp = old_head;
  while (true) {
    const x = _tmp;
    if (x === undefined) {
      return;
    } else {
      const _Some = x;
      const _x = _Some;
      const _next = _x.next;
      const _key = _x.key;
      const _value = _x.value;
      const _hash = _x.hash;
      _M0MPB3Map15set__with__hashGssE(self, _key, _value, _hash);
      _tmp = _next;
      continue;
    }
  }
}
function _M0MPB3Map3setGsbE(self, key, value) {
  _M0MPB3Map15set__with__hashGsbE(self, key, value, _M0IP016_24default__implPB4Hash4hashGsE(key));
}
function _M0MPB3Map3setGsRPB4JsonE(self, key, value) {
  _M0MPB3Map15set__with__hashGsRPB4JsonE(self, key, value, _M0IP016_24default__implPB4Hash4hashGsE(key));
}
function _M0MPB3Map3setGssE(self, key, value) {
  _M0MPB3Map15set__with__hashGssE(self, key, value, _M0IP016_24default__implPB4Hash4hashGsE(key));
}
function _M0MPB3Map11from__arrayGsRPB4JsonE(arr) {
  const length = _M0MPC15array9ArrayView6lengthGUsRPB4JsonEE(arr);
  let capacity = _M0MPC13int3Int20next__power__of__two(length);
  if (length > _M0FPB21calc__grow__threshold(capacity)) {
    capacity = Math.imul(capacity, 2) | 0;
  }
  const m = _M0MPB3Map11new_2einnerGsRPB4JsonE(capacity);
  const _bind = arr.end - arr.start | 0;
  let _tmp = 0;
  while (true) {
    const _ = _tmp;
    if (_ < _bind) {
      const e = arr.buf[arr.start + _ | 0];
      _M0MPB3Map3setGsRPB4JsonE(m, e._0, e._1);
      _tmp = _ + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return m;
}
function _M0MPB3Map11from__arrayGsbE(arr) {
  const length = _M0MPC15array9ArrayView6lengthGUsRPB4JsonEE(arr);
  let capacity = _M0MPC13int3Int20next__power__of__two(length);
  if (length > _M0FPB21calc__grow__threshold(capacity)) {
    capacity = Math.imul(capacity, 2) | 0;
  }
  const m = _M0MPB3Map11new_2einnerGsbE(capacity);
  const _bind = arr.end - arr.start | 0;
  let _tmp = 0;
  while (true) {
    const _ = _tmp;
    if (_ < _bind) {
      const e = arr.buf[arr.start + _ | 0];
      _M0MPB3Map3setGsbE(m, e._0, e._1);
      _tmp = _ + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return m;
}
function _M0MPB3Map11from__arrayGssE(arr) {
  const length = _M0MPC15array9ArrayView6lengthGUsRPB4JsonEE(arr);
  let capacity = _M0MPC13int3Int20next__power__of__two(length);
  if (length > _M0FPB21calc__grow__threshold(capacity)) {
    capacity = Math.imul(capacity, 2) | 0;
  }
  const m = _M0MPB3Map11new_2einnerGsRPB4JsonE(capacity);
  const _bind = arr.end - arr.start | 0;
  let _tmp = 0;
  while (true) {
    const _ = _tmp;
    if (_ < _bind) {
      const e = arr.buf[arr.start + _ | 0];
      _M0MPB3Map3setGssE(m, e._0, e._1);
      _tmp = _ + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return m;
}
function _M0MPB3Map3getGsRPB4JsonE(self, key) {
  const hash = _M0IP016_24default__implPB4Hash4hashGsE(key);
  let _tmp = 0;
  let _tmp$2 = hash & self.capacity_mask;
  while (true) {
    const i = _tmp;
    const idx = _tmp$2;
    const _tmp$3 = self.entries;
    $bound_check(_tmp$3, idx);
    const _bind = _tmp$3[idx];
    if (_bind === undefined) {
      return undefined;
    } else {
      const _Some = _bind;
      const _entry = _Some;
      if (_entry.hash === hash && _entry.key === key) {
        return _entry.value;
      }
      if (i > _entry.psl) {
        return undefined;
      }
      _tmp = i + 1 | 0;
      _tmp$2 = (idx + 1 | 0) & self.capacity_mask;
      continue;
    }
  }
}
function _M0MPB3Map3getGssE(self, key) {
  const hash = _M0IP016_24default__implPB4Hash4hashGsE(key);
  let _tmp = 0;
  let _tmp$2 = hash & self.capacity_mask;
  while (true) {
    const i = _tmp;
    const idx = _tmp$2;
    const _tmp$3 = self.entries;
    $bound_check(_tmp$3, idx);
    const _bind = _tmp$3[idx];
    if (_bind === undefined) {
      return undefined;
    } else {
      const _Some = _bind;
      const _entry = _Some;
      if (_entry.hash === hash && _entry.key === key) {
        return _entry.value;
      }
      if (i > _entry.psl) {
        return undefined;
      }
      _tmp = i + 1 | 0;
      _tmp$2 = (idx + 1 | 0) & self.capacity_mask;
      continue;
    }
  }
}
function _M0MPB3Map8containsGsbE(self, key) {
  const hash = _M0IP016_24default__implPB4Hash4hashGsE(key);
  let _tmp = 0;
  let _tmp$2 = hash & self.capacity_mask;
  while (true) {
    const i = _tmp;
    const idx = _tmp$2;
    const _tmp$3 = self.entries;
    $bound_check(_tmp$3, idx);
    const _bind = _tmp$3[idx];
    if (_bind === undefined) {
      return false;
    } else {
      const _Some = _bind;
      const _entry = _Some;
      if (_entry.hash === hash && _entry.key === key) {
        return true;
      }
      if (i > _entry.psl) {
        return false;
      }
      _tmp = i + 1 | 0;
      _tmp$2 = (idx + 1 | 0) & self.capacity_mask;
      continue;
    }
  }
}
function _M0MPB3Map8containsGsRPB4JsonE(self, key) {
  const hash = _M0IP016_24default__implPB4Hash4hashGsE(key);
  let _tmp = 0;
  let _tmp$2 = hash & self.capacity_mask;
  while (true) {
    const i = _tmp;
    const idx = _tmp$2;
    const _tmp$3 = self.entries;
    $bound_check(_tmp$3, idx);
    const _bind = _tmp$3[idx];
    if (_bind === undefined) {
      return false;
    } else {
      const _Some = _bind;
      const _entry = _Some;
      if (_entry.hash === hash && _entry.key === key) {
        return true;
      }
      if (i > _entry.psl) {
        return false;
      }
      _tmp = i + 1 | 0;
      _tmp$2 = (idx + 1 | 0) & self.capacity_mask;
      continue;
    }
  }
}
function _M0MPB3Map8containsGssE(self, key) {
  const hash = _M0IP016_24default__implPB4Hash4hashGsE(key);
  let _tmp = 0;
  let _tmp$2 = hash & self.capacity_mask;
  while (true) {
    const i = _tmp;
    const idx = _tmp$2;
    const _tmp$3 = self.entries;
    $bound_check(_tmp$3, idx);
    const _bind = _tmp$3[idx];
    if (_bind === undefined) {
      return false;
    } else {
      const _Some = _bind;
      const _entry = _Some;
      if (_entry.hash === hash && _entry.key === key) {
        return true;
      }
      if (i > _entry.psl) {
        return false;
      }
      _tmp = i + 1 | 0;
      _tmp$2 = (idx + 1 | 0) & self.capacity_mask;
      continue;
    }
  }
}
function _M0MPB3Map4iterGsRPB4JsonE(self) {
  const curr_entry = new _M0TPB8MutLocalGORPB5EntryGsRPB4JsonEE(self.head);
  return _M0MPB4Iter3newGUsRPB4JsonEE(() => {
    const _bind = curr_entry.val;
    if (_bind === undefined) {
      return undefined;
    } else {
      const _Some = _bind;
      const _x = _Some;
      const _key = _x.key;
      const _value = _x.value;
      const _next = _x.next;
      curr_entry.val = _next;
      return { _0: _key, _1: _value };
    }
  });
}
function _M0MPB3Map5iter2GsRPB4JsonE(self) {
  return _M0MPB3Map4iterGsRPB4JsonE(self);
}
function _M0IPC14byte4BytePB2Eq5equal(self, that) {
  return self === that;
}
function _M0MPC14json4Json6string(string) {
  return new _M0DTPB4Json6String(string);
}
function _M0MPC14json4Json7boolean(boolean) {
  return boolean ? _M0DTPB4Json4True__ : _M0DTPB4Json5False__;
}
function _M0MPC14json4Json6object(object) {
  return new _M0DTPB4Json6Object(object);
}
function _M0IPC13int3IntPB6ToJson8to__json(self) {
  return _M0MPC14json4Json6number(self + 0, undefined);
}
function _M0MPB5Iter24nextGsRPB4JsonE(self) {
  return _M0MPB4Iter4nextGUsRPB4JsonEE(self);
}
function _M0MPC16string6String20unsafe__charcode__at(self, idx) {
  return self.charCodeAt(idx);
}
function _M0MPC14byte4Byte9to__int64(self) {
  return BigInt.asUintN(64, BigInt(self));
}
function _M0MPB6Hasher15combine__string(self, value) {
  const _bind = value.length;
  let _tmp = 0;
  while (true) {
    const i = _tmp;
    if (i < _bind) {
      _M0MPB6Hasher13combine__uint(self, value.charCodeAt(i));
      _tmp = i + 1 | 0;
      continue;
    } else {
      return;
    }
  }
}
function _M0IPC16string6StringPB4Hash13hash__combine(self, hasher) {
  _M0MPB6Hasher15combine__string(hasher, self);
}
function _M0MPC16double6Double7to__int(self) {
  return self !== self ? 0 : self >= 2147483647 ? 2147483647 : self <= -2147483648 ? -2147483648 : self | 0;
}
function _M0MPC14char4Char10utf16__len(self) {
  const code = self;
  return code <= 65535 ? 1 : 2;
}
function _M0MPC15bytes9BytesView6length(self) {
  return self.end - self.start | 0;
}
function _M0MPC15bytes5Bytes12view_2einner(self, start, end) {
  const len = self.length;
  let end$2;
  if (end === undefined) {
    end$2 = len;
  } else {
    const _Some = end;
    const _end = _Some;
    end$2 = _end < 0 ? len + _end | 0 : _end;
  }
  const start$2 = start < 0 ? len + start | 0 : start;
  if (start$2 >= 0 && (start$2 <= end$2 && end$2 <= len)) {
    const _bind = end$2 - start$2 | 0;
    return new _M0TPC15bytes9BytesView(self, start$2, start$2 + _bind | 0);
  } else {
    return _M0FPC15abort5abortGRP411cogna_2ddev5cogna4core6config11ConfigErrorE("Invalid index for View");
  }
}
function _M0MPC15array5Array2atGRPB4JsonE(self, index) {
  const len = self.length;
  if (index >= 0 && index < len) {
    $bound_check(self, index);
    return self[index];
  } else {
    return $panic();
  }
}
function _M0MPC15array5Array9is__emptyGsE(self) {
  return self.length === 0;
}
function _M0FPC28internal7strconv9base__errGUiRPC16string10StringViewbEE() {
  return new _M0DTPC16result6ResultGUiRPC16string10StringViewbERPB7FailureE3Err(new _M0DTPC15error5Error48moonbitlang_2fcore_2fbuiltin_2eFailure_2eFailure(_M0FPC28internal7strconv14base__err__str));
}
function _M0FPC28internal7strconv25check__and__consume__base(view, base) {
  if (base === 0) {
    _L: {
      let rest;
      _L$2: {
        let rest$2;
        _L$3: {
          let rest$3;
          _L$4: {
            if (_M0MPC16string6String24char__length__ge_2einner(view.str, 2, view.start, view.end)) {
              const _x = _M0MPC16string6String16unsafe__char__at(view.str, _M0MPC16string6String29offset__of__nth__char_2einner(view.str, 0, view.start, view.end));
              if (_x === 48) {
                const _x$2 = _M0MPC16string6String16unsafe__char__at(view.str, _M0MPC16string6String29offset__of__nth__char_2einner(view.str, 1, view.start, view.end));
                switch (_x$2) {
                  case 120: {
                    const _tmp = view.str;
                    const _bind = _M0MPC16string6String29offset__of__nth__char_2einner(view.str, 2, view.start, view.end);
                    let _tmp$2;
                    if (_bind === undefined) {
                      _tmp$2 = view.end;
                    } else {
                      const _Some = _bind;
                      _tmp$2 = _Some;
                    }
                    const _x$3 = new _M0TPC16string10StringView(_tmp, _tmp$2, view.end);
                    rest$3 = _x$3;
                    break _L$4;
                  }
                  case 88: {
                    const _tmp$3 = view.str;
                    const _bind$2 = _M0MPC16string6String29offset__of__nth__char_2einner(view.str, 2, view.start, view.end);
                    let _tmp$4;
                    if (_bind$2 === undefined) {
                      _tmp$4 = view.end;
                    } else {
                      const _Some = _bind$2;
                      _tmp$4 = _Some;
                    }
                    const _x$4 = new _M0TPC16string10StringView(_tmp$3, _tmp$4, view.end);
                    rest$3 = _x$4;
                    break _L$4;
                  }
                  case 111: {
                    const _tmp$5 = view.str;
                    const _bind$3 = _M0MPC16string6String29offset__of__nth__char_2einner(view.str, 2, view.start, view.end);
                    let _tmp$6;
                    if (_bind$3 === undefined) {
                      _tmp$6 = view.end;
                    } else {
                      const _Some = _bind$3;
                      _tmp$6 = _Some;
                    }
                    const _x$5 = new _M0TPC16string10StringView(_tmp$5, _tmp$6, view.end);
                    rest$2 = _x$5;
                    break _L$3;
                  }
                  case 79: {
                    const _tmp$7 = view.str;
                    const _bind$4 = _M0MPC16string6String29offset__of__nth__char_2einner(view.str, 2, view.start, view.end);
                    let _tmp$8;
                    if (_bind$4 === undefined) {
                      _tmp$8 = view.end;
                    } else {
                      const _Some = _bind$4;
                      _tmp$8 = _Some;
                    }
                    const _x$6 = new _M0TPC16string10StringView(_tmp$7, _tmp$8, view.end);
                    rest$2 = _x$6;
                    break _L$3;
                  }
                  case 98: {
                    const _tmp$9 = view.str;
                    const _bind$5 = _M0MPC16string6String29offset__of__nth__char_2einner(view.str, 2, view.start, view.end);
                    let _tmp$10;
                    if (_bind$5 === undefined) {
                      _tmp$10 = view.end;
                    } else {
                      const _Some = _bind$5;
                      _tmp$10 = _Some;
                    }
                    const _x$7 = new _M0TPC16string10StringView(_tmp$9, _tmp$10, view.end);
                    rest = _x$7;
                    break _L$2;
                  }
                  case 66: {
                    const _tmp$11 = view.str;
                    const _bind$6 = _M0MPC16string6String29offset__of__nth__char_2einner(view.str, 2, view.start, view.end);
                    let _tmp$12;
                    if (_bind$6 === undefined) {
                      _tmp$12 = view.end;
                    } else {
                      const _Some = _bind$6;
                      _tmp$12 = _Some;
                    }
                    const _x$8 = new _M0TPC16string10StringView(_tmp$11, _tmp$12, view.end);
                    rest = _x$8;
                    break _L$2;
                  }
                  default: {
                    break _L;
                  }
                }
              } else {
                break _L;
              }
            } else {
              break _L;
            }
          }
          return new _M0DTPC16result6ResultGUiRPC16string10StringViewbERPC15error5ErrorE2Ok({ _0: 16, _1: rest$3, _2: true });
        }
        return new _M0DTPC16result6ResultGUiRPC16string10StringViewbERPC15error5ErrorE2Ok({ _0: 8, _1: rest$2, _2: true });
      }
      return new _M0DTPC16result6ResultGUiRPC16string10StringViewbERPC15error5ErrorE2Ok({ _0: 2, _1: rest, _2: true });
    }
    return new _M0DTPC16result6ResultGUiRPC16string10StringViewbERPC15error5ErrorE2Ok({ _0: 10, _1: view, _2: false });
  } else {
    _L: {
      let rest;
      _L$2: {
        let rest$2;
        _L$3: {
          let rest$3;
          _L$4: {
            if (_M0MPC16string6String24char__length__ge_2einner(view.str, 2, view.start, view.end)) {
              const _x = _M0MPC16string6String16unsafe__char__at(view.str, _M0MPC16string6String29offset__of__nth__char_2einner(view.str, 0, view.start, view.end));
              if (_x === 48) {
                const _x$2 = _M0MPC16string6String16unsafe__char__at(view.str, _M0MPC16string6String29offset__of__nth__char_2einner(view.str, 1, view.start, view.end));
                switch (_x$2) {
                  case 120: {
                    const _tmp = view.str;
                    const _bind = _M0MPC16string6String29offset__of__nth__char_2einner(view.str, 2, view.start, view.end);
                    let _tmp$2;
                    if (_bind === undefined) {
                      _tmp$2 = view.end;
                    } else {
                      const _Some = _bind;
                      _tmp$2 = _Some;
                    }
                    const _x$3 = new _M0TPC16string10StringView(_tmp, _tmp$2, view.end);
                    if (base === 16) {
                      rest$3 = _x$3;
                      break _L$4;
                    } else {
                      break _L;
                    }
                  }
                  case 88: {
                    const _tmp$3 = view.str;
                    const _bind$2 = _M0MPC16string6String29offset__of__nth__char_2einner(view.str, 2, view.start, view.end);
                    let _tmp$4;
                    if (_bind$2 === undefined) {
                      _tmp$4 = view.end;
                    } else {
                      const _Some = _bind$2;
                      _tmp$4 = _Some;
                    }
                    const _x$4 = new _M0TPC16string10StringView(_tmp$3, _tmp$4, view.end);
                    if (base === 16) {
                      rest$3 = _x$4;
                      break _L$4;
                    } else {
                      break _L;
                    }
                  }
                  case 111: {
                    const _tmp$5 = view.str;
                    const _bind$3 = _M0MPC16string6String29offset__of__nth__char_2einner(view.str, 2, view.start, view.end);
                    let _tmp$6;
                    if (_bind$3 === undefined) {
                      _tmp$6 = view.end;
                    } else {
                      const _Some = _bind$3;
                      _tmp$6 = _Some;
                    }
                    const _x$5 = new _M0TPC16string10StringView(_tmp$5, _tmp$6, view.end);
                    if (base === 8) {
                      rest$2 = _x$5;
                      break _L$3;
                    } else {
                      break _L;
                    }
                  }
                  case 79: {
                    const _tmp$7 = view.str;
                    const _bind$4 = _M0MPC16string6String29offset__of__nth__char_2einner(view.str, 2, view.start, view.end);
                    let _tmp$8;
                    if (_bind$4 === undefined) {
                      _tmp$8 = view.end;
                    } else {
                      const _Some = _bind$4;
                      _tmp$8 = _Some;
                    }
                    const _x$6 = new _M0TPC16string10StringView(_tmp$7, _tmp$8, view.end);
                    if (base === 8) {
                      rest$2 = _x$6;
                      break _L$3;
                    } else {
                      break _L;
                    }
                  }
                  case 98: {
                    const _tmp$9 = view.str;
                    const _bind$5 = _M0MPC16string6String29offset__of__nth__char_2einner(view.str, 2, view.start, view.end);
                    let _tmp$10;
                    if (_bind$5 === undefined) {
                      _tmp$10 = view.end;
                    } else {
                      const _Some = _bind$5;
                      _tmp$10 = _Some;
                    }
                    const _x$7 = new _M0TPC16string10StringView(_tmp$9, _tmp$10, view.end);
                    if (base === 2) {
                      rest = _x$7;
                      break _L$2;
                    } else {
                      break _L;
                    }
                  }
                  case 66: {
                    const _tmp$11 = view.str;
                    const _bind$6 = _M0MPC16string6String29offset__of__nth__char_2einner(view.str, 2, view.start, view.end);
                    let _tmp$12;
                    if (_bind$6 === undefined) {
                      _tmp$12 = view.end;
                    } else {
                      const _Some = _bind$6;
                      _tmp$12 = _Some;
                    }
                    const _x$8 = new _M0TPC16string10StringView(_tmp$11, _tmp$12, view.end);
                    if (base === 2) {
                      rest = _x$8;
                      break _L$2;
                    } else {
                      break _L;
                    }
                  }
                  default: {
                    break _L;
                  }
                }
              } else {
                break _L;
              }
            } else {
              break _L;
            }
          }
          return new _M0DTPC16result6ResultGUiRPC16string10StringViewbERPC15error5ErrorE2Ok({ _0: 16, _1: rest$3, _2: true });
        }
        return new _M0DTPC16result6ResultGUiRPC16string10StringViewbERPC15error5ErrorE2Ok({ _0: 8, _1: rest$2, _2: true });
      }
      return new _M0DTPC16result6ResultGUiRPC16string10StringViewbERPC15error5ErrorE2Ok({ _0: 2, _1: rest, _2: true });
    }
    return base >= 2 && base <= 36 ? new _M0DTPC16result6ResultGUiRPC16string10StringViewbERPC15error5ErrorE2Ok({ _0: base, _1: view, _2: false }) : _M0FPC28internal7strconv9base__errGUiRPC16string10StringViewbEE();
  }
}
function _M0FPC28internal7strconv10range__errGuE() {
  return new _M0DTPC16result6ResultGuRPB7FailureE3Err(new _M0DTPC15error5Error48moonbitlang_2fcore_2fbuiltin_2eFailure_2eFailure(_M0FPC28internal7strconv15range__err__str));
}
function _M0FPC28internal7strconv11syntax__errGiE() {
  return new _M0DTPC16result6ResultGiRPB7FailureE3Err(new _M0DTPC15error5Error48moonbitlang_2fcore_2fbuiltin_2eFailure_2eFailure(_M0FPC28internal7strconv16syntax__err__str));
}
function _M0FPC28internal7strconv11syntax__errGuE() {
  return new _M0DTPC16result6ResultGuRPB7FailureE3Err(new _M0DTPC15error5Error48moonbitlang_2fcore_2fbuiltin_2eFailure_2eFailure(_M0FPC28internal7strconv16syntax__err__str));
}
function _M0FPC28internal7strconv11syntax__errGlE() {
  return new _M0DTPC16result6ResultGlRPB7FailureE3Err(new _M0DTPC15error5Error48moonbitlang_2fcore_2fbuiltin_2eFailure_2eFailure(_M0FPC28internal7strconv16syntax__err__str));
}
function _M0FPC28internal7strconv11syntax__errGdE() {
  return new _M0DTPC16result6ResultGdRPB7FailureE3Err(new _M0DTPC15error5Error48moonbitlang_2fcore_2fbuiltin_2eFailure_2eFailure(_M0FPC28internal7strconv16syntax__err__str));
}
function _M0FPC28internal7strconv11syntax__errGORPC28internal7strconv6NumberE() {
  return new _M0DTPC16result6ResultGORPC28internal7strconv6NumberRPB7FailureE3Err(new _M0DTPC15error5Error48moonbitlang_2fcore_2fbuiltin_2eFailure_2eFailure(_M0FPC28internal7strconv16syntax__err__str));
}
function _M0EPC16string10StringViewPC28internal7strconv12fold__digitsGmE(self, init, f) {
  let ret = init;
  let len = 0;
  let str = self;
  while (true) {
    const _bind = str;
    if (_M0MPC16string6String24char__length__ge_2einner(_bind.str, 1, _bind.start, _bind.end)) {
      const _ch = _M0MPC16string6String16unsafe__char__at(_bind.str, _M0MPC16string6String29offset__of__nth__char_2einner(_bind.str, 0, _bind.start, _bind.end));
      const _tmp = _bind.str;
      const _bind$2 = _M0MPC16string6String29offset__of__nth__char_2einner(_bind.str, 1, _bind.start, _bind.end);
      let _tmp$2;
      if (_bind$2 === undefined) {
        _tmp$2 = _bind.end;
      } else {
        const _Some = _bind$2;
        _tmp$2 = _Some;
      }
      const _x = new _M0TPC16string10StringView(_tmp, _tmp$2, _bind.end);
      if (_ch >= 48 && _ch <= 57) {
        len = len + 1 | 0;
        ret = f(_ch - 48 | 0, ret);
      } else {
        if (_ch !== 95) {
          break;
        }
      }
      str = _x;
      continue;
    } else {
      break;
    }
  }
  return { _0: str, _1: ret, _2: len };
}
function _M0FPC28internal7strconv13parse__digits(s, x) {
  return _M0EPC16string10StringViewPC28internal7strconv12fold__digitsGmE(s, x, (digit, acc) => BigInt.asUintN(64, BigInt.asUintN(64, acc * 10n) + BigInt.asUintN(64, BigInt(digit >>> 0))));
}
function _M0FPC28internal7strconv20try__parse__19digits(s, x) {
  let x$2 = x;
  let len = 0;
  let _tmp = s;
  while (true) {
    const s$2 = _tmp;
    let s$3;
    _L: {
      if (_M0MPC16string6String24char__length__ge_2einner(s$2.str, 1, s$2.start, s$2.end)) {
        const _x = _M0MPC16string6String16unsafe__char__at(s$2.str, _M0MPC16string6String29offset__of__nth__char_2einner(s$2.str, 0, s$2.start, s$2.end));
        if (_x >= 48 && _x <= 57) {
          const _tmp$2 = s$2.str;
          const _bind = _M0MPC16string6String29offset__of__nth__char_2einner(s$2.str, 1, s$2.start, s$2.end);
          let _tmp$3;
          if (_bind === undefined) {
            _tmp$3 = s$2.end;
          } else {
            const _Some = _bind;
            _tmp$3 = _Some;
          }
          const _x$2 = new _M0TPC16string10StringView(_tmp$2, _tmp$3, s$2.end);
          if (BigInt.asUintN(64, x$2) < BigInt.asUintN(64, _M0FPC28internal7strconv17min__19digit__int)) {
            len = len + 1 | 0;
            x$2 = BigInt.asUintN(64, BigInt.asUintN(64, x$2 * 10n) + BigInt.asUintN(64, BigInt((_x - 48 | 0) >>> 0)));
            _tmp = _x$2;
            continue;
          } else {
            s$3 = s$2;
            break _L;
          }
        } else {
          if (_x === 95) {
            const _tmp$2 = s$2.str;
            const _bind = _M0MPC16string6String29offset__of__nth__char_2einner(s$2.str, 1, s$2.start, s$2.end);
            let _tmp$3;
            if (_bind === undefined) {
              _tmp$3 = s$2.end;
            } else {
              const _Some = _bind;
              _tmp$3 = _Some;
            }
            const _x$2 = new _M0TPC16string10StringView(_tmp$2, _tmp$3, s$2.end);
            _tmp = _x$2;
            continue;
          } else {
            s$3 = s$2;
            break _L;
          }
        }
      } else {
        s$3 = s$2;
        break _L;
      }
    }
    return { _0: s$3, _1: x$2, _2: len };
  }
}
function _M0FPC28internal7strconv17parse__scientific(s) {
  let s$2 = s;
  let neg_exp = false;
  let rest;
  let ch;
  _L: {
    _L$2: {
      const _bind = s$2;
      if (_M0MPC16string6String24char__length__ge_2einner(_bind.str, 1, _bind.start, _bind.end)) {
        const _x = _M0MPC16string6String16unsafe__char__at(_bind.str, _M0MPC16string6String29offset__of__nth__char_2einner(_bind.str, 0, _bind.start, _bind.end));
        switch (_x) {
          case 43: {
            const _tmp = _bind.str;
            const _bind$2 = _M0MPC16string6String29offset__of__nth__char_2einner(_bind.str, 1, _bind.start, _bind.end);
            let _tmp$2;
            if (_bind$2 === undefined) {
              _tmp$2 = _bind.end;
            } else {
              const _Some = _bind$2;
              _tmp$2 = _Some;
            }
            const _x$2 = new _M0TPC16string10StringView(_tmp, _tmp$2, _bind.end);
            rest = _x$2;
            ch = _x;
            break _L$2;
          }
          case 45: {
            const _tmp$3 = _bind.str;
            const _bind$3 = _M0MPC16string6String29offset__of__nth__char_2einner(_bind.str, 1, _bind.start, _bind.end);
            let _tmp$4;
            if (_bind$3 === undefined) {
              _tmp$4 = _bind.end;
            } else {
              const _Some = _bind$3;
              _tmp$4 = _Some;
            }
            const _x$3 = new _M0TPC16string10StringView(_tmp$3, _tmp$4, _bind.end);
            rest = _x$3;
            ch = _x;
            break _L$2;
          }
        }
      }
      break _L;
    }
    neg_exp = ch === 45;
    s$2 = rest;
  }
  _L$2: {
    const _bind = s$2;
    if (_M0MPC16string6String24char__length__ge_2einner(_bind.str, 1, _bind.start, _bind.end)) {
      const _x = _M0MPC16string6String16unsafe__char__at(_bind.str, _M0MPC16string6String29offset__of__nth__char_2einner(_bind.str, 0, _bind.start, _bind.end));
      if (_x >= 48 && _x <= 57) {
        const _bind$2 = _M0EPC16string10StringViewPC28internal7strconv12fold__digitsGmE(s$2, _M0FPC28internal7strconv17parse__scientificN8exp__numS240, (digit, exp_num) => BigInt.asIntN(64, exp_num) < BigInt.asIntN(64, 65536n) ? BigInt.asUintN(64, BigInt.asUintN(64, 10n * exp_num) + BigInt.asUintN(64, BigInt(digit))) : exp_num);
        const _s = _bind$2._0;
        const _exp_num = _bind$2._1;
        return neg_exp ? { _0: _s, _1: BigInt.asUintN(64, -_exp_num) } : { _0: _s, _1: _exp_num };
      } else {
        break _L$2;
      }
    } else {
      break _L$2;
    }
  }
  return undefined;
}
function _M0FPC28internal7strconv13parse__number(s) {
  let s$2;
  let negative;
  _L: {
    let rest;
    _L$2: {
      if (_M0MPC16string6String24char__length__ge_2einner(s.str, 1, s.start, s.end)) {
        const _x = _M0MPC16string6String16unsafe__char__at(s.str, _M0MPC16string6String29offset__of__nth__char_2einner(s.str, 0, s.start, s.end));
        switch (_x) {
          case 45: {
            const _tmp = s.str;
            const _bind = _M0MPC16string6String29offset__of__nth__char_2einner(s.str, 1, s.start, s.end);
            let _tmp$2;
            if (_bind === undefined) {
              _tmp$2 = s.end;
            } else {
              const _Some = _bind;
              _tmp$2 = _Some;
            }
            const _x$2 = new _M0TPC16string10StringView(_tmp, _tmp$2, s.end);
            s$2 = _x$2;
            negative = true;
            break _L;
          }
          case 43: {
            const _tmp$3 = s.str;
            const _bind$2 = _M0MPC16string6String29offset__of__nth__char_2einner(s.str, 1, s.start, s.end);
            let _tmp$4;
            if (_bind$2 === undefined) {
              _tmp$4 = s.end;
            } else {
              const _Some = _bind$2;
              _tmp$4 = _Some;
            }
            const _x$3 = new _M0TPC16string10StringView(_tmp$3, _tmp$4, s.end);
            rest = _x$3;
            break _L$2;
          }
          default: {
            rest = s;
            break _L$2;
          }
        }
      } else {
        rest = s;
        break _L$2;
      }
    }
    s$2 = rest;
    negative = false;
    break _L;
  }
  if (_M0MPC16string10StringView9is__empty(s$2)) {
    return new _M0DTPC16result6ResultGORPC28internal7strconv6NumberRPC15error5ErrorE2Ok(undefined);
  }
  const _bind = _M0FPC28internal7strconv13parse__digits(s$2, 0n);
  const _s = _bind._0;
  const _mantissa = _bind._1;
  const _consumed = _bind._2;
  let mantissa = _mantissa;
  let s$3 = _s;
  let n_digits = _consumed;
  let n_after_dot = 0;
  let exponent = 0n;
  const _bind$2 = s$3;
  if (_M0MPC16string6String24char__length__ge_2einner(_bind$2.str, 1, _bind$2.start, _bind$2.end)) {
    const _x = _M0MPC16string6String16unsafe__char__at(_bind$2.str, _M0MPC16string6String29offset__of__nth__char_2einner(_bind$2.str, 0, _bind$2.start, _bind$2.end));
    if (_x === 46) {
      const _tmp = _bind$2.str;
      const _bind$3 = _M0MPC16string6String29offset__of__nth__char_2einner(_bind$2.str, 1, _bind$2.start, _bind$2.end);
      let _tmp$2;
      if (_bind$3 === undefined) {
        _tmp$2 = _bind$2.end;
      } else {
        const _Some = _bind$3;
        _tmp$2 = _Some;
      }
      const _x$2 = new _M0TPC16string10StringView(_tmp, _tmp$2, _bind$2.end);
      s$3 = _x$2;
      const _bind$4 = _M0FPC28internal7strconv13parse__digits(s$3, mantissa);
      const _new_s = _bind$4._0;
      const _new_mantissa = _bind$4._1;
      const _consumed_digit = _bind$4._2;
      s$3 = _new_s;
      mantissa = _new_mantissa;
      n_after_dot = _consumed_digit;
      exponent = BigInt.asUintN(64, -BigInt.asUintN(64, BigInt(n_after_dot)));
    }
  }
  n_digits = n_digits + n_after_dot | 0;
  if (n_digits === 0) {
    return new _M0DTPC16result6ResultGORPC28internal7strconv6NumberRPC15error5ErrorE2Ok(undefined);
  }
  let rest;
  _L$2: {
    _L$3: {
      const _bind$3 = s$3;
      if (_M0MPC16string6String24char__length__ge_2einner(_bind$3.str, 1, _bind$3.start, _bind$3.end)) {
        const _x = _M0MPC16string6String16unsafe__char__at(_bind$3.str, _M0MPC16string6String29offset__of__nth__char_2einner(_bind$3.str, 0, _bind$3.start, _bind$3.end));
        switch (_x) {
          case 101: {
            const _tmp = _bind$3.str;
            const _bind$4 = _M0MPC16string6String29offset__of__nth__char_2einner(_bind$3.str, 1, _bind$3.start, _bind$3.end);
            let _tmp$2;
            if (_bind$4 === undefined) {
              _tmp$2 = _bind$3.end;
            } else {
              const _Some = _bind$4;
              _tmp$2 = _Some;
            }
            const _x$2 = new _M0TPC16string10StringView(_tmp, _tmp$2, _bind$3.end);
            rest = _x$2;
            break _L$3;
          }
          case 69: {
            const _tmp$3 = _bind$3.str;
            const _bind$5 = _M0MPC16string6String29offset__of__nth__char_2einner(_bind$3.str, 1, _bind$3.start, _bind$3.end);
            let _tmp$4;
            if (_bind$5 === undefined) {
              _tmp$4 = _bind$3.end;
            } else {
              const _Some = _bind$5;
              _tmp$4 = _Some;
            }
            const _x$3 = new _M0TPC16string10StringView(_tmp$3, _tmp$4, _bind$3.end);
            rest = _x$3;
            break _L$3;
          }
        }
      }
      break _L$2;
    }
    const _bind$3 = _M0FPC28internal7strconv17parse__scientific(rest);
    let _bind$4;
    if (_bind$3 === undefined) {
      return new _M0DTPC16result6ResultGORPC28internal7strconv6NumberRPC15error5ErrorE2Ok(undefined);
    } else {
      const _Some = _bind$3;
      _bind$4 = _Some;
    }
    const _new_s = _bind$4._0;
    const _exp_number = _bind$4._1;
    s$3 = _new_s;
    exponent = BigInt.asUintN(64, exponent + _exp_number);
  }
  const _bind$3 = s$3;
  if (_M0MPC16string6String24char__length__eq_2einner(_bind$3.str, 0, _bind$3.start, _bind$3.end)) {
    if (n_digits <= 19) {
      return new _M0DTPC16result6ResultGORPC28internal7strconv6NumberRPC15error5ErrorE2Ok(new _M0TPC28internal7strconv6Number(exponent, mantissa, negative, false));
    }
    n_digits = n_digits - 19 | 0;
    let many_digits = false;
    let _tmp = s;
    while (true) {
      const s$4 = _tmp;
      _L$3: {
        let rest$2;
        let ch;
        _L$4: {
          if (_M0MPC16string6String24char__length__ge_2einner(s$4.str, 1, s$4.start, s$4.end)) {
            const _x = _M0MPC16string6String16unsafe__char__at(s$4.str, _M0MPC16string6String29offset__of__nth__char_2einner(s$4.str, 0, s$4.start, s$4.end));
            switch (_x) {
              case 48: {
                const _tmp$2 = s$4.str;
                const _bind$4 = _M0MPC16string6String29offset__of__nth__char_2einner(s$4.str, 1, s$4.start, s$4.end);
                let _tmp$3;
                if (_bind$4 === undefined) {
                  _tmp$3 = s$4.end;
                } else {
                  const _Some = _bind$4;
                  _tmp$3 = _Some;
                }
                const _x$2 = new _M0TPC16string10StringView(_tmp$2, _tmp$3, s$4.end);
                rest$2 = _x$2;
                ch = _x;
                break _L$4;
              }
              case 46: {
                const _tmp$4 = s$4.str;
                const _bind$5 = _M0MPC16string6String29offset__of__nth__char_2einner(s$4.str, 1, s$4.start, s$4.end);
                let _tmp$5;
                if (_bind$5 === undefined) {
                  _tmp$5 = s$4.end;
                } else {
                  const _Some = _bind$5;
                  _tmp$5 = _Some;
                }
                const _x$3 = new _M0TPC16string10StringView(_tmp$4, _tmp$5, s$4.end);
                rest$2 = _x$3;
                ch = _x;
                break _L$4;
              }
              default: {
                break _L$3;
              }
            }
          } else {
            break _L$3;
          }
        }
        const _tmp$2 = n_digits;
        if (2 === 0) {
          $panic();
        }
        n_digits = _tmp$2 - ((ch - 46 | 0) / 2 | 0) | 0;
        _tmp = rest$2;
        continue;
      }
      break;
    }
    let mantissa$2 = mantissa;
    if (n_digits > 0) {
      many_digits = true;
      mantissa$2 = 0n;
      const _bind$4 = _M0FPC28internal7strconv20try__parse__19digits(s, mantissa$2);
      const _s$2 = _bind$4._0;
      const _new_mantissa = _bind$4._1;
      const _consumed_digit = _bind$4._2;
      mantissa$2 = _new_mantissa;
      let _tmp$2;
      if (BigInt.asUintN(64, mantissa$2) >= BigInt.asUintN(64, _M0FPC28internal7strconv17min__19digit__int)) {
        _tmp$2 = _consumed_digit;
      } else {
        if (_M0MPC16string6String24char__length__ge_2einner(_s$2.str, 1, _s$2.start, _s$2.end)) {
          const _tmp$3 = _s$2.str;
          const _bind$5 = _M0MPC16string6String29offset__of__nth__char_2einner(_s$2.str, 1, _s$2.start, _s$2.end);
          let _tmp$4;
          if (_bind$5 === undefined) {
            _tmp$4 = _s$2.end;
          } else {
            const _Some = _bind$5;
            _tmp$4 = _Some;
          }
          const _x = new _M0TPC16string10StringView(_tmp$3, _tmp$4, _s$2.end);
          const _bind$6 = _M0FPC28internal7strconv20try__parse__19digits(_x, mantissa$2);
          const _new_mantissa$2 = _bind$6._1;
          const _consumed_digit$2 = _bind$6._2;
          mantissa$2 = _new_mantissa$2;
          _tmp$2 = _consumed_digit$2;
        } else {
          return new _M0DTPC16result6ResultGORPC28internal7strconv6NumberRPC15error5ErrorE2Ok(undefined);
        }
      }
      exponent = BigInt.asUintN(64, BigInt(_tmp$2));
      exponent = BigInt.asUintN(64, exponent + _M0FPC28internal7strconv13parse__numberN11exp__numberS221);
    }
    return new _M0DTPC16result6ResultGORPC28internal7strconv6NumberRPC15error5ErrorE2Ok(new _M0TPC28internal7strconv6Number(exponent, mantissa$2, negative, many_digits));
  } else {
    return _M0FPC28internal7strconv11syntax__errGORPC28internal7strconv6NumberE();
  }
}
function _M0FPC28internal7strconv15parse__inf__nan(rest) {
  let pos;
  let rest$2;
  _L: {
    let rest$3;
    _L$2: {
      if (_M0MPC16string6String24char__length__ge_2einner(rest.str, 1, rest.start, rest.end)) {
        const _x = _M0MPC16string6String16unsafe__char__at(rest.str, _M0MPC16string6String29offset__of__nth__char_2einner(rest.str, 0, rest.start, rest.end));
        switch (_x) {
          case 45: {
            const _tmp = rest.str;
            const _bind = _M0MPC16string6String29offset__of__nth__char_2einner(rest.str, 1, rest.start, rest.end);
            let _tmp$2;
            if (_bind === undefined) {
              _tmp$2 = rest.end;
            } else {
              const _Some = _bind;
              _tmp$2 = _Some;
            }
            const _x$2 = new _M0TPC16string10StringView(_tmp, _tmp$2, rest.end);
            pos = false;
            rest$2 = _x$2;
            break _L;
          }
          case 43: {
            const _tmp$3 = rest.str;
            const _bind$2 = _M0MPC16string6String29offset__of__nth__char_2einner(rest.str, 1, rest.start, rest.end);
            let _tmp$4;
            if (_bind$2 === undefined) {
              _tmp$4 = rest.end;
            } else {
              const _Some = _bind$2;
              _tmp$4 = _Some;
            }
            const _x$3 = new _M0TPC16string10StringView(_tmp$3, _tmp$4, rest.end);
            rest$3 = _x$3;
            break _L$2;
          }
          default: {
            rest$3 = rest;
            break _L$2;
          }
        }
      } else {
        rest$3 = rest;
        break _L$2;
      }
    }
    pos = true;
    rest$2 = rest$3;
    break _L;
  }
  const _data = _M0MPC16string10StringView4data(rest$2);
  const _start = _M0MPC16string10StringView13start__offset(rest$2);
  const _end = _start + _M0MPC16string10StringView6length(rest$2) | 0;
  let _cursor = _start;
  let accept_state = -1;
  let match_end = -1;
  _L$2: {
    _L$3: {
      if ((_cursor + 2 | 0) < _end) {
        _L$4: {
          _L$5: {
            const next_char = _M0MPC16string6String20unsafe__charcode__at(_data, _cursor);
            _cursor = _cursor + 1 | 0;
            if (next_char < 79) {
              if (next_char < 74) {
                if (next_char < 73) {
                  break _L$2;
                } else {
                  break _L$4;
                }
              } else {
                if (next_char > 77) {
                  break _L$5;
                } else {
                  break _L$2;
                }
              }
            } else {
              if (next_char > 104) {
                if (next_char < 110) {
                  if (next_char < 106) {
                    break _L$4;
                  } else {
                    break _L$2;
                  }
                } else {
                  if (next_char > 110) {
                    break _L$2;
                  } else {
                    break _L$5;
                  }
                }
              } else {
                break _L$2;
              }
            }
          }
          _L$6: {
            const next_char = _M0MPC16string6String20unsafe__charcode__at(_data, _cursor);
            _cursor = _cursor + 1 | 0;
            if (next_char < 66) {
              if (next_char < 65) {
                break _L$2;
              } else {
                break _L$6;
              }
            } else {
              if (next_char > 96) {
                if (next_char < 98) {
                  break _L$6;
                } else {
                  break _L$2;
                }
              } else {
                break _L$2;
              }
            }
          }
          _L$7: {
            const next_char = _M0MPC16string6String20unsafe__charcode__at(_data, _cursor);
            _cursor = _cursor + 1 | 0;
            if (next_char < 79) {
              if (next_char < 78) {
                break _L$2;
              } else {
                break _L$7;
              }
            } else {
              if (next_char > 109) {
                if (next_char < 111) {
                  break _L$7;
                } else {
                  break _L$2;
                }
              } else {
                break _L$2;
              }
            }
          }
          if (_cursor < _end) {
            break _L$2;
          } else {
            accept_state = 0;
            match_end = _cursor;
            break _L$2;
          }
        }
        _L$5: {
          const next_char = _M0MPC16string6String20unsafe__charcode__at(_data, _cursor);
          _cursor = _cursor + 1 | 0;
          if (next_char < 79) {
            if (next_char < 78) {
              break _L$2;
            } else {
              break _L$5;
            }
          } else {
            if (next_char > 109) {
              if (next_char < 111) {
                break _L$5;
              } else {
                break _L$2;
              }
            } else {
              break _L$2;
            }
          }
        }
        _L$6: {
          const next_char = _M0MPC16string6String20unsafe__charcode__at(_data, _cursor);
          _cursor = _cursor + 1 | 0;
          if (next_char < 71) {
            if (next_char < 70) {
              break _L$2;
            } else {
              break _L$6;
            }
          } else {
            if (next_char > 101) {
              if (next_char < 103) {
                break _L$6;
              } else {
                break _L$2;
              }
            } else {
              break _L$2;
            }
          }
        }
        if (_cursor < _end) {
          _L$7: {
            const next_char = _M0MPC16string6String20unsafe__charcode__at(_data, _cursor);
            _cursor = _cursor + 1 | 0;
            if (next_char < 74) {
              if (next_char < 73) {
                break _L$2;
              } else {
                break _L$7;
              }
            } else {
              if (next_char > 104) {
                if (next_char < 106) {
                  break _L$7;
                } else {
                  break _L$2;
                }
              } else {
                break _L$2;
              }
            }
          }
          if ((_cursor + 3 | 0) < _end) {
            _L$8: {
              const next_char = _M0MPC16string6String20unsafe__charcode__at(_data, _cursor);
              _cursor = _cursor + 1 | 0;
              if (next_char < 79) {
                if (next_char < 78) {
                  break _L$2;
                } else {
                  break _L$8;
                }
              } else {
                if (next_char > 109) {
                  if (next_char < 111) {
                    break _L$8;
                  } else {
                    break _L$2;
                  }
                } else {
                  break _L$2;
                }
              }
            }
            _L$9: {
              const next_char = _M0MPC16string6String20unsafe__charcode__at(_data, _cursor);
              _cursor = _cursor + 1 | 0;
              if (next_char < 74) {
                if (next_char < 73) {
                  break _L$2;
                } else {
                  break _L$9;
                }
              } else {
                if (next_char > 104) {
                  if (next_char < 106) {
                    break _L$9;
                  } else {
                    break _L$2;
                  }
                } else {
                  break _L$2;
                }
              }
            }
            _L$10: {
              const next_char = _M0MPC16string6String20unsafe__charcode__at(_data, _cursor);
              _cursor = _cursor + 1 | 0;
              if (next_char < 85) {
                if (next_char < 84) {
                  break _L$2;
                } else {
                  break _L$10;
                }
              } else {
                if (next_char > 115) {
                  if (next_char < 117) {
                    break _L$10;
                  } else {
                    break _L$2;
                  }
                } else {
                  break _L$2;
                }
              }
            }
            _L$11: {
              const next_char = _M0MPC16string6String20unsafe__charcode__at(_data, _cursor);
              _cursor = _cursor + 1 | 0;
              if (next_char < 90) {
                if (next_char < 89) {
                  break _L$2;
                } else {
                  break _L$11;
                }
              } else {
                if (next_char > 120) {
                  if (next_char < 122) {
                    break _L$11;
                  } else {
                    break _L$2;
                  }
                } else {
                  break _L$2;
                }
              }
            }
            if (_cursor < _end) {
              break _L$2;
            } else {
              break _L$3;
            }
          } else {
            break _L$2;
          }
        } else {
          break _L$3;
        }
      } else {
        break _L$2;
      }
    }
    accept_state = 1;
    match_end = _cursor;
    break _L$2;
  }
  switch (accept_state) {
    case 0: {
      return new _M0DTPC16result6ResultGdRPC15error5ErrorE2Ok(_M0FPC16double14not__a__number);
    }
    case 1: {
      return pos ? new _M0DTPC16result6ResultGdRPC15error5ErrorE2Ok(_M0FPC16double8infinity) : new _M0DTPC16result6ResultGdRPC15error5ErrorE2Ok(_M0FPC16double13neg__infinity);
    }
    default: {
      return _M0FPC28internal7strconv11syntax__errGdE();
    }
  }
}
function _M0FPC28internal7strconv12checked__mul(a, b) {
  if (BigInt.asUintN(64, a) === BigInt.asUintN(64, 0n) || BigInt.asUintN(64, b) === BigInt.asUintN(64, 0n)) {
    return _M0FPC28internal7strconv12checked__mulN6constrS1107;
  }
  if (BigInt.asUintN(64, a) === BigInt.asUintN(64, 1n)) {
    return b;
  }
  if (BigInt.asUintN(64, b) === BigInt.asUintN(64, 1n)) {
    return a;
  }
  if ($i64_clz(b) === 0 || $i64_clz(a) === 0) {
    return undefined;
  }
  if (b === 0n) {
    $panic();
  }
  const quotient = BigInt.asUintN(64, BigInt.asUintN(64, 18446744073709551615n) / BigInt.asUintN(64, b));
  if (BigInt.asUintN(64, a) > BigInt.asUintN(64, quotient)) {
    return undefined;
  }
  return BigInt.asUintN(64, a * b);
}
function _M0FPC28internal7strconv19overflow__threshold(base, neg) {
  if (!neg) {
    if (base === 10) {
      return 922337203685477581n;
    } else {
      if (base === 16) {
        return 576460752303423488n;
      } else {
        const _tmp = BigInt.asUintN(64, BigInt(base));
        if (_tmp === 0n) {
          $panic();
        }
        return BigInt.asUintN(64, BigInt.asUintN(64, BigInt.asIntN(64, 9223372036854775807n) / BigInt.asIntN(64, _tmp)) + 1n);
      }
    }
  } else {
    if (base === 10) {
      return 17524406870024074036n;
    } else {
      if (base === 16) {
        return 17870283321406128128n;
      } else {
        const _tmp = BigInt.asUintN(64, BigInt(base));
        if (_tmp === 0n) {
          $panic();
        }
        return BigInt.asUintN(64, BigInt.asIntN(64, 9223372036854775808n) / BigInt.asIntN(64, _tmp));
      }
    }
  }
}
function _M0FPC28internal7strconv20parse__int64_2einner(str, base) {
  if (_M0IP016_24default__implPB2Eq10not__equalGRPC16string10StringViewE(str, new _M0TPC16string10StringView(_M0FPC28internal7strconv20parse__int64_2einnerN7_2abindS645, 0, _M0FPC28internal7strconv20parse__int64_2einnerN7_2abindS645.length))) {
    let neg;
    let rest;
    _L: {
      let rest$2;
      _L$2: {
        const _bind = _M0MPC16string10StringView12view_2einner(str, 0, undefined);
        if (_M0MPC16string6String24char__length__ge_2einner(_bind.str, 1, _bind.start, _bind.end)) {
          const _x = _M0MPC16string6String16unsafe__char__at(_bind.str, _M0MPC16string6String29offset__of__nth__char_2einner(_bind.str, 0, _bind.start, _bind.end));
          switch (_x) {
            case 43: {
              const _tmp = _bind.str;
              const _bind$2 = _M0MPC16string6String29offset__of__nth__char_2einner(_bind.str, 1, _bind.start, _bind.end);
              let _tmp$2;
              if (_bind$2 === undefined) {
                _tmp$2 = _bind.end;
              } else {
                const _Some = _bind$2;
                _tmp$2 = _Some;
              }
              const _x$2 = new _M0TPC16string10StringView(_tmp, _tmp$2, _bind.end);
              neg = false;
              rest = _x$2;
              break _L;
            }
            case 45: {
              const _tmp$3 = _bind.str;
              const _bind$3 = _M0MPC16string6String29offset__of__nth__char_2einner(_bind.str, 1, _bind.start, _bind.end);
              let _tmp$4;
              if (_bind$3 === undefined) {
                _tmp$4 = _bind.end;
              } else {
                const _Some = _bind$3;
                _tmp$4 = _Some;
              }
              const _x$3 = new _M0TPC16string10StringView(_tmp$3, _tmp$4, _bind.end);
              neg = true;
              rest = _x$3;
              break _L;
            }
            default: {
              rest$2 = _bind;
              break _L$2;
            }
          }
        } else {
          rest$2 = _bind;
          break _L$2;
        }
      }
      neg = false;
      rest = rest$2;
      break _L;
    }
    const _bind = _M0FPC28internal7strconv25check__and__consume__base(rest, base);
    let _bind$2;
    if (_bind.$tag === 1) {
      const _ok = _bind;
      _bind$2 = _ok._0;
    } else {
      return _bind;
    }
    const _num_base = _bind$2._0;
    const _rest = _bind$2._1;
    const _allow_underscore = _bind$2._2;
    const overflow_threshold = _M0FPC28internal7strconv19overflow__threshold(_num_base, neg);
    let has_digit;
    if (_M0MPC16string6String24char__length__ge_2einner(_rest.str, 1, _rest.start, _rest.end)) {
      const _x = _M0MPC16string6String16unsafe__char__at(_rest.str, _M0MPC16string6String29offset__of__nth__char_2einner(_rest.str, 0, _rest.start, _rest.end));
      if (_x >= 48 && _x <= 57) {
        has_digit = true;
      } else {
        if (_x >= 97 && _x <= 122) {
          has_digit = true;
        } else {
          if (_x >= 65 && _x <= 90) {
            has_digit = true;
          } else {
            if (_M0MPC16string6String24char__length__ge_2einner(_rest.str, 2, _rest.start, _rest.end)) {
              if (_x === 95) {
                const _x$2 = _M0MPC16string6String16unsafe__char__at(_rest.str, _M0MPC16string6String29offset__of__nth__char_2einner(_rest.str, 1, _rest.start, _rest.end));
                has_digit = _x$2 >= 48 && _x$2 <= 57 ? true : _x$2 >= 97 && _x$2 <= 122 ? true : _x$2 >= 65 && _x$2 <= 90;
              } else {
                has_digit = false;
              }
            } else {
              has_digit = false;
            }
          }
        }
      }
    } else {
      has_digit = false;
    }
    if (has_digit) {
      let _tmp;
      let _tmp$2 = _rest;
      let _tmp$3 = 0n;
      let _tmp$4 = _allow_underscore;
      while (true) {
        const rest$2 = _tmp$2;
        const acc = _tmp$3;
        const allow_underscore = _tmp$4;
        let acc$2;
        let rest$3;
        let c;
        _L$2: {
          _L$3: {
            if (_M0MPC16string6String24char__length__eq_2einner(rest$2.str, 1, rest$2.start, rest$2.end)) {
              const _x = _M0MPC16string6String16unsafe__char__at(rest$2.str, _M0MPC16string6String29offset__of__nth__char_2einner(rest$2.str, 0, rest$2.start, rest$2.end));
              if (_x === 95) {
                const _bind$3 = _M0FPC28internal7strconv11syntax__errGuE();
                if (_bind$3.$tag === 1) {
                  const _ok = _bind$3;
                  _ok._0;
                } else {
                  return _bind$3;
                }
              } else {
                const _tmp$5 = rest$2.str;
                const _bind$3 = _M0MPC16string6String29offset__of__nth__char_2einner(rest$2.str, 1, rest$2.start, rest$2.end);
                let _tmp$6;
                if (_bind$3 === undefined) {
                  _tmp$6 = rest$2.end;
                } else {
                  const _Some = _bind$3;
                  _tmp$6 = _Some;
                }
                const _x$2 = new _M0TPC16string10StringView(_tmp$5, _tmp$6, rest$2.end);
                acc$2 = acc;
                rest$3 = _x$2;
                c = _x;
                break _L$3;
              }
            } else {
              if (_M0MPC16string6String24char__length__ge_2einner(rest$2.str, 1, rest$2.start, rest$2.end)) {
                const _x = _M0MPC16string6String16unsafe__char__at(rest$2.str, _M0MPC16string6String29offset__of__nth__char_2einner(rest$2.str, 0, rest$2.start, rest$2.end));
                if (_x === 95) {
                  if (allow_underscore === false) {
                    const _bind$3 = _M0FPC28internal7strconv11syntax__errGuE();
                    if (_bind$3.$tag === 1) {
                      const _ok = _bind$3;
                      _ok._0;
                    } else {
                      return _bind$3;
                    }
                  } else {
                    const _tmp$5 = rest$2.str;
                    const _bind$3 = _M0MPC16string6String29offset__of__nth__char_2einner(rest$2.str, 1, rest$2.start, rest$2.end);
                    let _tmp$6;
                    if (_bind$3 === undefined) {
                      _tmp$6 = rest$2.end;
                    } else {
                      const _Some = _bind$3;
                      _tmp$6 = _Some;
                    }
                    const _x$2 = new _M0TPC16string10StringView(_tmp$5, _tmp$6, rest$2.end);
                    _tmp$2 = _x$2;
                    _tmp$4 = false;
                    continue;
                  }
                } else {
                  const _tmp$5 = rest$2.str;
                  const _bind$3 = _M0MPC16string6String29offset__of__nth__char_2einner(rest$2.str, 1, rest$2.start, rest$2.end);
                  let _tmp$6;
                  if (_bind$3 === undefined) {
                    _tmp$6 = rest$2.end;
                  } else {
                    const _Some = _bind$3;
                    _tmp$6 = _Some;
                  }
                  const _x$2 = new _M0TPC16string10StringView(_tmp$5, _tmp$6, rest$2.end);
                  acc$2 = acc;
                  rest$3 = _x$2;
                  c = _x;
                  break _L$3;
                }
              } else {
                _tmp = acc;
                break;
              }
            }
            break _L$2;
          }
          const c$2 = c;
          let d;
          if (c$2 >= 48 && c$2 <= 57) {
            d = c$2 - 48 | 0;
          } else {
            if (c$2 >= 97 && c$2 <= 122) {
              d = c$2 + -87 | 0;
            } else {
              if (c$2 >= 65 && c$2 <= 90) {
                d = c$2 + -55 | 0;
              } else {
                const _bind$3 = _M0FPC28internal7strconv11syntax__errGiE();
                if (_bind$3.$tag === 1) {
                  const _ok = _bind$3;
                  d = _ok._0;
                } else {
                  return _bind$3;
                }
              }
            }
          }
          if (d < _num_base) {
            if (neg) {
              if (BigInt.asIntN(64, acc$2) >= BigInt.asIntN(64, overflow_threshold)) {
                const next_acc = BigInt.asUintN(64, BigInt.asUintN(64, acc$2 * BigInt.asUintN(64, BigInt(_num_base))) - BigInt.asUintN(64, BigInt(d)));
                if (BigInt.asIntN(64, next_acc) <= BigInt.asIntN(64, acc$2)) {
                  _tmp$2 = rest$3;
                  _tmp$3 = next_acc;
                  _tmp$4 = true;
                  continue;
                } else {
                  const _bind$3 = _M0FPC28internal7strconv10range__errGuE();
                  if (_bind$3.$tag === 1) {
                    const _ok = _bind$3;
                    _ok._0;
                  } else {
                    return _bind$3;
                  }
                }
              } else {
                const _bind$3 = _M0FPC28internal7strconv10range__errGuE();
                if (_bind$3.$tag === 1) {
                  const _ok = _bind$3;
                  _ok._0;
                } else {
                  return _bind$3;
                }
              }
            } else {
              if (BigInt.asIntN(64, acc$2) < BigInt.asIntN(64, overflow_threshold)) {
                const next_acc = BigInt.asUintN(64, BigInt.asUintN(64, acc$2 * BigInt.asUintN(64, BigInt(_num_base))) + BigInt.asUintN(64, BigInt(d)));
                if (BigInt.asIntN(64, next_acc) >= BigInt.asIntN(64, acc$2)) {
                  _tmp$2 = rest$3;
                  _tmp$3 = next_acc;
                  _tmp$4 = true;
                  continue;
                } else {
                  const _bind$3 = _M0FPC28internal7strconv10range__errGuE();
                  if (_bind$3.$tag === 1) {
                    const _ok = _bind$3;
                    _ok._0;
                  } else {
                    return _bind$3;
                  }
                }
              } else {
                const _bind$3 = _M0FPC28internal7strconv10range__errGuE();
                if (_bind$3.$tag === 1) {
                  const _ok = _bind$3;
                  _ok._0;
                } else {
                  return _bind$3;
                }
              }
            }
          } else {
            const _bind$3 = _M0FPC28internal7strconv11syntax__errGuE();
            if (_bind$3.$tag === 1) {
              const _ok = _bind$3;
              _ok._0;
            } else {
              return _bind$3;
            }
          }
        }
        continue;
      }
      return new _M0DTPC16result6ResultGlRPC15error5ErrorE2Ok(_tmp);
    } else {
      return _M0FPC28internal7strconv11syntax__errGlE();
    }
  } else {
    return _M0FPC28internal7strconv11syntax__errGlE();
  }
}
function _M0FPC28internal7strconv18parse__int_2einner(str, base) {
  const _bind = _M0FPC28internal7strconv20parse__int64_2einner(str, base);
  let n;
  if (_bind.$tag === 1) {
    const _ok = _bind;
    n = _ok._0;
  } else {
    return _bind;
  }
  if (BigInt.asIntN(64, n) < BigInt.asIntN(64, 18446744071562067968n) || BigInt.asIntN(64, n) > BigInt.asIntN(64, 2147483647n)) {
    const _bind$2 = _M0FPC28internal7strconv10range__errGuE();
    if (_bind$2.$tag === 1) {
      const _ok = _bind$2;
      _ok._0;
    } else {
      return _bind$2;
    }
  }
  return new _M0DTPC16result6ResultGiRPC15error5ErrorE2Ok(Number(BigInt.asIntN(32, n)) | 0);
}
function _M0FPC28internal7strconv17check__underscore(str) {
  let rest;
  if (_M0MPC16string6String24char__length__ge_2einner(str.str, 1, str.start, str.end)) {
    const _x = _M0MPC16string6String16unsafe__char__at(str.str, _M0MPC16string6String29offset__of__nth__char_2einner(str.str, 0, str.start, str.end));
    switch (_x) {
      case 43: {
        const _tmp = str.str;
        const _bind = _M0MPC16string6String29offset__of__nth__char_2einner(str.str, 1, str.start, str.end);
        let _tmp$2;
        if (_bind === undefined) {
          _tmp$2 = str.end;
        } else {
          const _Some = _bind;
          _tmp$2 = _Some;
        }
        const _x$2 = new _M0TPC16string10StringView(_tmp, _tmp$2, str.end);
        rest = _x$2;
        break;
      }
      case 45: {
        const _tmp$3 = str.str;
        const _bind$2 = _M0MPC16string6String29offset__of__nth__char_2einner(str.str, 1, str.start, str.end);
        let _tmp$4;
        if (_bind$2 === undefined) {
          _tmp$4 = str.end;
        } else {
          const _Some = _bind$2;
          _tmp$4 = _Some;
        }
        const _x$3 = new _M0TPC16string10StringView(_tmp$3, _tmp$4, str.end);
        rest = _x$3;
        break;
      }
      default: {
        rest = str;
      }
    }
  } else {
    rest = str;
  }
  let rest$2;
  let allow_underscore;
  let hex;
  _L: {
    const _data = _M0MPC16string10StringView4data(rest);
    const _start = _M0MPC16string10StringView13start__offset(rest);
    const _end = _start + _M0MPC16string10StringView6length(rest) | 0;
    let _cursor = _start;
    let accept_state = -1;
    let match_end = -1;
    _L$2: {
      if ((_cursor + 1 | 0) < _end) {
        if (_M0MPC16string6String20unsafe__charcode__at(_data, _cursor) === 48) {
          _cursor = _cursor + 1 | 0;
          _L$3: {
            _L$4: {
              _L$5: {
                const next_char = _M0MPC16string6String20unsafe__charcode__at(_data, _cursor);
                _cursor = _cursor + 1 | 0;
                if (next_char < 89) {
                  if (next_char < 79) {
                    if (next_char === 66) {
                      break _L$3;
                    } else {
                      break _L$2;
                    }
                  } else {
                    if (next_char > 79) {
                      if (next_char < 88) {
                        break _L$2;
                      } else {
                        break _L$5;
                      }
                    } else {
                      break _L$4;
                    }
                  }
                } else {
                  if (next_char > 97) {
                    if (next_char < 112) {
                      if (next_char < 99) {
                        break _L$3;
                      } else {
                        if (next_char > 110) {
                          break _L$4;
                        } else {
                          break _L$2;
                        }
                      }
                    } else {
                      if (next_char > 119) {
                        if (next_char < 121) {
                          break _L$5;
                        } else {
                          break _L$2;
                        }
                      } else {
                        break _L$2;
                      }
                    }
                  } else {
                    break _L$2;
                  }
                }
              }
              accept_state = 2;
              match_end = _cursor;
              break _L$2;
            }
            accept_state = 1;
            match_end = _cursor;
            break _L$2;
          }
          accept_state = 0;
          match_end = _cursor;
          break _L$2;
        } else {
          break _L$2;
        }
      } else {
        break _L$2;
      }
    }
    switch (accept_state) {
      case 2: {
        const rest$3 = _M0MPC16string6String4view(_data, match_end, _end);
        rest$2 = rest$3;
        allow_underscore = true;
        hex = true;
        break _L;
      }
      case 1: {
        const rest$4 = _M0MPC16string6String4view(_data, match_end, _end);
        rest$2 = rest$4;
        allow_underscore = true;
        hex = false;
        break _L;
      }
      case 0: {
        const rest$5 = _M0MPC16string6String4view(_data, match_end, _end);
        rest$2 = rest$5;
        allow_underscore = true;
        hex = false;
        break _L;
      }
      default: {
        rest$2 = rest;
        allow_underscore = false;
        hex = false;
        break _L;
      }
    }
  }
  let _tmp = rest$2;
  let _tmp$2 = allow_underscore;
  let _tmp$3 = false;
  while (true) {
    const rest$3 = _tmp;
    const allow_underscore$2 = _tmp$2;
    const follow_underscore = _tmp$3;
    let rest$4;
    let c;
    let follow_underscore$2;
    _L$2: {
      if (_M0MPC16string6String24char__length__eq_2einner(rest$3.str, 0, rest$3.start, rest$3.end)) {
        return true;
      } else {
        if (_M0MPC16string6String24char__length__eq_2einner(rest$3.str, 1, rest$3.start, rest$3.end)) {
          const _x = _M0MPC16string6String16unsafe__char__at(rest$3.str, _M0MPC16string6String29offset__of__nth__char_2einner(rest$3.str, 0, rest$3.start, rest$3.end));
          if (_x === 95) {
            return false;
          } else {
            const _tmp$4 = rest$3.str;
            const _bind = _M0MPC16string6String29offset__of__nth__char_2einner(rest$3.str, 1, rest$3.start, rest$3.end);
            let _tmp$5;
            if (_bind === undefined) {
              _tmp$5 = rest$3.end;
            } else {
              const _Some = _bind;
              _tmp$5 = _Some;
            }
            const _x$2 = new _M0TPC16string10StringView(_tmp$4, _tmp$5, rest$3.end);
            rest$4 = _x$2;
            c = _x;
            follow_underscore$2 = follow_underscore;
            break _L$2;
          }
        } else {
          const _x = _M0MPC16string6String16unsafe__char__at(rest$3.str, _M0MPC16string6String29offset__of__nth__char_2einner(rest$3.str, 0, rest$3.start, rest$3.end));
          if (_x === 95) {
            if (allow_underscore$2 === false) {
              return false;
            } else {
              const _tmp$4 = rest$3.str;
              const _bind = _M0MPC16string6String29offset__of__nth__char_2einner(rest$3.str, 1, rest$3.start, rest$3.end);
              let _tmp$5;
              if (_bind === undefined) {
                _tmp$5 = rest$3.end;
              } else {
                const _Some = _bind;
                _tmp$5 = _Some;
              }
              const _x$2 = new _M0TPC16string10StringView(_tmp$4, _tmp$5, rest$3.end);
              _tmp = _x$2;
              _tmp$2 = false;
              _tmp$3 = true;
              continue;
            }
          } else {
            const _tmp$4 = rest$3.str;
            const _bind = _M0MPC16string6String29offset__of__nth__char_2einner(rest$3.str, 1, rest$3.start, rest$3.end);
            let _tmp$5;
            if (_bind === undefined) {
              _tmp$5 = rest$3.end;
            } else {
              const _Some = _bind;
              _tmp$5 = _Some;
            }
            const _x$2 = new _M0TPC16string10StringView(_tmp$4, _tmp$5, rest$3.end);
            rest$4 = _x$2;
            c = _x;
            follow_underscore$2 = follow_underscore;
            break _L$2;
          }
        }
      }
    }
    if (c >= 48 && c <= 57 ? true : hex && (c >= 97 && c <= 102 ? true : c >= 65 && c <= 70)) {
      _tmp = rest$4;
      _tmp$2 = true;
      _tmp$3 = false;
      continue;
    } else {
      if (follow_underscore$2) {
        return false;
      } else {
        _tmp = rest$4;
        _tmp$2 = false;
        _tmp$3 = false;
        continue;
      }
    }
  }
}
function _M0MPC28internal7strconv7Decimal9new__priv() {
  return new _M0TPC28internal7strconv7Decimal($makebytes(800, _M0IPC14byte4BytePB7Default7default()), 0, 0, false, false);
}
function _M0MPC28internal7strconv7Decimal4trim(self) {
  while (true) {
    let _tmp;
    if (self.digits_num > 0) {
      const _tmp$2 = self.digits;
      const _tmp$3 = self.digits_num - 1 | 0;
      $bound_check(_tmp$2, _tmp$3);
      _tmp = _M0IPC14byte4BytePB2Eq5equal(_tmp$2[_tmp$3], 0);
    } else {
      _tmp = false;
    }
    if (_tmp) {
      self.digits_num = self.digits_num - 1 | 0;
      continue;
    } else {
      break;
    }
  }
  if (self.digits_num === 0) {
    self.decimal_point = 0;
    return;
  } else {
    return;
  }
}
function _M0FPC28internal7strconv26parse__decimal__from__view(str) {
  const d = _M0MPC28internal7strconv7Decimal9new__priv();
  let has_dp = false;
  let has_digits = false;
  let rest;
  _L: {
    _L$2: {
      if (_M0MPC16string6String24char__length__ge_2einner(str.str, 1, str.start, str.end)) {
        const _x = _M0MPC16string6String16unsafe__char__at(str.str, _M0MPC16string6String29offset__of__nth__char_2einner(str.str, 0, str.start, str.end));
        switch (_x) {
          case 45: {
            const _tmp = str.str;
            const _bind = _M0MPC16string6String29offset__of__nth__char_2einner(str.str, 1, str.start, str.end);
            let _tmp$2;
            if (_bind === undefined) {
              _tmp$2 = str.end;
            } else {
              const _Some = _bind;
              _tmp$2 = _Some;
            }
            const _x$2 = new _M0TPC16string10StringView(_tmp, _tmp$2, str.end);
            d.negative = true;
            rest = _x$2;
            break;
          }
          case 43: {
            const _tmp$3 = str.str;
            const _bind$2 = _M0MPC16string6String29offset__of__nth__char_2einner(str.str, 1, str.start, str.end);
            let _tmp$4;
            if (_bind$2 === undefined) {
              _tmp$4 = str.end;
            } else {
              const _Some = _bind$2;
              _tmp$4 = _Some;
            }
            rest = new _M0TPC16string10StringView(_tmp$3, _tmp$4, str.end);
            break;
          }
          default: {
            break _L$2;
          }
        }
      } else {
        break _L$2;
      }
      break _L;
    }
    rest = str;
  }
  let rest$2;
  let _tmp = rest;
  while (true) {
    const rest$3 = _tmp;
    let rest$4;
    _L$2: {
      _L$3: {
        if (_M0MPC16string6String24char__length__ge_2einner(rest$3.str, 1, rest$3.start, rest$3.end)) {
          const _x = _M0MPC16string6String16unsafe__char__at(rest$3.str, _M0MPC16string6String29offset__of__nth__char_2einner(rest$3.str, 0, rest$3.start, rest$3.end));
          if (_x === 95) {
            const _tmp$2 = rest$3.str;
            const _bind = _M0MPC16string6String29offset__of__nth__char_2einner(rest$3.str, 1, rest$3.start, rest$3.end);
            let _tmp$3;
            if (_bind === undefined) {
              _tmp$3 = rest$3.end;
            } else {
              const _Some = _bind;
              _tmp$3 = _Some;
            }
            const _x$2 = new _M0TPC16string10StringView(_tmp$2, _tmp$3, rest$3.end);
            _tmp = _x$2;
            continue;
          } else {
            if (_x === 46) {
              const _tmp$2 = rest$3.str;
              const _bind = _M0MPC16string6String29offset__of__nth__char_2einner(rest$3.str, 1, rest$3.start, rest$3.end);
              let _tmp$3;
              if (_bind === undefined) {
                _tmp$3 = rest$3.end;
              } else {
                const _Some = _bind;
                _tmp$3 = _Some;
              }
              const _x$2 = new _M0TPC16string10StringView(_tmp$2, _tmp$3, rest$3.end);
              if (!has_dp) {
                has_dp = true;
                d.decimal_point = d.digits_num;
                _tmp = _x$2;
                continue;
              } else {
                const _bind$2 = _M0FPC28internal7strconv11syntax__errGuE();
                if (_bind$2.$tag === 1) {
                  const _ok = _bind$2;
                  _ok._0;
                } else {
                  return _bind$2;
                }
              }
            } else {
              if (_x >= 48 && _x <= 57) {
                const _tmp$2 = rest$3.str;
                const _bind = _M0MPC16string6String29offset__of__nth__char_2einner(rest$3.str, 1, rest$3.start, rest$3.end);
                let _tmp$3;
                if (_bind === undefined) {
                  _tmp$3 = rest$3.end;
                } else {
                  const _Some = _bind;
                  _tmp$3 = _Some;
                }
                const _x$2 = new _M0TPC16string10StringView(_tmp$2, _tmp$3, rest$3.end);
                has_digits = true;
                if (_x === 48 && d.digits_num === 0) {
                  d.decimal_point = d.decimal_point - 1 | 0;
                  _tmp = _x$2;
                  continue;
                }
                if (d.digits_num < d.digits.length) {
                  const _tmp$4 = d.digits;
                  const _tmp$5 = d.digits_num;
                  $bound_check(_tmp$4, _tmp$5);
                  _tmp$4[_tmp$5] = (_x - 48 | 0) & 255;
                  d.digits_num = d.digits_num + 1 | 0;
                } else {
                  if (_x !== 48) {
                    d.truncated = true;
                  }
                }
                _tmp = _x$2;
                continue;
              } else {
                rest$4 = rest$3;
                break _L$3;
              }
            }
          }
        } else {
          rest$4 = rest$3;
          break _L$3;
        }
        break _L$2;
      }
      rest$2 = rest$4;
      break;
    }
    continue;
  }
  if (has_digits) {
    if (!has_dp) {
      d.decimal_point = d.digits_num;
    }
    let rest$3;
    let rest$4;
    _L$2: {
      _L$3: {
        if (_M0MPC16string6String24char__length__ge_2einner(rest$2.str, 1, rest$2.start, rest$2.end)) {
          const _x = _M0MPC16string6String16unsafe__char__at(rest$2.str, _M0MPC16string6String29offset__of__nth__char_2einner(rest$2.str, 0, rest$2.start, rest$2.end));
          switch (_x) {
            case 101: {
              const _tmp$2 = rest$2.str;
              const _bind = _M0MPC16string6String29offset__of__nth__char_2einner(rest$2.str, 1, rest$2.start, rest$2.end);
              let _tmp$3;
              if (_bind === undefined) {
                _tmp$3 = rest$2.end;
              } else {
                const _Some = _bind;
                _tmp$3 = _Some;
              }
              const _x$2 = new _M0TPC16string10StringView(_tmp$2, _tmp$3, rest$2.end);
              rest$4 = _x$2;
              break _L$3;
            }
            case 69: {
              const _tmp$4 = rest$2.str;
              const _bind$2 = _M0MPC16string6String29offset__of__nth__char_2einner(rest$2.str, 1, rest$2.start, rest$2.end);
              let _tmp$5;
              if (_bind$2 === undefined) {
                _tmp$5 = rest$2.end;
              } else {
                const _Some = _bind$2;
                _tmp$5 = _Some;
              }
              const _x$3 = new _M0TPC16string10StringView(_tmp$4, _tmp$5, rest$2.end);
              rest$4 = _x$3;
              break _L$3;
            }
            default: {
              rest$3 = rest$2;
            }
          }
        } else {
          rest$3 = rest$2;
        }
        break _L$2;
      }
      let exp_sign = 1;
      let rest$5;
      if (_M0MPC16string6String24char__length__ge_2einner(rest$4.str, 1, rest$4.start, rest$4.end)) {
        const _x = _M0MPC16string6String16unsafe__char__at(rest$4.str, _M0MPC16string6String29offset__of__nth__char_2einner(rest$4.str, 0, rest$4.start, rest$4.end));
        switch (_x) {
          case 43: {
            const _tmp$2 = rest$4.str;
            const _bind = _M0MPC16string6String29offset__of__nth__char_2einner(rest$4.str, 1, rest$4.start, rest$4.end);
            let _tmp$3;
            if (_bind === undefined) {
              _tmp$3 = rest$4.end;
            } else {
              const _Some = _bind;
              _tmp$3 = _Some;
            }
            rest$5 = new _M0TPC16string10StringView(_tmp$2, _tmp$3, rest$4.end);
            break;
          }
          case 45: {
            const _tmp$4 = rest$4.str;
            const _bind$2 = _M0MPC16string6String29offset__of__nth__char_2einner(rest$4.str, 1, rest$4.start, rest$4.end);
            let _tmp$5;
            if (_bind$2 === undefined) {
              _tmp$5 = rest$4.end;
            } else {
              const _Some = _bind$2;
              _tmp$5 = _Some;
            }
            const _x$2 = new _M0TPC16string10StringView(_tmp$4, _tmp$5, rest$4.end);
            exp_sign = -1;
            rest$5 = _x$2;
            break;
          }
          default: {
            rest$5 = rest$4;
          }
        }
      } else {
        rest$5 = rest$4;
      }
      _L$4: {
        _L$5: {
          if (_M0MPC16string6String24char__length__ge_2einner(rest$5.str, 1, rest$5.start, rest$5.end)) {
            const _x = _M0MPC16string6String16unsafe__char__at(rest$5.str, _M0MPC16string6String29offset__of__nth__char_2einner(rest$5.str, 0, rest$5.start, rest$5.end));
            if (_x >= 48 && _x <= 57) {
              let exp = 0;
              let rest$6;
              let _tmp$2 = rest$5;
              while (true) {
                const rest$7 = _tmp$2;
                let rest$8;
                _L$6: {
                  if (_M0MPC16string6String24char__length__ge_2einner(rest$7.str, 1, rest$7.start, rest$7.end)) {
                    const _x$2 = _M0MPC16string6String16unsafe__char__at(rest$7.str, _M0MPC16string6String29offset__of__nth__char_2einner(rest$7.str, 0, rest$7.start, rest$7.end));
                    if (_x$2 === 95) {
                      const _tmp$3 = rest$7.str;
                      const _bind = _M0MPC16string6String29offset__of__nth__char_2einner(rest$7.str, 1, rest$7.start, rest$7.end);
                      let _tmp$4;
                      if (_bind === undefined) {
                        _tmp$4 = rest$7.end;
                      } else {
                        const _Some = _bind;
                        _tmp$4 = _Some;
                      }
                      const _x$3 = new _M0TPC16string10StringView(_tmp$3, _tmp$4, rest$7.end);
                      _tmp$2 = _x$3;
                      continue;
                    } else {
                      if (_x$2 >= 48 && _x$2 <= 57) {
                        const _tmp$3 = rest$7.str;
                        const _bind = _M0MPC16string6String29offset__of__nth__char_2einner(rest$7.str, 1, rest$7.start, rest$7.end);
                        let _tmp$4;
                        if (_bind === undefined) {
                          _tmp$4 = rest$7.end;
                        } else {
                          const _Some = _bind;
                          _tmp$4 = _Some;
                        }
                        const _x$3 = new _M0TPC16string10StringView(_tmp$3, _tmp$4, rest$7.end);
                        exp = (Math.imul(exp, 10) | 0) + (_x$2 - 48 | 0) | 0;
                        _tmp$2 = _x$3;
                        continue;
                      } else {
                        rest$8 = rest$7;
                        break _L$6;
                      }
                    }
                  } else {
                    rest$8 = rest$7;
                    break _L$6;
                  }
                }
                rest$6 = rest$8;
                break;
              }
              d.decimal_point = d.decimal_point + (Math.imul(exp_sign, exp) | 0) | 0;
              rest$3 = rest$6;
            } else {
              break _L$5;
            }
          } else {
            break _L$5;
          }
          break _L$4;
        }
        const _bind = _M0FPC28internal7strconv11syntax__errGlE();
        if (_bind.$tag === 1) {
          const _ok = _bind;
          rest$3 = _ok._0;
        } else {
          return _bind;
        }
      }
    }
    if (_M0MPC16string6String24char__length__eq_2einner(rest$3.str, 0, rest$3.start, rest$3.end)) {
      _M0MPC28internal7strconv7Decimal4trim(d);
      return new _M0DTPC16result6ResultGRPC28internal7strconv7DecimalRPC15error5ErrorE2Ok(d);
    } else {
      return _M0FPC28internal7strconv11syntax__errGlE();
    }
  } else {
    return _M0FPC28internal7strconv11syntax__errGlE();
  }
}
function _M0FPC28internal7strconv20parse__decimal__priv(str) {
  return _M0FPC28internal7strconv26parse__decimal__from__view(str);
}
function _M0FPC28internal7strconv14assemble__bits(mantissa, exponent, negative) {
  const biased_exp = exponent - _M0FPC28internal7strconv12double__info.bias | 0;
  let bits = BigInt.asUintN(64, mantissa & BigInt.asUintN(64, BigInt.asUintN(64, 1n << BigInt(_M0FPC28internal7strconv12double__info.mantissa_bits & 63)) - 1n));
  const exp_bits = BigInt.asUintN(64, BigInt(biased_exp & ((1 << _M0FPC28internal7strconv12double__info.exponent_bits) - 1 | 0)));
  bits = BigInt.asUintN(64, bits | BigInt.asUintN(64, exp_bits << BigInt(_M0FPC28internal7strconv12double__info.mantissa_bits & 63)));
  if (negative) {
    bits = BigInt.asUintN(64, bits | BigInt.asUintN(64, BigInt.asUintN(64, 1n << BigInt(_M0FPC28internal7strconv12double__info.mantissa_bits & 63)) << BigInt(_M0FPC28internal7strconv12double__info.exponent_bits & 63)));
  }
  return bits;
}
function _M0MPC28internal7strconv7Decimal17should__round__up(self, d) {
  if (d < 0 || d >= self.digits_num) {
    return false;
  }
  let _tmp;
  const _tmp$2 = self.digits;
  $bound_check(_tmp$2, d);
  if (_tmp$2[d] === 5) {
    _tmp = (d + 1 | 0) === self.digits_num;
  } else {
    _tmp = false;
  }
  if (_tmp) {
    if (self.truncated) {
      return true;
    }
    let _tmp$3;
    if (d > 0) {
      const _tmp$4 = self.digits;
      const _tmp$5 = d - 1 | 0;
      $bound_check(_tmp$4, _tmp$5);
      if (2 === 0) {
        $panic();
      }
      _tmp$3 = (_tmp$4[_tmp$5] % 2 | 0) !== 0;
    } else {
      _tmp$3 = false;
    }
    return _tmp$3;
  }
  const _tmp$3 = self.digits;
  $bound_check(_tmp$3, d);
  return _tmp$3[d] >= 5;
}
function _M0MPC28internal7strconv7Decimal16rounded__integer(self) {
  if (self.decimal_point > 20) {
    return 18446744073709551615n;
  }
  let _tmp = 0n;
  let _tmp$2 = 0;
  while (true) {
    const n = _tmp;
    const i = _tmp$2;
    if (i < self.decimal_point && i < self.digits_num) {
      const _tmp$3 = BigInt.asUintN(64, n * 10n);
      const _tmp$4 = self.digits;
      $bound_check(_tmp$4, i);
      _tmp = BigInt.asUintN(64, _tmp$3 + _M0MPC14byte4Byte9to__int64(_tmp$4[i]));
      _tmp$2 = i + 1 | 0;
      continue;
    } else {
      let n$2;
      let _tmp$3 = n;
      let _tmp$4 = i;
      while (true) {
        const n$3 = _tmp$3;
        const i$2 = _tmp$4;
        if (i$2 < self.decimal_point) {
          _tmp$3 = BigInt.asUintN(64, n$3 * 10n);
          _tmp$4 = i$2 + 1 | 0;
          continue;
        } else {
          n$2 = n$3;
          break;
        }
      }
      return _M0MPC28internal7strconv7Decimal17should__round__up(self, self.decimal_point) ? BigInt.asUintN(64, n$2 + 1n) : n$2;
    }
  }
}
function _M0MPC28internal7strconv7Decimal11new__digits(self, s) {
  const new_digits = _M0MPC15array13ReadOnlyArray2atGmE(_M0FPC28internal7strconv19left__shift__cheats, s)._0;
  const cheat_num = _M0MPC15array13ReadOnlyArray2atGmE(_M0FPC28internal7strconv19left__shift__cheats, s)._1;
  const _bind = cheat_num.length;
  let less;
  let _tmp = 0;
  while (true) {
    const i = _tmp;
    if (i < _bind) {
      if (i >= self.digits_num) {
        less = true;
        break;
      }
      const d = cheat_num.charCodeAt(i) - 48 | 0;
      const _tmp$2 = self.digits;
      $bound_check(_tmp$2, i);
      if (_tmp$2[i] !== d) {
        const _tmp$3 = self.digits;
        $bound_check(_tmp$3, i);
        less = _tmp$3[i] < d;
        break;
      }
      _tmp = i + 1 | 0;
      continue;
    } else {
      less = false;
      break;
    }
  }
  return less ? new_digits - 1 | 0 : new_digits;
}
function _M0MPC28internal7strconv7Decimal11left__shift(self, s) {
  const new_digits = _M0MPC28internal7strconv7Decimal11new__digits(self, s);
  let read_index = self.digits_num;
  let write_index = self.digits_num + new_digits | 0;
  let acc = 0n;
  read_index = read_index - 1 | 0;
  while (true) {
    if (read_index >= 0) {
      const _tmp = self.digits;
      const _tmp$2 = read_index;
      $bound_check(_tmp, _tmp$2);
      const d = _M0MPC14byte4Byte9to__int64(_tmp[_tmp$2]);
      acc = BigInt.asUintN(64, acc + BigInt.asUintN(64, d << BigInt(s & 63)));
      if (10n === 0n) {
        $panic();
      }
      const quo = BigInt.asUintN(64, BigInt.asIntN(64, acc) / BigInt.asIntN(64, 10n));
      const rem = Number(BigInt.asIntN(32, BigInt.asUintN(64, acc - BigInt.asUintN(64, quo * 10n)))) | 0;
      write_index = write_index - 1 | 0;
      if (write_index < self.digits.length) {
        const _tmp$3 = self.digits;
        const _tmp$4 = write_index;
        $bound_check(_tmp$3, _tmp$4);
        _tmp$3[_tmp$4] = rem & 255;
      } else {
        if (rem !== 0) {
          self.truncated = true;
        }
      }
      acc = quo;
      read_index = read_index - 1 | 0;
      continue;
    } else {
      break;
    }
  }
  while (true) {
    if (BigInt.asIntN(64, acc) > BigInt.asIntN(64, 0n)) {
      if (10n === 0n) {
        $panic();
      }
      const quo = BigInt.asUintN(64, BigInt.asIntN(64, acc) / BigInt.asIntN(64, 10n));
      const rem = Number(BigInt.asIntN(32, BigInt.asUintN(64, acc - BigInt.asUintN(64, 10n * quo)))) | 0;
      write_index = write_index - 1 | 0;
      if (write_index < self.digits.length) {
        const _tmp = self.digits;
        const _tmp$2 = write_index;
        $bound_check(_tmp, _tmp$2);
        _tmp[_tmp$2] = rem & 255;
      } else {
        if (rem !== 0) {
          self.truncated = true;
        }
      }
      acc = quo;
      continue;
    } else {
      break;
    }
  }
  self.digits_num = self.digits_num + new_digits | 0;
  if (self.digits_num > self.digits.length) {
    self.digits_num = self.digits.length;
  }
  self.decimal_point = self.decimal_point + new_digits | 0;
  _M0MPC28internal7strconv7Decimal4trim(self);
}
function _M0MPC28internal7strconv7Decimal12right__shift(self, s) {
  let read_index = 0;
  let write_index = 0;
  let acc = 0n;
  while (true) {
    if (BigInt.asUintN(64, BigInt.asUintN(64, BigInt.asUintN(64, acc) >> BigInt(s & 63))) === BigInt.asUintN(64, 0n)) {
      if (read_index >= self.digits_num) {
        while (true) {
          if (BigInt.asUintN(64, BigInt.asUintN(64, BigInt.asUintN(64, acc) >> BigInt(s & 63))) === BigInt.asUintN(64, 0n)) {
            acc = BigInt.asUintN(64, acc * 10n);
            read_index = read_index + 1 | 0;
            continue;
          } else {
            break;
          }
        }
        break;
      }
      const _tmp = self.digits;
      const _tmp$2 = read_index;
      $bound_check(_tmp, _tmp$2);
      const d = _tmp[_tmp$2];
      acc = BigInt.asUintN(64, BigInt.asUintN(64, acc * 10n) + _M0MPC14byte4Byte9to__int64(d));
      read_index = read_index + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  self.decimal_point = self.decimal_point - (read_index - 1 | 0) | 0;
  const mask = BigInt.asUintN(64, BigInt.asUintN(64, 1n << BigInt(s & 63)) - 1n);
  while (true) {
    if (read_index < self.digits_num) {
      const out = BigInt.asUintN(64, BigInt.asUintN(64, acc) >> BigInt(s & 63));
      const _tmp = self.digits;
      const _tmp$2 = write_index;
      $bound_check(_tmp, _tmp$2);
      _tmp[_tmp$2] = _M0MPC16uint646UInt648to__byte(out);
      write_index = write_index + 1 | 0;
      acc = BigInt.asUintN(64, acc & mask);
      const _tmp$3 = self.digits;
      const _tmp$4 = read_index;
      $bound_check(_tmp$3, _tmp$4);
      const d = _tmp$3[_tmp$4];
      acc = BigInt.asUintN(64, BigInt.asUintN(64, acc * 10n) + _M0MPC14byte4Byte9to__int64(d));
      read_index = read_index + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  while (true) {
    if (BigInt.asUintN(64, acc) > BigInt.asUintN(64, 0n)) {
      const out = BigInt.asUintN(64, BigInt.asUintN(64, acc) >> BigInt(s & 63));
      if (write_index < self.digits.length) {
        const _tmp = self.digits;
        const _tmp$2 = write_index;
        $bound_check(_tmp, _tmp$2);
        _tmp[_tmp$2] = _M0MPC16uint646UInt648to__byte(out);
        write_index = write_index + 1 | 0;
      } else {
        if (BigInt.asUintN(64, out) > BigInt.asUintN(64, 0n)) {
          self.truncated = true;
        }
      }
      acc = BigInt.asUintN(64, acc & mask);
      acc = BigInt.asUintN(64, acc * 10n);
      continue;
    } else {
      break;
    }
  }
  self.digits_num = write_index;
  _M0MPC28internal7strconv7Decimal4trim(self);
}
function _M0MPC28internal7strconv7Decimal11shift__priv(self, s) {
  if (self.digits_num === 0) {
    return undefined;
  }
  let s$2 = s;
  if (s$2 > 0) {
    while (true) {
      if (s$2 > 59) {
        _M0MPC28internal7strconv7Decimal11left__shift(self, 59);
        s$2 = s$2 - 59 | 0;
        continue;
      } else {
        break;
      }
    }
    _M0MPC28internal7strconv7Decimal11left__shift(self, s$2);
  }
  if (s$2 < 0) {
    while (true) {
      if (s$2 < -59) {
        _M0MPC28internal7strconv7Decimal12right__shift(self, 59);
        s$2 = s$2 + 59 | 0;
        continue;
      } else {
        break;
      }
    }
    _M0MPC28internal7strconv7Decimal12right__shift(self, -s$2 | 0);
    return;
  } else {
    return;
  }
}
function _M0MPC28internal7strconv7Decimal16to__double__priv(self) {
  let exponent = 0;
  let mantissa = 0n;
  if (self.digits_num === 0 || self.decimal_point < -330) {
    mantissa = 0n;
    exponent = _M0FPC28internal7strconv12double__info.bias;
    const bits = _M0FPC28internal7strconv14assemble__bits(mantissa, exponent, self.negative);
    return new _M0DTPC16result6ResultGdRPC15error5ErrorE2Ok($i64_reinterpret_f64(bits));
  }
  if (self.decimal_point > 310) {
    const _bind = _M0FPC28internal7strconv10range__errGuE();
    if (_bind.$tag === 1) {
      const _ok = _bind;
      _ok._0;
    } else {
      return _bind;
    }
  }
  while (true) {
    if (self.decimal_point > 0) {
      let n = 0;
      if (self.decimal_point >= _M0MPC15array13ReadOnlyArray6lengthGiE(_M0FPC28internal7strconv6powtab)) {
        n = 60;
      } else {
        n = _M0MPC15array13ReadOnlyArray2atGiE(_M0FPC28internal7strconv6powtab, self.decimal_point);
      }
      _M0MPC28internal7strconv7Decimal11shift__priv(self, -n | 0);
      exponent = exponent + n | 0;
      continue;
    } else {
      break;
    }
  }
  while (true) {
    let _tmp;
    if (self.decimal_point < 0) {
      _tmp = true;
    } else {
      let _tmp$2;
      if (self.decimal_point === 0) {
        const _tmp$3 = self.digits;
        $bound_check(_tmp$3, 0);
        _tmp$2 = _tmp$3[0] < 5;
      } else {
        _tmp$2 = false;
      }
      _tmp = _tmp$2;
    }
    if (_tmp) {
      let n = 0;
      if ((-self.decimal_point | 0) >= _M0MPC15array13ReadOnlyArray6lengthGiE(_M0FPC28internal7strconv6powtab)) {
        n = 60;
      } else {
        n = _M0MPC15array13ReadOnlyArray2atGiE(_M0FPC28internal7strconv6powtab, -self.decimal_point | 0);
      }
      _M0MPC28internal7strconv7Decimal11shift__priv(self, n);
      exponent = exponent - n | 0;
      continue;
    } else {
      break;
    }
  }
  exponent = exponent - 1 | 0;
  if (exponent < (_M0FPC28internal7strconv12double__info.bias + 1 | 0)) {
    const n = (_M0FPC28internal7strconv12double__info.bias + 1 | 0) - exponent | 0;
    _M0MPC28internal7strconv7Decimal11shift__priv(self, -n | 0);
    exponent = exponent + n | 0;
  }
  if ((exponent - _M0FPC28internal7strconv12double__info.bias | 0) >= ((1 << _M0FPC28internal7strconv12double__info.exponent_bits) - 1 | 0)) {
    const _bind = _M0FPC28internal7strconv10range__errGuE();
    if (_bind.$tag === 1) {
      const _ok = _bind;
      _ok._0;
    } else {
      return _bind;
    }
  }
  _M0MPC28internal7strconv7Decimal11shift__priv(self, _M0FPC28internal7strconv12double__info.mantissa_bits + 1 | 0);
  mantissa = _M0MPC28internal7strconv7Decimal16rounded__integer(self);
  if (BigInt.asUintN(64, mantissa) === BigInt.asUintN(64, BigInt.asUintN(64, 2n << BigInt(_M0FPC28internal7strconv12double__info.mantissa_bits & 63)))) {
    mantissa = BigInt.asUintN(64, BigInt.asIntN(64, mantissa) >> BigInt(1 & 63));
    exponent = exponent + 1 | 0;
    if ((exponent - _M0FPC28internal7strconv12double__info.bias | 0) >= ((1 << _M0FPC28internal7strconv12double__info.exponent_bits) - 1 | 0)) {
      const _bind = _M0FPC28internal7strconv10range__errGuE();
      if (_bind.$tag === 1) {
        const _ok = _bind;
        _ok._0;
      } else {
        return _bind;
      }
    }
  }
  if (BigInt.asUintN(64, BigInt.asUintN(64, mantissa & BigInt.asUintN(64, 1n << BigInt(_M0FPC28internal7strconv12double__info.mantissa_bits & 63)))) === BigInt.asUintN(64, 0n)) {
    exponent = _M0FPC28internal7strconv12double__info.bias;
  }
  const bits = _M0FPC28internal7strconv14assemble__bits(mantissa, exponent, self.negative);
  return new _M0DTPC16result6ResultGdRPC15error5ErrorE2Ok($i64_reinterpret_f64(bits));
}
function _M0FPC28internal7strconv17pow10__fast__path(exponent) {
  return _M0MPC15array13ReadOnlyArray2atGdE(_M0FPC28internal7strconv5table, exponent & 31);
}
function _M0MPC28internal7strconv6Number14is__fast__path(self) {
  return BigInt.asIntN(64, _M0FPC28internal7strconv25min__exponent__fast__path) <= BigInt.asIntN(64, self.exponent) && (BigInt.asIntN(64, self.exponent) <= BigInt.asIntN(64, _M0FPC28internal7strconv36max__exponent__disguised__fast__path) && (BigInt.asUintN(64, self.mantissa) <= BigInt.asUintN(64, _M0FPC28internal7strconv25max__mantissa__fast__path) && !self.many_digits));
}
function _M0MPC28internal7strconv6Number15try__fast__path(self) {
  if (_M0MPC28internal7strconv6Number14is__fast__path(self)) {
    let value;
    if (BigInt.asIntN(64, self.exponent) <= BigInt.asIntN(64, _M0FPC28internal7strconv25max__exponent__fast__path)) {
      const value$2 = $f64_convert_i64_u(BigInt.asUintN(64, self.mantissa));
      value = BigInt.asIntN(64, self.exponent) < BigInt.asIntN(64, 0n) ? value$2 / _M0FPC28internal7strconv17pow10__fast__path(-(Number(BigInt.asIntN(32, self.exponent)) | 0) | 0) : value$2 * _M0FPC28internal7strconv17pow10__fast__path(Number(BigInt.asIntN(32, self.exponent)) | 0);
    } else {
      const shift = BigInt.asUintN(64, self.exponent - _M0FPC28internal7strconv25max__exponent__fast__path);
      const _bind = _M0FPC28internal7strconv12checked__mul(self.mantissa, _M0MPC15array13ReadOnlyArray2atGmE(_M0FPC28internal7strconv10int__pow10, Number(BigInt.asIntN(32, shift)) | 0));
      let mantissa;
      if (_bind === undefined) {
        return _M0DTPC16option6OptionGdE4None__;
      } else {
        const _Some = _bind;
        mantissa = _Some;
      }
      if (BigInt.asUintN(64, mantissa) > BigInt.asUintN(64, _M0FPC28internal7strconv25max__mantissa__fast__path)) {
        return _M0DTPC16option6OptionGdE4None__;
      }
      value = $f64_convert_i64_u(BigInt.asUintN(64, mantissa)) * _M0FPC28internal7strconv17pow10__fast__path(Number(BigInt.asIntN(32, _M0FPC28internal7strconv25max__exponent__fast__path)) | 0);
    }
    if (self.negative) {
      value = -value;
    }
    return new _M0DTPC16option6OptionGdE4Some(value);
  } else {
    return _M0DTPC16option6OptionGdE4None__;
  }
}
function _M0FPC28internal7strconv13parse__double(str) {
  if (_M0MPC16string10StringView6length(str) > 0) {
    if (_M0FPC28internal7strconv17check__underscore(str)) {
      const _bind = _M0FPC28internal7strconv13parse__number(str);
      let _bind$2;
      if (_bind.$tag === 1) {
        const _ok = _bind;
        _bind$2 = _ok._0;
      } else {
        return _bind;
      }
      if (_bind$2 === undefined) {
        return _M0FPC28internal7strconv15parse__inf__nan(str);
      } else {
        const _Some = _bind$2;
        const _num = _Some;
        const _bind$3 = _M0MPC28internal7strconv6Number15try__fast__path(_num);
        if (_bind$3.$tag === 1) {
          const _Some$2 = _bind$3;
          const _value = _Some$2._0;
          return new _M0DTPC16result6ResultGdRPC15error5ErrorE2Ok(_value);
        } else {
          const _bind$4 = _M0FPC28internal7strconv20parse__decimal__priv(str);
          let _tmp;
          if (_bind$4.$tag === 1) {
            const _ok = _bind$4;
            _tmp = _ok._0;
          } else {
            return _bind$4;
          }
          return _M0MPC28internal7strconv7Decimal16to__double__priv(_tmp);
        }
      }
    } else {
      return _M0FPC28internal7strconv11syntax__errGdE();
    }
  } else {
    return _M0FPC28internal7strconv11syntax__errGdE();
  }
}
function _M0FPC14json20offset__to__position(input, offset) {
  let _tmp = 0;
  let _tmp$2 = 1;
  let _tmp$3 = 0;
  while (true) {
    const i = _tmp;
    const line = _tmp$2;
    const column = _tmp$3;
    if (i < offset) {
      if (_M0IPC16uint166UInt16PB2Eq5equal(_M0MPC16string10StringView11unsafe__get(input, i), 10)) {
        _tmp = i + 1 | 0;
        _tmp$2 = line + 1 | 0;
        _tmp$3 = 0;
        continue;
      } else {
        _tmp = i + 1 | 0;
        _tmp$3 = column + 1 | 0;
        continue;
      }
    } else {
      return new _M0TPC14json8Position(line, column);
    }
  }
}
function _M0MPC14json12ParseContext21invalid__char_2einnerGRPB4JsonE(ctx, shift) {
  const offset = ctx.offset + shift | 0;
  return new _M0DTPC16result6ResultGRPB4JsonRPC14json10ParseErrorE3Err(new _M0DTPC15error5Error52moonbitlang_2fcore_2fjson_2eParseError_2eInvalidChar(_M0FPC14json20offset__to__position(ctx.input, offset), _M0MPC16option6Option10unwrap__orGcE(_M0MPC16string10StringView9get__char(ctx.input, offset), 65533)));
}
function _M0MPC14json12ParseContext21invalid__char_2einnerGuE(ctx, shift) {
  const offset = ctx.offset + shift | 0;
  return new _M0DTPC16result6ResultGuRPC14json10ParseErrorE3Err(new _M0DTPC15error5Error52moonbitlang_2fcore_2fjson_2eParseError_2eInvalidChar(_M0FPC14json20offset__to__position(ctx.input, offset), _M0MPC16option6Option10unwrap__orGcE(_M0MPC16string10StringView9get__char(ctx.input, offset), 65533)));
}
function _M0MPC14json12ParseContext21lex__skip__whitespace(ctx) {
  const rest = _M0MPC16string10StringView12view_2einner(ctx.input, ctx.offset, ctx.end_offset);
  const _data = _M0MPC16string10StringView4data(rest);
  const _start = _M0MPC16string10StringView13start__offset(rest);
  const _end = _start + _M0MPC16string10StringView6length(rest) | 0;
  let _cursor = _start;
  let accept_state = -1;
  let match_end = -1;
  _L: {
    if (_cursor < _end) {
      _L$2: {
        const next_char = _M0MPC16string6String20unsafe__charcode__at(_data, _cursor);
        _cursor = _cursor + 1 | 0;
        if (next_char < 13) {
          if (next_char >= 9 && next_char <= 10) {
            break _L$2;
          } else {
            break _L;
          }
        } else {
          if (next_char > 13) {
            if (next_char === 32) {
              break _L$2;
            } else {
              break _L;
            }
          } else {
            break _L$2;
          }
        }
      }
      while (true) {
        accept_state = 0;
        match_end = _cursor;
        if (_cursor < _end) {
          _L$3: {
            const next_char = _M0MPC16string6String20unsafe__charcode__at(_data, _cursor);
            _cursor = _cursor + 1 | 0;
            if (next_char < 13) {
              if (next_char >= 9 && next_char <= 10) {
                break _L$3;
              } else {
                break _L;
              }
            } else {
              if (next_char > 13) {
                if (next_char === 32) {
                  break _L$3;
                } else {
                  break _L;
                }
              } else {
                break _L$3;
              }
            }
          }
          continue;
        } else {
          break _L;
        }
      }
    } else {
      break _L;
    }
  }
  if (accept_state === 0) {
    const next = _M0MPC16string6String4view(_data, match_end, _end);
    ctx.offset = ctx.end_offset - _M0MPC16string10StringView6length(next) | 0;
    return;
  } else {
    return;
  }
}
function _M0MPC14json12ParseContext4make(input, max_nesting_depth) {
  return new _M0TPC14json12ParseContext(0, input, _M0MPC16string10StringView6length(input), max_nesting_depth);
}
function _M0MPC14json12ParseContext19expect__ascii__char(ctx, c) {
  if (ctx.offset < ctx.end_offset) {
    const c1 = _M0MPC16string10StringView11unsafe__get(ctx.input, ctx.offset);
    ctx.offset = ctx.offset + 1 | 0;
    return c !== c1 ? _M0MPC14json12ParseContext21invalid__char_2einnerGuE(ctx, -1) : new _M0DTPC16result6ResultGuRPC14json10ParseErrorE2Ok(undefined);
  } else {
    return new _M0DTPC16result6ResultGuRPC14json10ParseErrorE3Err(_M0DTPC15error5Error51moonbitlang_2fcore_2fjson_2eParseError_2eInvalidEof__);
  }
}
function _M0MPC14json12ParseContext16lex__number__end(ctx, start, end) {
  const s = _M0MPC16string10StringView12view_2einner(ctx.input, start, end);
  if (!_M0MPC16string10StringView8contains(s, new _M0TPC16string10StringView(_M0MPC14json12ParseContext16lex__number__endN7_2abindS1061, 0, _M0MPC14json12ParseContext16lex__number__endN7_2abindS1061.length)) && (!_M0MPC16string10StringView8contains(s, new _M0TPC16string10StringView(_M0MPC14json12ParseContext16lex__number__endN7_2abindS1062, 0, _M0MPC14json12ParseContext16lex__number__endN7_2abindS1062.length)) && !_M0MPC16string10StringView8contains(s, new _M0TPC16string10StringView(_M0MPC14json12ParseContext16lex__number__endN7_2abindS1063, 0, _M0MPC14json12ParseContext16lex__number__endN7_2abindS1063.length)))) {
    let parsed_int;
    let _try_err;
    _L: {
      _L$2: {
        const _bind = _M0FPC28internal7strconv20parse__int64_2einner(s, 0);
        let _tmp;
        if (_bind.$tag === 1) {
          const _ok = _bind;
          _tmp = _ok._0;
        } else {
          const _err = _bind;
          _try_err = _err._0;
          break _L$2;
        }
        parsed_int = new _M0DTPC16result6ResultGlRPC15error5ErrorE2Ok(_tmp);
        break _L;
      }
      parsed_int = new _M0DTPC16result6ResultGlRPC15error5ErrorE3Err(_try_err);
    }
    _L$2: {
      if (parsed_int.$tag === 1) {
        const _Ok = parsed_int;
        const _i = _Ok._0;
        if (BigInt.asIntN(64, _i) <= BigInt.asIntN(64, 9007199254740991n) && BigInt.asIntN(64, _i) >= BigInt.asIntN(64, 18437736874454810625n)) {
          return { _0: $f64_convert_i64(BigInt.asIntN(64, _i)), _1: undefined };
        } else {
          break _L$2;
        }
      } else {
        break _L$2;
      }
    }
    _L$3: {
      if (_M0MPC16string6String24char__length__ge_2einner(s.str, 1, s.start, s.end)) {
        const _x = _M0MPC16string6String16unsafe__char__at(s.str, _M0MPC16string6String29offset__of__nth__char_2einner(s.str, 0, s.start, s.end));
        if (_x === 45) {
          return { _0: _M0FPC16double13neg__infinity, _1: s };
        } else {
          break _L$3;
        }
      } else {
        break _L$3;
      }
    }
    return { _0: _M0FPC16double8infinity, _1: s };
  } else {
    let parsed_double;
    let _try_err;
    _L: {
      _L$2: {
        const _bind = _M0FPC28internal7strconv13parse__double(s);
        let _tmp;
        if (_bind.$tag === 1) {
          const _ok = _bind;
          _tmp = _ok._0;
        } else {
          const _err = _bind;
          _try_err = _err._0;
          break _L$2;
        }
        parsed_double = new _M0DTPC16result6ResultGdRPC15error5ErrorE2Ok(_tmp);
        break _L;
      }
      parsed_double = new _M0DTPC16result6ResultGdRPC15error5ErrorE3Err(_try_err);
    }
    if (parsed_double.$tag === 1) {
      const _Ok = parsed_double;
      const _d = _Ok._0;
      return { _0: _d, _1: undefined };
    } else {
      _L$2: {
        if (_M0MPC16string6String24char__length__ge_2einner(s.str, 1, s.start, s.end)) {
          const _x = _M0MPC16string6String16unsafe__char__at(s.str, _M0MPC16string6String29offset__of__nth__char_2einner(s.str, 0, s.start, s.end));
          if (_x === 45) {
            return { _0: _M0FPC16double13neg__infinity, _1: s };
          } else {
            break _L$2;
          }
        } else {
          break _L$2;
        }
      }
      return { _0: _M0FPC16double8infinity, _1: s };
    }
  }
}
function _M0MPC14json12ParseContext10read__char(ctx) {
  if (ctx.offset < ctx.end_offset) {
    const c1 = _M0MPC16string10StringView11unsafe__get(ctx.input, ctx.offset);
    ctx.offset = ctx.offset + 1 | 0;
    if (c1 >= 55296 && c1 <= 56319) {
      if (ctx.offset < ctx.end_offset) {
        const c2 = _M0MPC16string10StringView11unsafe__get(ctx.input, ctx.offset);
        if (c2 >= 56320 && c2 <= 57343) {
          ctx.offset = ctx.offset + 1 | 0;
          const c3 = ((c1 << 10) + c2 | 0) - 56613888 | 0;
          return c3;
        }
      }
    }
    return c1;
  } else {
    return -1;
  }
}
function _M0MPC14json12ParseContext31lex__decimal__exponent__integer(ctx, start) {
  while (true) {
    const _bind = _M0MPC14json12ParseContext10read__char(ctx);
    if (_bind === -1) {
      return _M0MPC14json12ParseContext16lex__number__end(ctx, start, ctx.offset);
    } else {
      const _Some = _bind;
      const _c = _Some;
      if (_c >= 48 && _c <= 57) {
        continue;
      }
      ctx.offset = ctx.offset - 1 | 0;
      return _M0MPC14json12ParseContext16lex__number__end(ctx, start, ctx.offset);
    }
  }
}
function _M0MPC14json12ParseContext28lex__decimal__exponent__sign(ctx, start) {
  const _bind = _M0MPC14json12ParseContext10read__char(ctx);
  if (_bind === -1) {
    return new _M0DTPC16result6ResultGUdORPC16string10StringViewERPC14json10ParseErrorE3Err(_M0DTPC15error5Error51moonbitlang_2fcore_2fjson_2eParseError_2eInvalidEof__);
  } else {
    const _Some = _bind;
    const _c = _Some;
    if (_c >= 48 && _c <= 57) {
      return new _M0DTPC16result6ResultGUdORPC16string10StringViewERPC14json10ParseErrorE2Ok(_M0MPC14json12ParseContext31lex__decimal__exponent__integer(ctx, start));
    }
    ctx.offset = ctx.offset - 1 | 0;
    return _M0MPC14json12ParseContext21invalid__char_2einnerGRPB4JsonE(ctx, 0);
  }
}
function _M0MPC14json12ParseContext22lex__decimal__exponent(ctx, start) {
  _L: {
    const _bind = _M0MPC14json12ParseContext10read__char(ctx);
    if (_bind === -1) {
      return new _M0DTPC16result6ResultGUdORPC16string10StringViewERPC14json10ParseErrorE3Err(_M0DTPC15error5Error51moonbitlang_2fcore_2fjson_2eParseError_2eInvalidEof__);
    } else {
      const _Some = _bind;
      const _x = _Some;
      switch (_x) {
        case 43: {
          break _L;
        }
        case 45: {
          break _L;
        }
        default: {
          if (_x >= 48 && _x <= 57) {
            return new _M0DTPC16result6ResultGUdORPC16string10StringViewERPC14json10ParseErrorE2Ok(_M0MPC14json12ParseContext31lex__decimal__exponent__integer(ctx, start));
          }
          ctx.offset = ctx.offset - 1 | 0;
          return _M0MPC14json12ParseContext21invalid__char_2einnerGRPB4JsonE(ctx, 0);
        }
      }
    }
  }
  const _bind = _M0MPC14json12ParseContext28lex__decimal__exponent__sign(ctx, start);
  let _tmp;
  if (_bind.$tag === 1) {
    const _ok = _bind;
    _tmp = _ok._0;
  } else {
    return _bind;
  }
  return new _M0DTPC16result6ResultGUdORPC16string10StringViewERPC14json10ParseErrorE2Ok(_tmp);
}
function _M0MPC14json12ParseContext22lex__decimal__fraction(ctx, start) {
  let _tmp;
  _L: while (true) {
    _L$2: {
      const _bind = _M0MPC14json12ParseContext10read__char(ctx);
      if (_bind === -1) {
        return new _M0DTPC16result6ResultGUdORPC16string10StringViewERPC14json10ParseErrorE2Ok(_M0MPC14json12ParseContext16lex__number__end(ctx, start, ctx.offset));
      } else {
        const _Some = _bind;
        const _x = _Some;
        switch (_x) {
          case 101: {
            break _L$2;
          }
          case 69: {
            break _L$2;
          }
          default: {
            if (_x >= 48 && _x <= 57) {
              continue _L;
            }
            ctx.offset = ctx.offset - 1 | 0;
            return new _M0DTPC16result6ResultGUdORPC16string10StringViewERPC14json10ParseErrorE2Ok(_M0MPC14json12ParseContext16lex__number__end(ctx, start, ctx.offset));
          }
        }
      }
    }
    const _bind = _M0MPC14json12ParseContext22lex__decimal__exponent(ctx, start);
    let _tmp$2;
    if (_bind.$tag === 1) {
      const _ok = _bind;
      _tmp$2 = _ok._0;
    } else {
      return _bind;
    }
    return new _M0DTPC16result6ResultGUdORPC16string10StringViewERPC14json10ParseErrorE2Ok(_tmp$2);
  }
  return new _M0DTPC16result6ResultGUdORPC16string10StringViewERPC14json10ParseErrorE2Ok(_tmp);
}
function _M0MPC14json12ParseContext19lex__decimal__point(ctx, start) {
  const _bind = _M0MPC14json12ParseContext10read__char(ctx);
  if (_bind === -1) {
    return new _M0DTPC16result6ResultGUdORPC16string10StringViewERPC14json10ParseErrorE3Err(_M0DTPC15error5Error51moonbitlang_2fcore_2fjson_2eParseError_2eInvalidEof__);
  } else {
    const _Some = _bind;
    const _c = _Some;
    return _c >= 48 && _c <= 57 ? _M0MPC14json12ParseContext22lex__decimal__fraction(ctx, start) : _M0MPC14json12ParseContext21invalid__char_2einnerGRPB4JsonE(ctx, -1);
  }
}
function _M0MPC14json12ParseContext21lex__decimal__integer(ctx, start) {
  let _tmp;
  _L: while (true) {
    _L$2: {
      const _bind = _M0MPC14json12ParseContext10read__char(ctx);
      if (_bind === -1) {
        return new _M0DTPC16result6ResultGUdORPC16string10StringViewERPC14json10ParseErrorE2Ok(_M0MPC14json12ParseContext16lex__number__end(ctx, start, ctx.offset));
      } else {
        const _Some = _bind;
        const _x = _Some;
        switch (_x) {
          case 46: {
            const _bind$2 = _M0MPC14json12ParseContext19lex__decimal__point(ctx, start);
            let _tmp$2;
            if (_bind$2.$tag === 1) {
              const _ok = _bind$2;
              _tmp$2 = _ok._0;
            } else {
              return _bind$2;
            }
            return new _M0DTPC16result6ResultGUdORPC16string10StringViewERPC14json10ParseErrorE2Ok(_tmp$2);
          }
          case 101: {
            break _L$2;
          }
          case 69: {
            break _L$2;
          }
          default: {
            if (_x >= 48 && _x <= 57) {
              continue _L;
            }
            ctx.offset = ctx.offset - 1 | 0;
            return new _M0DTPC16result6ResultGUdORPC16string10StringViewERPC14json10ParseErrorE2Ok(_M0MPC14json12ParseContext16lex__number__end(ctx, start, ctx.offset));
          }
        }
      }
    }
    const _bind = _M0MPC14json12ParseContext22lex__decimal__exponent(ctx, start);
    let _tmp$2;
    if (_bind.$tag === 1) {
      const _ok = _bind;
      _tmp$2 = _ok._0;
    } else {
      return _bind;
    }
    return new _M0DTPC16result6ResultGUdORPC16string10StringViewERPC14json10ParseErrorE2Ok(_tmp$2);
  }
  return new _M0DTPC16result6ResultGUdORPC16string10StringViewERPC14json10ParseErrorE2Ok(_tmp);
}
function _M0MPC14json12ParseContext16lex__hex__digits(ctx, n) {
  let _tmp;
  let _tmp$2 = 0;
  let _tmp$3 = 0;
  while (true) {
    const _ = _tmp$2;
    const r = _tmp$3;
    if (_ < n) {
      const _bind = _M0MPC14json12ParseContext10read__char(ctx);
      if (_bind === -1) {
        return new _M0DTPC16result6ResultGiRPC14json10ParseErrorE3Err(_M0DTPC15error5Error51moonbitlang_2fcore_2fjson_2eParseError_2eInvalidEof__);
      } else {
        const _Some = _bind;
        const _c = _Some;
        if (_c >= 65) {
          const d = ((_c & ~32) - 65 | 0) + 10 | 0;
          if (d > 15) {
            const _bind$2 = _M0MPC14json12ParseContext21invalid__char_2einnerGuE(ctx, -1);
            if (_bind$2.$tag === 1) {
              const _ok = _bind$2;
              _ok._0;
            } else {
              return _bind$2;
            }
          }
          _tmp$2 = _ + 1 | 0;
          _tmp$3 = r << 4 | d;
          continue;
        } else {
          if (_c >= 48) {
            const d = _c - 48 | 0;
            if (d > 9) {
              const _bind$2 = _M0MPC14json12ParseContext21invalid__char_2einnerGuE(ctx, -1);
              if (_bind$2.$tag === 1) {
                const _ok = _bind$2;
                _ok._0;
              } else {
                return _bind$2;
              }
            }
            _tmp$2 = _ + 1 | 0;
            _tmp$3 = r << 4 | d;
            continue;
          } else {
            const _bind$2 = _M0MPC14json12ParseContext21invalid__char_2einnerGuE(ctx, -1);
            if (_bind$2.$tag === 1) {
              const _ok = _bind$2;
              _ok._0;
            } else {
              return _bind$2;
            }
          }
        }
      }
      _tmp$2 = _ + 1 | 0;
      continue;
    } else {
      _tmp = r;
      break;
    }
  }
  return new _M0DTPC16result6ResultGiRPC14json10ParseErrorE2Ok(_tmp);
}
function _M0MPC14json12ParseContext11lex__stringN5flushS276(_env, end) {
  const ctx = _env._2;
  const start = _env._1;
  const buf = _env._0;
  if (start.val > 0 && end > start.val) {
    _M0IPB13StringBuilderPB6Logger11write__view(buf, _M0MPC16string10StringView11sub_2einner(ctx.input, start.val, end));
    return;
  } else {
    return;
  }
}
function _M0MPC14json12ParseContext11lex__string(ctx) {
  const buf = _M0MPB13StringBuilder11new_2einner(0);
  const start = new _M0TPB8MutLocalGiE(ctx.offset);
  const _env = { _0: buf, _1: start, _2: ctx };
  _L: while (true) {
    _L$2: {
      _L$3: {
        const _bind = _M0MPC14json12ParseContext10read__char(ctx);
        if (_bind === -1) {
          return new _M0DTPC16result6ResultGsRPC14json10ParseErrorE3Err(_M0DTPC15error5Error51moonbitlang_2fcore_2fjson_2eParseError_2eInvalidEof__);
        } else {
          const _Some = _bind;
          const _x = _Some;
          switch (_x) {
            case 34: {
              _M0MPC14json12ParseContext11lex__stringN5flushS276(_env, ctx.offset - 1 | 0);
              break _L;
            }
            case 10: {
              break _L$3;
            }
            case 13: {
              break _L$3;
            }
            case 92: {
              _M0MPC14json12ParseContext11lex__stringN5flushS276(_env, ctx.offset - 1 | 0);
              const _bind$2 = _M0MPC14json12ParseContext10read__char(ctx);
              if (_bind$2 === -1) {
                return new _M0DTPC16result6ResultGsRPC14json10ParseErrorE3Err(_M0DTPC15error5Error51moonbitlang_2fcore_2fjson_2eParseError_2eInvalidEof__);
              } else {
                const _Some$2 = _bind$2;
                const _x$2 = _Some$2;
                switch (_x$2) {
                  case 98: {
                    _M0IPB13StringBuilderPB6Logger11write__char(buf, 8);
                    break;
                  }
                  case 102: {
                    _M0IPB13StringBuilderPB6Logger11write__char(buf, 12);
                    break;
                  }
                  case 110: {
                    _M0IPB13StringBuilderPB6Logger11write__char(buf, 10);
                    break;
                  }
                  case 114: {
                    _M0IPB13StringBuilderPB6Logger11write__char(buf, 13);
                    break;
                  }
                  case 116: {
                    _M0IPB13StringBuilderPB6Logger11write__char(buf, 9);
                    break;
                  }
                  case 34: {
                    _M0IPB13StringBuilderPB6Logger11write__char(buf, 34);
                    break;
                  }
                  case 92: {
                    _M0IPB13StringBuilderPB6Logger11write__char(buf, 92);
                    break;
                  }
                  case 47: {
                    _M0IPB13StringBuilderPB6Logger11write__char(buf, 47);
                    break;
                  }
                  case 117: {
                    const _bind$3 = _M0MPC14json12ParseContext16lex__hex__digits(ctx, 4);
                    let c;
                    if (_bind$3.$tag === 1) {
                      const _ok = _bind$3;
                      c = _ok._0;
                    } else {
                      return _bind$3;
                    }
                    _M0IPB13StringBuilderPB6Logger11write__char(buf, c);
                    break;
                  }
                  default: {
                    const _bind$4 = _M0MPC14json12ParseContext21invalid__char_2einnerGuE(ctx, -1);
                    if (_bind$4.$tag === 1) {
                      const _ok = _bind$4;
                      _ok._0;
                    } else {
                      return _bind$4;
                    }
                  }
                }
              }
              start.val = ctx.offset;
              break;
            }
            default: {
              if (_x < 32) {
                const _bind$3 = _M0MPC14json12ParseContext21invalid__char_2einnerGuE(ctx, -1);
                if (_bind$3.$tag === 1) {
                  const _ok = _bind$3;
                  _ok._0;
                } else {
                  return _bind$3;
                }
              } else {
                continue _L;
              }
            }
          }
        }
        break _L$2;
      }
      const _bind = _M0MPC14json12ParseContext21invalid__char_2einnerGuE(ctx, -1);
      if (_bind.$tag === 1) {
        const _ok = _bind;
        _ok._0;
      } else {
        return _bind;
      }
    }
    continue;
  }
  return new _M0DTPC16result6ResultGsRPC14json10ParseErrorE2Ok(_M0MPB13StringBuilder10to__string(buf));
}
function _M0MPC14json12ParseContext9lex__zero(ctx, start) {
  _L: {
    const _bind = _M0MPC14json12ParseContext10read__char(ctx);
    if (_bind === -1) {
      return new _M0DTPC16result6ResultGUdORPC16string10StringViewERPC14json10ParseErrorE2Ok(_M0MPC14json12ParseContext16lex__number__end(ctx, start, ctx.offset));
    } else {
      const _Some = _bind;
      const _x = _Some;
      switch (_x) {
        case 46: {
          return _M0MPC14json12ParseContext19lex__decimal__point(ctx, start);
        }
        case 101: {
          break _L;
        }
        case 69: {
          break _L;
        }
        default: {
          if (_x >= 48 && _x <= 57) {
            ctx.offset = ctx.offset - 1 | 0;
            const _bind$2 = _M0MPC14json12ParseContext21invalid__char_2einnerGuE(ctx, 0);
            if (_bind$2.$tag === 1) {
              const _ok = _bind$2;
              _ok._0;
            } else {
              return _bind$2;
            }
          }
          ctx.offset = ctx.offset - 1 | 0;
          return new _M0DTPC16result6ResultGUdORPC16string10StringViewERPC14json10ParseErrorE2Ok(_M0MPC14json12ParseContext16lex__number__end(ctx, start, ctx.offset));
        }
      }
    }
  }
  return _M0MPC14json12ParseContext22lex__decimal__exponent(ctx, start);
}
function _M0MPC14json12ParseContext10lex__value(ctx, allow_rbracket) {
  _M0MPC14json12ParseContext21lex__skip__whitespace(ctx);
  const _bind = _M0MPC14json12ParseContext10read__char(ctx);
  if (_bind === -1) {
    return new _M0DTPC16result6ResultGRPC14json5TokenRPC14json10ParseErrorE3Err(_M0DTPC15error5Error51moonbitlang_2fcore_2fjson_2eParseError_2eInvalidEof__);
  } else {
    const _Some = _bind;
    const _x = _Some;
    if (_x === 123) {
      return new _M0DTPC16result6ResultGRPC14json5TokenRPC14json10ParseErrorE2Ok(_M0DTPC14json5Token6LBrace__);
    } else {
      if (_x === 91) {
        return new _M0DTPC16result6ResultGRPC14json5TokenRPC14json10ParseErrorE2Ok(_M0DTPC14json5Token8LBracket__);
      } else {
        if (_x === 93) {
          if (allow_rbracket) {
            return new _M0DTPC16result6ResultGRPC14json5TokenRPC14json10ParseErrorE2Ok(_M0DTPC14json5Token8RBracket__);
          } else {
            return _M0MPC14json12ParseContext21invalid__char_2einnerGRPB4JsonE(ctx, -1);
          }
        } else {
          if (_x === 110) {
            const _bind$2 = _M0MPC14json12ParseContext19expect__ascii__char(ctx, 117);
            if (_bind$2.$tag === 1) {
              const _ok = _bind$2;
              _ok._0;
            } else {
              return _bind$2;
            }
            const _bind$3 = _M0MPC14json12ParseContext19expect__ascii__char(ctx, 108);
            if (_bind$3.$tag === 1) {
              const _ok = _bind$3;
              _ok._0;
            } else {
              return _bind$3;
            }
            const _bind$4 = _M0MPC14json12ParseContext19expect__ascii__char(ctx, 108);
            if (_bind$4.$tag === 1) {
              const _ok = _bind$4;
              _ok._0;
            } else {
              return _bind$4;
            }
            return new _M0DTPC16result6ResultGRPC14json5TokenRPC14json10ParseErrorE2Ok(_M0DTPC14json5Token4Null__);
          } else {
            if (_x === 116) {
              const _bind$2 = _M0MPC14json12ParseContext19expect__ascii__char(ctx, 114);
              if (_bind$2.$tag === 1) {
                const _ok = _bind$2;
                _ok._0;
              } else {
                return _bind$2;
              }
              const _bind$3 = _M0MPC14json12ParseContext19expect__ascii__char(ctx, 117);
              if (_bind$3.$tag === 1) {
                const _ok = _bind$3;
                _ok._0;
              } else {
                return _bind$3;
              }
              const _bind$4 = _M0MPC14json12ParseContext19expect__ascii__char(ctx, 101);
              if (_bind$4.$tag === 1) {
                const _ok = _bind$4;
                _ok._0;
              } else {
                return _bind$4;
              }
              return new _M0DTPC16result6ResultGRPC14json5TokenRPC14json10ParseErrorE2Ok(_M0DTPC14json5Token4True__);
            } else {
              if (_x === 102) {
                const _bind$2 = _M0MPC14json12ParseContext19expect__ascii__char(ctx, 97);
                if (_bind$2.$tag === 1) {
                  const _ok = _bind$2;
                  _ok._0;
                } else {
                  return _bind$2;
                }
                const _bind$3 = _M0MPC14json12ParseContext19expect__ascii__char(ctx, 108);
                if (_bind$3.$tag === 1) {
                  const _ok = _bind$3;
                  _ok._0;
                } else {
                  return _bind$3;
                }
                const _bind$4 = _M0MPC14json12ParseContext19expect__ascii__char(ctx, 115);
                if (_bind$4.$tag === 1) {
                  const _ok = _bind$4;
                  _ok._0;
                } else {
                  return _bind$4;
                }
                const _bind$5 = _M0MPC14json12ParseContext19expect__ascii__char(ctx, 101);
                if (_bind$5.$tag === 1) {
                  const _ok = _bind$5;
                  _ok._0;
                } else {
                  return _bind$5;
                }
                return new _M0DTPC16result6ResultGRPC14json5TokenRPC14json10ParseErrorE2Ok(_M0DTPC14json5Token5False__);
              } else {
                if (_x === 45) {
                  const _bind$2 = _M0MPC14json12ParseContext10read__char(ctx);
                  if (_bind$2 === -1) {
                    return new _M0DTPC16result6ResultGRPC14json5TokenRPC14json10ParseErrorE3Err(_M0DTPC15error5Error51moonbitlang_2fcore_2fjson_2eParseError_2eInvalidEof__);
                  } else {
                    const _Some$2 = _bind$2;
                    const _x$2 = _Some$2;
                    if (_x$2 === 48) {
                      const _bind$3 = _M0MPC14json12ParseContext9lex__zero(ctx, ctx.offset - 2 | 0);
                      let _bind$4;
                      if (_bind$3.$tag === 1) {
                        const _ok = _bind$3;
                        _bind$4 = _ok._0;
                      } else {
                        return _bind$3;
                      }
                      const _n = _bind$4._0;
                      const _repr = _bind$4._1;
                      return new _M0DTPC16result6ResultGRPC14json5TokenRPC14json10ParseErrorE2Ok(new _M0DTPC14json5Token6Number(_n, _M0MPC16option6Option3mapGRPC16string10StringViewsE(_repr, (repr) => _M0IPC16string10StringViewPB4Show10to__string(repr))));
                    } else {
                      if (_x$2 >= 49 && _x$2 <= 57) {
                        const _bind$3 = _M0MPC14json12ParseContext21lex__decimal__integer(ctx, ctx.offset - 2 | 0);
                        let _bind$4;
                        if (_bind$3.$tag === 1) {
                          const _ok = _bind$3;
                          _bind$4 = _ok._0;
                        } else {
                          return _bind$3;
                        }
                        const _n = _bind$4._0;
                        const _repr = _bind$4._1;
                        return new _M0DTPC16result6ResultGRPC14json5TokenRPC14json10ParseErrorE2Ok(new _M0DTPC14json5Token6Number(_n, _M0MPC16option6Option3mapGRPC16string10StringViewsE(_repr, (repr) => _M0IPC16string10StringViewPB4Show10to__string(repr))));
                      }
                      return _M0MPC14json12ParseContext21invalid__char_2einnerGRPB4JsonE(ctx, -1);
                    }
                  }
                } else {
                  if (_x === 48) {
                    const _bind$2 = _M0MPC14json12ParseContext9lex__zero(ctx, ctx.offset - 1 | 0);
                    let _bind$3;
                    if (_bind$2.$tag === 1) {
                      const _ok = _bind$2;
                      _bind$3 = _ok._0;
                    } else {
                      return _bind$2;
                    }
                    const _n = _bind$3._0;
                    const _repr = _bind$3._1;
                    return new _M0DTPC16result6ResultGRPC14json5TokenRPC14json10ParseErrorE2Ok(new _M0DTPC14json5Token6Number(_n, _M0MPC16option6Option3mapGRPC16string10StringViewsE(_repr, (repr) => _M0IPC16string10StringViewPB4Show10to__string(repr))));
                  } else {
                    if (_x >= 49 && _x <= 57) {
                      const _bind$2 = _M0MPC14json12ParseContext21lex__decimal__integer(ctx, ctx.offset - 1 | 0);
                      let _bind$3;
                      if (_bind$2.$tag === 1) {
                        const _ok = _bind$2;
                        _bind$3 = _ok._0;
                      } else {
                        return _bind$2;
                      }
                      const _n = _bind$3._0;
                      const _repr = _bind$3._1;
                      return new _M0DTPC16result6ResultGRPC14json5TokenRPC14json10ParseErrorE2Ok(new _M0DTPC14json5Token6Number(_n, _M0MPC16option6Option3mapGRPC16string10StringViewsE(_repr, (repr) => _M0IPC16string10StringViewPB4Show10to__string(repr))));
                    } else {
                      if (_x === 34) {
                        const _bind$2 = _M0MPC14json12ParseContext11lex__string(ctx);
                        let s;
                        if (_bind$2.$tag === 1) {
                          const _ok = _bind$2;
                          s = _ok._0;
                        } else {
                          return _bind$2;
                        }
                        return new _M0DTPC16result6ResultGRPC14json5TokenRPC14json10ParseErrorE2Ok(new _M0DTPC14json5Token6String(s));
                      } else {
                        const shift = -_M0MPC14char4Char10utf16__len(_x) | 0;
                        return _M0MPC14json12ParseContext21invalid__char_2einnerGRPB4JsonE(ctx, shift);
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
function _M0MPC14json12ParseContext24lex__after__array__value(ctx) {
  _M0MPC14json12ParseContext21lex__skip__whitespace(ctx);
  const _bind = _M0MPC14json12ParseContext10read__char(ctx);
  if (_bind === -1) {
    return new _M0DTPC16result6ResultGRPC14json5TokenRPC14json10ParseErrorE3Err(_M0DTPC15error5Error51moonbitlang_2fcore_2fjson_2eParseError_2eInvalidEof__);
  } else {
    const _Some = _bind;
    const _x = _Some;
    switch (_x) {
      case 93: {
        return new _M0DTPC16result6ResultGRPC14json5TokenRPC14json10ParseErrorE2Ok(_M0DTPC14json5Token8RBracket__);
      }
      case 44: {
        return new _M0DTPC16result6ResultGRPC14json5TokenRPC14json10ParseErrorE2Ok(_M0DTPC14json5Token5Comma__);
      }
      default: {
        return _M0MPC14json12ParseContext21invalid__char_2einnerGRPB4JsonE(ctx, -1);
      }
    }
  }
}
function _M0MPC14json12ParseContext25lex__after__object__value(ctx) {
  _M0MPC14json12ParseContext21lex__skip__whitespace(ctx);
  const _bind = _M0MPC14json12ParseContext10read__char(ctx);
  if (_bind === -1) {
    return new _M0DTPC16result6ResultGRPC14json5TokenRPC14json10ParseErrorE3Err(_M0DTPC15error5Error51moonbitlang_2fcore_2fjson_2eParseError_2eInvalidEof__);
  } else {
    const _Some = _bind;
    const _x = _Some;
    switch (_x) {
      case 125: {
        return new _M0DTPC16result6ResultGRPC14json5TokenRPC14json10ParseErrorE2Ok(_M0DTPC14json5Token6RBrace__);
      }
      case 44: {
        return new _M0DTPC16result6ResultGRPC14json5TokenRPC14json10ParseErrorE2Ok(_M0DTPC14json5Token5Comma__);
      }
      default: {
        return _M0MPC14json12ParseContext21invalid__char_2einnerGRPB4JsonE(ctx, -1);
      }
    }
  }
}
function _M0MPC14json12ParseContext26lex__after__property__name(ctx) {
  _M0MPC14json12ParseContext21lex__skip__whitespace(ctx);
  const _bind = _M0MPC14json12ParseContext10read__char(ctx);
  if (_bind === -1) {
    return new _M0DTPC16result6ResultGuRPC14json10ParseErrorE3Err(_M0DTPC15error5Error51moonbitlang_2fcore_2fjson_2eParseError_2eInvalidEof__);
  } else {
    const _Some = _bind;
    const _x = _Some;
    if (_x === 58) {
      return new _M0DTPC16result6ResultGuRPC14json10ParseErrorE2Ok(undefined);
    } else {
      return _M0MPC14json12ParseContext21invalid__char_2einnerGuE(ctx, -1);
    }
  }
}
function _M0MPC14json12ParseContext19lex__property__name(ctx) {
  _M0MPC14json12ParseContext21lex__skip__whitespace(ctx);
  const _bind = _M0MPC14json12ParseContext10read__char(ctx);
  if (_bind === -1) {
    return new _M0DTPC16result6ResultGRPC14json5TokenRPC14json10ParseErrorE3Err(_M0DTPC15error5Error51moonbitlang_2fcore_2fjson_2eParseError_2eInvalidEof__);
  } else {
    const _Some = _bind;
    const _x = _Some;
    switch (_x) {
      case 125: {
        return new _M0DTPC16result6ResultGRPC14json5TokenRPC14json10ParseErrorE2Ok(_M0DTPC14json5Token6RBrace__);
      }
      case 34: {
        const _bind$2 = _M0MPC14json12ParseContext11lex__string(ctx);
        let s;
        if (_bind$2.$tag === 1) {
          const _ok = _bind$2;
          s = _ok._0;
        } else {
          return _bind$2;
        }
        return new _M0DTPC16result6ResultGRPC14json5TokenRPC14json10ParseErrorE2Ok(new _M0DTPC14json5Token6String(s));
      }
      default: {
        return _M0MPC14json12ParseContext21invalid__char_2einnerGRPB4JsonE(ctx, -1);
      }
    }
  }
}
function _M0MPC14json12ParseContext20lex__property__name2(ctx) {
  _M0MPC14json12ParseContext21lex__skip__whitespace(ctx);
  const _bind = _M0MPC14json12ParseContext10read__char(ctx);
  if (_bind === -1) {
    return new _M0DTPC16result6ResultGRPC14json5TokenRPC14json10ParseErrorE3Err(_M0DTPC15error5Error51moonbitlang_2fcore_2fjson_2eParseError_2eInvalidEof__);
  } else {
    const _Some = _bind;
    const _x = _Some;
    if (_x === 34) {
      const _bind$2 = _M0MPC14json12ParseContext11lex__string(ctx);
      let s;
      if (_bind$2.$tag === 1) {
        const _ok = _bind$2;
        s = _ok._0;
      } else {
        return _bind$2;
      }
      return new _M0DTPC16result6ResultGRPC14json5TokenRPC14json10ParseErrorE2Ok(new _M0DTPC14json5Token6String(s));
    } else {
      return _M0MPC14json12ParseContext21invalid__char_2einnerGRPB4JsonE(ctx, -1);
    }
  }
}
function _M0MPC14json12ParseContext12parse__value(ctx) {
  const _bind = _M0MPC14json12ParseContext10lex__value(ctx, false);
  let tok;
  if (_bind.$tag === 1) {
    const _ok = _bind;
    tok = _ok._0;
  } else {
    return _bind;
  }
  return _M0MPC14json12ParseContext13parse__value2(ctx, tok);
}
function _M0MPC14json12ParseContext13parse__value2(ctx, tok) {
  _L: {
    switch (tok.$tag) {
      case 0: {
        return new _M0DTPC16result6ResultGRPB4JsonRPC14json10ParseErrorE2Ok(_M0FPB4null);
      }
      case 1: {
        return new _M0DTPC16result6ResultGRPB4JsonRPC14json10ParseErrorE2Ok(_M0MPC14json4Json7boolean(true));
      }
      case 2: {
        return new _M0DTPC16result6ResultGRPB4JsonRPC14json10ParseErrorE2Ok(_M0MPC14json4Json7boolean(false));
      }
      case 3: {
        const _Number = tok;
        const _n = _Number._0;
        const _repr = _Number._1;
        return new _M0DTPC16result6ResultGRPB4JsonRPC14json10ParseErrorE2Ok(_M0MPC14json4Json6number(_n, _repr));
      }
      case 4: {
        const _String = tok;
        const _s = _String._0;
        return new _M0DTPC16result6ResultGRPB4JsonRPC14json10ParseErrorE2Ok(_M0MPC14json4Json6string(_s));
      }
      case 5: {
        return _M0MPC14json12ParseContext13parse__object(ctx);
      }
      case 7: {
        return _M0MPC14json12ParseContext12parse__array(ctx);
      }
      case 8: {
        break _L;
      }
      case 6: {
        break _L;
      }
      default: {
        break _L;
      }
    }
  }
  return new _M0DTPC16result6ResultGRPB4JsonRPC14json10ParseErrorE2Ok(_M0FPC15abort5abortGRP411cogna_2ddev5cogna4core6config11ConfigErrorE("unreachable"));
}
function _M0MPC14json12ParseContext12parse__array(ctx) {
  if (ctx.remaining_available_depth <= 0) {
    return new _M0DTPC16result6ResultGRPB4JsonRPC14json10ParseErrorE3Err(_M0DTPC15error5Error59moonbitlang_2fcore_2fjson_2eParseError_2eDepthLimitExceeded__);
  }
  ctx.remaining_available_depth = ctx.remaining_available_depth - 1 | 0;
  const vec = [];
  let _tmp;
  const _bind = _M0MPC14json12ParseContext10lex__value(ctx, true);
  let _tmp$2;
  if (_bind.$tag === 1) {
    const _ok = _bind;
    _tmp$2 = _ok._0;
  } else {
    return _bind;
  }
  let _tmp$3 = _tmp$2;
  _L: while (true) {
    const x = _tmp$3;
    if (x.$tag === 8) {
      ctx.remaining_available_depth = ctx.remaining_available_depth + 1 | 0;
      _tmp = _M0MPC14json4Json5array(vec);
      break;
    } else {
      const _bind$2 = _M0MPC14json12ParseContext13parse__value2(ctx, x);
      let _tmp$4;
      if (_bind$2.$tag === 1) {
        const _ok = _bind$2;
        _tmp$4 = _ok._0;
      } else {
        return _bind$2;
      }
      _M0MPC15array5Array4pushGRPB4JsonE(vec, _tmp$4);
      const _bind$3 = _M0MPC14json12ParseContext24lex__after__array__value(ctx);
      let tok2;
      if (_bind$3.$tag === 1) {
        const _ok = _bind$3;
        tok2 = _ok._0;
      } else {
        return _bind$3;
      }
      switch (tok2.$tag) {
        case 9: {
          const _bind$4 = _M0MPC14json12ParseContext10lex__value(ctx, false);
          if (_bind$4.$tag === 1) {
            const _ok = _bind$4;
            _tmp$3 = _ok._0;
          } else {
            return _bind$4;
          }
          continue _L;
        }
        case 8: {
          ctx.remaining_available_depth = ctx.remaining_available_depth + 1 | 0;
          _tmp = _M0MPC14json4Json5array(vec);
          break _L;
        }
        default: {
          _M0FPC15abort5abortGuE("unreachable");
        }
      }
    }
    continue;
  }
  return new _M0DTPC16result6ResultGRPB4JsonRPC14json10ParseErrorE2Ok(_tmp);
}
function _M0MPC14json12ParseContext13parse__object(ctx) {
  if (ctx.remaining_available_depth <= 0) {
    return new _M0DTPC16result6ResultGRPB4JsonRPC14json10ParseErrorE3Err(_M0DTPC15error5Error59moonbitlang_2fcore_2fjson_2eParseError_2eDepthLimitExceeded__);
  }
  ctx.remaining_available_depth = ctx.remaining_available_depth - 1 | 0;
  const map = _M0MPB3Map11new_2einnerGsRPB4JsonE(8);
  let _tmp;
  const _bind = _M0MPC14json12ParseContext19lex__property__name(ctx);
  let _tmp$2;
  if (_bind.$tag === 1) {
    const _ok = _bind;
    _tmp$2 = _ok._0;
  } else {
    return _bind;
  }
  let _tmp$3 = _tmp$2;
  _L: while (true) {
    const x = _tmp$3;
    switch (x.$tag) {
      case 6: {
        ctx.remaining_available_depth = ctx.remaining_available_depth + 1 | 0;
        _tmp = _M0MPC14json4Json6object(map);
        break _L;
      }
      case 4: {
        const _String = x;
        const _name = _String._0;
        const _bind$2 = _M0MPC14json12ParseContext26lex__after__property__name(ctx);
        if (_bind$2.$tag === 1) {
          const _ok = _bind$2;
          _ok._0;
        } else {
          return _bind$2;
        }
        const _bind$3 = _M0MPC14json12ParseContext12parse__value(ctx);
        let _tmp$4;
        if (_bind$3.$tag === 1) {
          const _ok = _bind$3;
          _tmp$4 = _ok._0;
        } else {
          return _bind$3;
        }
        _M0MPB3Map3setGsRPB4JsonE(map, _name, _tmp$4);
        const _bind$4 = _M0MPC14json12ParseContext25lex__after__object__value(ctx);
        let _bind$5;
        if (_bind$4.$tag === 1) {
          const _ok = _bind$4;
          _bind$5 = _ok._0;
        } else {
          return _bind$4;
        }
        switch (_bind$5.$tag) {
          case 9: {
            const _bind$6 = _M0MPC14json12ParseContext20lex__property__name2(ctx);
            if (_bind$6.$tag === 1) {
              const _ok = _bind$6;
              _tmp$3 = _ok._0;
            } else {
              return _bind$6;
            }
            continue _L;
          }
          case 6: {
            ctx.remaining_available_depth = ctx.remaining_available_depth + 1 | 0;
            _tmp = _M0MPC14json4Json6object(map);
            break _L;
          }
          default: {
            _M0FPC15abort5abortGuE("unreachable");
          }
        }
        break;
      }
      default: {
        _M0FPC15abort5abortGuE("unreachable");
      }
    }
    continue;
  }
  return new _M0DTPC16result6ResultGRPB4JsonRPC14json10ParseErrorE2Ok(_tmp);
}
function _M0FPC14json13parse_2einner(input, max_nesting_depth) {
  const ctx = _M0MPC14json12ParseContext4make(input, max_nesting_depth);
  const _bind = _M0MPC14json12ParseContext12parse__value(ctx);
  let val;
  if (_bind.$tag === 1) {
    const _ok = _bind;
    val = _ok._0;
  } else {
    return _bind;
  }
  _M0MPC14json12ParseContext21lex__skip__whitespace(ctx);
  return ctx.offset >= ctx.end_offset ? new _M0DTPC16result6ResultGRPB4JsonRPC14json10ParseErrorE2Ok(val) : _M0MPC14json12ParseContext21invalid__char_2einnerGRPB4JsonE(ctx, 0);
}
function _M0MPC13ref3Ref3newGOsE(x) {
  return new _M0TPC13ref3RefGOsE(x);
}
function _M0FPC28encoding4utf814decode_2einner(bytes, ignore_bom) {
  let bytes$2;
  _L: {
    _L$2: {
      if (ignore_bom) {
        _L$3: {
          _L$4: {
            if ((bytes.end - bytes.start | 0) >= 3) {
              const _x = bytes.bytes[bytes.start];
              if (_x === 239) {
                const _x$2 = bytes.bytes[bytes.start + 1 | 0];
                if (_x$2 === 187) {
                  const _x$3 = bytes.bytes[bytes.start + 2 | 0];
                  if (_x$3 === 191) {
                    bytes$2 = new _M0TPC15bytes9BytesView(bytes.bytes, bytes.start + 3 | 0, bytes.end);
                  } else {
                    break _L$4;
                  }
                } else {
                  break _L$4;
                }
              } else {
                break _L$4;
              }
            } else {
              break _L$4;
            }
            break _L$3;
          }
          break _L$2;
        }
      } else {
        break _L$2;
      }
      break _L;
    }
    bytes$2 = bytes;
  }
  const t = $makebytes(Math.imul(_M0MPC15bytes9BytesView6length(bytes$2), 2) | 0, 0);
  let tlen;
  let _tmp = 0;
  let _tmp$2 = bytes$2;
  while (true) {
    const tlen$2 = _tmp;
    const bs = _tmp$2;
    let bytes$3;
    _L$2: {
      let tlen$3;
      let b0;
      let b1;
      let b2;
      let b3;
      let rest;
      _L$3: {
        let tlen$4;
        let b0$2;
        let b1$2;
        let b2$2;
        let rest$2;
        _L$4: {
          let tlen$5;
          let rest$3;
          let b0$3;
          let b1$3;
          _L$5: {
            let tlen$6;
            let rest$4;
            let b;
            _L$6: {
              if ((bs.end - bs.start | 0) === 0) {
                tlen = tlen$2;
                break;
              } else {
                if ((bs.end - bs.start | 0) >= 8) {
                  const _x = bs.bytes[bs.start];
                  if (_x <= 127) {
                    const _x$2 = bs.bytes[bs.start + 1 | 0];
                    if (_x$2 <= 127) {
                      const _x$3 = bs.bytes[bs.start + 2 | 0];
                      if (_x$3 <= 127) {
                        const _x$4 = bs.bytes[bs.start + 3 | 0];
                        if (_x$4 <= 127) {
                          const _x$5 = bs.bytes[bs.start + 4 | 0];
                          if (_x$5 <= 127) {
                            const _x$6 = bs.bytes[bs.start + 5 | 0];
                            if (_x$6 <= 127) {
                              const _x$7 = bs.bytes[bs.start + 6 | 0];
                              if (_x$7 <= 127) {
                                const _x$8 = bs.bytes[bs.start + 7 | 0];
                                if (_x$8 <= 127) {
                                  const _x$9 = new _M0TPC15bytes9BytesView(bs.bytes, bs.start + 8 | 0, bs.end);
                                  t[tlen$2] = _x;
                                  t[tlen$2 + 2 | 0] = _x$2;
                                  t[tlen$2 + 4 | 0] = _x$3;
                                  t[tlen$2 + 6 | 0] = _x$4;
                                  t[tlen$2 + 8 | 0] = _x$5;
                                  t[tlen$2 + 10 | 0] = _x$6;
                                  t[tlen$2 + 12 | 0] = _x$7;
                                  t[tlen$2 + 14 | 0] = _x$8;
                                  _tmp = tlen$2 + 16 | 0;
                                  _tmp$2 = _x$9;
                                  continue;
                                } else {
                                  const _x$9 = new _M0TPC15bytes9BytesView(bs.bytes, bs.start + 1 | 0, bs.end);
                                  tlen$6 = tlen$2;
                                  rest$4 = _x$9;
                                  b = _x;
                                  break _L$6;
                                }
                              } else {
                                const _x$8 = new _M0TPC15bytes9BytesView(bs.bytes, bs.start + 1 | 0, bs.end);
                                tlen$6 = tlen$2;
                                rest$4 = _x$8;
                                b = _x;
                                break _L$6;
                              }
                            } else {
                              const _x$7 = new _M0TPC15bytes9BytesView(bs.bytes, bs.start + 1 | 0, bs.end);
                              tlen$6 = tlen$2;
                              rest$4 = _x$7;
                              b = _x;
                              break _L$6;
                            }
                          } else {
                            const _x$6 = new _M0TPC15bytes9BytesView(bs.bytes, bs.start + 1 | 0, bs.end);
                            tlen$6 = tlen$2;
                            rest$4 = _x$6;
                            b = _x;
                            break _L$6;
                          }
                        } else {
                          const _x$5 = new _M0TPC15bytes9BytesView(bs.bytes, bs.start + 1 | 0, bs.end);
                          tlen$6 = tlen$2;
                          rest$4 = _x$5;
                          b = _x;
                          break _L$6;
                        }
                      } else {
                        const _x$4 = new _M0TPC15bytes9BytesView(bs.bytes, bs.start + 1 | 0, bs.end);
                        tlen$6 = tlen$2;
                        rest$4 = _x$4;
                        b = _x;
                        break _L$6;
                      }
                    } else {
                      const _x$3 = new _M0TPC15bytes9BytesView(bs.bytes, bs.start + 1 | 0, bs.end);
                      tlen$6 = tlen$2;
                      rest$4 = _x$3;
                      b = _x;
                      break _L$6;
                    }
                  } else {
                    if (_x >= 194 && _x <= 223) {
                      const _x$2 = bs.bytes[bs.start + 1 | 0];
                      if (_x$2 >= 128 && _x$2 <= 191) {
                        const _x$3 = new _M0TPC15bytes9BytesView(bs.bytes, bs.start + 2 | 0, bs.end);
                        tlen$5 = tlen$2;
                        rest$3 = _x$3;
                        b0$3 = _x;
                        b1$3 = _x$2;
                        break _L$5;
                      } else {
                        bytes$3 = bs;
                        break _L$2;
                      }
                    } else {
                      if (_x === 224) {
                        const _x$2 = bs.bytes[bs.start + 1 | 0];
                        if (_x$2 >= 160 && _x$2 <= 191) {
                          const _x$3 = bs.bytes[bs.start + 2 | 0];
                          if (_x$3 >= 128 && _x$3 <= 191) {
                            const _x$4 = new _M0TPC15bytes9BytesView(bs.bytes, bs.start + 3 | 0, bs.end);
                            tlen$4 = tlen$2;
                            b0$2 = _x;
                            b1$2 = _x$2;
                            b2$2 = _x$3;
                            rest$2 = _x$4;
                            break _L$4;
                          } else {
                            bytes$3 = bs;
                            break _L$2;
                          }
                        } else {
                          bytes$3 = bs;
                          break _L$2;
                        }
                      } else {
                        if (_x >= 225 && _x <= 236) {
                          const _x$2 = bs.bytes[bs.start + 1 | 0];
                          if (_x$2 >= 128 && _x$2 <= 191) {
                            const _x$3 = bs.bytes[bs.start + 2 | 0];
                            if (_x$3 >= 128 && _x$3 <= 191) {
                              const _x$4 = new _M0TPC15bytes9BytesView(bs.bytes, bs.start + 3 | 0, bs.end);
                              tlen$4 = tlen$2;
                              b0$2 = _x;
                              b1$2 = _x$2;
                              b2$2 = _x$3;
                              rest$2 = _x$4;
                              break _L$4;
                            } else {
                              bytes$3 = bs;
                              break _L$2;
                            }
                          } else {
                            bytes$3 = bs;
                            break _L$2;
                          }
                        } else {
                          if (_x === 237) {
                            const _x$2 = bs.bytes[bs.start + 1 | 0];
                            if (_x$2 >= 128 && _x$2 <= 159) {
                              const _x$3 = bs.bytes[bs.start + 2 | 0];
                              if (_x$3 >= 128 && _x$3 <= 191) {
                                const _x$4 = new _M0TPC15bytes9BytesView(bs.bytes, bs.start + 3 | 0, bs.end);
                                tlen$4 = tlen$2;
                                b0$2 = _x;
                                b1$2 = _x$2;
                                b2$2 = _x$3;
                                rest$2 = _x$4;
                                break _L$4;
                              } else {
                                bytes$3 = bs;
                                break _L$2;
                              }
                            } else {
                              bytes$3 = bs;
                              break _L$2;
                            }
                          } else {
                            if (_x >= 238 && _x <= 239) {
                              const _x$2 = bs.bytes[bs.start + 1 | 0];
                              if (_x$2 >= 128 && _x$2 <= 191) {
                                const _x$3 = bs.bytes[bs.start + 2 | 0];
                                if (_x$3 >= 128 && _x$3 <= 191) {
                                  const _x$4 = new _M0TPC15bytes9BytesView(bs.bytes, bs.start + 3 | 0, bs.end);
                                  tlen$4 = tlen$2;
                                  b0$2 = _x;
                                  b1$2 = _x$2;
                                  b2$2 = _x$3;
                                  rest$2 = _x$4;
                                  break _L$4;
                                } else {
                                  bytes$3 = bs;
                                  break _L$2;
                                }
                              } else {
                                bytes$3 = bs;
                                break _L$2;
                              }
                            } else {
                              if (_x === 240) {
                                const _x$2 = bs.bytes[bs.start + 1 | 0];
                                if (_x$2 >= 144 && _x$2 <= 191) {
                                  const _x$3 = bs.bytes[bs.start + 2 | 0];
                                  if (_x$3 >= 128 && _x$3 <= 191) {
                                    const _x$4 = bs.bytes[bs.start + 3 | 0];
                                    if (_x$4 >= 128 && _x$4 <= 191) {
                                      const _x$5 = new _M0TPC15bytes9BytesView(bs.bytes, bs.start + 4 | 0, bs.end);
                                      tlen$3 = tlen$2;
                                      b0 = _x;
                                      b1 = _x$2;
                                      b2 = _x$3;
                                      b3 = _x$4;
                                      rest = _x$5;
                                      break _L$3;
                                    } else {
                                      bytes$3 = bs;
                                      break _L$2;
                                    }
                                  } else {
                                    bytes$3 = bs;
                                    break _L$2;
                                  }
                                } else {
                                  bytes$3 = bs;
                                  break _L$2;
                                }
                              } else {
                                if (_x >= 241 && _x <= 243) {
                                  const _x$2 = bs.bytes[bs.start + 1 | 0];
                                  if (_x$2 >= 128 && _x$2 <= 191) {
                                    const _x$3 = bs.bytes[bs.start + 2 | 0];
                                    if (_x$3 >= 128 && _x$3 <= 191) {
                                      const _x$4 = bs.bytes[bs.start + 3 | 0];
                                      if (_x$4 >= 128 && _x$4 <= 191) {
                                        const _x$5 = new _M0TPC15bytes9BytesView(bs.bytes, bs.start + 4 | 0, bs.end);
                                        tlen$3 = tlen$2;
                                        b0 = _x;
                                        b1 = _x$2;
                                        b2 = _x$3;
                                        b3 = _x$4;
                                        rest = _x$5;
                                        break _L$3;
                                      } else {
                                        bytes$3 = bs;
                                        break _L$2;
                                      }
                                    } else {
                                      bytes$3 = bs;
                                      break _L$2;
                                    }
                                  } else {
                                    bytes$3 = bs;
                                    break _L$2;
                                  }
                                } else {
                                  if (_x === 244) {
                                    const _x$2 = bs.bytes[bs.start + 1 | 0];
                                    if (_x$2 >= 128 && _x$2 <= 143) {
                                      const _x$3 = bs.bytes[bs.start + 2 | 0];
                                      if (_x$3 >= 128 && _x$3 <= 191) {
                                        const _x$4 = bs.bytes[bs.start + 3 | 0];
                                        if (_x$4 >= 128 && _x$4 <= 191) {
                                          const _x$5 = new _M0TPC15bytes9BytesView(bs.bytes, bs.start + 4 | 0, bs.end);
                                          tlen$3 = tlen$2;
                                          b0 = _x;
                                          b1 = _x$2;
                                          b2 = _x$3;
                                          b3 = _x$4;
                                          rest = _x$5;
                                          break _L$3;
                                        } else {
                                          bytes$3 = bs;
                                          break _L$2;
                                        }
                                      } else {
                                        bytes$3 = bs;
                                        break _L$2;
                                      }
                                    } else {
                                      bytes$3 = bs;
                                      break _L$2;
                                    }
                                  } else {
                                    bytes$3 = bs;
                                    break _L$2;
                                  }
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                } else {
                  const _x = bs.bytes[bs.start];
                  if (_x >= 0 && _x <= 127) {
                    const _x$2 = new _M0TPC15bytes9BytesView(bs.bytes, bs.start + 1 | 0, bs.end);
                    tlen$6 = tlen$2;
                    rest$4 = _x$2;
                    b = _x;
                    break _L$6;
                  } else {
                    if ((bs.end - bs.start | 0) >= 2) {
                      if (_x >= 194 && _x <= 223) {
                        const _x$2 = bs.bytes[bs.start + 1 | 0];
                        if (_x$2 >= 128 && _x$2 <= 191) {
                          const _x$3 = new _M0TPC15bytes9BytesView(bs.bytes, bs.start + 2 | 0, bs.end);
                          tlen$5 = tlen$2;
                          rest$3 = _x$3;
                          b0$3 = _x;
                          b1$3 = _x$2;
                          break _L$5;
                        } else {
                          if ((bs.end - bs.start | 0) >= 3) {
                            (bs.end - bs.start | 0) >= 4;
                            bytes$3 = bs;
                            break _L$2;
                          } else {
                            bytes$3 = bs;
                            break _L$2;
                          }
                        }
                      } else {
                        if ((bs.end - bs.start | 0) >= 3) {
                          if (_x === 224) {
                            const _x$2 = bs.bytes[bs.start + 1 | 0];
                            if (_x$2 >= 160 && _x$2 <= 191) {
                              const _x$3 = bs.bytes[bs.start + 2 | 0];
                              if (_x$3 >= 128 && _x$3 <= 191) {
                                const _x$4 = new _M0TPC15bytes9BytesView(bs.bytes, bs.start + 3 | 0, bs.end);
                                tlen$4 = tlen$2;
                                b0$2 = _x;
                                b1$2 = _x$2;
                                b2$2 = _x$3;
                                rest$2 = _x$4;
                                break _L$4;
                              } else {
                                (bs.end - bs.start | 0) >= 4;
                                bytes$3 = bs;
                                break _L$2;
                              }
                            } else {
                              (bs.end - bs.start | 0) >= 4;
                              bytes$3 = bs;
                              break _L$2;
                            }
                          } else {
                            if (_x >= 225 && _x <= 236) {
                              const _x$2 = bs.bytes[bs.start + 1 | 0];
                              if (_x$2 >= 128 && _x$2 <= 191) {
                                const _x$3 = bs.bytes[bs.start + 2 | 0];
                                if (_x$3 >= 128 && _x$3 <= 191) {
                                  const _x$4 = new _M0TPC15bytes9BytesView(bs.bytes, bs.start + 3 | 0, bs.end);
                                  tlen$4 = tlen$2;
                                  b0$2 = _x;
                                  b1$2 = _x$2;
                                  b2$2 = _x$3;
                                  rest$2 = _x$4;
                                  break _L$4;
                                } else {
                                  (bs.end - bs.start | 0) >= 4;
                                  bytes$3 = bs;
                                  break _L$2;
                                }
                              } else {
                                (bs.end - bs.start | 0) >= 4;
                                bytes$3 = bs;
                                break _L$2;
                              }
                            } else {
                              if (_x === 237) {
                                const _x$2 = bs.bytes[bs.start + 1 | 0];
                                if (_x$2 >= 128 && _x$2 <= 159) {
                                  const _x$3 = bs.bytes[bs.start + 2 | 0];
                                  if (_x$3 >= 128 && _x$3 <= 191) {
                                    const _x$4 = new _M0TPC15bytes9BytesView(bs.bytes, bs.start + 3 | 0, bs.end);
                                    tlen$4 = tlen$2;
                                    b0$2 = _x;
                                    b1$2 = _x$2;
                                    b2$2 = _x$3;
                                    rest$2 = _x$4;
                                    break _L$4;
                                  } else {
                                    (bs.end - bs.start | 0) >= 4;
                                    bytes$3 = bs;
                                    break _L$2;
                                  }
                                } else {
                                  (bs.end - bs.start | 0) >= 4;
                                  bytes$3 = bs;
                                  break _L$2;
                                }
                              } else {
                                if (_x >= 238 && _x <= 239) {
                                  const _x$2 = bs.bytes[bs.start + 1 | 0];
                                  if (_x$2 >= 128 && _x$2 <= 191) {
                                    const _x$3 = bs.bytes[bs.start + 2 | 0];
                                    if (_x$3 >= 128 && _x$3 <= 191) {
                                      const _x$4 = new _M0TPC15bytes9BytesView(bs.bytes, bs.start + 3 | 0, bs.end);
                                      tlen$4 = tlen$2;
                                      b0$2 = _x;
                                      b1$2 = _x$2;
                                      b2$2 = _x$3;
                                      rest$2 = _x$4;
                                      break _L$4;
                                    } else {
                                      (bs.end - bs.start | 0) >= 4;
                                      bytes$3 = bs;
                                      break _L$2;
                                    }
                                  } else {
                                    (bs.end - bs.start | 0) >= 4;
                                    bytes$3 = bs;
                                    break _L$2;
                                  }
                                } else {
                                  if ((bs.end - bs.start | 0) >= 4) {
                                    if (_x === 240) {
                                      const _x$2 = bs.bytes[bs.start + 1 | 0];
                                      if (_x$2 >= 144 && _x$2 <= 191) {
                                        const _x$3 = bs.bytes[bs.start + 2 | 0];
                                        if (_x$3 >= 128 && _x$3 <= 191) {
                                          const _x$4 = bs.bytes[bs.start + 3 | 0];
                                          if (_x$4 >= 128 && _x$4 <= 191) {
                                            const _x$5 = new _M0TPC15bytes9BytesView(bs.bytes, bs.start + 4 | 0, bs.end);
                                            tlen$3 = tlen$2;
                                            b0 = _x;
                                            b1 = _x$2;
                                            b2 = _x$3;
                                            b3 = _x$4;
                                            rest = _x$5;
                                            break _L$3;
                                          } else {
                                            bytes$3 = bs;
                                            break _L$2;
                                          }
                                        } else {
                                          bytes$3 = bs;
                                          break _L$2;
                                        }
                                      } else {
                                        bytes$3 = bs;
                                        break _L$2;
                                      }
                                    } else {
                                      if (_x >= 241 && _x <= 243) {
                                        const _x$2 = bs.bytes[bs.start + 1 | 0];
                                        if (_x$2 >= 128 && _x$2 <= 191) {
                                          const _x$3 = bs.bytes[bs.start + 2 | 0];
                                          if (_x$3 >= 128 && _x$3 <= 191) {
                                            const _x$4 = bs.bytes[bs.start + 3 | 0];
                                            if (_x$4 >= 128 && _x$4 <= 191) {
                                              const _x$5 = new _M0TPC15bytes9BytesView(bs.bytes, bs.start + 4 | 0, bs.end);
                                              tlen$3 = tlen$2;
                                              b0 = _x;
                                              b1 = _x$2;
                                              b2 = _x$3;
                                              b3 = _x$4;
                                              rest = _x$5;
                                              break _L$3;
                                            } else {
                                              bytes$3 = bs;
                                              break _L$2;
                                            }
                                          } else {
                                            bytes$3 = bs;
                                            break _L$2;
                                          }
                                        } else {
                                          bytes$3 = bs;
                                          break _L$2;
                                        }
                                      } else {
                                        if (_x === 244) {
                                          const _x$2 = bs.bytes[bs.start + 1 | 0];
                                          if (_x$2 >= 128 && _x$2 <= 143) {
                                            const _x$3 = bs.bytes[bs.start + 2 | 0];
                                            if (_x$3 >= 128 && _x$3 <= 191) {
                                              const _x$4 = bs.bytes[bs.start + 3 | 0];
                                              if (_x$4 >= 128 && _x$4 <= 191) {
                                                const _x$5 = new _M0TPC15bytes9BytesView(bs.bytes, bs.start + 4 | 0, bs.end);
                                                tlen$3 = tlen$2;
                                                b0 = _x;
                                                b1 = _x$2;
                                                b2 = _x$3;
                                                b3 = _x$4;
                                                rest = _x$5;
                                                break _L$3;
                                              } else {
                                                bytes$3 = bs;
                                                break _L$2;
                                              }
                                            } else {
                                              bytes$3 = bs;
                                              break _L$2;
                                            }
                                          } else {
                                            bytes$3 = bs;
                                            break _L$2;
                                          }
                                        } else {
                                          bytes$3 = bs;
                                          break _L$2;
                                        }
                                      }
                                    }
                                  } else {
                                    bytes$3 = bs;
                                    break _L$2;
                                  }
                                }
                              }
                            }
                          }
                        } else {
                          bytes$3 = bs;
                          break _L$2;
                        }
                      }
                    } else {
                      bytes$3 = bs;
                      break _L$2;
                    }
                  }
                }
              }
            }
            t[tlen$6] = b;
            _tmp = tlen$6 + 2 | 0;
            _tmp$2 = rest$4;
            continue;
          }
          const ch = (b0$3 & 31) << 6 | b1$3 & 63;
          t[tlen$5] = ch & 255;
          t[tlen$5 + 1 | 0] = ch >> 8 & 255;
          _tmp = tlen$5 + 2 | 0;
          _tmp$2 = rest$3;
          continue;
        }
        const ch = (b0$2 & 15) << 12 | (b1$2 & 63) << 6 | b2$2 & 63;
        t[tlen$4] = ch & 255;
        t[tlen$4 + 1 | 0] = ch >> 8 & 255;
        _tmp = tlen$4 + 2 | 0;
        _tmp$2 = rest$2;
        continue;
      }
      const ch = (b0 & 7) << 18 | (b1 & 63) << 12 | (b2 & 63) << 6 | b3 & 63;
      const chm = ch - 65536 | 0;
      const ch1 = (chm >> 10) + 55296 | 0;
      const ch2 = (chm & 1023) + 56320 | 0;
      t[tlen$3] = ch1 & 255;
      t[tlen$3 + 1 | 0] = ch1 >> 8 & 255;
      t[tlen$3 + 2 | 0] = ch2 & 255;
      t[tlen$3 + 3 | 0] = ch2 >> 8 & 255;
      _tmp = tlen$3 + 4 | 0;
      _tmp$2 = rest;
      continue;
    }
    return new _M0DTPC16result6ResultGsRPC28encoding4utf89MalformedE3Err(new _M0DTPC15error5Error60moonbitlang_2fcore_2fencoding_2futf8_2eMalformed_2eMalformed(bytes$3));
  }
  return new _M0DTPC16result6ResultGsRPC28encoding4utf89MalformedE2Ok(_M0MPC15bytes5Bytes29to__unchecked__string_2einner(t, 0, tlen));
}
function _M0FP411moonbitlang1x8internal3ffi28utf8__bytes__to__mbt__string(bytes) {
  const res = [];
  const len = bytes.length;
  const i = new _M0TPB8MutLocalGiE(0);
  while (true) {
    if (i.val < len) {
      const _tmp = i.val;
      $bound_check(bytes, _tmp);
      const c = new _M0TPB8MutLocalGiE(bytes[_tmp]);
      if (c.val < 128) {
        _M0MPC15array5Array4pushGcE(res, c.val);
        i.val = i.val + 1 | 0;
      } else {
        if (c.val < 224) {
          if ((i.val + 1 | 0) >= len) {
            break;
          }
          const _tmp$2 = (c.val & 31) << 6;
          const _tmp$3 = i.val + 1 | 0;
          $bound_check(bytes, _tmp$3);
          c.val = _tmp$2 | bytes[_tmp$3] & 63;
          _M0MPC15array5Array4pushGcE(res, c.val);
          i.val = i.val + 2 | 0;
        } else {
          if (c.val < 240) {
            if ((i.val + 2 | 0) >= len) {
              break;
            }
            const _tmp$2 = (c.val & 15) << 12;
            const _tmp$3 = i.val + 1 | 0;
            $bound_check(bytes, _tmp$3);
            const _tmp$4 = _tmp$2 | (bytes[_tmp$3] & 63) << 6;
            const _tmp$5 = i.val + 2 | 0;
            $bound_check(bytes, _tmp$5);
            c.val = _tmp$4 | bytes[_tmp$5] & 63;
            _M0MPC15array5Array4pushGcE(res, c.val);
            i.val = i.val + 3 | 0;
          } else {
            if ((i.val + 3 | 0) >= len) {
              break;
            }
            const _tmp$2 = (c.val & 7) << 18;
            const _tmp$3 = i.val + 1 | 0;
            $bound_check(bytes, _tmp$3);
            const _tmp$4 = _tmp$2 | (bytes[_tmp$3] & 63) << 12;
            const _tmp$5 = i.val + 2 | 0;
            $bound_check(bytes, _tmp$5);
            const _tmp$6 = _tmp$4 | (bytes[_tmp$5] & 63) << 6;
            const _tmp$7 = i.val + 3 | 0;
            $bound_check(bytes, _tmp$7);
            c.val = _tmp$6 | bytes[_tmp$7] & 63;
            c.val = c.val - 65536 | 0;
            _M0MPC15array5Array4pushGcE(res, (c.val >> 10) + 55296 | 0);
            _M0MPC15array5Array4pushGcE(res, (c.val & 1023) + 56320 | 0);
            i.val = i.val + 4 | 0;
          }
        }
      }
      continue;
    } else {
      break;
    }
  }
  return _M0MPC16string6String11from__array(new _M0TPB9ArrayViewGcE(res, 0, res.length));
}
function _M0FP311moonbitlang1x2fs31read__file__to__bytes__internal(path) {
  const res = _M0FP311moonbitlang1x2fs15read__file__ffi(path);
  if (res === -1) {
    return new _M0DTPC16result6ResultGzRP311moonbitlang1x2fs7IOErrorE3Err(new _M0DTPC15error5Error40moonbitlang_2fx_2ffs_2eIOError_2eIOError(_M0FP311moonbitlang1x2fs24get__error__message__ffi()));
  }
  return new _M0DTPC16result6ResultGzRP311moonbitlang1x2fs7IOErrorE2Ok(_M0FP311moonbitlang1x2fs23get__file__content__ffi());
}
function _M0FP311moonbitlang1x2fs40read__file__to__string__internal_2einner(path, encoding) {
  if (encoding === "utf8") {
    const _bind = _M0FP311moonbitlang1x2fs31read__file__to__bytes__internal(path);
    let bytes;
    if (_bind.$tag === 1) {
      const _ok = _bind;
      bytes = _ok._0;
    } else {
      return _bind;
    }
    return new _M0DTPC16result6ResultGsRP311moonbitlang1x2fs7IOErrorE2Ok(_M0FP411moonbitlang1x8internal3ffi28utf8__bytes__to__mbt__string(bytes));
  } else {
    return new _M0DTPC16result6ResultGsRP311moonbitlang1x2fs7IOErrorE3Err(new _M0DTPC15error5Error40moonbitlang_2fx_2ffs_2eIOError_2eIOError(`Unsupported encoding: ${_M0IPC16string6StringPB4Show10to__string(encoding)}, only utf8 is supported for now`));
  }
}
function _M0FP311moonbitlang1x2fs22path__exists__internal(path) {
  return _M0FP311moonbitlang1x2fs17path__exists__ffi(path);
}
function _M0IP311moonbitlang1x2fs7IOErrorPB4Show6output(self, logger) {
  let message;
  _L: {
    const _IOError = self;
    const _message = _IOError._0;
    message = _message;
    break _L;
  }
  logger.method_table.method_0(logger.self, "IOError(");
  _M0MPB6Logger13write__objectGsE(logger, message);
  logger.method_table.method_3(logger.self, 41);
}
function _M0FP311moonbitlang1x2fs21read__file__to__bytes(path) {
  return _M0FP311moonbitlang1x2fs31read__file__to__bytes__internal(path);
}
function _M0FP311moonbitlang1x2fs30read__file__to__string_2einner(path, encoding) {
  return _M0FP311moonbitlang1x2fs40read__file__to__string__internal_2einner(path, encoding);
}
function _M0FP311moonbitlang1x2fs12path__exists(path) {
  return _M0FP311moonbitlang1x2fs22path__exists__internal(path);
}
function _M0FP411cogna_2ddev5cogna4core6config28has__disallowed__input__path(paths) {
  let _tmp = 0;
  while (true) {
    const i = _tmp;
    if (i < paths.length) {
      const input_path = _M0MPC15array5Array2atGRPB4JsonE(paths, i);
      let _tmp$2;
      const _bind = "README";
      if (_M0MPC16string6String8contains(input_path, new _M0TPC16string10StringView(_bind, 0, _bind.length))) {
        _tmp$2 = true;
      } else {
        let _tmp$3;
        const _bind$2 = "readme";
        if (_M0MPC16string6String8contains(input_path, new _M0TPC16string10StringView(_bind$2, 0, _bind$2.length))) {
          _tmp$3 = true;
        } else {
          let _tmp$4;
          const _bind$3 = "example";
          if (_M0MPC16string6String8contains(input_path, new _M0TPC16string10StringView(_bind$3, 0, _bind$3.length))) {
            _tmp$4 = true;
          } else {
            const _bind$4 = "examples";
            _tmp$4 = _M0MPC16string6String8contains(input_path, new _M0TPC16string10StringView(_bind$4, 0, _bind$4.length));
          }
          _tmp$3 = _tmp$4;
        }
        _tmp$2 = _tmp$3;
      }
      if (_tmp$2) {
        return true;
      }
      _tmp = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return false;
}
function _M0FP411cogna_2ddev5cogna4core6config22is__supported__profile(profile) {
  switch (profile) {
    case "openapi-spec": {
      return true;
    }
    case "go-module": {
      return true;
    }
    case "rust-crate": {
      return true;
    }
    case "terraform-module": {
      return true;
    }
    default: {
      return false;
    }
  }
}
function _M0FP411cogna_2ddev5cogna4core6config8validate(config, path) {
  if (_M0IP016_24default__implPB2Eq10not__equalGsE(config.schema_version, "ciq-config/v1") && _M0IP016_24default__implPB2Eq10not__equalGsE(config.schema_version, "ciq-config/v2")) {
    return new _M0DTPC16result6ResultGRP411cogna_2ddev5cogna4core6config6ConfigRP411cogna_2ddev5cogna4core6config11ConfigErrorE3Err(new _M0DTPC15error5Error67cogna_2ddev_2fcogna_2fcore_2fconfig_2eConfigError_2eValidationError(path, "schemaVersion must be ciq-config/v1 or ciq-config/v2"));
  } else {
    if (!_M0FP411cogna_2ddev5cogna4core6config22is__supported__profile(config.profile)) {
      return new _M0DTPC16result6ResultGRP411cogna_2ddev5cogna4core6config6ConfigRP411cogna_2ddev5cogna4core6config11ConfigErrorE3Err(new _M0DTPC15error5Error67cogna_2ddev_2fcogna_2fcore_2fconfig_2eConfigError_2eValidationError(path, "$.profile: value is not in enum"));
    } else {
      if (config.purl === "") {
        return new _M0DTPC16result6ResultGRP411cogna_2ddev5cogna4core6config6ConfigRP411cogna_2ddev5cogna4core6config11ConfigErrorE3Err(new _M0DTPC15error5Error67cogna_2ddev_2fcogna_2fcore_2fconfig_2eConfigError_2eValidationError(path, "purl must not be empty"));
      } else {
        const _tmp = config.purl;
        const _bind = "pkg:";
        if (!_M0MPC16string6String11has__prefix(_tmp, new _M0TPC16string10StringView(_bind, 0, _bind.length))) {
          return new _M0DTPC16result6ResultGRP411cogna_2ddev5cogna4core6config6ConfigRP411cogna_2ddev5cogna4core6config11ConfigErrorE3Err(new _M0DTPC15error5Error67cogna_2ddev_2fcogna_2fcore_2fconfig_2eConfigError_2eValidationError(path, "purl must start with pkg:"));
        } else {
          return config.source.repo === "" ? new _M0DTPC16result6ResultGRP411cogna_2ddev5cogna4core6config6ConfigRP411cogna_2ddev5cogna4core6config11ConfigErrorE3Err(new _M0DTPC15error5Error67cogna_2ddev_2fcogna_2fcore_2fconfig_2eConfigError_2eValidationError(path, "source.repo must not be empty")) : config.source.source_ref === "" ? new _M0DTPC16result6ResultGRP411cogna_2ddev5cogna4core6config6ConfigRP411cogna_2ddev5cogna4core6config11ConfigErrorE3Err(new _M0DTPC15error5Error67cogna_2ddev_2fcogna_2fcore_2fconfig_2eConfigError_2eValidationError(path, "source.ref must not be empty")) : _M0MPC15array5Array9is__emptyGsE(config.inputs.include_paths) ? new _M0DTPC16result6ResultGRP411cogna_2ddev5cogna4core6config6ConfigRP411cogna_2ddev5cogna4core6config11ConfigErrorE3Err(new _M0DTPC15error5Error67cogna_2ddev_2fcogna_2fcore_2fconfig_2eConfigError_2eValidationError(path, "inputs.include must not be empty")) : _M0FP411cogna_2ddev5cogna4core6config28has__disallowed__input__path(config.inputs.include_paths) ? new _M0DTPC16result6ResultGRP411cogna_2ddev5cogna4core6config6ConfigRP411cogna_2ddev5cogna4core6config11ConfigErrorE3Err(new _M0DTPC15error5Error67cogna_2ddev_2fcogna_2fcore_2fconfig_2eConfigError_2eValidationError(path, "inputs.include must reference code/spec files only (no README/example paths)")) : _M0IP016_24default__implPB2Eq10not__equalGsE(config.checks.format, "sarif") ? new _M0DTPC16result6ResultGRP411cogna_2ddev5cogna4core6config6ConfigRP411cogna_2ddev5cogna4core6config11ConfigErrorE3Err(new _M0DTPC15error5Error67cogna_2ddev_2fcogna_2fcore_2fconfig_2eConfigError_2eValidationError(path, "checks.format must be sarif")) : config.checks.policy === "" ? new _M0DTPC16result6ResultGRP411cogna_2ddev5cogna4core6config6ConfigRP411cogna_2ddev5cogna4core6config11ConfigErrorE3Err(new _M0DTPC15error5Error67cogna_2ddev_2fcogna_2fcore_2fconfig_2eConfigError_2eValidationError(path, "checks.policy must not be empty")) : _M0IP016_24default__implPB2Eq10not__equalGsE(config.validation, "none") && _M0IP016_24default__implPB2Eq10not__equalGsE(config.validation, "lsp") ? new _M0DTPC16result6ResultGRP411cogna_2ddev5cogna4core6config6ConfigRP411cogna_2ddev5cogna4core6config11ConfigErrorE3Err(new _M0DTPC15error5Error67cogna_2ddev_2fcogna_2fcore_2fconfig_2eConfigError_2eValidationError(path, "validation must be none or lsp")) : config.schema_version === "ciq-config/v2" && _M0IP016_24default__implPB2Eq10not__equalGsE(config.sbom.format, "spdx") ? new _M0DTPC16result6ResultGRP411cogna_2ddev5cogna4core6config6ConfigRP411cogna_2ddev5cogna4core6config11ConfigErrorE3Err(new _M0DTPC15error5Error67cogna_2ddev_2fcogna_2fcore_2fconfig_2eConfigError_2eValidationError(path, "sbom.format must be spdx")) : config.schema_version === "ciq-config/v2" && (_M0IP016_24default__implPB2Eq10not__equalGsE(config.cache.type_, "local") && _M0IP016_24default__implPB2Eq10not__equalGsE(config.cache.type_, "http")) ? new _M0DTPC16result6ResultGRP411cogna_2ddev5cogna4core6config6ConfigRP411cogna_2ddev5cogna4core6config11ConfigErrorE3Err(new _M0DTPC15error5Error67cogna_2ddev_2fcogna_2fcore_2fconfig_2eConfigError_2eValidationError(path, "cache.type must be local or http")) : config.schema_version === "ciq-config/v2" && config.cache.local_store.store_dir === "" ? new _M0DTPC16result6ResultGRP411cogna_2ddev5cogna4core6config6ConfigRP411cogna_2ddev5cogna4core6config11ConfigErrorE3Err(new _M0DTPC15error5Error67cogna_2ddev_2fcogna_2fcore_2fconfig_2eConfigError_2eValidationError(path, "cache.local.storeDir must not be empty")) : config.schema_version === "ciq-config/v2" && (config.cache.type_ === "http" && config.cache.http.base_url === "") ? new _M0DTPC16result6ResultGRP411cogna_2ddev5cogna4core6config6ConfigRP411cogna_2ddev5cogna4core6config11ConfigErrorE3Err(new _M0DTPC15error5Error67cogna_2ddev_2fcogna_2fcore_2fconfig_2eConfigError_2eValidationError(path, "cache.http.baseUrl must not be empty")) : config.schema_version === "ciq-config/v2" && config.cache.http.timeout_ms <= 0 ? new _M0DTPC16result6ResultGRP411cogna_2ddev5cogna4core6config6ConfigRP411cogna_2ddev5cogna4core6config11ConfigErrorE3Err(new _M0DTPC15error5Error67cogna_2ddev_2fcogna_2fcore_2fconfig_2eConfigError_2eValidationError(path, "cache.http.timeoutMs must be positive")) : config.schema_version === "ciq-config/v2" && (config.mcp.port <= 0 || config.mcp.port > 65535) ? new _M0DTPC16result6ResultGRP411cogna_2ddev5cogna4core6config6ConfigRP411cogna_2ddev5cogna4core6config11ConfigErrorE3Err(new _M0DTPC15error5Error67cogna_2ddev_2fcogna_2fcore_2fconfig_2eConfigError_2eValidationError(path, "mcp.port must be in range 1..65535")) : new _M0DTPC16result6ResultGRP411cogna_2ddev5cogna4core6config6ConfigRP411cogna_2ddev5cogna4core6config11ConfigErrorE2Ok(config);
        }
      }
    }
  }
}
function _M0FP411cogna_2ddev5cogna4core6config12trim__spaces(value) {
  const start = new _M0TPB8MutLocalGiE(0);
  const end = new _M0TPB8MutLocalGiE(value.length);
  while (true) {
    if (start.val < end.val) {
      const _tmp = start.val;
      $bound_check(value, _tmp);
      const c = value.charCodeAt(_tmp);
      if (_M0IPC16uint166UInt16PB2Eq5equal(c, 32) || (_M0IPC16uint166UInt16PB2Eq5equal(c, 9) || _M0IPC16uint166UInt16PB2Eq5equal(c, 13))) {
        start.val = start.val + 1 | 0;
      } else {
        break;
      }
      continue;
    } else {
      break;
    }
  }
  while (true) {
    if (end.val > start.val) {
      const _tmp = end.val - 1 | 0;
      $bound_check(value, _tmp);
      const c = value.charCodeAt(_tmp);
      if (_M0IPC16uint166UInt16PB2Eq5equal(c, 32) || (_M0IPC16uint166UInt16PB2Eq5equal(c, 9) || _M0IPC16uint166UInt16PB2Eq5equal(c, 13))) {
        end.val = end.val - 1 | 0;
      } else {
        break;
      }
      continue;
    } else {
      break;
    }
  }
  return _M0IPC16string10StringViewPB4Show10to__string(_M0MPC16string6String11sub_2einner(value, start.val, end.val));
}
function _M0FP411cogna_2ddev5cogna4core6config17parse__key__value(line, path, line_no) {
  const split_idx = new _M0TPB8MutLocalGiE(-1);
  const _bind = 0;
  const _bind$2 = line.length;
  let _tmp = _bind;
  while (true) {
    const i = _tmp;
    if (i < _bind$2) {
      $bound_check(line, i);
      if (_M0IPC16uint166UInt16PB2Eq5equal(line.charCodeAt(i), 58)) {
        split_idx.val = i;
        break;
      }
      _tmp = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  if (split_idx.val < 0) {
    return new _M0DTPC16result6ResultGUssERP411cogna_2ddev5cogna4core6config11ConfigErrorE3Err(new _M0DTPC15error5Error62cogna_2ddev_2fcogna_2fcore_2fconfig_2eConfigError_2eParseError(path, `line ${_M0IP016_24default__implPB4Show10to__stringGiE(line_no)}: expected key:value pair`));
  }
  const key = _M0FP411cogna_2ddev5cogna4core6config12trim__spaces(_M0IPC16string10StringViewPB4Show10to__string(_M0MPC16string6String11sub_2einner(line, 0, split_idx.val)));
  const value = _M0FP411cogna_2ddev5cogna4core6config12trim__spaces(_M0IPC16string10StringViewPB4Show10to__string(_M0MPC16string6String11sub_2einner(line, split_idx.val + 1 | 0, undefined)));
  return new _M0DTPC16result6ResultGUssERP411cogna_2ddev5cogna4core6config11ConfigErrorE2Ok({ _0: key, _1: value });
}
function _M0FP411cogna_2ddev5cogna4core6config11parse__bool(value, path, line_no, field) {
  switch (value) {
    case "true": {
      return new _M0DTPC16result6ResultGbRP411cogna_2ddev5cogna4core6config11ConfigErrorE2Ok(true);
    }
    case "false": {
      return new _M0DTPC16result6ResultGbRP411cogna_2ddev5cogna4core6config11ConfigErrorE2Ok(false);
    }
    default: {
      return new _M0DTPC16result6ResultGbRP411cogna_2ddev5cogna4core6config11ConfigErrorE3Err(new _M0DTPC15error5Error62cogna_2ddev_2fcogna_2fcore_2fconfig_2eConfigError_2eParseError(path, `line ${_M0IP016_24default__implPB4Show10to__stringGiE(line_no)}: ${_M0IPC16string6StringPB4Show10to__string(field)} must be true or false`));
    }
  }
}
function _M0FP411cogna_2ddev5cogna4core6config10parse__int(value, path, line_no, field) {
  let parsed;
  let _try_err;
  _L: {
    _L$2: {
      const _bind = _M0FPC28internal7strconv18parse__int_2einner(new _M0TPC16string10StringView(value, 0, value.length), 0);
      let _tmp;
      if (_bind.$tag === 1) {
        const _ok = _bind;
        _tmp = _ok._0;
      } else {
        const _err = _bind;
        _try_err = _err._0;
        break _L$2;
      }
      parsed = new _M0DTPC16result6ResultGiRPC15error5ErrorE2Ok(_tmp);
      break _L;
    }
    parsed = new _M0DTPC16result6ResultGiRPC15error5ErrorE3Err(_try_err);
  }
  let number;
  _L$2: {
    if (parsed.$tag === 1) {
      const _Ok = parsed;
      const _number = _Ok._0;
      number = _number;
      break _L$2;
    } else {
      return new _M0DTPC16result6ResultGiRP411cogna_2ddev5cogna4core6config11ConfigErrorE3Err(new _M0DTPC15error5Error62cogna_2ddev_2fcogna_2fcore_2fconfig_2eConfigError_2eParseError(path, `line ${_M0IP016_24default__implPB4Show10to__stringGiE(line_no)}: ${_M0IPC16string6StringPB4Show10to__string(field)} must be an integer`));
    }
  }
  return new _M0DTPC16result6ResultGiRP411cogna_2ddev5cogna4core6config11ConfigErrorE2Ok(number);
}
function _M0FP411cogna_2ddev5cogna4core6config10join__path(base, child) {
  if (base === "" || base === ".") {
    return `./${_M0IPC16string6StringPB4Show10to__string(child)}`;
  } else {
    const _bind = "/";
    if (_M0MPC16string6String11has__suffix(base, new _M0TPC16string10StringView(_bind, 0, _bind.length))) {
      return `${_M0IPC16string6StringPB4Show10to__string(base)}${_M0IPC16string6StringPB4Show10to__string(child)}`;
    } else {
      return `${_M0IPC16string6StringPB4Show10to__string(base)}/${_M0IPC16string6StringPB4Show10to__string(child)}`;
    }
  }
}
function _M0FP411cogna_2ddev5cogna4core6config11parent__dir(path) {
  const _bind = "/";
  const parts = _M0MPB4Iter9to__arrayGRPC16string10StringViewE(_M0MPC16string6String5split(path, new _M0TPC16string10StringView(_bind, 0, _bind.length)));
  if (parts.length <= 1) {
    return ".";
  } else {
    const out = new _M0TPB8MutLocalGsE("");
    const _bind$2 = 0;
    const _bind$3 = parts.length - 1 | 0;
    let _tmp = _bind$2;
    while (true) {
      const i = _tmp;
      if (i < _bind$3) {
        if (i > 0) {
          out.val = `${_M0IPC16string6StringPB4Show10to__string(out.val)}/`;
        }
        out.val = `${_M0IPC16string6StringPB4Show10to__string(out.val)}${_M0IPC16string10StringViewPB4Show10to__string(_M0MPC15array5Array2atGRPB4JsonE(parts, i))}`;
        _tmp = i + 1 | 0;
        continue;
      } else {
        break;
      }
    }
    return out.val === "" ? "." : out.val;
  }
}
function _M0FP411cogna_2ddev5cogna4core6config18find__config__path(root_dir) {
  const base = root_dir === "" ? "." : root_dir;
  const preferred = _M0FP411cogna_2ddev5cogna4core6config10join__path(base, "cogna.yml");
  if (_M0FP311moonbitlang1x2fs12path__exists(preferred)) {
    return preferred;
  }
  const fallback = _M0FP411cogna_2ddev5cogna4core6config10join__path(base, "cogna.yaml");
  return _M0FP311moonbitlang1x2fs12path__exists(fallback) ? fallback : undefined;
}
function _M0FP411cogna_2ddev5cogna4core6config15default__config() {
  return new _M0TP411cogna_2ddev5cogna4core6config6Config("ciq-config/v2", "openapi-spec", "none", "pkg:openapi/acme/payment-api@2026.03.01", new _M0TP411cogna_2ddev5cogna4core6config6Source("https://github.com/acme/payment-api", "main"), new _M0TP411cogna_2ddev5cogna4core6config6Inputs(["openapi/**/*.yaml"]), new _M0TP411cogna_2ddev5cogna4core6config6Checks("sarif", "./.cogna/policies"), new _M0TP411cogna_2ddev5cogna4core6config12DiffSettings(undefined, false), new _M0TP411cogna_2ddev5cogna4core6config12SbomSettings("spdx", true, true), new _M0TP411cogna_2ddev5cogna4core6config13CacheSettings("local", new _M0TP411cogna_2ddev5cogna4core6config18LocalCacheSettings(".cogna/cache"), new _M0TP411cogna_2ddev5cogna4core6config17HttpCacheSettings("", 10000)), new _M0TP411cogna_2ddev5cogna4core6config11McpSettings(3000));
}
function _M0FP411cogna_2ddev5cogna4core6config13parse__config(content, path) {
  const defaults = _M0FP411cogna_2ddev5cogna4core6config15default__config();
  const schema_version = new _M0TPB8MutLocalGsE(defaults.schema_version);
  const profile = new _M0TPB8MutLocalGsE(defaults.profile);
  const validation = new _M0TPB8MutLocalGsE(defaults.validation);
  const purl = new _M0TPB8MutLocalGsE(defaults.purl);
  const source_repo = new _M0TPB8MutLocalGsE(defaults.source.repo);
  const source_ref = new _M0TPB8MutLocalGsE(defaults.source.source_ref);
  const includes = [];
  const checks_format = new _M0TPB8MutLocalGsE(defaults.checks.format);
  const checks_policy = new _M0TPB8MutLocalGsE(defaults.checks.policy);
  const diff_since = new _M0TPB8MutLocalGOsE(defaults.diff.since);
  const diff_include_test_changes = new _M0TPB8MutLocalGbE(defaults.diff.include_test_changes);
  const sbom_format = new _M0TPB8MutLocalGsE(defaults.sbom.format);
  const sbom_dependency_bundles = new _M0TPB8MutLocalGbE(defaults.sbom.dependency_bundles);
  const sbom_require_local_packages = new _M0TPB8MutLocalGbE(defaults.sbom.require_local_packages);
  const cache_type = new _M0TPB8MutLocalGsE(defaults.cache.type_);
  const cache_local_store_dir = new _M0TPB8MutLocalGsE(defaults.cache.local_store.store_dir);
  const cache_http_base_url = new _M0TPB8MutLocalGsE(defaults.cache.http.base_url);
  const cache_http_timeout_ms = new _M0TPB8MutLocalGiE(defaults.cache.http.timeout_ms);
  const mcp_port = new _M0TPB8MutLocalGiE(defaults.mcp.port);
  const _bind = "\n";
  const lines = _M0MPB4Iter9to__arrayGRPC16string10StringViewE(_M0MPC16string6String5split(content, new _M0TPC16string10StringView(_bind, 0, _bind.length)));
  const section = new _M0TPB8MutLocalGsE("root");
  const _bind$2 = 0;
  const _bind$3 = lines.length;
  let _tmp = _bind$2;
  while (true) {
    const i = _tmp;
    if (i < _bind$3) {
      _L: {
        const line_no = i + 1 | 0;
        const raw_line = _M0IPC16string10StringViewPB4Show10to__string(_M0MPC15array5Array2atGRPB4JsonE(lines, i));
        const line = _M0FP411cogna_2ddev5cogna4core6config12trim__spaces(raw_line);
        let _tmp$2;
        if (line === "") {
          _tmp$2 = true;
        } else {
          const _bind$4 = "#";
          _tmp$2 = _M0MPC16string6String11has__prefix(line, new _M0TPC16string10StringView(_bind$4, 0, _bind$4.length));
        }
        if (_tmp$2) {
          break _L;
        }
        if (line === "source:") {
          section.val = "source";
          break _L;
        }
        if (line === "inputs:") {
          section.val = "inputs";
          break _L;
        }
        if (line === "include:") {
          section.val = "inputs_include";
          break _L;
        }
        if (line === "checks:") {
          section.val = "checks";
          break _L;
        }
        if (line === "diff:") {
          section.val = "diff";
          break _L;
        }
        if (line === "sbom:") {
          section.val = "sbom";
          break _L;
        }
        if (line === "cache:") {
          section.val = "cache";
          break _L;
        }
        if (line === "local:" && (section.val === "cache" || (section.val === "cache_local" || section.val === "cache_http"))) {
          section.val = "cache_local";
          break _L;
        }
        if (line === "http:" && (section.val === "cache" || (section.val === "cache_local" || section.val === "cache_http"))) {
          section.val = "cache_http";
          break _L;
        }
        if (line === "mcp:") {
          section.val = "mcp";
          break _L;
        }
        const _bind$4 = "- ";
        if (_M0MPC16string6String11has__prefix(line, new _M0TPC16string10StringView(_bind$4, 0, _bind$4.length))) {
          if (_M0IP016_24default__implPB2Eq10not__equalGsE(section.val, "inputs_include")) {
            return new _M0DTPC16result6ResultGRP411cogna_2ddev5cogna4core6config6ConfigRP411cogna_2ddev5cogna4core6config11ConfigErrorE3Err(new _M0DTPC15error5Error62cogna_2ddev_2fcogna_2fcore_2fconfig_2eConfigError_2eParseError(path, `line ${_M0IP016_24default__implPB4Show10to__stringGiE(line_no)}: list item outside inputs.include`));
          }
          const include_path = _M0FP411cogna_2ddev5cogna4core6config12trim__spaces(_M0IPC16string10StringViewPB4Show10to__string(_M0MPC16string6String11sub_2einner(line, 2, undefined)));
          if (include_path === "") {
            return new _M0DTPC16result6ResultGRP411cogna_2ddev5cogna4core6config6ConfigRP411cogna_2ddev5cogna4core6config11ConfigErrorE3Err(new _M0DTPC15error5Error62cogna_2ddev_2fcogna_2fcore_2fconfig_2eConfigError_2eParseError(path, `line ${_M0IP016_24default__implPB4Show10to__stringGiE(line_no)}: include path is empty`));
          }
          _M0MPC15array5Array4pushGRPB4JsonE(includes, include_path);
          break _L;
        }
        const parsed = _M0FP411cogna_2ddev5cogna4core6config17parse__key__value(line, path, line_no);
        let key;
        let value;
        _L$2: {
          if (parsed.$tag === 1) {
            const _Ok = parsed;
            const _x = _Ok._0;
            const _key = _x._0;
            const _value = _x._1;
            key = _key;
            value = _value;
            break _L$2;
          } else {
            return new _M0DTPC16result6ResultGRP411cogna_2ddev5cogna4core6config6ConfigRP411cogna_2ddev5cogna4core6config11ConfigErrorE3Err(_M0MPC16result6Result11unwrap__errGRP411cogna_2ddev5cogna4core6config6ConfigRP411cogna_2ddev5cogna4core6config11ConfigErrorE(parsed));
          }
        }
        _L$3: {
          _L$4: {
            const _bind$5 = section.val;
            switch (_bind$5) {
              case "root": {
                switch (key) {
                  case "schemaVersion": {
                    schema_version.val = value;
                    break;
                  }
                  case "profile": {
                    profile.val = value;
                    break;
                  }
                  case "validation": {
                    validation.val = value;
                    break;
                  }
                  case "purl": {
                    purl.val = value;
                    break;
                  }
                  default: {
                    break _L$4;
                  }
                }
                break;
              }
              case "source": {
                switch (key) {
                  case "repo": {
                    source_repo.val = value;
                    break;
                  }
                  case "ref": {
                    source_ref.val = value;
                    break;
                  }
                  default: {
                    break _L$4;
                  }
                }
                break;
              }
              case "checks": {
                switch (key) {
                  case "format": {
                    checks_format.val = value;
                    break;
                  }
                  case "policy": {
                    checks_policy.val = value;
                    break;
                  }
                  default: {
                    break _L$4;
                  }
                }
                break;
              }
              case "diff": {
                switch (key) {
                  case "since": {
                    diff_since.val = value === "" ? undefined : value;
                    break;
                  }
                  case "includeTestChanges": {
                    const parsed$2 = _M0FP411cogna_2ddev5cogna4core6config11parse__bool(value, path, line_no, "diff.includeTestChanges");
                    let flag;
                    _L$5: {
                      if (parsed$2.$tag === 1) {
                        const _Ok = parsed$2;
                        const _flag = _Ok._0;
                        flag = _flag;
                        break _L$5;
                      } else {
                        return new _M0DTPC16result6ResultGRP411cogna_2ddev5cogna4core6config6ConfigRP411cogna_2ddev5cogna4core6config11ConfigErrorE3Err(_M0MPC16result6Result11unwrap__errGbRP411cogna_2ddev5cogna4core6config11ConfigErrorE(parsed$2));
                      }
                    }
                    diff_include_test_changes.val = flag;
                    break;
                  }
                  default: {
                    break _L$4;
                  }
                }
                break;
              }
              case "sbom": {
                switch (key) {
                  case "format": {
                    sbom_format.val = value;
                    break;
                  }
                  case "dependencyBundles": {
                    const parsed$3 = _M0FP411cogna_2ddev5cogna4core6config11parse__bool(value, path, line_no, "sbom.dependencyBundles");
                    let flag$2;
                    _L$6: {
                      if (parsed$3.$tag === 1) {
                        const _Ok = parsed$3;
                        const _flag = _Ok._0;
                        flag$2 = _flag;
                        break _L$6;
                      } else {
                        return new _M0DTPC16result6ResultGRP411cogna_2ddev5cogna4core6config6ConfigRP411cogna_2ddev5cogna4core6config11ConfigErrorE3Err(_M0MPC16result6Result11unwrap__errGbRP411cogna_2ddev5cogna4core6config11ConfigErrorE(parsed$3));
                      }
                    }
                    sbom_dependency_bundles.val = flag$2;
                    break;
                  }
                  case "requireLocalPackages": {
                    const parsed$4 = _M0FP411cogna_2ddev5cogna4core6config11parse__bool(value, path, line_no, "sbom.requireLocalPackages");
                    let flag$3;
                    _L$7: {
                      if (parsed$4.$tag === 1) {
                        const _Ok = parsed$4;
                        const _flag = _Ok._0;
                        flag$3 = _flag;
                        break _L$7;
                      } else {
                        return new _M0DTPC16result6ResultGRP411cogna_2ddev5cogna4core6config6ConfigRP411cogna_2ddev5cogna4core6config11ConfigErrorE3Err(_M0MPC16result6Result11unwrap__errGbRP411cogna_2ddev5cogna4core6config11ConfigErrorE(parsed$4));
                      }
                    }
                    sbom_require_local_packages.val = flag$3;
                    break;
                  }
                  default: {
                    break _L$4;
                  }
                }
                break;
              }
              case "cache": {
                if (key === "type") {
                  cache_type.val = value;
                } else {
                  break _L$4;
                }
                break;
              }
              case "cache_local": {
                if (key === "storeDir") {
                  cache_local_store_dir.val = value;
                } else {
                  break _L$4;
                }
                break;
              }
              case "cache_http": {
                switch (key) {
                  case "baseUrl": {
                    cache_http_base_url.val = value;
                    break;
                  }
                  case "timeoutMs": {
                    const parsed$5 = _M0FP411cogna_2ddev5cogna4core6config10parse__int(value, path, line_no, "cache.http.timeoutMs");
                    let number;
                    _L$8: {
                      if (parsed$5.$tag === 1) {
                        const _Ok = parsed$5;
                        const _number = _Ok._0;
                        number = _number;
                        break _L$8;
                      } else {
                        return new _M0DTPC16result6ResultGRP411cogna_2ddev5cogna4core6config6ConfigRP411cogna_2ddev5cogna4core6config11ConfigErrorE3Err(_M0MPC16result6Result11unwrap__errGiRP411cogna_2ddev5cogna4core6config11ConfigErrorE(parsed$5));
                      }
                    }
                    cache_http_timeout_ms.val = number;
                    break;
                  }
                  default: {
                    break _L$4;
                  }
                }
                break;
              }
              case "mcp": {
                if (key === "port") {
                  const parsed$6 = _M0FP411cogna_2ddev5cogna4core6config10parse__int(value, path, line_no, "mcp.port");
                  let number$2;
                  _L$9: {
                    if (parsed$6.$tag === 1) {
                      const _Ok = parsed$6;
                      const _number = _Ok._0;
                      number$2 = _number;
                      break _L$9;
                    } else {
                      return new _M0DTPC16result6ResultGRP411cogna_2ddev5cogna4core6config6ConfigRP411cogna_2ddev5cogna4core6config11ConfigErrorE3Err(_M0MPC16result6Result11unwrap__errGiRP411cogna_2ddev5cogna4core6config11ConfigErrorE(parsed$6));
                    }
                  }
                  mcp_port.val = number$2;
                } else {
                  break _L$4;
                }
                break;
              }
              default: {
                break _L$4;
              }
            }
            break _L$3;
          }
          return new _M0DTPC16result6ResultGRP411cogna_2ddev5cogna4core6config6ConfigRP411cogna_2ddev5cogna4core6config11ConfigErrorE3Err(new _M0DTPC15error5Error62cogna_2ddev_2fcogna_2fcore_2fconfig_2eConfigError_2eParseError(path, `line ${_M0IP016_24default__implPB4Show10to__stringGiE(line_no)}: unsupported key ${_M0IPC16string6StringPB4Show10to__string(key)} in section ${_M0IPC16string6StringPB4Show10to__string(section.val)}`));
        }
        break _L;
      }
      _tmp = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return new _M0DTPC16result6ResultGRP411cogna_2ddev5cogna4core6config6ConfigRP411cogna_2ddev5cogna4core6config11ConfigErrorE2Ok(new _M0TP411cogna_2ddev5cogna4core6config6Config(schema_version.val, profile.val, validation.val, purl.val, new _M0TP411cogna_2ddev5cogna4core6config6Source(source_repo.val, source_ref.val), new _M0TP411cogna_2ddev5cogna4core6config6Inputs(includes), new _M0TP411cogna_2ddev5cogna4core6config6Checks(checks_format.val, checks_policy.val), new _M0TP411cogna_2ddev5cogna4core6config12DiffSettings(diff_since.val, diff_include_test_changes.val), new _M0TP411cogna_2ddev5cogna4core6config12SbomSettings(sbom_format.val, sbom_dependency_bundles.val, sbom_require_local_packages.val), new _M0TP411cogna_2ddev5cogna4core6config13CacheSettings(cache_type.val, new _M0TP411cogna_2ddev5cogna4core6config18LocalCacheSettings(cache_local_store_dir.val), new _M0TP411cogna_2ddev5cogna4core6config17HttpCacheSettings(cache_http_base_url.val, cache_http_timeout_ms.val)), new _M0TP411cogna_2ddev5cogna4core6config11McpSettings(mcp_port.val)));
}
function _M0FP411cogna_2ddev5cogna4core6config16load__from__path(path) {
  let file_content;
  let _try_err;
  _L: {
    _L$2: {
      const _bind = _M0FP311moonbitlang1x2fs30read__file__to__string_2einner(path, "utf8");
      if (_bind.$tag === 1) {
        const _ok = _bind;
        file_content = _ok._0;
      } else {
        const _err = _bind;
        _try_err = _err._0;
        break _L$2;
      }
      break _L;
    }
    const err = _try_err;
    return new _M0DTPC16result6ResultGRP411cogna_2ddev5cogna4core6config6ConfigRP411cogna_2ddev5cogna4core6config11ConfigErrorE3Err(new _M0DTPC15error5Error65cogna_2ddev_2fcogna_2fcore_2fconfig_2eConfigError_2eFileReadError(path, _M0IP016_24default__implPB4Show10to__stringGRP311moonbitlang1x2fs7IOErrorE(err)));
  }
  const parsed = _M0FP411cogna_2ddev5cogna4core6config13parse__config(file_content, path);
  let config;
  _L$2: {
    if (parsed.$tag === 1) {
      const _Ok = parsed;
      const _config = _Ok._0;
      config = _config;
      break _L$2;
    } else {
      return new _M0DTPC16result6ResultGRP411cogna_2ddev5cogna4core6config6ConfigRP411cogna_2ddev5cogna4core6config11ConfigErrorE3Err(_M0MPC16result6Result11unwrap__errGRP411cogna_2ddev5cogna4core6config6ConfigRP411cogna_2ddev5cogna4core6config11ConfigErrorE(parsed));
    }
  }
  return _M0FP411cogna_2ddev5cogna4core6config8validate(config, path);
}
function _M0FP411cogna_2ddev5cogna4core6config7resolve(root_dir) {
  const base = root_dir === "" ? "." : root_dir;
  let path;
  _L: {
    const _bind = _M0FP411cogna_2ddev5cogna4core6config18find__config__path(base);
    if (_bind === undefined) {
      return new _M0DTPC16result6ResultGRP411cogna_2ddev5cogna4core6config14ResolvedConfigRP411cogna_2ddev5cogna4core6config11ConfigErrorE3Err(new _M0DTPC15error5Error65cogna_2ddev_2fcogna_2fcore_2fconfig_2eConfigError_2eFileReadError(base, "config file not found (tried cogna.yml, cogna.yaml)"));
    } else {
      const _Some = _bind;
      const _path = _Some;
      path = _path;
      break _L;
    }
  }
  const loaded = _M0FP411cogna_2ddev5cogna4core6config16load__from__path(path);
  let config;
  _L$2: {
    if (loaded.$tag === 1) {
      const _Ok = loaded;
      const _config = _Ok._0;
      config = _config;
      break _L$2;
    } else {
      return new _M0DTPC16result6ResultGRP411cogna_2ddev5cogna4core6config14ResolvedConfigRP411cogna_2ddev5cogna4core6config11ConfigErrorE3Err(_M0MPC16result6Result11unwrap__errGRP411cogna_2ddev5cogna4core6config6ConfigRP411cogna_2ddev5cogna4core6config11ConfigErrorE(loaded));
    }
  }
  return new _M0DTPC16result6ResultGRP411cogna_2ddev5cogna4core6config14ResolvedConfigRP411cogna_2ddev5cogna4core6config11ConfigErrorE2Ok(new _M0TP411cogna_2ddev5cogna4core6config14ResolvedConfig(path, _M0FP411cogna_2ddev5cogna4core6config11parent__dir(path), config));
}
function _M0MP411cogna_2ddev5cogna3sdk9generated14SourceLocation10from__json(j) {
  let obj;
  _L: {
    if (j.$tag === 6) {
      const _Object = j;
      const _obj = _Object._0;
      obj = _obj;
      break _L;
    } else {
      return undefined;
    }
  }
  let uri;
  let value;
  _L$2: {
    const _bind = _M0MPB3Map3getGsRPB4JsonE(obj, "uri");
    if (_bind === undefined) {
      return undefined;
    } else {
      const _Some = _bind;
      const _value = _Some;
      value = _value;
      break _L$2;
    }
  }
  let _bind;
  let text;
  _L$3: {
    _L$4: {
      if (value.$tag === 4) {
        const _String = value;
        const _text = _String._0;
        text = _text;
        break _L$4;
      } else {
        _bind = undefined;
      }
      break _L$3;
    }
    _bind = text;
  }
  if (_bind === undefined) {
    return undefined;
  } else {
    const _Some = _bind;
    const _parsed = _Some;
    uri = _parsed;
  }
  let start_line;
  let value$2;
  _L$4: {
    _L$5: {
      const _bind$2 = _M0MPB3Map3getGsRPB4JsonE(obj, "start_line");
      if (_bind$2 === undefined) {
        let value$3;
        _L$6: {
          const _bind$3 = _M0MPB3Map3getGsRPB4JsonE(obj, "startLine");
          if (_bind$3 === undefined) {
            return undefined;
          } else {
            const _Some = _bind$3;
            const _value = _Some;
            value$3 = _value;
            break _L$6;
          }
        }
        let _bind$3;
        let value$4;
        _L$7: {
          _L$8: {
            if (value$3.$tag === 3) {
              const _Number = value$3;
              const _value = _Number._0;
              value$4 = _value;
              break _L$8;
            } else {
              _bind$3 = undefined;
            }
            break _L$7;
          }
          _bind$3 = _M0MPC16double6Double7to__int(value$4);
        }
        if (_bind$3 === undefined) {
          return undefined;
        } else {
          const _Some = _bind$3;
          const _parsed = _Some;
          start_line = _parsed;
        }
      } else {
        const _Some = _bind$2;
        const _value = _Some;
        value$2 = _value;
        break _L$5;
      }
      break _L$4;
    }
    let _bind$2;
    let value$3;
    _L$6: {
      _L$7: {
        if (value$2.$tag === 3) {
          const _Number = value$2;
          const _value = _Number._0;
          value$3 = _value;
          break _L$7;
        } else {
          _bind$2 = undefined;
        }
        break _L$6;
      }
      _bind$2 = _M0MPC16double6Double7to__int(value$3);
    }
    if (_bind$2 === undefined) {
      return undefined;
    } else {
      const _Some = _bind$2;
      const _parsed = _Some;
      start_line = _parsed;
    }
  }
  let end_line;
  let value$3;
  _L$5: {
    _L$6: {
      const _bind$2 = _M0MPB3Map3getGsRPB4JsonE(obj, "end_line");
      if (_bind$2 === undefined) {
        let value$4;
        _L$7: {
          const _bind$3 = _M0MPB3Map3getGsRPB4JsonE(obj, "endLine");
          if (_bind$3 === undefined) {
            return undefined;
          } else {
            const _Some = _bind$3;
            const _value = _Some;
            value$4 = _value;
            break _L$7;
          }
        }
        let _bind$3;
        let value$5;
        _L$8: {
          _L$9: {
            if (value$4.$tag === 3) {
              const _Number = value$4;
              const _value = _Number._0;
              value$5 = _value;
              break _L$9;
            } else {
              _bind$3 = undefined;
            }
            break _L$8;
          }
          _bind$3 = _M0MPC16double6Double7to__int(value$5);
        }
        if (_bind$3 === undefined) {
          return undefined;
        } else {
          const _Some = _bind$3;
          const _parsed = _Some;
          end_line = _parsed;
        }
      } else {
        const _Some = _bind$2;
        const _value = _Some;
        value$3 = _value;
        break _L$6;
      }
      break _L$5;
    }
    let _bind$2;
    let value$4;
    _L$7: {
      _L$8: {
        if (value$3.$tag === 3) {
          const _Number = value$3;
          const _value = _Number._0;
          value$4 = _value;
          break _L$8;
        } else {
          _bind$2 = undefined;
        }
        break _L$7;
      }
      _bind$2 = _M0MPC16double6Double7to__int(value$4);
    }
    if (_bind$2 === undefined) {
      return undefined;
    } else {
      const _Some = _bind$2;
      const _parsed = _Some;
      end_line = _parsed;
    }
  }
  return new _M0TP411cogna_2ddev5cogna3sdk9generated14SourceLocation(uri, start_line, end_line);
}
function _M0MP411cogna_2ddev5cogna3sdk9generated11PackageNode10from__json(j) {
  let obj;
  _L: {
    if (j.$tag === 6) {
      const _Object = j;
      const _obj = _Object._0;
      obj = _obj;
      break _L;
    } else {
      return undefined;
    }
  }
  let name;
  let value;
  _L$2: {
    const _bind = _M0MPB3Map3getGsRPB4JsonE(obj, "name");
    if (_bind === undefined) {
      return undefined;
    } else {
      const _Some = _bind;
      const _value = _Some;
      value = _value;
      break _L$2;
    }
  }
  let _bind;
  let text;
  _L$3: {
    _L$4: {
      if (value.$tag === 4) {
        const _String = value;
        const _text = _String._0;
        text = _text;
        break _L$4;
      } else {
        _bind = undefined;
      }
      break _L$3;
    }
    _bind = text;
  }
  if (_bind === undefined) {
    return undefined;
  } else {
    const _Some = _bind;
    const _parsed = _Some;
    name = _parsed;
  }
  let version;
  let value$2;
  _L$4: {
    _L$5: {
      const _bind$2 = _M0MPB3Map3getGsRPB4JsonE(obj, "version");
      if (_bind$2 === undefined) {
        version = undefined;
      } else {
        const _Some = _bind$2;
        const _value = _Some;
        value$2 = _value;
        break _L$5;
      }
      break _L$4;
    }
    let text$2;
    _L$6: {
      _L$7: {
        if (value$2.$tag === 4) {
          const _String = value$2;
          const _text = _String._0;
          text$2 = _text;
          break _L$7;
        } else {
          version = undefined;
        }
        break _L$6;
      }
      version = text$2;
    }
  }
  let ecosystem;
  let value$3;
  _L$5: {
    _L$6: {
      const _bind$2 = _M0MPB3Map3getGsRPB4JsonE(obj, "ecosystem");
      if (_bind$2 === undefined) {
        ecosystem = undefined;
      } else {
        const _Some = _bind$2;
        const _value = _Some;
        value$3 = _value;
        break _L$6;
      }
      break _L$5;
    }
    let text$2;
    _L$7: {
      _L$8: {
        if (value$3.$tag === 4) {
          const _String = value$3;
          const _text = _String._0;
          text$2 = _text;
          break _L$8;
        } else {
          ecosystem = undefined;
        }
        break _L$7;
      }
      ecosystem = text$2;
    }
  }
  let relation;
  let value$4;
  _L$6: {
    const _bind$2 = _M0MPB3Map3getGsRPB4JsonE(obj, "relation");
    if (_bind$2 === undefined) {
      return undefined;
    } else {
      const _Some = _bind$2;
      const _value = _Some;
      value$4 = _value;
      break _L$6;
    }
  }
  let _bind$2;
  let text$2;
  _L$7: {
    _L$8: {
      if (value$4.$tag === 4) {
        const _String = value$4;
        const _text = _String._0;
        text$2 = _text;
        break _L$8;
      } else {
        _bind$2 = undefined;
      }
      break _L$7;
    }
    _bind$2 = text$2;
  }
  if (_bind$2 === undefined) {
    return undefined;
  } else {
    const _Some = _bind$2;
    const _parsed = _Some;
    relation = _parsed;
  }
  let summary;
  let value$5;
  _L$8: {
    _L$9: {
      const _bind$3 = _M0MPB3Map3getGsRPB4JsonE(obj, "summary");
      if (_bind$3 === undefined) {
        summary = undefined;
      } else {
        const _Some = _bind$3;
        const _value = _Some;
        value$5 = _value;
        break _L$9;
      }
      break _L$8;
    }
    let text$3;
    _L$10: {
      _L$11: {
        if (value$5.$tag === 4) {
          const _String = value$5;
          const _text = _String._0;
          text$3 = _text;
          break _L$11;
        } else {
          summary = undefined;
        }
        break _L$10;
      }
      summary = text$3;
    }
  }
  let children;
  let value$6;
  _L$9: {
    _L$10: {
      const _bind$3 = _M0MPB3Map3getGsRPB4JsonE(obj, "children");
      if (_bind$3 === undefined) {
        children = [];
      } else {
        const _Some = _bind$3;
        const _value = _Some;
        value$6 = _value;
        break _L$10;
      }
      break _L$9;
    }
    let _bind$3;
    let items;
    _L$11: {
      _L$12: {
        if (value$6.$tag === 5) {
          const _Array = value$6;
          const _items = _Array._0;
          items = _items;
          break _L$12;
        } else {
          _bind$3 = _M0DTPC16option6OptionGRPB5ArrayGRP411cogna_2ddev5cogna3sdk9generated11PackageNodeEE4None__;
        }
        break _L$11;
      }
      const parsed = [];
      const _bind$4 = items.length;
      let _tmp = 0;
      while (true) {
        const _ = _tmp;
        if (_ < _bind$4) {
          const item = items[_];
          let value$7;
          _L$13: {
            const _bind$5 = _M0MP411cogna_2ddev5cogna3sdk9generated11PackageNode10from__json(item);
            if (_bind$5 === undefined) {
              return undefined;
            } else {
              const _Some = _bind$5;
              const _value = _Some;
              value$7 = _value;
              break _L$13;
            }
          }
          _M0MPC15array5Array4pushGRPB4JsonE(parsed, value$7);
          _tmp = _ + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      _bind$3 = new _M0DTPC16option6OptionGRPB5ArrayGRP411cogna_2ddev5cogna3sdk9generated11PackageNodeEE4Some(parsed);
    }
    if (_bind$3.$tag === 1) {
      const _Some = _bind$3;
      const _parsed = _Some._0;
      children = _parsed;
    } else {
      return undefined;
    }
  }
  return new _M0TP411cogna_2ddev5cogna3sdk9generated11PackageNode(name, version, ecosystem, relation, summary, children);
}
function _M0MP411cogna_2ddev5cogna3sdk9generated7Outline10from__json(j) {
  let obj;
  _L: {
    if (j.$tag === 6) {
      const _Object = j;
      const _obj = _Object._0;
      obj = _obj;
      break _L;
    } else {
      return undefined;
    }
  }
  let id;
  let value;
  _L$2: {
    const _bind = _M0MPB3Map3getGsRPB4JsonE(obj, "id");
    if (_bind === undefined) {
      return undefined;
    } else {
      const _Some = _bind;
      const _value = _Some;
      value = _value;
      break _L$2;
    }
  }
  let _bind;
  let text;
  _L$3: {
    _L$4: {
      if (value.$tag === 4) {
        const _String = value;
        const _text = _String._0;
        text = _text;
        break _L$4;
      } else {
        _bind = undefined;
      }
      break _L$3;
    }
    _bind = text;
  }
  if (_bind === undefined) {
    return undefined;
  } else {
    const _Some = _bind;
    const _parsed = _Some;
    id = _parsed;
  }
  let symbol;
  let value$2;
  _L$4: {
    const _bind$2 = _M0MPB3Map3getGsRPB4JsonE(obj, "symbol");
    if (_bind$2 === undefined) {
      return undefined;
    } else {
      const _Some = _bind$2;
      const _value = _Some;
      value$2 = _value;
      break _L$4;
    }
  }
  let _bind$2;
  let text$2;
  _L$5: {
    _L$6: {
      if (value$2.$tag === 4) {
        const _String = value$2;
        const _text = _String._0;
        text$2 = _text;
        break _L$6;
      } else {
        _bind$2 = undefined;
      }
      break _L$5;
    }
    _bind$2 = text$2;
  }
  if (_bind$2 === undefined) {
    return undefined;
  } else {
    const _Some = _bind$2;
    const _parsed = _Some;
    symbol = _parsed;
  }
  let kind;
  let value$3;
  _L$6: {
    const _bind$3 = _M0MPB3Map3getGsRPB4JsonE(obj, "kind");
    if (_bind$3 === undefined) {
      return undefined;
    } else {
      const _Some = _bind$3;
      const _value = _Some;
      value$3 = _value;
      break _L$6;
    }
  }
  let _bind$3;
  let text$3;
  _L$7: {
    _L$8: {
      if (value$3.$tag === 4) {
        const _String = value$3;
        const _text = _String._0;
        text$3 = _text;
        break _L$8;
      } else {
        _bind$3 = undefined;
      }
      break _L$7;
    }
    _bind$3 = text$3;
  }
  if (_bind$3 === undefined) {
    return undefined;
  } else {
    const _Some = _bind$3;
    const _parsed = _Some;
    kind = _parsed;
  }
  let summary;
  let value$4;
  _L$8: {
    _L$9: {
      const _bind$4 = _M0MPB3Map3getGsRPB4JsonE(obj, "summary");
      if (_bind$4 === undefined) {
        summary = undefined;
      } else {
        const _Some = _bind$4;
        const _value = _Some;
        value$4 = _value;
        break _L$9;
      }
      break _L$8;
    }
    let text$4;
    _L$10: {
      _L$11: {
        if (value$4.$tag === 4) {
          const _String = value$4;
          const _text = _String._0;
          text$4 = _text;
          break _L$11;
        } else {
          summary = undefined;
        }
        break _L$10;
      }
      summary = text$4;
    }
  }
  let deprecated;
  let value$5;
  _L$9: {
    _L$10: {
      const _bind$4 = _M0MPB3Map3getGsRPB4JsonE(obj, "deprecated");
      if (_bind$4 === undefined) {
        deprecated = false;
      } else {
        const _Some = _bind$4;
        const _value = _Some;
        value$5 = _value;
        break _L$10;
      }
      break _L$9;
    }
    let _bind$4;
    switch (value$5.$tag) {
      case 1: {
        _bind$4 = true;
        break;
      }
      case 2: {
        _bind$4 = false;
        break;
      }
      default: {
        _bind$4 = -1;
      }
    }
    if (_bind$4 === -1) {
      return undefined;
    } else {
      const _Some = _bind$4;
      const _parsed = _Some;
      deprecated = _parsed;
    }
  }
  let location;
  let value$6;
  _L$10: {
    _L$11: {
      const _bind$4 = _M0MPB3Map3getGsRPB4JsonE(obj, "location");
      if (_bind$4 === undefined) {
        location = undefined;
      } else {
        const _Some = _bind$4;
        const _value = _Some;
        value$6 = _value;
        break _L$11;
      }
      break _L$10;
    }
    location = _M0MP411cogna_2ddev5cogna3sdk9generated14SourceLocation10from__json(value$6);
  }
  return new _M0TP411cogna_2ddev5cogna3sdk9generated7Outline(id, symbol, kind, summary, deprecated, location);
}
function _M0MP411cogna_2ddev5cogna3sdk9generated10QueryMatch10from__json(j) {
  let obj;
  _L: {
    if (j.$tag === 6) {
      const _Object = j;
      const _obj = _Object._0;
      obj = _obj;
      break _L;
    } else {
      return undefined;
    }
  }
  let id;
  let value;
  _L$2: {
    const _bind = _M0MPB3Map3getGsRPB4JsonE(obj, "id");
    if (_bind === undefined) {
      return undefined;
    } else {
      const _Some = _bind;
      const _value = _Some;
      value = _value;
      break _L$2;
    }
  }
  let _bind;
  let text;
  _L$3: {
    _L$4: {
      if (value.$tag === 4) {
        const _String = value;
        const _text = _String._0;
        text = _text;
        break _L$4;
      } else {
        _bind = undefined;
      }
      break _L$3;
    }
    _bind = text;
  }
  if (_bind === undefined) {
    return undefined;
  } else {
    const _Some = _bind;
    const _parsed = _Some;
    id = _parsed;
  }
  let symbol;
  let value$2;
  _L$4: {
    const _bind$2 = _M0MPB3Map3getGsRPB4JsonE(obj, "symbol");
    if (_bind$2 === undefined) {
      return undefined;
    } else {
      const _Some = _bind$2;
      const _value = _Some;
      value$2 = _value;
      break _L$4;
    }
  }
  let _bind$2;
  let text$2;
  _L$5: {
    _L$6: {
      if (value$2.$tag === 4) {
        const _String = value$2;
        const _text = _String._0;
        text$2 = _text;
        break _L$6;
      } else {
        _bind$2 = undefined;
      }
      break _L$5;
    }
    _bind$2 = text$2;
  }
  if (_bind$2 === undefined) {
    return undefined;
  } else {
    const _Some = _bind$2;
    const _parsed = _Some;
    symbol = _parsed;
  }
  let kind;
  let value$3;
  _L$6: {
    const _bind$3 = _M0MPB3Map3getGsRPB4JsonE(obj, "kind");
    if (_bind$3 === undefined) {
      return undefined;
    } else {
      const _Some = _bind$3;
      const _value = _Some;
      value$3 = _value;
      break _L$6;
    }
  }
  let _bind$3;
  let text$3;
  _L$7: {
    _L$8: {
      if (value$3.$tag === 4) {
        const _String = value$3;
        const _text = _String._0;
        text$3 = _text;
        break _L$8;
      } else {
        _bind$3 = undefined;
      }
      break _L$7;
    }
    _bind$3 = text$3;
  }
  if (_bind$3 === undefined) {
    return undefined;
  } else {
    const _Some = _bind$3;
    const _parsed = _Some;
    kind = _parsed;
  }
  let signature;
  let value$4;
  _L$8: {
    _L$9: {
      const _bind$4 = _M0MPB3Map3getGsRPB4JsonE(obj, "signature");
      if (_bind$4 === undefined) {
        signature = undefined;
      } else {
        const _Some = _bind$4;
        const _value = _Some;
        value$4 = _value;
        break _L$9;
      }
      break _L$8;
    }
    let text$4;
    _L$10: {
      _L$11: {
        if (value$4.$tag === 4) {
          const _String = value$4;
          const _text = _String._0;
          text$4 = _text;
          break _L$11;
        } else {
          signature = undefined;
        }
        break _L$10;
      }
      signature = text$4;
    }
  }
  let summary;
  let value$5;
  _L$9: {
    _L$10: {
      const _bind$4 = _M0MPB3Map3getGsRPB4JsonE(obj, "summary");
      if (_bind$4 === undefined) {
        summary = undefined;
      } else {
        const _Some = _bind$4;
        const _value = _Some;
        value$5 = _value;
        break _L$10;
      }
      break _L$9;
    }
    let text$4;
    _L$11: {
      _L$12: {
        if (value$5.$tag === 4) {
          const _String = value$5;
          const _text = _String._0;
          text$4 = _text;
          break _L$12;
        } else {
          summary = undefined;
        }
        break _L$11;
      }
      summary = text$4;
    }
  }
  let docs;
  let value$6;
  _L$10: {
    _L$11: {
      const _bind$4 = _M0MPB3Map3getGsRPB4JsonE(obj, "docs");
      if (_bind$4 === undefined) {
        docs = undefined;
      } else {
        const _Some = _bind$4;
        const _value = _Some;
        value$6 = _value;
        break _L$11;
      }
      break _L$10;
    }
    let text$4;
    _L$12: {
      _L$13: {
        if (value$6.$tag === 4) {
          const _String = value$6;
          const _text = _String._0;
          text$4 = _text;
          break _L$13;
        } else {
          docs = undefined;
        }
        break _L$12;
      }
      docs = text$4;
    }
  }
  let score;
  let value$7;
  _L$11: {
    _L$12: {
      const _bind$4 = _M0MPB3Map3getGsRPB4JsonE(obj, "score");
      if (_bind$4 === undefined) {
        score = _M0DTPC16option6OptionGdE4None__;
      } else {
        const _Some = _bind$4;
        const _value = _Some;
        value$7 = _value;
        break _L$12;
      }
      break _L$11;
    }
    let v;
    _L$13: {
      _L$14: {
        if (value$7.$tag === 3) {
          const _Number = value$7;
          const _v = _Number._0;
          v = _v;
          break _L$14;
        } else {
          score = _M0DTPC16option6OptionGdE4None__;
        }
        break _L$13;
      }
      score = new _M0DTPC16option6OptionGdE4Some(v);
    }
  }
  let location;
  let value$8;
  _L$12: {
    _L$13: {
      const _bind$4 = _M0MPB3Map3getGsRPB4JsonE(obj, "location");
      if (_bind$4 === undefined) {
        location = undefined;
      } else {
        const _Some = _bind$4;
        const _value = _Some;
        value$8 = _value;
        break _L$13;
      }
      break _L$12;
    }
    location = _M0MP411cogna_2ddev5cogna3sdk9generated14SourceLocation10from__json(value$8);
  }
  return new _M0TP411cogna_2ddev5cogna3sdk9generated10QueryMatch(id, symbol, kind, signature, summary, docs, score, location);
}
function _M0MP411cogna_2ddev5cogna3sdk9generated21FetchPackagesResponse10from__json(j) {
  let obj;
  _L: {
    if (j.$tag === 6) {
      const _Object = j;
      const _obj = _Object._0;
      obj = _obj;
      break _L;
    } else {
      return undefined;
    }
  }
  let root;
  let value;
  _L$2: {
    _L$3: {
      const _bind = _M0MPB3Map3getGsRPB4JsonE(obj, "root");
      if (_bind === undefined) {
        root = undefined;
      } else {
        const _Some = _bind;
        const _value = _Some;
        value = _value;
        break _L$3;
      }
      break _L$2;
    }
    root = _M0MP411cogna_2ddev5cogna3sdk9generated11PackageNode10from__json(value);
  }
  return new _M0TP411cogna_2ddev5cogna3sdk9generated21FetchPackagesResponse(root);
}
function _M0MP411cogna_2ddev5cogna3sdk9generated21QueryOutlinesResponse10from__json(j) {
  let obj;
  _L: {
    if (j.$tag === 6) {
      const _Object = j;
      const _obj = _Object._0;
      obj = _obj;
      break _L;
    } else {
      return undefined;
    }
  }
  let package_;
  let value;
  _L$2: {
    const _bind = _M0MPB3Map3getGsRPB4JsonE(obj, "package");
    if (_bind === undefined) {
      return undefined;
    } else {
      const _Some = _bind;
      const _value = _Some;
      value = _value;
      break _L$2;
    }
  }
  let _bind;
  let text;
  _L$3: {
    _L$4: {
      if (value.$tag === 4) {
        const _String = value;
        const _text = _String._0;
        text = _text;
        break _L$4;
      } else {
        _bind = undefined;
      }
      break _L$3;
    }
    _bind = text;
  }
  if (_bind === undefined) {
    return undefined;
  } else {
    const _Some = _bind;
    const _parsed = _Some;
    package_ = _parsed;
  }
  let outlines;
  let value$2;
  _L$4: {
    _L$5: {
      const _bind$2 = _M0MPB3Map3getGsRPB4JsonE(obj, "outlines");
      if (_bind$2 === undefined) {
        outlines = [];
      } else {
        const _Some = _bind$2;
        const _value = _Some;
        value$2 = _value;
        break _L$5;
      }
      break _L$4;
    }
    let _bind$2;
    let items;
    _L$6: {
      _L$7: {
        if (value$2.$tag === 5) {
          const _Array = value$2;
          const _items = _Array._0;
          items = _items;
          break _L$7;
        } else {
          _bind$2 = _M0DTPC16option6OptionGRPB5ArrayGRP411cogna_2ddev5cogna3sdk9generated7OutlineEE4None__;
        }
        break _L$6;
      }
      const parsed = [];
      const _bind$3 = items.length;
      let _tmp = 0;
      while (true) {
        const _ = _tmp;
        if (_ < _bind$3) {
          const item = items[_];
          let value$3;
          _L$8: {
            const _bind$4 = _M0MP411cogna_2ddev5cogna3sdk9generated7Outline10from__json(item);
            if (_bind$4 === undefined) {
              return undefined;
            } else {
              const _Some = _bind$4;
              const _value = _Some;
              value$3 = _value;
              break _L$8;
            }
          }
          _M0MPC15array5Array4pushGRPB4JsonE(parsed, value$3);
          _tmp = _ + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      _bind$2 = new _M0DTPC16option6OptionGRPB5ArrayGRP411cogna_2ddev5cogna3sdk9generated7OutlineEE4Some(parsed);
    }
    if (_bind$2.$tag === 1) {
      const _Some = _bind$2;
      const _parsed = _Some._0;
      outlines = _parsed;
    } else {
      return undefined;
    }
  }
  return new _M0TP411cogna_2ddev5cogna3sdk9generated21QueryOutlinesResponse(package_, outlines);
}
function _M0MP411cogna_2ddev5cogna3sdk9generated13QueryResponse10from__json(j) {
  let obj;
  _L: {
    if (j.$tag === 6) {
      const _Object = j;
      const _obj = _Object._0;
      obj = _obj;
      break _L;
    } else {
      return undefined;
    }
  }
  let package_;
  let value;
  _L$2: {
    const _bind = _M0MPB3Map3getGsRPB4JsonE(obj, "package");
    if (_bind === undefined) {
      return undefined;
    } else {
      const _Some = _bind;
      const _value = _Some;
      value = _value;
      break _L$2;
    }
  }
  let _bind;
  let text;
  _L$3: {
    _L$4: {
      if (value.$tag === 4) {
        const _String = value;
        const _text = _String._0;
        text = _text;
        break _L$4;
      } else {
        _bind = undefined;
      }
      break _L$3;
    }
    _bind = text;
  }
  if (_bind === undefined) {
    return undefined;
  } else {
    const _Some = _bind;
    const _parsed = _Some;
    package_ = _parsed;
  }
  let mode;
  let value$2;
  _L$4: {
    const _bind$2 = _M0MPB3Map3getGsRPB4JsonE(obj, "mode");
    if (_bind$2 === undefined) {
      return undefined;
    } else {
      const _Some = _bind$2;
      const _value = _Some;
      value$2 = _value;
      break _L$4;
    }
  }
  let _bind$2;
  let text$2;
  _L$5: {
    _L$6: {
      if (value$2.$tag === 4) {
        const _String = value$2;
        const _text = _String._0;
        text$2 = _text;
        break _L$6;
      } else {
        _bind$2 = undefined;
      }
      break _L$5;
    }
    _bind$2 = text$2;
  }
  if (_bind$2 === undefined) {
    return undefined;
  } else {
    const _Some = _bind$2;
    const _parsed = _Some;
    mode = _parsed;
  }
  let matches;
  let value$3;
  _L$6: {
    _L$7: {
      const _bind$3 = _M0MPB3Map3getGsRPB4JsonE(obj, "matches");
      if (_bind$3 === undefined) {
        matches = [];
      } else {
        const _Some = _bind$3;
        const _value = _Some;
        value$3 = _value;
        break _L$7;
      }
      break _L$6;
    }
    let _bind$3;
    let items;
    _L$8: {
      _L$9: {
        if (value$3.$tag === 5) {
          const _Array = value$3;
          const _items = _Array._0;
          items = _items;
          break _L$9;
        } else {
          _bind$3 = _M0DTPC16option6OptionGRPB5ArrayGRP411cogna_2ddev5cogna3sdk9generated10QueryMatchEE4None__;
        }
        break _L$8;
      }
      const parsed = [];
      const _bind$4 = items.length;
      let _tmp = 0;
      while (true) {
        const _ = _tmp;
        if (_ < _bind$4) {
          const item = items[_];
          let value$4;
          _L$10: {
            const _bind$5 = _M0MP411cogna_2ddev5cogna3sdk9generated10QueryMatch10from__json(item);
            if (_bind$5 === undefined) {
              return undefined;
            } else {
              const _Some = _bind$5;
              const _value = _Some;
              value$4 = _value;
              break _L$10;
            }
          }
          _M0MPC15array5Array4pushGRPB4JsonE(parsed, value$4);
          _tmp = _ + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      _bind$3 = new _M0DTPC16option6OptionGRPB5ArrayGRP411cogna_2ddev5cogna3sdk9generated10QueryMatchEE4Some(parsed);
    }
    if (_bind$3.$tag === 1) {
      const _Some = _bind$3;
      const _parsed = _Some._0;
      matches = _parsed;
    } else {
      return undefined;
    }
  }
  let cursor;
  let value$4;
  _L$7: {
    _L$8: {
      const _bind$3 = _M0MPB3Map3getGsRPB4JsonE(obj, "cursor");
      if (_bind$3 === undefined) {
        cursor = undefined;
      } else {
        const _Some = _bind$3;
        const _value = _Some;
        value$4 = _value;
        break _L$8;
      }
      break _L$7;
    }
    let text$3;
    _L$9: {
      _L$10: {
        if (value$4.$tag === 4) {
          const _String = value$4;
          const _text = _String._0;
          text$3 = _text;
          break _L$10;
        } else {
          cursor = undefined;
        }
        break _L$9;
      }
      cursor = text$3;
    }
  }
  return new _M0TP411cogna_2ddev5cogna3sdk9generated13QueryResponse(package_, mode, matches, cursor);
}
function _M0FP311cogna_2ddev5cogna3sdk8obj__str(obj, field) {
  const _bind = _M0MPB3Map3getGsRPB4JsonE(obj, field);
  if (_bind === undefined) {
    return "";
  } else {
    const _Some = _bind;
    const _x = _Some;
    if (_x.$tag === 4) {
      const _String = _x;
      const _s = _String._0;
      if (_M0IP016_24default__implPB2Eq10not__equalGsE(_s, "")) {
        return _s;
      } else {
        return "";
      }
    } else {
      return "";
    }
  }
}
function _M0FP311cogna_2ddev5cogna3sdk19resolved__root__dir() {
  let resolved;
  _L: {
    const _bind = _M0FP411cogna_2ddev5cogna4core6config7resolve(".");
    if (_bind.$tag === 1) {
      const _Ok = _bind;
      const _resolved = _Ok._0;
      resolved = _resolved;
      break _L;
    } else {
      return ".";
    }
  }
  return resolved.root_dir;
}
function _M0FP311cogna_2ddev5cogna3sdk18repo__for__package(pkg) {
  return _M0IP016_24default__implPB2Eq10not__equalGsE(pkg, "") && _M0FP311moonbitlang1x2fs12path__exists(pkg) ? pkg : _M0FP311cogna_2ddev5cogna3sdk19resolved__root__dir();
}
function _M0FP311cogna_2ddev5cogna3sdk17spdx__cache__path() {
  return `${_M0IPC16string6StringPB4Show10to__string(_M0FP311cogna_2ddev5cogna3sdk19resolved__root__dir())}/.cogna/sbom.spdx.json`;
}
function _M0FP311cogna_2ddev5cogna3sdk25package__name__from__purl(purl) {
  let prefix;
  const _bind = "pkg:";
  if (_M0MPC16string6String11has__prefix(purl, new _M0TPC16string10StringView(_bind, 0, _bind.length))) {
    prefix = _M0IPC16string10StringViewPB4Show10to__string(_M0MPC16string6String11sub_2einner(purl, 4, undefined));
  } else {
    prefix = purl;
  }
  let no_version;
  let first;
  _L: {
    _L$2: {
      const _bind$2 = "@";
      const _bind$3 = _M0MPB4Iter9to__arrayGRPC16string10StringViewE(_M0MPC16string6String5split(prefix, new _M0TPC16string10StringView(_bind$2, 0, _bind$2.length)));
      if (_bind$3.length >= 1) {
        const _first = _bind$3[0];
        first = _first;
        break _L$2;
      } else {
        no_version = prefix;
      }
      break _L;
    }
    no_version = _M0IPC16string10StringViewPB4Show10to__string(first);
  }
  const _bind$2 = "/";
  const parts = _M0MPB4Iter9to__arrayGRPC16string10StringViewE(_M0MPC16string6String5split(no_version, new _M0TPC16string10StringView(_bind$2, 0, _bind$2.length)));
  return parts.length === 0 ? no_version : _M0IPC16string10StringViewPB4Show10to__string(_M0MPC15array5Array2atGRPB4JsonE(parts, parts.length - 1 | 0));
}
function _M0FP311cogna_2ddev5cogna3sdk30package__ecosystem__from__purl(purl) {
  let prefix;
  const _bind = "pkg:";
  if (_M0MPC16string6String11has__prefix(purl, new _M0TPC16string10StringView(_bind, 0, _bind.length))) {
    prefix = _M0IPC16string10StringViewPB4Show10to__string(_M0MPC16string6String11sub_2einner(purl, 4, undefined));
  } else {
    prefix = purl;
  }
  const _bind$2 = "/";
  const parts = _M0MPB4Iter9to__arrayGRPC16string10StringViewE(_M0MPC16string6String5split(prefix, new _M0TPC16string10StringView(_bind$2, 0, _bind$2.length)));
  return parts.length === 0 ? undefined : _M0IPC16string10StringViewPB4Show10to__string(_M0MPC15array5Array2atGRPB4JsonE(parts, 0));
}
function _M0FP311cogna_2ddev5cogna3sdk19package__node__json(name, version, ecosystem, relation, summary, children) {
  const _bind = [{ _0: "name", _1: _M0IPC16string6StringPB6ToJson8to__json(name) }, { _0: "relation", _1: _M0IPC16string6StringPB6ToJson8to__json(relation) }, { _0: "children", _1: _M0MPC14json4Json5array(children) }];
  const obj = _M0MPB3Map11from__arrayGsRPB4JsonE(new _M0TPB9ArrayViewGUsRPB4JsonEE(_bind, 0, 3));
  let value;
  _L: {
    _L$2: {
      if (version === undefined) {
      } else {
        const _Some = version;
        const _value = _Some;
        if (_M0IP016_24default__implPB2Eq10not__equalGsE(_value, "")) {
          value = _value;
          break _L$2;
        }
      }
      break _L;
    }
    _M0MPB3Map3setGsRPB4JsonE(obj, "version", _M0MPC14json4Json6string(value));
  }
  let value$2;
  _L$2: {
    _L$3: {
      if (ecosystem === undefined) {
      } else {
        const _Some = ecosystem;
        const _value = _Some;
        if (_M0IP016_24default__implPB2Eq10not__equalGsE(_value, "")) {
          value$2 = _value;
          break _L$3;
        }
      }
      break _L$2;
    }
    _M0MPB3Map3setGsRPB4JsonE(obj, "ecosystem", _M0MPC14json4Json6string(value$2));
  }
  let value$3;
  _L$3: {
    _L$4: {
      if (summary === undefined) {
      } else {
        const _Some = summary;
        const _value = _Some;
        if (_M0IP016_24default__implPB2Eq10not__equalGsE(_value, "")) {
          value$3 = _value;
          break _L$4;
        }
      }
      break _L$3;
    }
    _M0MPB3Map3setGsRPB4JsonE(obj, "summary", _M0MPC14json4Json6string(value$3));
  }
  return _M0MPC14json4Json6object(obj);
}
function _M0FP311cogna_2ddev5cogna3sdk27fetch__packages__from__spdx() {
  if (!_M0FP311moonbitlang1x2fs12path__exists(_M0FP311cogna_2ddev5cogna3sdk17spdx__cache__path())) {
    return undefined;
  }
  let text;
  let _try_err;
  _L: {
    _L$2: {
      const _bind = _M0FP311moonbitlang1x2fs30read__file__to__string_2einner(_M0FP311cogna_2ddev5cogna3sdk17spdx__cache__path(), "utf8");
      if (_bind.$tag === 1) {
        const _ok = _bind;
        text = _ok._0;
      } else {
        const _err = _bind;
        _try_err = _err._0;
        break _L$2;
      }
      break _L;
    }
    return undefined;
  }
  let parsed;
  let _try_err$2;
  _L$2: {
    _L$3: {
      const _bind = _M0FPC14json13parse_2einner(new _M0TPC16string10StringView(text, 0, text.length), 1024);
      let _tmp;
      if (_bind.$tag === 1) {
        const _ok = _bind;
        _tmp = _ok._0;
      } else {
        const _err = _bind;
        _try_err$2 = _err._0;
        break _L$3;
      }
      parsed = new _M0DTPC16result6ResultGRPB4JsonRPC14json10ParseErrorE2Ok(_tmp);
      break _L$2;
    }
    parsed = new _M0DTPC16result6ResultGRPB4JsonRPC14json10ParseErrorE3Err(_try_err$2);
  }
  _L$3: {
    let doc;
    _L$4: {
      if (parsed.$tag === 1) {
        const _Ok = parsed;
        const _x = _Ok._0;
        if (_x.$tag === 6) {
          const _Object = _x;
          const _doc = _Object._0;
          doc = _doc;
          break _L$4;
        } else {
          break _L$3;
        }
      } else {
        break _L$3;
      }
    }
    _L$5: {
      let packages;
      _L$6: {
        const _bind = _M0MPB3Map3getGsRPB4JsonE(doc, "packages");
        if (_bind === undefined) {
          break _L$5;
        } else {
          const _Some = _bind;
          const _x = _Some;
          if (_x.$tag === 5) {
            const _Array = _x;
            const _packages = _Array._0;
            packages = _packages;
            break _L$6;
          } else {
            break _L$5;
          }
        }
      }
      const root_id_ref = _M0MPC13ref3Ref3newGOsE(undefined);
      const root_name_ref = _M0MPC13ref3Ref3newGOsE(undefined);
      const root_version_ref = _M0MPC13ref3Ref3newGOsE(undefined);
      const _bind = [];
      const pkg_by_id = _M0MPB3Map11from__arrayGsRPB4JsonE(new _M0TPB9ArrayViewGUsRPB4JsonEE(_bind, 0, 0));
      const _bind$2 = 0;
      const _bind$3 = packages.length;
      let _tmp = _bind$2;
      while (true) {
        const i = _tmp;
        if (i < _bind$3) {
          _L$7: {
            let pkg;
            _L$8: {
              const _bind$4 = _M0MPC15array5Array2atGRPB4JsonE(packages, i);
              if (_bind$4.$tag === 6) {
                const _Object = _bind$4;
                const _pkg = _Object._0;
                pkg = _pkg;
                break _L$8;
              } else {
                break _L$7;
              }
            }
            const spdx_id = _M0FP311cogna_2ddev5cogna3sdk8obj__str(pkg, "SPDXID");
            if (spdx_id === "") {
              break _L$7;
            }
            _M0MPB3Map3setGsRPB4JsonE(pkg_by_id, spdx_id, _M0MPC15array5Array2atGRPB4JsonE(packages, i));
            const _bind$4 = root_id_ref.val;
            if (_bind$4 === undefined) {
              const _bind$5 = "-Package-";
              if (!_M0MPC16string6String8contains(spdx_id, new _M0TPC16string10StringView(_bind$5, 0, _bind$5.length))) {
                root_id_ref.val = spdx_id;
                root_name_ref.val = _M0FP311cogna_2ddev5cogna3sdk8obj__str(pkg, "name");
                const root_version = _M0FP311cogna_2ddev5cogna3sdk8obj__str(pkg, "versionInfo");
                root_version_ref.val = root_version === "" ? undefined : root_version;
              }
            }
            break _L$7;
          }
          _tmp = i + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      let root_id;
      const _bind$4 = root_id_ref.val;
      if (_bind$4 === undefined) {
        return undefined;
      } else {
        const _Some = _bind$4;
        const _value = _Some;
        root_id = _value;
      }
      const _bind$5 = [];
      const relation_map = _M0MPB3Map11from__arrayGssE(new _M0TPB9ArrayViewGUssEE(_bind$5, 0, 0));
      let relationships;
      _L$7: {
        _L$8: {
          const _bind$6 = _M0MPB3Map3getGsRPB4JsonE(doc, "relationships");
          if (_bind$6 === undefined) {
          } else {
            const _Some = _bind$6;
            const _x = _Some;
            if (_x.$tag === 5) {
              const _Array = _x;
              const _relationships = _Array._0;
              relationships = _relationships;
              break _L$8;
            }
          }
          break _L$7;
        }
        const _bind$6 = 0;
        const _bind$7 = relationships.length;
        let _tmp$2 = _bind$6;
        while (true) {
          const i = _tmp$2;
          if (i < _bind$7) {
            _L$9: {
              let rel;
              _L$10: {
                const _bind$8 = _M0MPC15array5Array2atGRPB4JsonE(relationships, i);
                if (_bind$8.$tag === 6) {
                  const _Object = _bind$8;
                  const _rel = _Object._0;
                  rel = _rel;
                  break _L$10;
                } else {
                  break _L$9;
                }
              }
              if (_M0IP016_24default__implPB2Eq10not__equalGsE(_M0FP311cogna_2ddev5cogna3sdk8obj__str(rel, "relationshipType"), "DEPENDS_ON")) {
                break _L$9;
              }
              const source = _M0FP311cogna_2ddev5cogna3sdk8obj__str(rel, "spdxElementId");
              const target = _M0FP311cogna_2ddev5cogna3sdk8obj__str(rel, "relatedSpdxElement");
              if (source === root_id && _M0IP016_24default__implPB2Eq10not__equalGsE(target, "")) {
                _M0MPB3Map3setGssE(relation_map, target, "direct");
              } else {
                if (_M0IP016_24default__implPB2Eq10not__equalGsE(target, "") && !_M0MPB3Map8containsGssE(relation_map, target)) {
                  _M0MPB3Map3setGssE(relation_map, target, "transitive");
                }
              }
              break _L$9;
            }
            _tmp$2 = i + 1 | 0;
            continue;
          } else {
            break;
          }
        }
      }
      const children = [];
      const _it = _M0MPB3Map5iter2GsRPB4JsonE(pkg_by_id);
      while (true) {
        let spdx_id;
        let pkg_json;
        _L$8: {
          const _bind$6 = _M0MPB5Iter24nextGsRPB4JsonE(_it);
          if (_bind$6 === undefined) {
            break;
          } else {
            const _Some = _bind$6;
            const _x = _Some;
            const _spdx_id = _x._0;
            const _pkg_json = _x._1;
            spdx_id = _spdx_id;
            pkg_json = _pkg_json;
            break _L$8;
          }
        }
        if (spdx_id === root_id) {
          continue;
        }
        let pkg;
        _L$9: {
          if (pkg_json.$tag === 6) {
            const _Object = pkg_json;
            const _pkg = _Object._0;
            pkg = _pkg;
            break _L$9;
          } else {
            continue;
          }
        }
        const name = _M0FP311cogna_2ddev5cogna3sdk8obj__str(pkg, "name");
        if (name === "") {
          continue;
        }
        const version_text = _M0FP311cogna_2ddev5cogna3sdk8obj__str(pkg, "versionInfo");
        let ecosystem;
        _L$10: {
          _L$11: {
            let ext_refs;
            _L$12: {
              const _bind$6 = _M0MPB3Map3getGsRPB4JsonE(pkg, "externalRefs");
              if (_bind$6 === undefined) {
                break _L$11;
              } else {
                const _Some = _bind$6;
                const _x = _Some;
                if (_x.$tag === 5) {
                  const _Array = _x;
                  const _ext_refs = _Array._0;
                  ext_refs = _ext_refs;
                  break _L$12;
                } else {
                  break _L$11;
                }
              }
            }
            const found = new _M0TPB8MutLocalGOsE(undefined);
            const _bind$6 = 0;
            const _bind$7 = ext_refs.length;
            let _tmp$2 = _bind$6;
            while (true) {
              const j = _tmp$2;
              if (j < _bind$7) {
                _L$13: {
                  let ext_ref;
                  _L$14: {
                    const _bind$8 = _M0MPC15array5Array2atGRPB4JsonE(ext_refs, j);
                    if (_bind$8.$tag === 6) {
                      const _Object = _bind$8;
                      const _ext_ref = _Object._0;
                      ext_ref = _ext_ref;
                      break _L$14;
                    } else {
                      break _L$13;
                    }
                  }
                  if (_M0IP016_24default__implPB2Eq10not__equalGsE(_M0FP311cogna_2ddev5cogna3sdk8obj__str(ext_ref, "referenceType"), "purl")) {
                    break _L$13;
                  }
                  const locator = _M0FP311cogna_2ddev5cogna3sdk8obj__str(ext_ref, "referenceLocator");
                  if (_M0IP016_24default__implPB2Eq10not__equalGsE(locator, "")) {
                    found.val = _M0FP311cogna_2ddev5cogna3sdk30package__ecosystem__from__purl(locator);
                    break;
                  }
                  break _L$13;
                }
                _tmp$2 = j + 1 | 0;
                continue;
              } else {
                break;
              }
            }
            ecosystem = found.val;
            break _L$10;
          }
          ecosystem = undefined;
        }
        const desc = _M0FP311cogna_2ddev5cogna3sdk8obj__str(pkg, "description");
        const summary = _M0IP016_24default__implPB2Eq10not__equalGsE(desc, "") ? desc : undefined;
        const relation = _M0MPC16option6Option10unwrap__orGsE(_M0MPB3Map3getGssE(relation_map, spdx_id), "transitive");
        _M0MPC15array5Array4pushGRPB4JsonE(children, _M0FP311cogna_2ddev5cogna3sdk19package__node__json(name, version_text === "" ? undefined : version_text, ecosystem, relation, summary, []));
        continue;
      }
      const _bind$6 = [{ _0: "root", _1: _M0FP311cogna_2ddev5cogna3sdk19package__node__json(_M0MPC16option6Option10unwrap__orGsE(root_name_ref.val, "."), root_version_ref.val, "workspace", "root", undefined, children) }];
      return _M0MPC14json4Json6object(_M0MPB3Map11from__arrayGsRPB4JsonE(new _M0TPB9ArrayViewGUsRPB4JsonEE(_bind$6, 0, 1)));
    }
    return undefined;
  }
  return undefined;
}
function _M0FP311cogna_2ddev5cogna3sdk12decode__utf8(bytes, path) {
  let text;
  let _try_err;
  _L: {
    _L$2: {
      const _bind = _M0FPC28encoding4utf814decode_2einner(_M0MPC15bytes5Bytes12view_2einner(bytes, 0, bytes.length), false);
      if (_bind.$tag === 1) {
        const _ok = _bind;
        text = _ok._0;
      } else {
        const _err = _bind;
        _try_err = _err._0;
        break _L$2;
      }
      break _L;
    }
    return new _M0DTPC16result6ResultGssE3Err(`invalid utf-8 bytes in ${_M0IPC16string6StringPB4Show10to__string(path)}`);
  }
  return new _M0DTPC16result6ResultGssE2Ok(text);
}
function _M0FP311cogna_2ddev5cogna3sdk12read__ndjson(path) {
  let file_bytes;
  let _try_err;
  _L: {
    _L$2: {
      const _bind = _M0FP311moonbitlang1x2fs21read__file__to__bytes(path);
      if (_bind.$tag === 1) {
        const _ok = _bind;
        file_bytes = _ok._0;
      } else {
        const _err = _bind;
        _try_err = _err._0;
        break _L$2;
      }
      break _L;
    }
    return new _M0DTPC16result6ResultGRPB5ArrayGRPB4JsonEsE3Err(`cannot read ndjson ${_M0IPC16string6StringPB4Show10to__string(path)}`);
  }
  const text_out = _M0FP311cogna_2ddev5cogna3sdk12decode__utf8(file_bytes, path);
  let text;
  _L$2: {
    if (text_out.$tag === 1) {
      const _Ok = text_out;
      const _text = _Ok._0;
      text = _text;
      break _L$2;
    } else {
      return new _M0DTPC16result6ResultGRPB5ArrayGRPB4JsonEsE3Err(_M0MPC16result6Result11unwrap__errGRP411cogna_2ddev5cogna4core6config6ConfigRP411cogna_2ddev5cogna4core6config11ConfigErrorE(text_out));
    }
  }
  if (text === "") {
    return new _M0DTPC16result6ResultGRPB5ArrayGRPB4JsonEsE2Ok([]);
  }
  const _bind = "\n";
  const lines = _M0MPB4Iter9to__arrayGRPC16string10StringViewE(_M0MPC16string6String5split(text, new _M0TPC16string10StringView(_bind, 0, _bind.length)));
  const records = [];
  const _bind$2 = 0;
  const _bind$3 = lines.length;
  let _tmp = _bind$2;
  while (true) {
    const i = _tmp;
    if (i < _bind$3) {
      _L$3: {
        const line = _M0IPC16string10StringViewPB4Show10to__string(_M0MPC16string6String4trim(_M0IPC16string10StringViewPB4Show10to__string(_M0MPC15array5Array2atGRPB4JsonE(lines, i)), undefined));
        if (line === "") {
          break _L$3;
        }
        let parsed;
        let _try_err$2;
        _L$4: {
          _L$5: {
            const _bind$4 = _M0FPC14json13parse_2einner(new _M0TPC16string10StringView(line, 0, line.length), 1024);
            let _tmp$2;
            if (_bind$4.$tag === 1) {
              const _ok = _bind$4;
              _tmp$2 = _ok._0;
            } else {
              const _err = _bind$4;
              _try_err$2 = _err._0;
              break _L$5;
            }
            parsed = new _M0DTPC16result6ResultGRPB4JsonRPC14json10ParseErrorE2Ok(_tmp$2);
            break _L$4;
          }
          parsed = new _M0DTPC16result6ResultGRPB4JsonRPC14json10ParseErrorE3Err(_try_err$2);
        }
        let value;
        _L$5: {
          if (parsed.$tag === 1) {
            const _Ok = parsed;
            const _value = _Ok._0;
            value = _value;
            break _L$5;
          } else {
            return new _M0DTPC16result6ResultGRPB5ArrayGRPB4JsonEsE3Err(`invalid ndjson line in ${_M0IPC16string6StringPB4Show10to__string(path)} at ${_M0IP016_24default__implPB4Show10to__stringGiE(i + 1 | 0)}`);
          }
        }
        _M0MPC15array5Array4pushGRPB4JsonE(records, value);
        break _L$3;
      }
      _tmp = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return new _M0DTPC16result6ResultGRPB5ArrayGRPB4JsonEsE2Ok(records);
}
function _M0FP311cogna_2ddev5cogna3sdk14record__string(record, field) {
  let object;
  _L: {
    if (record.$tag === 6) {
      const _Object = record;
      const _object = _Object._0;
      object = _object;
      break _L;
    } else {
      return undefined;
    }
  }
  _L$2: {
    let value;
    _L$3: {
      const _bind = _M0MPB3Map3getGsRPB4JsonE(object, field);
      if (_bind === undefined) {
        break _L$2;
      } else {
        const _Some = _bind;
        const _x = _Some;
        if (_x.$tag === 4) {
          const _String = _x;
          const _value = _String._0;
          if (_M0IP016_24default__implPB2Eq10not__equalGsE(_value, "")) {
            value = _value;
            break _L$3;
          } else {
            break _L$2;
          }
        } else {
          break _L$2;
        }
      }
    }
    return value;
  }
  return undefined;
}
function _M0FP311cogna_2ddev5cogna3sdk14record__symbol(record) {
  const _bind = _M0FP311cogna_2ddev5cogna3sdk14record__string(record, "symbol");
  if (_bind === undefined) {
    const _bind$2 = _M0FP311cogna_2ddev5cogna3sdk14record__string(record, "canonical_name");
    if (_bind$2 === undefined) {
      const _bind$3 = _M0FP311cogna_2ddev5cogna3sdk14record__string(record, "name");
      if (_bind$3 === undefined) {
        return _M0MPC16option6Option10unwrap__orGsE(_M0FP311cogna_2ddev5cogna3sdk14record__string(record, "id"), "");
      } else {
        const _Some = _bind$3;
        const _value = _Some;
        return _value;
      }
    } else {
      const _Some = _bind$2;
      const _value = _Some;
      return _value;
    }
  } else {
    const _Some = _bind;
    const _value = _Some;
    return _value;
  }
}
function _M0FP311cogna_2ddev5cogna3sdk21selector__match__rank(record, selector_path) {
  const path = _M0MPC16option6Option10unwrap__orGsE(_M0FP311cogna_2ddev5cogna3sdk14record__string(record, "location"), "");
  const symbol = _M0FP311cogna_2ddev5cogna3sdk14record__symbol(record);
  const id = _M0MPC16option6Option10unwrap__orGsE(_M0FP311cogna_2ddev5cogna3sdk14record__string(record, "id"), "");
  const signature = _M0MPC16option6Option10unwrap__orGsE(_M0FP311cogna_2ddev5cogna3sdk14record__string(record, "signature"), "");
  return path === selector_path ? 0 : symbol === selector_path ? 1 : _M0MPC16string6String8contains(id, new _M0TPC16string10StringView(selector_path, 0, selector_path.length)) ? 2 : _M0MPC16string6String8contains(signature, new _M0TPC16string10StringView(selector_path, 0, selector_path.length)) ? 3 : undefined;
}
function _M0FP311cogna_2ddev5cogna3sdk16record__location(record, path_fallback) {
  let object;
  _L: {
    if (record.$tag === 6) {
      const _Object = record;
      const _object = _Object._0;
      object = _object;
      break _L;
    } else {
      const _bind = [{ _0: "uri", _1: _M0IPC16string6StringPB6ToJson8to__json(path_fallback) }, { _0: "startLine", _1: _M0MPC14json4Json6number(1, undefined) }, { _0: "endLine", _1: _M0MPC14json4Json6number(1, undefined) }];
      return _M0MPC14json4Json6object(_M0MPB3Map11from__arrayGsRPB4JsonE(new _M0TPB9ArrayViewGUsRPB4JsonEE(_bind, 0, 3)));
    }
  }
  _L$2: {
    let location_object;
    _L$3: {
      const _bind = _M0MPB3Map3getGsRPB4JsonE(object, "location");
      if (_bind === undefined) {
        break _L$2;
      } else {
        const _Some = _bind;
        const _x = _Some;
        if (_x.$tag === 6) {
          const _Object = _x;
          const _location_object = _Object._0;
          location_object = _location_object;
          break _L$3;
        } else {
          break _L$2;
        }
      }
    }
    let uri;
    _L$4: {
      _L$5: {
        const _bind = _M0MPB3Map3getGsRPB4JsonE(location_object, "uri");
        if (_bind === undefined) {
          break _L$5;
        } else {
          const _Some = _bind;
          const _x = _Some;
          if (_x.$tag === 4) {
            const _String = _x;
            const _value = _String._0;
            if (_M0IP016_24default__implPB2Eq10not__equalGsE(_value, "")) {
              uri = _value;
            } else {
              break _L$5;
            }
          } else {
            break _L$5;
          }
        }
        break _L$4;
      }
      uri = path_fallback;
    }
    let start_line;
    let value;
    _L$5: {
      _L$6: {
        const _bind = _M0MPB3Map3getGsRPB4JsonE(location_object, "startLine");
        if (_bind === undefined) {
          start_line = 1;
        } else {
          const _Some = _bind;
          const _x = _Some;
          if (_x.$tag === 3) {
            const _Number = _x;
            const _value = _Number._0;
            value = _value;
            break _L$6;
          } else {
            start_line = 1;
          }
        }
        break _L$5;
      }
      start_line = _M0MPC16double6Double7to__int(value);
    }
    let end_line;
    _L$6: {
      _L$7: {
        let value$2;
        _L$8: {
          const _bind = _M0MPB3Map3getGsRPB4JsonE(location_object, "endLine");
          if (_bind === undefined) {
            break _L$7;
          } else {
            const _Some = _bind;
            const _x = _Some;
            if (_x.$tag === 3) {
              const _Number = _x;
              const _value = _Number._0;
              value$2 = _value;
              break _L$8;
            } else {
              break _L$7;
            }
          }
        }
        end_line = _M0MPC16double6Double7to__int(value$2);
        break _L$6;
      }
      end_line = start_line;
    }
    const _bind = [{ _0: "uri", _1: _M0IPC16string6StringPB6ToJson8to__json(uri) }, { _0: "startLine", _1: _M0IPC13int3IntPB6ToJson8to__json(start_line) }, { _0: "endLine", _1: _M0IPC13int3IntPB6ToJson8to__json(end_line) }];
    return _M0MPC14json4Json6object(_M0MPB3Map11from__arrayGsRPB4JsonE(new _M0TPB9ArrayViewGUsRPB4JsonEE(_bind, 0, 3)));
  }
  const _bind = [{ _0: "uri", _1: _M0IPC16string6StringPB6ToJson8to__json(path_fallback) }, { _0: "startLine", _1: _M0MPC14json4Json6number(1, undefined) }, { _0: "endLine", _1: _M0MPC14json4Json6number(1, undefined) }];
  return _M0MPC14json4Json6object(_M0MPB3Map11from__arrayGsRPB4JsonE(new _M0TPB9ArrayViewGUsRPB4JsonEE(_bind, 0, 3)));
}
function _M0FP311cogna_2ddev5cogna3sdk21append__record__field(target, record_object, field) {
  let value;
  _L: {
    const _bind = _M0MPB3Map3getGsRPB4JsonE(record_object, field);
    if (_bind === undefined) {
      return;
    } else {
      const _Some = _bind;
      const _value = _Some;
      value = _value;
      break _L;
    }
  }
  _M0MPB3Map3setGsRPB4JsonE(target, field, value);
}
function _M0FP311cogna_2ddev5cogna3sdk35append__result__passthrough__fields(target, record_object) {
  const fields = ["docs", "location"];
  const _bind = 0;
  const _bind$2 = fields.length;
  let _tmp = _bind;
  while (true) {
    const i = _tmp;
    if (i < _bind$2) {
      _M0FP311cogna_2ddev5cogna3sdk21append__record__field(target, record_object, _M0MPC15array5Array2atGRPB4JsonE(fields, i));
      _tmp = i + 1 | 0;
      continue;
    } else {
      return;
    }
  }
}
function _M0FP311cogna_2ddev5cogna3sdk15append__records(records, source) {
  let values;
  _L: {
    if (source.$tag === 1) {
      const _Ok = source;
      const _values = _Ok._0;
      values = _values;
      break _L;
    } else {
      return;
    }
  }
  const _bind = 0;
  const _bind$2 = values.length;
  let _tmp = _bind;
  while (true) {
    const i = _tmp;
    if (i < _bind$2) {
      _M0MPC15array5Array4pushGRPB4JsonE(records, _M0MPC15array5Array2atGRPB4JsonE(values, i));
      _tmp = i + 1 | 0;
      continue;
    } else {
      return;
    }
  }
}
function _M0FP311cogna_2ddev5cogna3sdk19read__repo__records(repo, name) {
  const plain_path = `${_M0IPC16string6StringPB4Show10to__string(repo)}/dist/${_M0IPC16string6StringPB4Show10to__string(name)}.ndjson`;
  return _M0FP311moonbitlang1x2fs12path__exists(plain_path) ? _M0FP311cogna_2ddev5cogna3sdk12read__ndjson(plain_path) : new _M0DTPC16result6ResultGRPB5ArrayGRPB4JsonEsE3Err(`cannot read ndjson ${_M0IPC16string6StringPB4Show10to__string(plain_path)}`);
}
function _M0FP311cogna_2ddev5cogna3sdk24spdx__component__records(repo) {
  const path = `${_M0IPC16string6StringPB4Show10to__string(repo)}/.cogna/sbom.spdx.json`;
  if (!_M0FP311moonbitlang1x2fs12path__exists(path)) {
    return new _M0DTPC16result6ResultGRPB5ArrayGRPB4JsonEsE3Err(`cannot read json ${_M0IPC16string6StringPB4Show10to__string(path)}`);
  }
  let text;
  let _try_err;
  _L: {
    _L$2: {
      const _bind = _M0FP311moonbitlang1x2fs30read__file__to__string_2einner(path, "utf8");
      if (_bind.$tag === 1) {
        const _ok = _bind;
        text = _ok._0;
      } else {
        const _err = _bind;
        _try_err = _err._0;
        break _L$2;
      }
      break _L;
    }
    return new _M0DTPC16result6ResultGRPB5ArrayGRPB4JsonEsE3Err(`cannot read json ${_M0IPC16string6StringPB4Show10to__string(path)}`);
  }
  let parsed;
  let _try_err$2;
  _L$2: {
    _L$3: {
      const _bind = _M0FPC14json13parse_2einner(new _M0TPC16string10StringView(text, 0, text.length), 1024);
      let _tmp;
      if (_bind.$tag === 1) {
        const _ok = _bind;
        _tmp = _ok._0;
      } else {
        const _err = _bind;
        _try_err$2 = _err._0;
        break _L$3;
      }
      parsed = new _M0DTPC16result6ResultGRPB4JsonRPC14json10ParseErrorE2Ok(_tmp);
      break _L$2;
    }
    parsed = new _M0DTPC16result6ResultGRPB4JsonRPC14json10ParseErrorE3Err(_try_err$2);
  }
  _L$3: {
    let root;
    _L$4: {
      if (parsed.$tag === 1) {
        const _Ok = parsed;
        const _x = _Ok._0;
        if (_x.$tag === 6) {
          const _Object = _x;
          const _root = _Object._0;
          root = _root;
          break _L$4;
        } else {
          break _L$3;
        }
      } else {
        break _L$3;
      }
    }
    _L$5: {
      let packages;
      _L$6: {
        const _bind = _M0MPB3Map3getGsRPB4JsonE(root, "packages");
        if (_bind === undefined) {
          break _L$5;
        } else {
          const _Some = _bind;
          const _x = _Some;
          if (_x.$tag === 5) {
            const _Array = _x;
            const _packages = _Array._0;
            packages = _packages;
            break _L$6;
          } else {
            break _L$5;
          }
        }
      }
      const records = [];
      const _bind = 0;
      const _bind$2 = packages.length;
      let _tmp = _bind;
      while (true) {
        const i = _tmp;
        if (i < _bind$2) {
          _L$7: {
            let pkg;
            _L$8: {
              const _bind$3 = _M0MPC15array5Array2atGRPB4JsonE(packages, i);
              if (_bind$3.$tag === 6) {
                const _Object = _bind$3;
                const _pkg = _Object._0;
                pkg = _pkg;
                break _L$8;
              } else {
                break _L$7;
              }
            }
            const spdx_id = _M0FP311cogna_2ddev5cogna3sdk8obj__str(pkg, "SPDXID");
            let _tmp$2;
            if (spdx_id === "") {
              _tmp$2 = true;
            } else {
              const _bind$3 = "-Package-";
              _tmp$2 = !_M0MPC16string6String8contains(spdx_id, new _M0TPC16string10StringView(_bind$3, 0, _bind$3.length));
            }
            if (_tmp$2) {
              break _L$7;
            }
            const name = _M0FP311cogna_2ddev5cogna3sdk8obj__str(pkg, "name");
            if (name === "") {
              break _L$7;
            }
            const value = _M0FP311cogna_2ddev5cogna3sdk8obj__str(pkg, "versionInfo");
            const version = value === "" ? undefined : value;
            let purl;
            _L$9: {
              _L$10: {
                let refs;
                _L$11: {
                  const _bind$3 = _M0MPB3Map3getGsRPB4JsonE(pkg, "externalRefs");
                  if (_bind$3 === undefined) {
                    break _L$10;
                  } else {
                    const _Some = _bind$3;
                    const _x = _Some;
                    if (_x.$tag === 5) {
                      const _Array = _x;
                      const _refs = _Array._0;
                      refs = _refs;
                      break _L$11;
                    } else {
                      break _L$10;
                    }
                  }
                }
                const found = new _M0TPB8MutLocalGOsE(undefined);
                const _bind$3 = 0;
                const _bind$4 = refs.length;
                let _tmp$3 = _bind$3;
                while (true) {
                  const j = _tmp$3;
                  if (j < _bind$4) {
                    _L$12: {
                      let ref_obj;
                      _L$13: {
                        const _bind$5 = _M0MPC15array5Array2atGRPB4JsonE(refs, j);
                        if (_bind$5.$tag === 6) {
                          const _Object = _bind$5;
                          const _ref_obj = _Object._0;
                          ref_obj = _ref_obj;
                          break _L$13;
                        } else {
                          break _L$12;
                        }
                      }
                      if (_M0IP016_24default__implPB2Eq10not__equalGsE(_M0FP311cogna_2ddev5cogna3sdk8obj__str(ref_obj, "referenceType"), "purl")) {
                        break _L$12;
                      }
                      const locator = _M0FP311cogna_2ddev5cogna3sdk8obj__str(ref_obj, "referenceLocator");
                      if (_M0IP016_24default__implPB2Eq10not__equalGsE(locator, "")) {
                        found.val = locator;
                        break;
                      }
                      break _L$12;
                    }
                    _tmp$3 = j + 1 | 0;
                    continue;
                  } else {
                    break;
                  }
                }
                purl = found.val;
                break _L$9;
              }
              purl = undefined;
            }
            let id;
            if (purl === undefined) {
              id = `pkg:unknown/${_M0IPC16string6StringPB4Show10to__string(name)}`;
            } else {
              const _Some = purl;
              const _value = _Some;
              id = _value;
            }
            let signature;
            let value$2;
            _L$10: {
              _L$11: {
                if (version === undefined) {
                  signature = `library ${_M0IPC16string6StringPB4Show10to__string(name)}`;
                } else {
                  const _Some = version;
                  const _value = _Some;
                  value$2 = _value;
                  break _L$11;
                }
                break _L$10;
              }
              signature = `library ${_M0IPC16string6StringPB4Show10to__string(name)}@${_M0IPC16string6StringPB4Show10to__string(value$2)}`;
            }
            const _tmp$3 = { _0: "id", _1: _M0MPC14json4Json6string(id) };
            const _tmp$4 = { _0: "kind", _1: _M0MPC14json4Json6string("component") };
            const _tmp$5 = { _0: "path", _1: _M0MPC14json4Json6string("sbom.spdx.json") };
            const _tmp$6 = { _0: "signature", _1: _M0MPC14json4Json6string(signature) };
            const _tmp$7 = { _0: "name", _1: _M0MPC14json4Json6string(name) };
            const _tmp$8 = { _0: "componentType", _1: _M0MPC14json4Json6string("library") };
            const _tmp$9 = { _0: "scope", _1: _M0MPC14json4Json6string("dependency") };
            const _bind$3 = [{ _0: "uri", _1: _M0MPC14json4Json6string("sbom.spdx.json") }, { _0: "startLine", _1: _M0MPC14json4Json6number(1, undefined) }, { _0: "endLine", _1: _M0MPC14json4Json6number(1, undefined) }];
            const _bind$4 = [_tmp$3, _tmp$4, _tmp$5, _tmp$6, _tmp$7, _tmp$8, _tmp$9, { _0: "location", _1: _M0MPC14json4Json6object(_M0MPB3Map11from__arrayGsRPB4JsonE(new _M0TPB9ArrayViewGUsRPB4JsonEE(_bind$3, 0, 3))) }];
            const record = _M0MPB3Map11from__arrayGsRPB4JsonE(new _M0TPB9ArrayViewGUsRPB4JsonEE(_bind$4, 0, 8));
            let value$3;
            _L$11: {
              _L$12: {
                if (version === undefined) {
                } else {
                  const _Some = version;
                  const _value = _Some;
                  value$3 = _value;
                  break _L$12;
                }
                break _L$11;
              }
              _M0MPB3Map3setGsRPB4JsonE(record, "version", _M0MPC14json4Json6string(value$3));
            }
            let value$4;
            _L$12: {
              _L$13: {
                if (purl === undefined) {
                } else {
                  const _Some = purl;
                  const _value = _Some;
                  value$4 = _value;
                  break _L$13;
                }
                break _L$12;
              }
              _M0MPB3Map3setGsRPB4JsonE(record, "purl", _M0MPC14json4Json6string(value$4));
            }
            _M0MPC15array5Array4pushGRPB4JsonE(records, _M0MPC14json4Json6object(record));
            break _L$7;
          }
          _tmp = i + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      return new _M0DTPC16result6ResultGRPB5ArrayGRPB4JsonEsE2Ok(records);
    }
    return new _M0DTPC16result6ResultGRPB5ArrayGRPB4JsonEsE2Ok([]);
  }
  return new _M0DTPC16result6ResultGRPB5ArrayGRPB4JsonEsE3Err(`invalid json in ${_M0IPC16string6StringPB4Show10to__string(path)}`);
}
function _M0FP311cogna_2ddev5cogna3sdk24read__component__records(repo) {
  const _bind = _M0FP311cogna_2ddev5cogna3sdk19read__repo__records(repo, "software-components");
  if (_bind.$tag === 1) {
    const _Ok = _bind;
    const _records = _Ok._0;
    return _records;
  } else {
    const _bind$2 = _M0FP311cogna_2ddev5cogna3sdk24spdx__component__records(repo);
    if (_bind$2.$tag === 1) {
      const _Ok = _bind$2;
      const _records = _Ok._0;
      return _records;
    } else {
      return [];
    }
  }
}
function _M0FP311cogna_2ddev5cogna3sdk20all__bundle__records(repo) {
  const records = [];
  _M0FP311cogna_2ddev5cogna3sdk15append__records(records, _M0FP311cogna_2ddev5cogna3sdk19read__repo__records(repo, "declarations"));
  const components = _M0FP311cogna_2ddev5cogna3sdk24read__component__records(repo);
  const _bind = 0;
  const _bind$2 = components.length;
  let _tmp = _bind;
  while (true) {
    const i = _tmp;
    if (i < _bind$2) {
      _M0MPC15array5Array4pushGRPB4JsonE(records, _M0MPC15array5Array2atGRPB4JsonE(components, i));
      _tmp = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return records;
}
function _M0FP311cogna_2ddev5cogna3sdk25record__matches__selector(record, selector_path, selector_kind, expected_rank) {
  let path;
  const _bind = _M0FP311cogna_2ddev5cogna3sdk14record__string(record, "path");
  if (_bind === undefined) {
    path = "";
  } else {
    const _Some = _bind;
    const _value = _Some;
    path = _value;
  }
  let kind;
  const _bind$2 = _M0FP311cogna_2ddev5cogna3sdk14record__string(record, "kind");
  if (_bind$2 === undefined) {
    kind = "";
  } else {
    const _Some = _bind$2;
    const _value = _Some;
    kind = _value;
  }
  let id;
  const _bind$3 = _M0FP311cogna_2ddev5cogna3sdk14record__string(record, "id");
  if (_bind$3 === undefined) {
    id = "";
  } else {
    const _Some = _bind$3;
    const _value = _Some;
    id = _value;
  }
  let signature;
  const _bind$4 = _M0FP311cogna_2ddev5cogna3sdk14record__string(record, "signature");
  if (_bind$4 === undefined) {
    signature = "";
  } else {
    const _Some = _bind$4;
    const _value = _Some;
    signature = _value;
  }
  if (id === "" || (kind === "" || signature === "")) {
    return undefined;
  }
  if (kind === "component") {
    return undefined;
  }
  const symbol = _M0FP311cogna_2ddev5cogna3sdk14record__symbol(record);
  if (symbol === "") {
    return undefined;
  }
  let kind_hint;
  _L: {
    _L$2: {
      if (selector_kind === undefined) {
      } else {
        const _Some = selector_kind;
        const _kind_hint = _Some;
        if (_M0IP016_24default__implPB2Eq10not__equalGsE(kind, _kind_hint)) {
          kind_hint = _kind_hint;
          break _L$2;
        }
      }
      break _L;
    }
    return undefined;
  }
  let rank;
  _L$2: {
    const _bind$5 = _M0FP311cogna_2ddev5cogna3sdk21selector__match__rank(record, selector_path);
    if (_bind$5 === undefined) {
      return undefined;
    } else {
      const _Some = _bind$5;
      const _rank = _Some;
      rank = _rank;
      break _L$2;
    }
  }
  if (rank !== expected_rank) {
    return undefined;
  }
  const location_path = path === "" ? selector_path : path;
  const _bind$5 = [{ _0: "id", _1: _M0IPC16string6StringPB6ToJson8to__json(id) }, { _0: "kind", _1: _M0IPC16string6StringPB6ToJson8to__json(kind) }, { _0: "symbol", _1: _M0IPC16string6StringPB6ToJson8to__json(symbol) }, { _0: "signature", _1: _M0IPC16string6StringPB6ToJson8to__json(signature) }, { _0: "location", _1: _M0FP311cogna_2ddev5cogna3sdk16record__location(record, location_path) }];
  const match_record = _M0MPB3Map11from__arrayGsRPB4JsonE(new _M0TPB9ArrayViewGUsRPB4JsonEE(_bind$5, 0, 5));
  let record_object;
  _L$3: {
    if (record.$tag === 6) {
      const _Object = record;
      const _record_object = _Object._0;
      record_object = _record_object;
      break _L$3;
    } else {
      return _M0MPC14json4Json6object(match_record);
    }
  }
  _M0FP311cogna_2ddev5cogna3sdk35append__result__passthrough__fields(match_record, record_object);
  return _M0MPC14json4Json6object(match_record);
}
function _M0FP311cogna_2ddev5cogna3sdk29query__matches__from__records(records, selector_path, selector_kind) {
  const selected = [];
  const _bind = [];
  const seen = _M0MPB3Map11from__arrayGsbE(new _M0TPB9ArrayViewGUsbEE(_bind, 0, 0));
  const _bind$2 = 0;
  const _bind$3 = 4;
  let _tmp = _bind$2;
  while (true) {
    const rank = _tmp;
    if (rank < _bind$3) {
      const _bind$4 = 0;
      const _bind$5 = records.length;
      let _tmp$2 = _bind$4;
      while (true) {
        const i = _tmp$2;
        if (i < _bind$5) {
          _L: {
            const match_out = _M0FP311cogna_2ddev5cogna3sdk25record__matches__selector(_M0MPC15array5Array2atGRPB4JsonE(records, i), selector_path, selector_kind, rank);
            let found;
            _L$2: {
              if (match_out === undefined) {
                break _L;
              } else {
                const _Some = match_out;
                const _found = _Some;
                found = _found;
                break _L$2;
              }
            }
            let found_object;
            _L$3: {
              if (found.$tag === 6) {
                const _Object = found;
                const _found_object = _Object._0;
                found_object = _found_object;
                break _L$3;
              } else {
                break _L;
              }
            }
            _L$4: {
              _L$5: {
                let id;
                _L$6: {
                  const _bind$6 = _M0MPB3Map3getGsRPB4JsonE(found_object, "id");
                  if (_bind$6 === undefined) {
                    break _L$5;
                  } else {
                    const _Some = _bind$6;
                    const _x = _Some;
                    if (_x.$tag === 4) {
                      const _String = _x;
                      const _id = _String._0;
                      id = _id;
                      break _L$6;
                    } else {
                      break _L$5;
                    }
                  }
                }
                if (!_M0MPB3Map8containsGsbE(seen, id)) {
                  _M0MPB3Map3setGsbE(seen, id, true);
                  _M0MPC15array5Array4pushGRPB4JsonE(selected, found);
                }
                break _L$4;
              }
              break _L;
            }
            break _L;
          }
          _tmp$2 = i + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      _tmp = rank + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return selected;
}
function _M0FP311cogna_2ddev5cogna3sdk14query__matches(repo, selector_path, selector_kind) {
  const records = _M0FP311cogna_2ddev5cogna3sdk20all__bundle__records(repo);
  return _M0FP311cogna_2ddev5cogna3sdk29query__matches__from__records(records, selector_path, selector_kind);
}
function _M0FP311cogna_2ddev5cogna3sdk21fetch__packages__json() {
  let value;
  _L: {
    _L$2: {
      const _bind = _M0FP311cogna_2ddev5cogna3sdk27fetch__packages__from__spdx();
      if (_bind === undefined) {
      } else {
        const _Some = _bind;
        const _value = _Some;
        value = _value;
        break _L$2;
      }
      break _L;
    }
    return value;
  }
  const root = _M0FP311cogna_2ddev5cogna3sdk19resolved__root__dir();
  let root_name;
  let records;
  _L$2: {
    _L$3: {
      const _bind = _M0FP311cogna_2ddev5cogna3sdk19read__repo__records(root, "manifest");
      if (_bind.$tag === 1) {
        const _Ok = _bind;
        const _records = _Ok._0;
        if (_records.length > 0) {
          records = _records;
          break _L$3;
        } else {
          root_name = ".";
        }
      } else {
        root_name = ".";
      }
      break _L$2;
    }
    let obj;
    _L$4: {
      _L$5: {
        const _bind = _M0MPC15array5Array2atGRPB4JsonE(records, 0);
        if (_bind.$tag === 6) {
          const _Object = _bind;
          const _obj = _Object._0;
          obj = _obj;
          break _L$5;
        } else {
          root_name = ".";
        }
        break _L$4;
      }
      const purl = _M0FP311cogna_2ddev5cogna3sdk8obj__str(obj, "purl");
      root_name = _M0IP016_24default__implPB2Eq10not__equalGsE(purl, "") ? _M0FP311cogna_2ddev5cogna3sdk25package__name__from__purl(purl) : ".";
    }
  }
  const children = [];
  const records$2 = _M0FP311cogna_2ddev5cogna3sdk24read__component__records(root);
  const _bind = 0;
  const _bind$2 = records$2.length;
  let _tmp = _bind;
  while (true) {
    const i = _tmp;
    if (i < _bind$2) {
      _L$3: {
        let obj;
        _L$4: {
          const _bind$3 = _M0MPC15array5Array2atGRPB4JsonE(records$2, i);
          if (_bind$3.$tag === 6) {
            const _Object = _bind$3;
            const _obj = _Object._0;
            obj = _obj;
            break _L$4;
          } else {
            break _L$3;
          }
        }
        const name = _M0FP311cogna_2ddev5cogna3sdk8obj__str(obj, "name");
        const scope = _M0FP311cogna_2ddev5cogna3sdk8obj__str(obj, "scope");
        const relation = scope === "" ? "dependency" : scope;
        if (name === "") {
          break _L$3;
        }
        let version;
        const _bind$3 = _M0MPB3Map3getGsRPB4JsonE(obj, "version");
        if (_bind$3 === undefined) {
          version = "";
        } else {
          const _Some = _bind$3;
          const _x = _Some;
          if (_x.$tag === 4) {
            const _String = _x;
            const _v = _String._0;
            if (_M0IP016_24default__implPB2Eq10not__equalGsE(_v, "")) {
              version = _v;
            } else {
              version = "";
            }
          } else {
            version = "";
          }
        }
        _M0MPC15array5Array4pushGRPB4JsonE(children, _M0FP311cogna_2ddev5cogna3sdk19package__node__json(name, _M0IP016_24default__implPB2Eq10not__equalGsE(version, "") ? version : undefined, undefined, relation, undefined, []));
        break _L$3;
      }
      _tmp = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  const _bind$3 = [{ _0: "root", _1: _M0FP311cogna_2ddev5cogna3sdk19package__node__json(root_name, undefined, "workspace", "root", undefined, children) }];
  return _M0MPC14json4Json6object(_M0MPB3Map11from__arrayGsRPB4JsonE(new _M0TPB9ArrayViewGUsRPB4JsonEE(_bind$3, 0, 1)));
}
function _M0FP311cogna_2ddev5cogna3sdk29query__outlines__for__package(pkg) {
  const records = _M0FP311cogna_2ddev5cogna3sdk20all__bundle__records(_M0FP311cogna_2ddev5cogna3sdk18repo__for__package(pkg));
  const outlines = [];
  const _bind = [];
  const seen = _M0MPB3Map11from__arrayGsbE(new _M0TPB9ArrayViewGUsbEE(_bind, 0, 0));
  const _bind$2 = 0;
  const _bind$3 = records.length;
  let _tmp = _bind$2;
  while (true) {
    const i = _tmp;
    if (i < _bind$3) {
      _L: {
        let obj;
        _L$2: {
          const _bind$4 = _M0MPC15array5Array2atGRPB4JsonE(records, i);
          if (_bind$4.$tag === 6) {
            const _Object = _bind$4;
            const _obj = _Object._0;
            obj = _obj;
            break _L$2;
          } else {
            break _L;
          }
        }
        const id = _M0FP311cogna_2ddev5cogna3sdk8obj__str(obj, "id");
        const kind = _M0FP311cogna_2ddev5cogna3sdk8obj__str(obj, "kind");
        if (id === "" || kind === "") {
          break _L;
        }
        if (kind === "component") {
          break _L;
        }
        if (_M0MPB3Map8containsGsbE(seen, id)) {
          break _L;
        }
        _M0MPB3Map3setGsbE(seen, id, true);
        const s = _M0FP311cogna_2ddev5cogna3sdk8obj__str(obj, "symbol");
        let symbol;
        if (_M0IP016_24default__implPB2Eq10not__equalGsE(s, "")) {
          symbol = s;
        } else {
          const canonical = _M0FP311cogna_2ddev5cogna3sdk8obj__str(obj, "canonical_name");
          if (_M0IP016_24default__implPB2Eq10not__equalGsE(canonical, "")) {
            symbol = canonical;
          } else {
            const name = _M0FP311cogna_2ddev5cogna3sdk8obj__str(obj, "name");
            symbol = _M0IP016_24default__implPB2Eq10not__equalGsE(name, "") ? name : _M0FP311cogna_2ddev5cogna3sdk8obj__str(obj, "id");
          }
        }
        const d = _M0FP311cogna_2ddev5cogna3sdk8obj__str(obj, "docs");
        const summary_str = _M0IP016_24default__implPB2Eq10not__equalGsE(d, "") ? d : _M0FP311cogna_2ddev5cogna3sdk8obj__str(obj, "signature");
        const _bind$4 = [{ _0: "id", _1: _M0IPC16string6StringPB6ToJson8to__json(id) }, { _0: "symbol", _1: _M0IPC16string6StringPB6ToJson8to__json(symbol) }, { _0: "kind", _1: _M0IPC16string6StringPB6ToJson8to__json(kind) }, { _0: "deprecated", _1: _M0MPC14json4Json7boolean(false) }];
        const outline = _M0MPB3Map11from__arrayGsRPB4JsonE(new _M0TPB9ArrayViewGUsRPB4JsonEE(_bind$4, 0, 4));
        if (_M0IP016_24default__implPB2Eq10not__equalGsE(summary_str, "")) {
          _M0MPB3Map3setGsRPB4JsonE(outline, "summary", _M0MPC14json4Json6string(summary_str));
        }
        let loc;
        _L$3: {
          _L$4: {
            const _bind$5 = _M0MPB3Map3getGsRPB4JsonE(obj, "location");
            if (_bind$5 === undefined) {
            } else {
              const _Some = _bind$5;
              const _loc = _Some;
              loc = _loc;
              break _L$4;
            }
            break _L$3;
          }
          _M0MPB3Map3setGsRPB4JsonE(outline, "location", loc);
        }
        _M0MPC15array5Array4pushGRPB4JsonE(outlines, _M0MPC14json4Json6object(outline));
        break _L;
      }
      _tmp = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  const _bind$4 = [{ _0: "package", _1: _M0IPC16string6StringPB6ToJson8to__json(pkg) }, { _0: "outlines", _1: _M0MPC14json4Json5array(outlines) }];
  return _M0MPC14json4Json6object(_M0MPB3Map11from__arrayGsRPB4JsonE(new _M0TPB9ArrayViewGUsRPB4JsonEE(_bind$4, 0, 2)));
}
function _M0FP311cogna_2ddev5cogna3sdk14query__package(pkg, exact_id, exact_symbol, text, limit, _cursor) {
  let mode;
  let selector;
  _L: {
    _L$2: {
      let id;
      _L$3: {
        if (exact_id === undefined) {
          break _L$2;
        } else {
          const _Some = exact_id;
          const _id = _Some;
          if (_M0IP016_24default__implPB2Eq10not__equalGsE(_id, "")) {
            id = _id;
            break _L$3;
          } else {
            break _L$2;
          }
        }
      }
      mode = "exact-id";
      selector = id;
      break _L;
    }
    _L$3: {
      let sym;
      _L$4: {
        if (exact_symbol === undefined) {
          break _L$3;
        } else {
          const _Some = exact_symbol;
          const _sym = _Some;
          if (_M0IP016_24default__implPB2Eq10not__equalGsE(_sym, "")) {
            sym = _sym;
            break _L$4;
          } else {
            break _L$3;
          }
        }
      }
      mode = "exact-symbol";
      selector = sym;
      break _L;
    }
    _L$4: {
      let t;
      _L$5: {
        if (text === undefined) {
          break _L$4;
        } else {
          const _Some = text;
          const _t = _Some;
          if (_M0IP016_24default__implPB2Eq10not__equalGsE(_t, "")) {
            t = _t;
            break _L$5;
          } else {
            break _L$4;
          }
        }
      }
      mode = "fuzzy-text";
      selector = t;
      break _L;
    }
    mode = "fuzzy-text";
    selector = "";
    break _L;
  }
  let max;
  if (limit === undefined) {
    max = 20;
  } else {
    const _Some = limit;
    const _n = _Some;
    if (_n > 0) {
      max = _n;
    } else {
      max = 20;
    }
  }
  const raw_matches = _M0FP311cogna_2ddev5cogna3sdk14query__matches(_M0FP311cogna_2ddev5cogna3sdk18repo__for__package(pkg), selector, undefined);
  const enriched = [];
  const _bind = 0;
  const _bind$2 = raw_matches.length;
  let _tmp = _bind;
  while (true) {
    const i = _tmp;
    if (i < _bind$2) {
      _L$2: {
        let obj;
        _L$3: {
          const _bind$3 = _M0MPC15array5Array2atGRPB4JsonE(raw_matches, i);
          if (_bind$3.$tag === 6) {
            const _Object = _bind$3;
            const _obj = _Object._0;
            obj = _obj;
            break _L$3;
          } else {
            _M0MPC15array5Array4pushGRPB4JsonE(enriched, _M0MPC15array5Array2atGRPB4JsonE(raw_matches, i));
            break _L$2;
          }
        }
        const s = _M0FP311cogna_2ddev5cogna3sdk8obj__str(obj, "symbol");
        const symbol = _M0IP016_24default__implPB2Eq10not__equalGsE(s, "") ? s : _M0FP311cogna_2ddev5cogna3sdk8obj__str(obj, "id");
        const _bind$3 = [];
        const enriched_obj = _M0MPB3Map11from__arrayGsRPB4JsonE(new _M0TPB9ArrayViewGUsRPB4JsonEE(_bind$3, 0, 0));
        const _it = _M0MPB3Map5iter2GsRPB4JsonE(obj);
        while (true) {
          let key;
          let val;
          _L$4: {
            const _bind$4 = _M0MPB5Iter24nextGsRPB4JsonE(_it);
            if (_bind$4 === undefined) {
              break;
            } else {
              const _Some = _bind$4;
              const _x = _Some;
              const _key = _x._0;
              const _val = _x._1;
              key = _key;
              val = _val;
              break _L$4;
            }
          }
          _M0MPB3Map3setGsRPB4JsonE(enriched_obj, key, val);
          continue;
        }
        _M0MPB3Map3setGsRPB4JsonE(enriched_obj, "symbol", _M0MPC14json4Json6string(symbol));
        if (!_M0MPB3Map8containsGsRPB4JsonE(obj, "summary")) {
          const d = _M0FP311cogna_2ddev5cogna3sdk8obj__str(obj, "docs");
          if (_M0IP016_24default__implPB2Eq10not__equalGsE(d, "")) {
            _M0MPB3Map3setGsRPB4JsonE(enriched_obj, "summary", _M0MPC14json4Json6string(d));
          }
        }
        _M0MPC15array5Array4pushGRPB4JsonE(enriched, _M0MPC14json4Json6object(enriched_obj));
        break _L$2;
      }
      _tmp = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  let page;
  if (enriched.length > max) {
    const out = [];
    const _bind$3 = 0;
    let _tmp$2 = _bind$3;
    while (true) {
      const i = _tmp$2;
      if (i < max) {
        _M0MPC15array5Array4pushGRPB4JsonE(out, _M0MPC15array5Array2atGRPB4JsonE(enriched, i));
        _tmp$2 = i + 1 | 0;
        continue;
      } else {
        break;
      }
    }
    page = out;
  } else {
    page = enriched;
  }
  const _bind$3 = [{ _0: "package", _1: _M0IPC16string6StringPB6ToJson8to__json(pkg) }, { _0: "mode", _1: _M0IPC16string6StringPB6ToJson8to__json(mode) }, { _0: "matches", _1: _M0MPC14json4Json5array(page) }];
  return _M0MPC14json4Json6object(_M0MPB3Map11from__arrayGsRPB4JsonE(new _M0TPB9ArrayViewGUsRPB4JsonEE(_bind$3, 0, 3)));
}
function _M0FP311cogna_2ddev5cogna3sdk15fetch__packages(req) {
  return _M0MP411cogna_2ddev5cogna3sdk9generated21FetchPackagesResponse10from__json(_M0FP311cogna_2ddev5cogna3sdk21fetch__packages__json());
}
function _M0FP311cogna_2ddev5cogna3sdk15query__outlines(req) {
  return _M0MP411cogna_2ddev5cogna3sdk9generated21QueryOutlinesResponse10from__json(_M0FP311cogna_2ddev5cogna3sdk29query__outlines__for__package(req.package));
}
function _M0FP311cogna_2ddev5cogna3sdk5query(req) {
  return _M0MP411cogna_2ddev5cogna3sdk9generated13QueryResponse10from__json(_M0FP311cogna_2ddev5cogna3sdk14query__package(req.package, req.exact_id, req.exact_symbol, req.text, req.limit, req.cursor));
}
function _M0FP311cogna_2ddev5cogna3sdk19fetch__packages__js(req) {
  return _M0FP311cogna_2ddev5cogna3sdk15fetch__packages(req);
}
function _M0FP311cogna_2ddev5cogna3sdk19query__outlines__js(req) {
  return _M0FP311cogna_2ddev5cogna3sdk15query__outlines(req);
}
function _M0FP311cogna_2ddev5cogna3sdk9query__js(req) {
  return _M0FP311cogna_2ddev5cogna3sdk5query(req);
}
export { _M0FP311cogna_2ddev5cogna3sdk19fetch__packages__js as fetch_packages, _M0FP311cogna_2ddev5cogna3sdk19query__outlines__js as query_outlines, _M0FP311cogna_2ddev5cogna3sdk9query__js as query }

