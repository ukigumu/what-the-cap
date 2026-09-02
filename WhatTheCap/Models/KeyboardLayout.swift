import Foundation

/// One physical key in a layout row. `code` is the macOS virtual key code
/// (the only identifier WTC ever counts). A nil code is a layout spacer.
struct KeyDef: Hashable {
    let code: UInt16?
    let legend: String
    var sublegend: String?
    var width: CGFloat = 1
    var isControl = false

    static func key(_ code: UInt16, _ legend: String, sub: String? = nil, width: CGFloat = 1) -> KeyDef {
        KeyDef(code: code, legend: legend, sublegend: sub, width: width)
    }

    static func control(_ code: UInt16, _ legend: String, width: CGFloat) -> KeyDef {
        KeyDef(code: code, legend: legend, sublegend: nil, width: width, isControl: true)
    }
}

/// Layouts are data, not branching: the heatmap and the top-keys list both
/// render whatever rows and legends the selected layout provides.
struct KeyboardLayout: Identifiable, Hashable {
    let id: String
    let name: String
    let rows: [[KeyDef]]

    private var legends: [UInt16: String] {
        var map: [UInt16: String] = [:]
        for row in rows {
            for key in row {
                if let code = key.code, map[code] == nil {
                    map[code] = key.legend
                }
            }
        }
        return map
    }

    func legend(for code: UInt16) -> String {
        legends[code] ?? "#\(code)"
    }

    static let all: [KeyboardLayout] = [.isoSpanish, .ansi]

    static let isoSpanish = KeyboardLayout(
        id: "iso-es",
        name: "ISO Spanish",
        rows: [
            [
                .key(10, "º", sub: "ª"),
                .key(18, "1", sub: "!"), .key(19, "2", sub: "\""), .key(20, "3", sub: "·"),
                .key(21, "4", sub: "$"), .key(23, "5", sub: "%"), .key(22, "6", sub: "&"),
                .key(26, "7", sub: "/"), .key(28, "8", sub: "("), .key(25, "9", sub: ")"),
                .key(29, "0", sub: "="), .key(27, "'", sub: "?"), .key(24, "¡", sub: "¿"),
                .control(51, "⌫", width: 2),
            ],
            [
                .control(48, "⇥", width: 1.5),
                .key(12, "Q"), .key(13, "W"), .key(14, "E"), .key(15, "R"), .key(17, "T"),
                .key(16, "Y"), .key(32, "U"), .key(34, "I"), .key(31, "O"), .key(35, "P"),
                .key(33, "`", sub: "^"), .key(30, "+", sub: "*"),
                .control(36, "⏎", width: 1.5),
            ],
            [
                .control(57, "⇪", width: 1.75),
                .key(0, "A"), .key(1, "S"), .key(2, "D"), .key(3, "F"), .key(5, "G"),
                .key(4, "H"), .key(38, "J"), .key(40, "K"), .key(37, "L"), .key(41, "Ñ"),
                .key(39, "´", sub: "¨"), .key(42, "Ç"),
                .control(36, "⏎", width: 1.25),
            ],
            [
                .control(56, "⇧", width: 1.25),
                .key(50, "<", sub: ">"),
                .key(6, "Z"), .key(7, "X"), .key(8, "C"), .key(9, "V"), .key(11, "B"),
                .key(45, "N"), .key(46, "M"),
                .key(43, ",", sub: ";"), .key(47, ".", sub: ":"), .key(44, "-", sub: "_"),
                .control(60, "⇧", width: 2.75),
            ],
            bottomRow,
        ]
    )

    static let ansi = KeyboardLayout(
        id: "ansi",
        name: "ANSI",
        rows: [
            [
                .key(50, "`", sub: "~"),
                .key(18, "1"), .key(19, "2"), .key(20, "3"), .key(21, "4"), .key(23, "5"),
                .key(22, "6"), .key(26, "7"), .key(28, "8"), .key(25, "9"), .key(29, "0"),
                .key(27, "-"), .key(24, "="),
                .control(51, "⌫", width: 2),
            ],
            [
                .control(48, "⇥", width: 1.5),
                .key(12, "Q"), .key(13, "W"), .key(14, "E"), .key(15, "R"), .key(17, "T"),
                .key(16, "Y"), .key(32, "U"), .key(34, "I"), .key(31, "O"), .key(35, "P"),
                .key(33, "["), .key(30, "]"), .key(42, "\\", width: 1.5),
            ],
            [
                .control(57, "⇪", width: 1.75),
                .key(0, "A"), .key(1, "S"), .key(2, "D"), .key(3, "F"), .key(5, "G"),
                .key(4, "H"), .key(38, "J"), .key(40, "K"), .key(37, "L"),
                .key(41, ";"), .key(39, "'"),
                .control(36, "⏎", width: 2.25),
            ],
            [
                .control(56, "⇧", width: 2.25),
                .key(6, "Z"), .key(7, "X"), .key(8, "C"), .key(9, "V"), .key(11, "B"),
                .key(45, "N"), .key(46, "M"),
                .key(43, ","), .key(47, "."), .key(44, "/"),
                .control(60, "⇧", width: 2.75),
            ],
            bottomRow,
        ]
    )

    private static let bottomRow: [KeyDef] = [
        .control(63, "fn", width: 1),
        .control(59, "⌃", width: 1),
        .control(58, "⌥", width: 1),
        .control(55, "⌘", width: 1.5),
        .key(49, "", width: 8),
        .control(54, "⌘", width: 1.5),
        .control(61, "⌥", width: 1),
    ]
}
