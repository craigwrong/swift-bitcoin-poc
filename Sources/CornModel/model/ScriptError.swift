import Foundation

public enum ScriptError: Error {
    case nonStandardScript,
         unknownWitnessVersion,
         invalidScript,
         invalidInstruction
}
