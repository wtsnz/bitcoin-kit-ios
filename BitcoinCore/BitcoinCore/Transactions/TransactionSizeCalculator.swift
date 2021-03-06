public class TransactionSizeCalculator {
    static let legacyTx = 16 + 4 + 4 + 16          //40 Version + number of inputs + number of outputs + locktime
    static let legacyWitnessData = 1               //1 Only 0x00 for legacy input
    static let witnessData = 1 + signatureLength + pubKeyLength   //108 Number of stack items for input + Size of stack item 0 + Stack item 0, signature + Size of stack item 1 + Stack item 1, pubkey
    static let witnessTx = legacyTx + 1 + 1        //42 SegWit marker + SegWit flag

    static let signatureLength = 72 + 1     // signature length plus pushByte
    static let pubKeyLength = 33 + 1         // pubKey length plus pushByte
    static let p2wpkhShLength = 22 + 1          // 0014<20byte-scriptHash> plus pushByte

    public init() {}

    private func outputSize(lockingScriptSize: Int) -> Int {
        8 + 1 + lockingScriptSize            // spentValue + scriptLength + script
    }
}

extension TransactionSizeCalculator: ITransactionSizeCalculator {

    public func transactionSize(inputs: [ScriptType], outputScriptTypes: [ScriptType]) -> Int {      // in real bytes upped to int
        transactionSize(inputs: inputs, outputScriptTypes: outputScriptTypes, pluginDataOutputSize: 0)
    }

    public func transactionSize(inputs: [ScriptType], outputScriptTypes: [ScriptType], pluginDataOutputSize: Int) -> Int {      // in real bytes upped to int
        var segWit = false
        var inputWeight = 0

        for input in inputs {
            if input.witness {
                segWit = true
                break
            }
        }

        inputs.forEach { input in
            inputWeight += inputSize(type: input) * 4      // to vbytes
            if segWit {
                inputWeight += witnessSize(type: input)
            }
        }

        var outputWeight: Int = outputScriptTypes.reduce(0) { $0 + outputSize(type: $1) } * 4 // in vbytes
        if pluginDataOutputSize > 0 {
            outputWeight += outputSize(lockingScriptSize: pluginDataOutputSize) * 4
        }
        let txWeight = segWit ? TransactionSizeCalculator.witnessTx : TransactionSizeCalculator.legacyTx

        return toBytes(fee: txWeight + inputWeight + outputWeight)
    }

    public func outputSize(type: ScriptType) -> Int {              // in real bytes
        outputSize(lockingScriptSize: Int(type.size))
    }

    public func  inputSize(type: ScriptType) -> Int {              // in real bytes
        let sigScriptLength: Int
        switch type {
        case .p2pkh: sigScriptLength = TransactionSizeCalculator.signatureLength + TransactionSizeCalculator.pubKeyLength
        case .p2pk: sigScriptLength = TransactionSizeCalculator.signatureLength
        case .p2wpkhSh: sigScriptLength = TransactionSizeCalculator.p2wpkhShLength
        default: sigScriptLength = 0
        }
        let inputTxSize: Int = 32 + 4 + 1 + sigScriptLength + 4 // PreviousOutputHex + InputIndex + sigLength + sigScript + sequence
        return inputTxSize
    }

    public func witnessSize(type: ScriptType) -> Int {             // in vbytes
        if type.witness {
            return TransactionSizeCalculator.witnessData
        }
        return TransactionSizeCalculator.legacyWitnessData
    }

    public func toBytes(fee: Int) -> Int {
        fee / 4 + (fee % 4 == 0 ? 0 : 1)
    }

}
