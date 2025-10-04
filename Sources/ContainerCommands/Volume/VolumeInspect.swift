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
import Foundation

extension Application.VolumeCommand {
    public struct VolumeInspect: AsyncParsableCommand {
        public static let configuration = CommandConfiguration(
            commandName: "inspect",
            abstract: "Display information about one or more volumes"
        )

        @OptionGroup
        var global: Flags.Global

        @Argument(help: "Volume names")
        var names: [String]

        public init() {}

        public func run() async throws {
            var volumes: [Volume] = []

            for name in names {
                let volume = try await ClientVolume.inspect(name)
                volumes.append(volume)
            }

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601

            let data = try encoder.encode(volumes)
            print(String(data: data, encoding: .utf8)!)
        }
    }
}
