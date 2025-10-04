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
import ContainerizationError
import Foundation

extension Application {
    public struct BuilderDelete: AsyncParsableCommand {
        public static var configuration: CommandConfiguration {
            var config = CommandConfiguration()
            config.commandName = "delete"
            config.aliases = ["rm"]
            config.abstract = "Delete the builder container"
            return config
        }

        @Flag(name: .shortAndLong, help: "Delete the builder even if it is running")
        var force = false

        @OptionGroup
        var global: Flags.Global

        public init() {}

        public func run() async throws {
            do {
                let container = try await ClientContainer.get(id: "buildkit")
                if container.status != .stopped {
                    guard force else {
                        throw ContainerizationError(.invalidState, message: "BuildKit container is not stopped, use --force to override")
                    }
                    try await container.stop()
                }
                try await container.delete()
            } catch {
                if error is ContainerizationError {
                    if (error as? ContainerizationError)?.code == .notFound {
                        return
                    }
                }
                throw error
            }
        }
    }
}
