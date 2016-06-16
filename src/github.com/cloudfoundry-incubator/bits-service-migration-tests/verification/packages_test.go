package verification_test

import (
	. "github.com/cloudfoundry-incubator/bits-service-migration-tests/helpers"
	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gexec"
)

var _ = Describe("Packages", func() {
	It("starts an app with a package previously uploaded", func() {
		Expect(cf.Cf("start", PackageTestAppName).Wait(cfPushTimeout)).To(Exit(0))
	})
})
