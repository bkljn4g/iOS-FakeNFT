import Foundation

protocol NftStorage: AnyObject {
    func saveNft(_ nft: Nft)
    func getNft(with id: String) -> Nft?
    func clearStorage()
    func delete(_ id: String)
}

final class NftStorageImpl: NftStorage {
    private var storage: [String: Nft] = [:]

    private let syncQueue = DispatchQueue(label: "sync-nft-queue")

    func saveNft(_ nft: Nft) {
        syncQueue.async { [weak self] in
            self?.storage[nft.id] = nft
        }
    }

    func getNft(with id: String) -> Nft? {
        syncQueue.sync {
            storage[id]
        }
    }
    
    func clearStorage() {
        storage = [:]
    }
    
    func delete(_ id: String) {
        storage.removeValue(forKey: id)
    }
}
