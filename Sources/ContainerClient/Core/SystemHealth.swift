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

import Foundation

/// Snapshot of the health of container services and resources
public struct SystemHealth: Sendable, Codable {
    /// The full pathname of the application data root.
    public let appRoot: URL

    /// The full pathname of the application install root.
    public let installRoot: URL

    /// The release version of the container services.
    public let apiServerVersion: String

    /// The Git commit ID for the container services.
    public let apiServerCommit: String
}
