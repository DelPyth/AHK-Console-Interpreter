/*
	* Lib: JSON.ahk
	*     JSON lib for AutoHotkey.
	* Version:
	*     v2.1.3 [updated 04/18/2016 (MM/DD/YYYY)]
	* Edit:
	*     Edited by Delta [3/24/2018]
	* License:
	*     WTFPL [http://wtfpl.net/]
	* Requirements:
	*     Latest version of AutoHotkey (v1.1+ or v2.0-a+)
	* Installation:
	*     Use #Include JSON.ahk or copy into a function library folder and then
	*     use #Include <JSON>
	* Links:
	*     GitHub:     - https://github.com/cocobelgica/AutoHotkey-JSON
	*     Forum Topic - http://goo.gl/r0zI8t
	*     Email:      - cocobelgica <at> gmail <dot> com
*/

/*
	* Class: JSON
	*     The JSON object contains methods for parsing JSON and converting values
	*     to JSON. Callable - NO; Instantiable - YES; Subclassable - YES;
	*     Nestable(via #Include) - NO.
	* Methods:
	*     Load() - see relevant documentation before method definition header
	*     Dump() - see relevant documentation before method definition header
*/
class JSON {

	/*
		* Method: LoadFile
		*     Loads a file to parse
		* Syntax:
		*     value := JSON.LoadFile(file)
		* Parameter(s):
		*     value		 [retval] - parsed value
		*     file	[in, fileloc] - file to parse
		*     args		[in, opt] - args to pass to the Load method
	*/
	class LoadFile extends JSON.Functor {
		Call(Self, File, Args*) {
			Return, JSON.Load(FileOpen(File, "r").Read(), Args*)
		}
	}

