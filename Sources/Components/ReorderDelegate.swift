import SwiftUI
import UniformTypeIdentifiers

struct ReorderDelegate: DropDelegate {
    let target: Int
    @Binding var dragging: Int?
    let engine: AudioEngine

    func dropEntered(info: DropInfo) {
        guard let from = dragging, from != target else { return }
        engine.move(from: from, to: target)
        dragging = target
    }
    func dropUpdated(info: DropInfo) -> DropProposal? { DropProposal(operation: .move) }
    func performDrop(info: DropInfo) -> Bool { dragging = nil; return true }
    func dropExited(info: DropInfo) {}
}
