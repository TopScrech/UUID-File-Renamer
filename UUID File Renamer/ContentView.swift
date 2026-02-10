import ScrechKit
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var isTargeted = false
    @State private var isRenaming = false
    @State private var statusMessage = "Drop files here to rename them to a random UUID"
    @State private var lastRenamed: [String] = []
    @State private var progressTotal = 0
    @State private var progressCompleted = 0
    @State private var currentItemName = ""
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isTargeted ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.08))
                
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(style: StrokeStyle(lineWidth: 3, dash: [10, 6]))
                    .foregroundStyle(isTargeted ? Color.accentColor : .secondary)
                
                VStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.down.on.square")
                        .largeTitle()
                    
                    Text("Drop Files Here")
                        .headline()
                    
                    Text("Folders are kept, items inside are renamed recursively")
                        .subheadline()
                        .secondary()
                }
                .multilineTextAlignment(.center)
                .padding()
            }
            .frame(width: 320, height: 220)
            .onDrop(of: [.fileURL], isTargeted: $isTargeted) {
                handleDrop(providers: $0)
            }
            
            Text(statusMessage)
                .subheadline()
                .secondary()
                .multilineTextAlignment(.center)
            
            if isRenaming {
                VStack(spacing: 6) {
                    ProgressView(value: Double(progressCompleted), total: Double(progressTotal))
                        .frame(maxWidth: 260)
                    
                    Text("Renaming \(progressCompleted) of \(progressTotal)")
                        .footnote()
                        .secondary()
                    
                    if !currentItemName.isEmpty {
                        Text(currentItemName)
                            .footnote()
                            .secondary()
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
            }
            
            if !lastRenamed.isEmpty {
                VStack(spacing: 4) {
                    Text("Last renamed:")
                        .footnote(.semibold)
                    
                    ForEach(lastRenamed.prefix(5), id: \.self) {
                        Text($0)
                            .footnote()
                            .secondary()
                    }
                }
            }
        }
        .padding(24)
        .frame(minWidth: 380, minHeight: 360)
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard !providers.isEmpty else { return false }
        guard !isRenaming else {
            statusMessage = "Rename already in progress"
            return true
        }
        
        Task {
            let urls = await loadDroppedURLs(from: providers)
            await renameFiles(urls)
        }
        
        return true
    }
    
    private func loadDroppedURLs(from providers: [NSItemProvider]) async -> [URL] {
        await withTaskGroup(of: URL?.self) { group in
            for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                group.addTask {
                    await loadFileURL(from: provider)
                }
            }
            
            var urls: [URL] = []
            for await url in group {
                if let url {
                    urls.append(url)
                }
            }
            return urls
        }
    }
    
    private func loadFileURL(from provider: NSItemProvider) async -> URL? {
        await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                    continuation.resume(returning: url)
                    return
                }
                
                if let url = item as? URL {
                    continuation.resume(returning: url)
                    return
                }
                
                continuation.resume(returning: nil)
            }
        }
    }
    
    private func collectItemsToRename(from urls: [URL]) -> [URL] {
        let fileManager = FileManager.default
        let keys: Set<URLResourceKey> = [.isDirectoryKey]
        var collected: [URL] = []
        var seenPaths = Set<String>()
        
        func appendIfNeeded(_ url: URL) {
            let key = url.standardizedFileURL.path
            guard seenPaths.insert(key).inserted else { return }
            collected.append(url)
        }
        
        for root in urls {
            let values = try? root.resourceValues(forKeys: keys)
            
            if values?.isDirectory == true {
                if let enumerator = fileManager.enumerator(at: root, includingPropertiesForKeys: Array(keys)) {
                    for case let item as URL in enumerator {
                        let itemValues = try? item.resourceValues(forKeys: keys)
                        if itemValues?.isDirectory == false {
                            appendIfNeeded(item)
                        }
                    }
                }
            } else {
                appendIfNeeded(root)
            }
        }
        
        return collected
    }
    
    private func renameFiles(_ urls: [URL]) async {
        guard !urls.isEmpty else {
            statusMessage = "No files were detected"
            lastRenamed = []
            return
        }
        
        var accessedRoots: [URL] = []
        for url in urls where url.startAccessingSecurityScopedResource() {
            accessedRoots.append(url)
        }
        defer {
            for url in accessedRoots {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        let itemsToRename = collectItemsToRename(from: urls)
        guard !itemsToRename.isEmpty else {
            statusMessage = "No files were detected"
            lastRenamed = []
            return
        }
        
        isRenaming = true
        progressTotal = itemsToRename.count
        progressCompleted = 0
        currentItemName = ""
        statusMessage = "Renaming \(itemsToRename.count) item(s)"
        lastRenamed = []
        
        var renamed: [String] = []
        var failed: [String] = []
        let fileManager = FileManager.default
        
        for (index, url) in itemsToRename.enumerated() {
            currentItemName = url.lastPathComponent
            let directory = url.deletingLastPathComponent()
            let ext = url.pathExtension
            var newURL: URL
            
            repeat {
                let uuid = UUID().uuidString
                let newName = ext.isEmpty ? uuid : "\(uuid).\(ext)"
                newURL = directory.appendingPathComponent(newName)
            } while fileManager.fileExists(atPath: newURL.path)
            
            do {
                try fileManager.moveItem(at: url, to: newURL)
                renamed.append(url.lastPathComponent)
            } catch {
                failed.append(url.lastPathComponent)
            }
            
            progressCompleted = index + 1
            await Task.yield()
        }
        
        isRenaming = false
        currentItemName = ""
        
        if failed.isEmpty {
            statusMessage = "Renamed \(renamed.count) file(s)"
        } else {
            statusMessage = "Renamed \(renamed.count) file(s), \(failed.count) failed"
        }
        
        lastRenamed = renamed
    }
}

#Preview {
    ContentView()
}
