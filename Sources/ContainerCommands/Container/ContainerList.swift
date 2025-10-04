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
import ContainerNetworkService
import ContainerizationExtras
import Foundation
import SwiftProtobuf

extension Application {
    public struct ContainerList: AsyncParsableCommand {
        public static let configuration = CommandConfiguration(
            commandName: "list",
            abstract: "List containers",
            aliases: ["ls"])

        @Flag(name: .shortAndLong, help: "Include containers that are not running")
        var all = false

        @Option(name: .long, help: "Format of the output")
        var format: ListFormat = .table

        @Flag(name: .shortAndLong, help: "Only output the container ID")
        var quiet = false

        @OptionGroup
        var global: Flags.Global

        public init() {}

        public func run() async throws {
            let containers = try await ClientContainer.list()
            try printContainers(containers: containers, format: format)
        }

        private func createHeader() -> [[String]] {
            [["ID", "IMAGE", "OS", "ARCH", "STATE", "ADDR", "CPUS", "MEMORY"]]
        }

        private func printContainers(containers: [ClientContainer], format: ListFormat) throws {
            if format == .json {
                let printables = containers.map {
                    PrintableContainer($0)
                }
                let data = try JSONEncoder().encode(printables)
                print(String(data: data, encoding: .utf8)!)

                return
            }

            if self.quiet {
                containers.forEach {
                    if !self.all && $0.status != .running {
                        return
                    }
                    print($0.id)
                }
                return
            }

            var rows = createHeader()
            for container in containers {
                if !self.all && container.status != .running {
                    continue
                }
                rows.append(container.asRow)
            }

            let formatter = TableOutput(rows: rows)
            print(formatter.format())
        }
    }
}

extension ClientContainer {
    fileprivate var asRow: [String] {
        [
            self.id,
            self.configuration.image.reference,
            self.configuration.platform.os,
            self.configuration.platform.architecture,
            self.status.rawValue,
            self.networks.compactMap { try? CIDRAddress($0.address).address.description }.joined(separator: ","),
            "\(self.configuration.resources.cpus)",
            "\(self.configuration.resources.memoryInBytes / (1024 * 1024)) MB",
        ]
    }
}

struct PrintableContainer: Codable {
    let status: RuntimeStatus
    let configuration: ContainerConfiguration
    let networks: [Attachment]

    init(_ container: ClientContainer) {
        self.status = container.status
        self.configuration = container.configuration
        self.networks = container.networks
    }
}
