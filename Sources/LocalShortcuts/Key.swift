//
//  Key.swift
//  LocalShortcuts
//
//  Created by Aryan Rogye on 12/4/25.
//

#if os(macOS)
import AppKit

extension LocalShortcuts {
    @MainActor
    public enum Key: String, Codable, CaseIterable, Hashable {
        // Letters
        case a, A,
             b, B,
             c, C,
             d, D,
             e, E,
             f, F,
             g, G,
             h, H,
             i, I,
             j, J,
             k, K,
             l, L,
             m, M,
             n, N,
             o, O,
             p, P,
             q, Q,
             r, R,
             s, S,
             t, T,
             u, U,
             v, V,
             w, W,
             x, X,
             y, Y,
             z, Z
        
        // Numbers
        case zero = "0"
        case one  = "1"
        case two  = "2"
        case three = "3"
        case four  = "4"
        case five  = "5"
        case six   = "6"
        case seven = "7"
        case eight = "8"
        case nine  = "9"
            
        case semi_colon = ":"
        case period = "."
        case comma  = ","
        case backtick = "`"
        
        case dollar = "$"
        case underscore = "_"
        case backslash = "\\"
        case slash = "/"

        // Common specials
        case space
        case escape
        case returnOrEnter = "return"
        case tab
        case delete // backspace
        
        case equal = "="
        case plus = "+"
        case minus = "-"
        
        case leftArrow
        case rightArrow
        case upArrow
        case downArrow
        case leftBracket = "["
        case rightBracket = "]"
        case leftBrace = "{"
        case rightBrace = "}"

        public static func activeKeys(event: NSEvent) -> [Key] {
            // Attempt to create a Key from the event; if successful, wrap it in an array.
            if let key = Key(from: event) {
                return [key]
            }
            return []
        }
    }
}

extension LocalShortcuts.Key {
    /// Create a Key from an NSEvent (for local monitors)
    init?(from event: NSEvent) {
        var key: LocalShortcuts.Key? = nil
        
        // First try character-based keys
        if let chars = event.charactersIgnoringModifiers, let first = chars.first {
            switch first {
            case "a": key = .a
            case "A": key = .A
            case "b": key = .b
            case "B": key = .B
            case "c": key = .c
            case "C": key = .C
            case "d": key = .d
            case "D": key = .D
            case "e": key = .e
            case "E": key = .E
            case "f": key = .f
            case "F": key = .F
            case "g": key = .g
            case "G": key = .G
            case "h": key = .h
            case "i": key = .i
            case "j": key = .j
            case "k": key = .k
            case "l": key = .l
            case "m": key = .m
            case "n": key = .n
            case "o": key = .o
            case "p": key = .p
            case "q": key = .q
            case "r": key = .r
            case "s": key = .s
            case "t": key = .t
            case "u": key = .u
            case "v": key = .v
            case "V": key = .V
            case "w": key = .w
            case "x": key = .x
            case "X": key = .X
            case "y": key = .y
            case "Y": key = .Y
            case "z": key = .z
            case "Z": key = .Z
            case ";", ":": key = .semi_colon
            case ".": key = .period
            case ">": key = .period
            case ",": key = .comma
            case "<": key = .comma
            case "`": key = .backtick
            case "[": key = .leftBracket
            case "{": key = .leftBrace
            case "]": key = .rightBracket
            case "}": key = .rightBrace
            case "\\": key = .backslash
            case "/": key = .slash
                
            case "0": key = .zero
            case "1": key = .one
            case "2": key = .two
            case "3": key = .three
            case "4": key = .four
            case "5": key = .five
            case "6": key = .six
            case "7": key = .seven
            case "8": key = .eight
            case "9": key = .nine
                
            case "=": key = .equal
            case "-": key = .minus
            case "_": key = .underscore
            case "+": key = .plus
            case "$": key = .dollar
                
            case " ": key = .space
            case "\r": key = .returnOrEnter
            case "\t": key = .tab
            case "\u{8}": key = .delete
                
            default:
                break
            }
        }
        
        if let key { self = key; return }
        
        // Fallback to keyCode for non-character keys
        switch event.keyCode {
        case 27: self = .minus
        case 53: self = .escape
        case 51: self = .delete
        case 36: self = .returnOrEnter
        case 48: self = .tab
        case 49: self = .space
        case 47: self = .period
        case 43: self = .comma
        case 41: self = .semi_colon
        case 123: self = .leftArrow
        case 124: self = .rightArrow
        case 125: self = .downArrow
        case 126: self = .upArrow
        default:
            return nil
        }
    }
    
    func matches(event: NSEvent) -> Bool {
        return LocalShortcuts.Key(from: event) == self
    }
    
    public var capital: Self? {
        switch self {
        case .a, .A: return .A
        case .b, .B: return .B
        case .c, .C: return .C
        case .d, .D: return .D
        case .e, .E: return .E
        case .f, .F: return .F
        case .g, .G: return .G
        case .h, .H: return .H
        case .i, .I: return .I
        case .j, .J: return .J
        case .k, .K: return .K
        case .l, .L: return .L
        case .m, .M: return .M
        case .n, .N: return .N
        case .o, .O: return .O
        case .p, .P: return .P
        case .q, .Q: return .Q
        case .r, .R: return .R
        case .s, .S: return .S
        case .t, .T: return .T
        case .u, .U: return .U
        case .v, .V: return .V
        case .w, .W: return .W
        case .x, .X: return .X
        case .y, .Y: return .Y
        case .z, .Z: return .Z
        default: return nil
        }
    }
    
    public var lowerCase: Self? {
        switch self {
        case .a, .A: return .a
        case .b, .B: return .b
        case .c, .C: return .c
        case .d, .D: return .d
        case .e, .E: return .e
        case .f, .F: return .f
        case .g, .G: return .g
        case .h, .H: return .h
        case .i, .I: return .i
        case .j, .J: return .j
        case .k, .K: return .k
        case .l, .L: return .l
        case .m, .M: return .m
        case .n, .N: return .n
        case .o, .O: return .o
        case .p, .P: return .p
        case .q, .Q: return .q
        case .r, .R: return .r
        case .s, .S: return .s
        case .t, .T: return .t
        case .u, .U: return .u
        case .v, .V: return .v
        case .w, .W: return .w
        case .x, .X: return .x
        case .y, .Y: return .y
        case .z, .Z: return .z
        default: return nil
        }
    }
}
#endif
