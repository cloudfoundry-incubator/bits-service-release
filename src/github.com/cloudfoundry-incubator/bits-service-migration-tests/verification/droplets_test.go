package verification_test

import (
	"fmt"

	. "github.com/cloudfoundry-incubator/bits-service-migration-tests/helpers"
	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gbytes"
)

var _ = Describe("Verification/Droplets", func() {
	It("finds the previously created droplet", func() {
		appGuid := GetAppGuid(DropletTestAppName)
		session := cf.Cf("curl", "-i", "--output", "/dev/null", fmt.Sprintf("/v2/apps/%v/droplet/download", appGuid)).Wait(defaultTimeout)

		Expect(session).To(Say("200 OK"))
	})
})
