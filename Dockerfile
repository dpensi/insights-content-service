# Copyright 2020 Red Hat, Inc
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM registry.access.redhat.com/ubi8/go-toolset:1.18.9-8.1675807488 AS builder

COPY . .

USER 0

# clone rules content repository and build the content service
RUN curl -ksL https://password.corp.redhat.com/RH-IT-Root-CA.crt \
         -o /etc/pki/ca-trust/source/anchors/RH-IT-Root-CA.crt && \
    update-ca-trust && \
    umask 0022 && \
    make build && \
    chmod a+x insights-content-service && \
    ./update_rules_content.sh

FROM registry.access.redhat.com/ubi8/ubi-minimal:latest

COPY --from=builder /opt/app-root/src/insights-content-service .
COPY --from=builder /opt/app-root/src/openapi.json /openapi/openapi.json
COPY --from=builder /opt/app-root/src/groups_config.yaml /groups/groups_config.yaml

# copy just the rule content instead of the whole ocp-rules repository
COPY --from=builder /opt/app-root/src/rules-content /rules-content
# copy tutorial/fake rule to external rules to be hit by all reports
COPY rules/tutorial/content/ /rules-content/external/rules

USER 1001

CMD ["/insights-content-service"]
