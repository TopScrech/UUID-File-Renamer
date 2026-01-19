import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var isTargeted = false
    @State private var statusMessage = "Drop files here to rename them to a random UUID."
    @State private var lastRenamed: [String] = []

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isTargeted ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.08))
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(style: StrokeStyle(lineWidth: 3, dash: [10, 6]))
                    .foregroundStyle(isTargeted ? Color.accentColor : Color.secondary)
                VStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.down.on.square")
                        .font(.system(size: 34, weight: .semibold))
                    Text("Drop Files Here")
                        .font(.headline)
                    Text("They’ll be renamed to a UUID (extension preserved).")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)
                .padding()
            }
            .frame(width: 320, height: 220)
            .onDrop(of: [UTType.fileURL], isTargeted: $isTargeted) { providers in
                handleDrop(providers: providers)
            }

            Text(statusMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if !lastRenamed.isEmpty {
                VStack(spacing: 4) {
                    Text("Last renamed:")
                        .font(.footnote.weight(.semibold))
                    ForEach(lastRenamed.prefix(5), id: \.self) { name in
                        Text(name)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(24)
        .frame(minWidth: 380, minHeight: 360)
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard !providers.isEmpty else { return false }

        let group = DispatchGroup()
        var urls: [URL] = []

        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            group.enter()
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                defer { group.leave() }
                if let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    urls.append(url)
                } else if let url = item as? URL {
                    urls.append(url)
                }
            }
        }

        group.notify(queue: .main) {
            renameFiles(urls)
        }

        return true
    }

    private func renameFiles(_ urls: [URL]) {
        guard !urls.isEmpty else {
            statusMessage = "No files were detected."
            lastRenamed = []
            return
        }

        var renamed: [String] = []
        var failed: [String] = []

        for url in urls {
            var didAccess = false
            if url.startAccessingSecurityScopedResource() {
                didAccess = true
            }

            defer {
                if didAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            guard !url.hasDirectoryPath else {
                failed.append(url.lastPathComponent)
                continue
            }

            let directory = url.deletingLastPathComponent()
            let ext = url.pathExtension
            let uuid = UUID().uuidString
            let newName = ext.isEmpty ? uuid : "\(uuid).\(ext)"
            let newURL = directory.appendingPathComponent(newName)

            do {
                try FileManager.default.moveItem(at: url, to: newURL)
                renamed.append(url.lastPathComponent)
            } catch {
                failed.append(url.lastPathComponent)
            }
        }

        if failed.isEmpty {
            statusMessage = "Renamed \(renamed.count) file(s)."
        } else {
            statusMessage = "Renamed \(renamed.count) file(s), \(failed.count) failed."
        }
        lastRenamed = renamed
    }
}

#Preview {
    ContentView()
}
