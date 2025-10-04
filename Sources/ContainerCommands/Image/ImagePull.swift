//===----------------------------------------------------------------------===//
// Copyright © 2025 Apple Inc. and the container project authors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//===----------------------------------------------------------------------===//

import ArgumentParser
import ContainerClient
import Containerization
import ContainerizationError
import ContainerizationOCI
import TerminalProgress

extension Application {
    public struct ImagePull: AsyncParsableCommand {
        public static let configuration = CommandConfiguration(
            commandName: "pull",
            abstract: "Pull an image"
        )

        @OptionGroup
        var global: Flags.Global

        @OptionGroup
        var registry: Flags.Registry

        @OptionGroup
        var progressFlags: Flags.Progress

        @Option(
            name: .shortAndLong,
            help: "Limit the pull to the specified architecture"
        )
        var arch: String?

        @Option(
            help: "Limit the pull to the specified OS"
        )
        var os: String?

        @Option(
            help: "Limit the pull to the specified platform (format: os/arch[/variant], takes precedence over --os and --arch)"
        )
        var platform: String?

        @Argument var reference: String

        public init() {}

        public init(platform: String? = nil, scheme: String = "auto", reference: String, disableProgress: Bool = false) {
            self.global = Flags.Global()
            self.registry = Flags.Registry(scheme: scheme)
            self.progressFlags = Flags.Progress(disableProgressUpdates: disableProgress)
            self.platform = platform
            self.reference = reference
        }

        public func run() async throws {
            var p: Platform?
            if let platform {
                p = try Platform(from: platform)
            } else if let arch {
                p = try Platform(from: "\(os ?? "linux")/\(arch)")
            } else if let os {
                p = try Platform(from: "\(os)/\(arch ?? Arch.hostArchitecture().rawValue)")
            }

            let scheme = try RequestScheme(registry.scheme)

            let processedReference = try ClientImage.normalizeReference(reference)

            var progressConfig: ProgressConfig
            if self.progressFlags.disableProgressUpdates {
                progressConfig = try ProgressConfig(disableProgressUpdates: self.progressFlags.disableProgressUpdates)
            } else {
                progressConfig = try ProgressConfig(
                    showTasks: true,
                    showItems: true,
                    ignoreSmallSize: true,
                    totalTasks: 2
                )
            }

            let progress = ProgressBar(config: progressConfig)
            defer {
                progress.finish()
            }
            progress.start()

            progress.set(description: "Fetching image")
            progress.set(itemsName: "blobs")
            let taskManager = ProgressTaskCoordinator()
            let fetchTask = await taskManager.startTask()
            let image = try await ClientImage.pull(
                reference: processedReference, platform: p, scheme: scheme, progressUpdate: ProgressTaskCoordinator.handler(for: fetchTask, from: progress.handler)
            )

            progress.set(description: "Unpacking image")
            progress.set(itemsName: "entries")
            let unpackTask = await taskManager.startTask()
            try await image.unpack(platform: p, progressUpdate: ProgressTaskCoordinator.handler(for: unpackTask, from: progress.handler))
            await taskManager.finish()
            progress.finish()
        }
    }
}
