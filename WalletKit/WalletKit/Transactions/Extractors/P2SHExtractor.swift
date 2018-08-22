import Foundation

class P2SHExtractor: ScriptExtractor {
    static let scriptLength = 23

    var type: ScriptType { return .p2sh }

    func extract(from script: Script, converter: ScriptConverter) throws -> Data {
        guard script.length == P2SHExtractor.scriptLength else {
            throw ScriptError.wrongScriptLength
        }
        let validCodes = OpCode.p2shStart + Data(bytes: [0x14]) + OpCode.p2shFinish
        try script.validate(opCodes: validCodes)

        guard script.chunks.count > 1, let pushData = script.chunks[1].data else {
            throw ScriptError.wrongSequence
        }
        return pushData
    }

}
