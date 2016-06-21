package preparation_test

import (
	"math/rand"
	"testing"
	"time"

	"github.com/cloudfoundry-incubator/cf-test-helpers/cf"
	"github.com/cloudfoundry-incubator/cf-test-helpers/helpers"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var (
	context        helpers.SuiteContext
	config         helpers.Config
	defaultTimeout time.Duration = 30 * time.Second
	cfPushTimeout  time.Duration = 2 * time.Minute
)

func TestPreparation(t *testing.T) {
	config = helpers.LoadConfig()

	if config.DefaultTimeout > 0 {
		defaultTimeout = config.DefaultTimeout * time.Second
	}

	if config.CfPushTimeout > 0 {
		cfPushTimeout = config.CfPushTimeout * time.Second
	}

	context = helpers.NewPersistentAppContext(config)
	environment := helpers.NewEnvironment(context)

	BeforeSuite(func() {
		cf.AsUser(context.AdminUserContext(), context.ShortTimeout(), func() {
			cf.Cf("delete-org", "-f", config.PersistentAppOrg).Wait(defaultTimeout)
		})

		environment.Setup()
		rand.Seed(time.Now().Unix())
	})

	RegisterFailHandler(Fail)
	RunSpecs(t, "Preparation Suite")
}
