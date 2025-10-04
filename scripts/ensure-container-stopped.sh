#! /bin/bash -f
# Copyright © 2025 Apple Inc. and the container project authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

domain_string=""

launchd_domain=$(launchctl managername)

if [[ "$launchd_domain" == "System" ]]; then
  domain_string="system"
elif [[ "$launchd_domain" == "Aqua" ]]; then
  domain_string="gui/$(id -u)"
elif [[ "$launchd_domain" == "Background" ]]; then
  domain_string="user/$(id -u)"
else
    echo "Unsupported launchd domain. Exiting"
    exit 1
fi

launchctl list | grep -e 'com\.apple\.container\W' | awk '{print $3}' | xargs -I % launchctl bootout $domain_string/%
