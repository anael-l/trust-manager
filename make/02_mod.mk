# Copyright 2023 The cert-manager Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

$(kind_cluster_config): make/config/kind/cluster.yaml | $(bin_dir)/scratch
	cat $< | \
	sed -e 's|{{KIND_IMAGES}}|$(CURDIR)/$(images_tar_dir)|g' \
	> $@

include make/test-smoke.mk
include make/test-integration.mk
include make/test-unit.mk

# Deprecated ci-target for backwards compatibility
.PHONY: smoke-setup-trust-manager
provision-buildx: noop

# Deprecated ci-target for backwards compatibility
.PHONY: smoke
smoke:
	$(MAKE) test-unit
	$(MAKE) test-integration
	$(MAKE) test-smoke

include make/debian-trust-package.mk

.PHONY: release
## Publish all release artifacts (image + helm chart)
## @category [shared] Release
release: $(helm_chart_archive) | $(NEEDS_CRANE)
	$(MAKE) oci-push-manager
	$(MAKE) oci-maybe-push-package_debian

	@echo "RELEASE_OCI_MANAGER_IMAGE=$(oci_manager_image_name)" >> "$(GITHUB_OUTPUT)"
	@echo "RELEASE_OCI_MANAGER_TAG=$(oci_manager_image_tag)" >> "$(GITHUB_OUTPUT)"
	@echo "RELEASE_OCI_PACKAGE_DEBIAN_IMAGE=$(oci_package_debian_image_name)" >> "$(GITHUB_OUTPUT)"
	@echo "RELEASE_OCI_PACKAGE_DEBIAN_TAG=$(oci_package_debian_image_tag)" >> "$(GITHUB_OUTPUT)"
	@echo "RELEASE_HELM_CHART_NAME=$(helm_chart_name)" >> "$(GITHUB_OUTPUT)"
	@echo "RELEASE_HELM_CHART_VERSION=$(helm_chart_version)" >> "$(GITHUB_OUTPUT)"
	@echo "RELEASE_HELM_CHART_TAR=$(helm_chart_archive)" >> "$(GITHUB_OUTPUT)"

	@echo "Release complete!"

.PHONY: release-debian-trust-package
release-debian-trust-package: | $(NEEDS_CRANE)
	$(MAKE) oci-maybe-push-package_debian

	@echo "RELEASE_OCI_PACKAGE_DEBIAN_IMAGE=$(oci_package_debian_image_name)" >> "$(GITHUB_OUTPUT)"
	@echo "RELEASE_OCI_PACKAGE_DEBIAN_TAG=$(oci_package_debian_image_tag)" >> "$(GITHUB_OUTPUT)"

	@echo "Release complete!"