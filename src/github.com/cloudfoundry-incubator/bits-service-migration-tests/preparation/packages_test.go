package preparation_test

import (
	. "github.com/cloudfoundry-incubator/bits-service-migration-tests/helpers"
	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gexec"
)

var _ = Describe("Packages", func() {
	It("starts an app", func() {
		Expect(cf.Cf("push", PackageTestAppName, "--no-start", "-p", TestAppPath, "-d", config.AppsDomain).Wait(defaultTimeout)).To(Exit(0))
		SetBackend(PackageTestAppName)
	})
})
