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

func propertyBool(_ source: TISInputSource, _ key: CFString) -> Bool {
    guard let object = propertyObject(source, key) else {
        return false
    }
    if let number = object as? NSNumber {
        return number.boolValue
    }
    return false
}

func inputSources(filter: [String: Any]) -> [TISInputSource] {
    guard let unmanaged = TISCreateInputSourceList(filter as CFDictionary, true) else {
        return []
    }
    return unmanaged.takeRetainedValue() as? [TISInputSource] ?? []
}

func findRulemak() -> TISInputSource? {
    let exactIDs = [
        "org.custom.keyboardlayout.rulemak-cdh.rulemak-cdh",
        "org.unknown.keylayout.Rulemak-CDH",
    ]

    for id in exactIDs {
        let sources = inputSources(filter: [kTISPropertyInputSourceID as String: id])
        if let enabled = sources.first(where: { propertyBool($0, kTISPropertyInputSourceIsEnabled) }) {
            return enabled
        }
        if let source = sources.first {
            return source
        }
    }

    let named = inputSources(filter: [kTISPropertyLocalizedName as String: "Rulemak-CDH"])
    if let enabled = named.first(where: { propertyBool($0, kTISPropertyInputSourceIsEnabled) }) {
        return enabled
    }
    if let source = named.first {
        return source
    }

    return nil
}

let args = CommandLine.arguments
guard args.count == 2 else {
    fputs("usage: \(args[0]) /path/to/Rulemak-CDH.keylayout-or-bundle\n", stderr)
    exit(64)
}

let url = URL(fileURLWithPath: args[1])
var didRegister = false

if findRulemak() == nil {
    let registerStatus = TISRegisterInputSource(url as CFURL)
    guard registerStatus == noErr else {
        fputs("TISRegisterInputSource failed: \(registerStatus)\n", stderr)
        exit(1)
    }
    didRegister = true
}

guard var source = findRulemak() else {
    fputs("Rulemak-CDH is not registered in TIS\n", stderr)
    exit(2)
}

let enableStatus = TISEnableInputSource(source)

guard let refreshedSource = findRulemak() else {
    fputs("Rulemak-CDH disappeared after enable attempt\n", stderr)
    exit(3)
}
source = refreshedSource

let enabled = propertyBool(source, kTISPropertyInputSourceIsEnabled)
let selectCapable = propertyBool(source, kTISPropertyInputSourceIsSelectCapable)
let hasUnicodeData = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) != nil

print("name=\(propertyString(source, kTISPropertyLocalizedName))")
print("id=\(propertyString(source, kTISPropertyInputSourceID))")
print("bundle=\(propertyString(source, kTISPropertyBundleID))")
print("registered=\(didRegister ? 1 : 0)")
print("enableStatus=\(enableStatus)")
print("enabled=\(enabled ? 1 : 0)")
print("selectCapable=\(selectCapable ? 1 : 0)")
print("unicodeLayoutData=\(hasUnicodeData ? "yes" : "no")")

if enabled && selectCapable {
    let selectStatus = TISSelectInputSource(source)
    guard selectStatus == noErr else {
        fputs("TISSelectInputSource failed: \(selectStatus)\n", stderr)
        exit(4)
    }
    exit(0)
}

exit(5)
