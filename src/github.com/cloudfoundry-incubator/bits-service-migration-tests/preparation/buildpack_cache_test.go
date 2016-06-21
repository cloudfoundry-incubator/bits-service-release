package preparation_test

import (
	"fmt"
	"io/ioutil"
	"os"
	"path"

	. "github.com/cloudfoundry-incubator/bits-service-migration-tests/helpers"
	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"
	"github.com/cloudfoundry-incubator/cf-test-helpers/helpers"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gbytes"
	. "github.com/onsi/gomega/gexec"
	archive_helpers "github.com/pivotal-golang/archiver/extractor/test_helper"
)

var _ = Describe("BuildpackCache", func() {

	var (
		matchingFilename string
		appPath          string

		buildpackPath        string
		buildpackArchivePath string
	)

	BeforeEach(func() {
		matchingFilename = fmt.Sprintf("buildpack-for-buildpack-cache-test-%s", BuildpackCacheAppName)
		cf.AsUser(context.AdminUserContext(), defaultTimeout, func() {

			cf.Cf("delete-buildpack", "-f", BuildpackCacheBuildpackName).Wait(defaultTimeout)

			var err error
			appPath, err = ioutil.TempDir("", "matching-app")
			Expect(err).ToNot(HaveOccurred())

			buildpackPath, err = ioutil.TempDir("", "matching-buildpack")
			Expect(err).ToNot(HaveOccurred())

			buildpackArchivePath = path.Join(buildpackPath, "buildpack.zip")

			archive_helpers.CreateZipArchive(buildpackArchivePath, []archive_helpers.ArchiveFile{
				{
					Name: "bin/compile",
					Body: `#!/usr/bin/env bash
mkdir -p $1 $2
if [ -f "$2/cached-file" ]; then
	cp $2/cached-file $1/content
else
	echo "cache not found" > $1/content
fi
echo "here's a cache" > $2/cached-file
`,
				},
				{
					Name: "bin/detect",
					Body: fmt.Sprintf(`#!/bin/bash
if [ -f "${1}/%s" ]; then
  echo Buildpack that needs cache
else
  echo no
  exit 1
fi
`, matchingFilename),
				},
				{
					Name: "bin/release",
					Body: `#!/usr/bin/env bash
content=$(cat $1/content)
cat <<EOF
---
config_vars:
  PATH: bin:/usr/local/bin:/usr/bin:/bin
  FROM_BUILD_PACK: "yes"
default_process_types:
  web: while true; do { echo -e 'HTTP/1.1 200 OK\r\n'; echo "custom buildpack contents - $content"; } | nc -l \$PORT; done
EOF
`,
				},
			})

			_, err = os.Create(path.Join(appPath, matchingFilename))
			Expect(err).ToNot(HaveOccurred())

			_, err = os.Create(path.Join(appPath, "some-file"))
			Expect(err).ToNot(HaveOccurred())

			createBuildpack := cf.Cf("create-buildpack", BuildpackCacheBuildpackName, buildpackArchivePath, "1001").Wait(DEFAULT_TIMEOUT)
			Expect(createBuildpack).Should(Exit(0))
			Expect(createBuildpack).Should(Say("Creating"))
			Expect(createBuildpack).Should(Say("OK"))
			Expect(createBuildpack).Should(Say("Uploading"))
			Expect(createBuildpack).Should(Say("OK"))
		})
	})

	It("creates a buildpack cache when uploading an app", func() {
		Expect(cf.Cf("push", BuildpackCacheAppName,
			"--no-start",
			"-b", BuildpackCacheBuildpackName,
			"-p", appPath,
			"-d", config.AppsDomain,
		).Wait(defaultTimeout)).To(Exit(0))
		SetBackend(BuildpackCacheAppName)

		start := cf.Cf("start", BuildpackCacheAppName).Wait(cfPushTimeout)
		Expect(start).To(Exit(0))

		Eventually(func() string {
			return helpers.CurlAppRoot(BuildpackCacheAppName)
		}, defaultTimeout).Should(ContainSubstring("custom buildpack contents - cache not found"))
	})
})
