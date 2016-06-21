package preparation_test

import (
	. "github.com/cloudfoundry-incubator/bits-service-migration-tests/helpers"
	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gexec"
)

var _ = Describe("Buildpacks", func() {
	BeforeEach(func() {
		cf.AsUser(context.AdminUserContext(), context.ShortTimeout(), func() {
			cf.Cf("delete-buildpack", "-f", BuildpackName).Wait(defaultTimeout)
		})
	})

	It("uploads a buildpack for later use", func() {
		cf.AsUser(context.AdminUserContext(), context.ShortTimeout(), func() {
			Expect(cf.Cf("create-buildpack", BuildpackName, BuildpackPath, "1000").Wait(defaultTimeout)).To(Exit(0))
		})
	})
})
