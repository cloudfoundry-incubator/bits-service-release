package verification_test

import (
	. "github.com/cloudfoundry-incubator/bits-service-migration-tests/helpers"
	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"
	"github.com/cloudfoundry-incubator/cf-test-helpers/helpers"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gexec"
)

var _ = Describe("BuildpackCache", func() {
	It("uses the buildpack cache when restaging an app", func() {
		restage := cf.Cf("restage", BuildpackCacheAppName).Wait(cfPushTimeout)
		Expect(restage).To(Exit(0))

		Eventually(func() string {
			return helpers.CurlAppRoot(BuildpackCacheAppName)
		}, defaultTimeout).Should(ContainSubstring("custom buildpack contents - here's a cache"))
	})
})
