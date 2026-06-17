import Carbon
import Foundation

func propertyObject(_ source: TISInputSource, _ key: CFString) -> AnyObject? {
    guard let raw = TISGetInputSourceProperty(source, key) else {
        return nil
    }
    return Unmanaged<AnyObject>.fromOpaque(raw).takeUnretainedValue()
}

func propertyString(_ source: TISInputSource, _ key: CFString) -> String {
    guard let object = propertyObject(source, key) else {
        return ""
    }
    return String(describing: object)
}

func allKeyboardLayouts() -> [TISInputSource] {
    let filter = [kTISPropertyInputSourceType as String: kTISTypeKeyboardLayout as String]
    return TISCreateInputSourceList(filter as CFDictionary, true).takeRetainedValue() as! [TISInputSource]
}

func findSource(exactID: String, needles: [String]) -> TISInputSource? {
    let sources = allKeyboardLayouts()
    if !exactID.isEmpty {
        for source in sources where propertyString(source, kTISPropertyInputSourceID) == exactID {
            return source
        }

        fputs("Exact input source id not found: \(exactID)\n", stderr)
        for source in sources {
            fputs(
                "available id=\(propertyString(source, kTISPropertyInputSourceID)) name=\(propertyString(source, kTISPropertyLocalizedName)) bundle=\(propertyString(source, kTISPropertyBundleID))\n",
                stderr
            )
        }
        return nil
    }

    for source in sources {
        let fields = [
            propertyString(source, kTISPropertyLocalizedName),
            propertyString(source, kTISPropertyInputSourceID),
            propertyString(source, kTISPropertyBundleID),
        ]
        for needle in needles {
            if fields.contains(where: { $0.range(of: needle, options: .caseInsensitive) != nil }) {
                return source
            }
        }
    }
    return nil
}

func translate(_ source: TISInputSource, keyCode: UInt16, carbonModifiers: UInt32) -> String {
    guard let raw = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else {
        return "<no-layout-data>"
    }

    let data = Unmanaged<CFData>.fromOpaque(raw).takeUnretainedValue()
    let layout = UnsafeRawPointer(CFDataGetBytePtr(data)!).assumingMemoryBound(to: UCKeyboardLayout.self)
    var deadKeyState: UInt32 = 0
    var chars = [UniChar](repeating: 0, count: 8)
    var actual = 0

    let status = chars.withUnsafeMutableBufferPointer { buffer in
        UCKeyTranslate(
            layout,
            keyCode,
            UInt16(kUCKeyActionDown),
            carbonModifiers >> 8,
            UInt32(LMGetKbdType()),
            OptionBits(kUCKeyTranslateNoDeadKeysBit),
            &deadKeyState,
            buffer.count,
            &actual,
            buffer.baseAddress!
        )
    }

    guard status == noErr else {
        return "<err:\(status)>"
    }
    guard actual > 0 else {
        return ""
    }
    return String(utf16CodeUnits: chars, count: Int(actual))
}

func escaped(_ value: String) -> String {
    var output = ""
    for scalar in value.unicodeScalars {
        let v = scalar.value
        if v < 0x20 || (v >= 0x7f && v <= 0x9f) || (v >= 0xf700 && v <= 0xf8ff) {
            output += String(format: "U+%04X", v)
        } else {
            output.append(Character(scalar))
        }
    }
    return output
}

struct ModifierCase {
    let mods: UInt32
    let name: String
}

let env = ProcessInfo.processInfo.environment
let baselineID = env["BASELINE_INPUT_SOURCE_ID"] ?? ""
let candidateID = env["CANDIDATE_INPUT_SOURCE_ID"] ?? ""
let candidateNeedle = env["CANDIDATE_NEEDLE"] ?? "rulemak"

guard let russianPC = findSource(exactID: baselineID, needles: ["RussianWin", "Russian - PC", "Russian – PC"]),
      let rulemak = findSource(exactID: candidateID, needles: [candidateNeedle])
else {
    fputs("Could not find Russian-PC or Rulemak-CDH input source\n", stderr)
    exit(2)
}

print("baseline=\(propertyString(russianPC, kTISPropertyLocalizedName)) (\(propertyString(russianPC, kTISPropertyInputSourceID)))")
print("candidate=\(propertyString(rulemak, kTISPropertyLocalizedName)) (\(propertyString(rulemak, kTISPropertyInputSourceID)))")
print("")

let shortcutKeys: [UInt16] = [
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 11, 12, 13, 14, 15, 16, 17,
    18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32,
    33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47,
    48, 49, 50, 51, 53, 123, 124, 125, 126,
]

let cases = [
    ModifierCase(mods: UInt32(cmdKey), name: "cmd"),
    ModifierCase(mods: UInt32(cmdKey | shiftKey), name: "cmd+shift"),
    ModifierCase(mods: UInt32(cmdKey | optionKey), name: "cmd+option"),
    ModifierCase(mods: UInt32(cmdKey | controlKey), name: "cmd+control"),
    ModifierCase(mods: UInt32(controlKey), name: "control"),
    ModifierCase(mods: UInt32(controlKey | shiftKey), name: "control+shift"),
    ModifierCase(mods: UInt32(controlKey | optionKey), name: "control+option"),
]

var mismatches = 0
for modCase in cases {
    for keyCode in shortcutKeys {
        let a = translate(russianPC, keyCode: keyCode, carbonModifiers: modCase.mods)
        let b = translate(rulemak, keyCode: keyCode, carbonModifiers: modCase.mods)
        if a != b {
            print("mismatch mod=\(modCase.name) key=\(keyCode) russian=\(escaped(a)) rulemak=\(escaped(b))")
            mismatches += 1
        }
    }
}

print("")
print("mismatches=\(mismatches)")
exit(mismatches == 0 ? 0 : 1)
