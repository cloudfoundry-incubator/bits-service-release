package verification_test

import (
	. "github.com/cloudfoundry-incubator/bits-service-migration-tests/helpers"
	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"
	"github.com/cloudfoundry-incubator/cf-test-helpers/generator"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gexec"
)

var _ = Describe("Buildpacks", func() {
	var appName string

	BeforeEach(func() {
		appName = generator.PrefixedRandomName("BSMT-APP-")
	})

	AfterEach(func() {
		Expect(cf.Cf("delete", appName, "-f", "-r").Wait(defaultTimeout)).To(Exit(0))
	})

	It("uses a previously uploaded buildpack", func() {
		Expect(cf.Cf("push", appName, "--no-start", "-b", BuildpackName, "-p", TestAppPath, "-d", config.AppsDomain).Wait(defaultTimeout)).To(Exit(0))
		SetBackend(appName)
		Expect(cf.Cf("start", appName).Wait(cfPushTimeout)).To(Exit(0))
	})
})
