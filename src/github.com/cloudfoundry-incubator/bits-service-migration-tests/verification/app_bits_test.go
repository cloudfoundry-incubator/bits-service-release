package verification_test

import (
	"io/ioutil"

	. "github.com/cloudfoundry-incubator/bits-service-migration-tests/helpers"
	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gbytes"
	. "github.com/onsi/gomega/gexec"
)

var _ = Describe("AppBits", func() {
	It("uses previously cached app_bits", func() {
		tmpFile, err := ioutil.TempFile("", "uploaded-app")
		defer tmpFile.Close()
		Expect(err).ToNot(HaveOccurred())
		appID := GetAppGuid(AppBitsAppName)

		Expect(cf.Cf("curl", "/v2/apps/"+appID+"/download", "--output", tmpFile.Name()).Wait(defaultTimeout)).To(Exit(0))

		tmpDir, err := ioutil.TempDir("", "unziped-app-path")
		Expect(err).ToNot(HaveOccurred())
		Unzip(tmpFile.Name(), tmpDir)
		resourceMatchBody := string(ResourceMatchBody(tmpDir))

		resourceMatches := cf.Cf("curl", "-X", "PUT", "/v2/resource_match", "-d", resourceMatchBody).Wait(defaultTimeout)

		Expect(resourceMatches).To(Exit(0))
		Expect(resourceMatches).To(Say(resourceMatchBody))
	})
})
