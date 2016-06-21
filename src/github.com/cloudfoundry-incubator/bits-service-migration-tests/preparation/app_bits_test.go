package preparation_test

import (
	"io/ioutil"
	"math/rand"

	. "github.com/cloudfoundry-incubator/bits-service-migration-tests/helpers"
	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gbytes"
	. "github.com/onsi/gomega/gexec"
)

var _ = Describe("AppBits", func() {
	var (
		randomAppPath string
	)

	const randomFileLength = 1024 * 1024 * 2

	createRandomFile := func(path string, fileSize int) error {
		b := make([]byte, fileSize)
		_, err := rand.Read(b)
		Expect(err).ToNot(HaveOccurred())
		return ioutil.WriteFile(path+"/app_file", b, 0777)
	}

	BeforeEach(func() {
		cf.Cf("delete", AppBitsAppName, "-f").Wait(defaultTimeout)

		var err error
		randomAppPath, err = ioutil.TempDir("", "app-bits-app")
		Expect(err).ToNot(HaveOccurred())

		err = createRandomFile(randomAppPath, randomFileLength)
		Expect(err).ToNot(HaveOccurred())
	})

	It("generate app_bits cache when pusing an app", func() {
		json := ResourceMatchBody(randomAppPath)
		resourceMatches := cf.Cf("curl", "-X", "PUT", "/v2/resource_match", "-d", string(json)).Wait(defaultTimeout)
		Expect(resourceMatches).To(Exit(0))
		Expect(resourceMatches).To(Say("\\[\\]"))

		Expect(cf.Cf("push", AppBitsAppName, "--no-start", "-p", randomAppPath).Wait(defaultTimeout)).To(Exit(0))
	})
})