	/*
		* Method: Load
		*     Parses a JSON string into an AHK value
		* Syntax:
		*     value := JSON.Load( text [, reviver ] )
		* Parameter(s):
		*     value      [retval] - parsed value
		*     text    [in, ByRef] - JSON formatted string
		*     reviver   [in, opt] - function object, similar to JavaScript's
		*                           JSON.parse() 'reviver' parameter
	*/
	class Load extends JSON.Functor {
		Call(Self, ByRef text, reviver := "") {
			This.rev := IsObject(reviver) ? reviver : false
		; Object keys(and array indices) are temporarily stored in arrays so that
		; we can enumerate them in the order they appear in the document/text instead
		; of alphabetically. Skip if no reviver function is specified.
			This.keys := This.rev ? {} : false

			static quot := Chr(34), bashq := "\" quot
				, json_value := quot . "{[01234567890-tfn"
				, json_value_or_array_closing := quot "{[]01234567890-tfn"
				, object_key_or_object_closing := quot "}"

			key := ""
			is_key := false
			root := {}
			stack := [root]
			next := json_value
			pos := 0
			text := RegExReplace(text, "im)((?:[\t ]+|)\/\/.*)$") ; Removes single line comments
			text := RegExReplace(text, "im)(\/\*([^*]|[\r\n]|(\*+([^*\/]|[\r\n])))*\*\/)$") ; Remove valid block comments

			/*
				Valid blocks include the same as this comment. Single line, or multi-line.
			*/

			; Built In Vars
			; Not needed, but still useful.
			text := RegExReplace(text, "i)\$\(Working_Dir\)", StrReplace(A_WorkingDir "\", "\", "\\"))
			text := RegExReplace(text, "i)\$\(Base_Dir\)", StrReplace(A_ScriptDir "\", "\", "\\"))
			text := RegExReplace(text, "i)\$\(Desktop\)", StrReplace(A_Desktop "\", "\", "\\"))
			text := RegExReplace(text, "i)\$\(AppData\)", StrReplace(A_AppData "\", "\", "\\"))

			While ((ch := SubStr(text, ++pos, 1)) != "") {
				If InStr(" `t`r`n", ch)
					Continue
				If !InStr(next, ch, 1)
					This.ParseError(next, text, pos)

				holder := stack[1]
				is_array := holder.IsArray

				if InStr(",:", ch) {
					next := (is_key := !is_array && ch == ",") ? quot : json_value

				} else if InStr("}]", ch) {
					ObjRemoveAt(stack, 1)
					next := stack[1]==root ? "" : stack[1].IsArray ? ",]" : ",}"

				} else {
					if InStr("{[", ch) {
					; Check if Array() is overridden and if its return value has
					; the 'IsArray' property. If so, Array() will be called normally,
					; otherwise, use a custom base object for arrays
						static json_array := Func("Array").IsBuiltIn || ![].IsArray ? {IsArray: true} : 0

					; sacrifice readability for minor(actually negligible) performance gain
						(ch == "{")
							? ( is_key := true
							  , value := {}
							  , next := object_key_or_object_closing )
						; ch == "["
							: ( value := json_array ? new json_array : []
							  , next := json_value_or_array_closing )

						ObjInsertAt(stack, 1, value)

						if (This.keys)
							This.keys[value] := []

					} else {
						if (ch == quot) {
							i := pos
							while (i := InStr(text, quot,, i+1)) {
								value := StrReplace(SubStr(text, pos+1, i-pos-1), "\\", "\u005c")

								static tail := A_AhkVersion<"2" ? 0 : -1
								if (SubStr(value, tail) != "\")
									break
							}

							if (!i)
								This.ParseError("'", text, pos)

							  value := StrReplace(value,  "\/",  "/")
							, value := StrReplace(value, bashq, quot)
							, value := StrReplace(value,  "\b", "`b")
							, value := StrReplace(value,  "\\",  "\")
							, value := StrReplace(value,  "\f", "`f")
							, value := StrReplace(value,  "\n", "`n")
							, value := StrReplace(value,  "\r", "`r")
							, value := StrReplace(value,  "\t", "`t")

							pos := i ; update pos

							i := 0
							while (i := InStr(value, "\",, i+1)) {
								if !(SubStr(value, i+1, 1) == "u")
									This.ParseError("\", text, pos - StrLen(SubStr(value, i+1)))

								uffff := Abs("0x" . SubStr(value, i+2, 4))
								if (A_IsUnicode || uffff < 0x100)
									value := SubStr(value, 1, i-1) . Chr(uffff) . SubStr(value, i+6)
							}

							if (is_key) {
								key := value, next := ":"
								continue
							}

						} else {
							value := SubStr(text, pos, i := RegExMatch(text, "[\]\},\s]|$",, pos)-pos)

							static number := "number", integer :="integer"
							if value is %number%
							{
								if value is %integer%
									value += 0
							}
							else if (value == "true" || value == "false")
								value := %value% + 0
							else if (value == "null")
								value := ""
							else
							; we can do more here to pinpoint the actual culprit
							; but that's just too much extra work.
								This.ParseError(next, text, pos, i)

							pos += i-1
						}

						next := holder==root ? "" : is_array ? ",]" : ",}"
					} ; If InStr("{[", ch) { ... } else

					is_array? key := ObjPush(holder, value) : holder[key] := value

					if (This.keys && This.keys.HasKey(holder))
						This.keys[holder].Push(key)
				}

			} ; while ( ... )

			return This.rev ? This.Walk(root, "") : root[""]
		}

		ParseError(expect, ByRef text, pos, len:=1) {
			static quot := Chr(34), qurly := quot . "}"
			static offset := A_AhkVersion < "2" ? -3 : -4

			line := StrSplit(SubStr(text, 1, pos), "`n", "`r").Length()
			col := pos - InStr(text, "`n",, -(StrLen(text)-pos+1))
			msg := Format("{1}`n`nLine:`t{2}`nCol:`t{3}`nChar:`t{4}"
				, (expect == "")     ? "Extra data"
				: (expect == "'")    ? "Unterminated string starting at"
				: (expect == "\")    ? "Invalid \escape"
				: (expect == ":")    ? "Expecting ':' delimiter"
				: (expect == quot)   ? "Expecting object key enclosed in double quotes"
				: (expect == qurly)  ? "Expecting object key enclosed in double quotes or object closing '}'"
				: (expect == ",}")   ? "Expecting ',' delimiter or object closing '}'"
				: (expect == ",]")   ? "Expecting ',' delimiter or array closing ']'"
				: InStr(expect, "]") ? "Expecting JSON value or array closing ']'"
				:						"Expecting JSON value (string, number, true, false, null, object or array)"
			, line, col, pos)

			Throw, Exception(Msg, A_ThisFunc, SubStr(text, pos, len))
		}

		Walk(holder, key) {
			value := holder[key]
			if IsObject(value) {
				for i, k in This.keys[value] {
					; check if ObjHasKey(value, k) ??
					v := This.Walk(value, k)
					if (v != JSON.Undefined)
						value[k] := v
					else
						ObjDelete(value, k)
				}
			}

			return This.rev.Call(holder, key, value)
		}
	}

	/*
		* Method: Dump
		*     Converts an AHK value into a JSON string
		* Syntax:
		*     str := JSON.Dump( value [, replacer, space ] )
		* Parameter(s):
		*     str        [retval] - JSON representation of an AHK value
		*     value          [in] - any value(object, string, number)
		*     replacer  [in, opt] - function object, similar to JavaScript's
		*                           JSON.stringify() 'replacer' parameter
		*     space     [in, opt] - similar to JavaScript's JSON.stringify()
		*                           'space' parameter
	*/
	class Dump extends JSON.Functor {
		Call(self, value, replacer := "", space := "") {
			This.rep := IsObject(replacer) ? replacer : ""

			This.gap := ""
			if (space) {
				static integer := "integer"
				if space is %integer%
					Loop, % ((n := Abs(space))>10 ? 10 : n)
						This.gap .= " "
				else
					This.gap := SubStr(space, 1, 10)

				This.indent := "`n"
			}

			return This.Str({"": value}, "")
		}

		Str(holder, key) {
			value := holder[key]

			if (This.rep)
				value := This.rep.Call(holder, key, ObjHasKey(holder, key) ? value : JSON.Undefined)

			if IsObject(value) {
			; Check object type, skip serialization for other object types such as
			; ComObject, Func, BoundFunc, FileObject, RegExMatchObject, Property, etc.
				static type := A_AhkVersion < "2" ? "" : Func("Type")
				if (type ? type.Call(value) == "Object" : ObjGetCapacity(value) != "") {
					if (This.gap) {
						stepback := This.indent
						This.indent .= This.gap
					}

					is_array := value.IsArray
				; Array() is not overridden, rollback to old method of
				; identifying array-like objects. Due to the use of a for-loop
				; sparse arrays such as '[1,,3]' are detected as objects({}).
					if (!is_array) {
						for i in value
							is_array := i == A_Index
						until !is_array
					}

					str := ""
					if (is_array) {
						Loop, % value.Length() {
							if (This.gap)
								str .= This.indent

							v := This.Str(value, A_Index)
							str .= (v != "") ? v . "," : "null,"
						}
					} else {
						colon := This.gap ? ": " : ":"
						for k in value {
							v := This.Str(value, k)
							if (v != "") {
								if (This.gap)
									str .= This.indent

								str .= This.Quote(k) . colon . v . ","
							}
						}
					}

					if (str != "") {
						str := RTrim(str, ",")
						if (This.gap)
							str .= stepback
					}

					if (This.gap)
						This.indent := stepback

					return is_array ? "[" . str . "]" : "{" . str . "}"
				}

			} else ; is_number ? value : "value"
				return ObjGetCapacity([value], 1)=="" ? value : This.Quote(value)
		}

		Quote(string) {
			static quot := Chr(34), bashq := "\" . quot

			if (string != "") {
				  string := StrReplace(string,  "\",  "\\")
				, string := StrReplace(string,  "/",  "\/") ; optional in ECMAScript
				, string := StrReplace(string, quot, bashq)
				, string := StrReplace(string, "`b",  "\b")
				, string := StrReplace(string, "`f",  "\f")
				, string := StrReplace(string, "`n",  "\n")
				, string := StrReplace(string, "`r",  "\r")
				, string := StrReplace(string, "`t",  "\t")

				static rx_escapable := A_AhkVersion < "2" ? "O)[^\x20-\x7e]" : "[^\x20-\x7e]"
				while RegExMatch(string, rx_escapable, m)
					string := StrReplace(string, m.Value, Format("\u{1:04x}", Ord(m.Value)))
			}

			return quot . string . quot
		}
	}

	/*
		* Property: Undefined
		*     Proxy for 'undefined' type
		* Syntax:
		*     undefined := JSON.Undefined
		* Remarks:
		*     For use with reviver and replacer functions since AutoHotkey does not
		*     have an 'undefined' type. Returning blank("") or 0 won't work since these
		*     can't be distnguished from actual JSON values. This leaves us with objects.
		*     Replacer() - the caller may return a non-serializable AHK objects such as
		*     ComObject, Func, BoundFunc, FileObject, RegExMatchObject, and Property to
		*     mimic the behavior of returning 'undefined' in JavaScript but for the sake
		*     of code readability and convenience, it's better to do 'return JSON.Undefined'.
		*     Internally, the property returns a ComObject with the variant type of VT_EMPTY.
	*/
	Undefined[] {
		get {
			static empty := {}, vt_empty := ComObject(0, &empty, 1)
			return vt_empty
		}
	}

	class Functor {
		__Call(method, ByRef arg, args*) {
		; When casting to Call(), use a new instance of the "function object"
		; so as to avoid directly storing the properties(used across sub-methods)
		; into the "function object" itself.
			if IsObject(method)
				return (new this).Call(method, arg, args*)
			else if (method == "")
				return (new this).Call(arg, args*)
		}
	}
}
